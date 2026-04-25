import Foundation
import SwiftUI

private let codexUsageAccountFingerprintKey = "codex-usage-account-fingerprint"
private let codexUsageAcceptedRefreshKey = "codex-usage-accepted-auth-refresh"
private let codexUsageConnectedKey = "codex-usage-connected"

// MARK: - Data Models

struct CodexUsageData {
    var primaryPercentage: Double = 0
    var primaryResetDate: Date?
    var primaryWindowMinutes: Int = 0
    var secondaryPercentage: Double = 0
    var secondaryResetDate: Date?
    var secondaryWindowMinutes: Int = 0

    var plan: String = "ChatGPT"
    var lastUpdated: Date = Date()
    var lastActivityDate: Date?
    var isAvailable: Bool = false
}

private struct CodexSessionEvent: Decodable {
    let timestamp: String
    let type: String
    let payload: Payload

    struct Payload: Decodable {
        let type: String
        let rateLimits: RateLimits?

        enum CodingKeys: String, CodingKey {
            case type
            case rateLimits = "rate_limits"
        }
    }

    struct RateLimits: Decodable {
        let limitID: String?
        let limitName: String?
        let primary: Bucket?
        let secondary: Bucket?
        let credits: Credits?
        let planType: String?

        enum CodingKeys: String, CodingKey {
            case limitID = "limit_id"
            case limitName = "limit_name"
            case primary
            case secondary
            case credits
            case planType = "plan_type"
        }
    }

    struct Bucket: Decodable {
        let usedPercent: Double
        let windowMinutes: Int
        let resetsAt: TimeInterval

        enum CodingKeys: String, CodingKey {
            case usedPercent = "used_percent"
            case windowMinutes = "window_minutes"
            case resetsAt = "resets_at"
        }
    }

    struct Credits: Decodable {
        let hasCredits: Bool?
        let unlimited: Bool?
        let balance: Double?

        enum CodingKeys: String, CodingKey {
            case hasCredits = "has_credits"
            case unlimited
            case balance
        }
    }
}

private enum CodexUsageLoadState {
    case disconnected
    case connectedWithoutSnapshot(data: CodexUsageData)
    case connected(data: CodexUsageData)
    case failed
}

private struct CodexUsageRefreshResult {
    let loadState: CodexUsageLoadState
    let watchPaths: [String]
}

private struct NormalizedCodexBucketState {
    let percentage: Double
    let resetDate: Date?
}

private enum CodexAuthReadResult {
    case missing
    case loaded(CodexAuthState)
    case unreadable
}

private struct CodexAuthState {
    let plan: String
    let accountID: String?
    let userID: String?
    let lastRefreshDate: Date?
    let subscriptionActiveStart: Date?

    var fingerprint: String? {
        let parts: [String] = [accountID, userID].compactMap { value in
            guard let value, !value.isEmpty else { return nil }
            return value
        }

        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: "|")
    }

    var switchCutoffDate: Date? {
        [lastRefreshDate, subscriptionActiveStart].compactMap { $0 }.max()
    }
}

// MARK: - Manager

@MainActor
final class CodexUsageManager: ObservableObject {
    static let shared = CodexUsageManager()

    @Published private(set) var usageData = CodexUsageData()
    @Published private(set) var isConnected: Bool = false
    @Published private(set) var fetchFailed: Bool = false

    private var refreshTimer: Timer?
    private var fileWatchSources: [DispatchSourceFileSystemObject] = []
    private var watchedPaths = Set<String>()
    private var pendingRefreshWorkItem: DispatchWorkItem?
    private var currentConfig: ConfigData = [:]
    private var isFetchInFlight = false
    private var queuedRefresh = false
    private var sourceUnavailableSince: Date?

    private static let refreshInterval: TimeInterval = 30
    private static let sourceUnavailableGraceInterval: TimeInterval = 300
    private static let fileWatchDebounceInterval: TimeInterval = 1

    private init() {
        isConnected = UserDefaults.standard.bool(forKey: codexUsageConnectedKey)

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleWake()
            }
        }
    }

    func startUpdating(config: ConfigData) {
        currentConfig = config
        connectAndFetch()
    }

    func reconnectIfNeeded() {
        connectAndFetch()
    }

    func stopUpdating() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        pendingRefreshWorkItem?.cancel()
        pendingRefreshWorkItem = nil
        stopWatchingFiles()
    }

    func refresh() {
        fetchFailed = false
        connectAndFetch()
    }

    private func handleWake() {
        refreshTimer?.invalidate()
        Task {
            try? await Task.sleep(for: .seconds(2))
            connectAndFetch()
        }
    }

    private func connectAndFetch() {
        if isFetchInFlight {
            queuedRefresh = true
            return
        }

        isFetchInFlight = true
        let planOverride = currentConfig["plan"]?.stringValue

        Task {
            let result = await Task.detached(priority: .utility) {
                let codexHome = FileManager.default.homeDirectoryForCurrentUser
                    .appendingPathComponent(".codex", isDirectory: true)
                let authURL = codexHome.appendingPathComponent("auth.json")
                let sessionsURL = codexHome.appendingPathComponent("sessions", isDirectory: true)

                return CodexUsageRefreshResult(
                    loadState: Self.loadUsage(planOverride: planOverride),
                    watchPaths: Self.watchPaths(codexHome: codexHome, authURL: authURL, sessionsURL: sessionsURL)
                )
            }.value

            self.updateWatchedPaths(result.watchPaths)
            let persistedConnected = UserDefaults.standard.bool(forKey: codexUsageConnectedKey)
            let wasConnectedBefore = self.isConnected || persistedConnected
            let now = Date()

            switch result.loadState {
            case .disconnected:
                if self.shouldPreserveStateDuringSourceLoss(now: now, wasConnectedBefore: wasConnectedBefore) {
                    self.isConnected = true
                    self.fetchFailed = false
                    self.scheduleRefreshTimer()
                } else {
                    self.sourceUnavailableSince = nil
                    self.isConnected = false
                    self.fetchFailed = false
                    self.usageData = CodexUsageData()
                    UserDefaults.standard.set(false, forKey: codexUsageConnectedKey)
                    self.scheduleRefreshTimer()
                }

            case .connectedWithoutSnapshot(let data):
                self.sourceUnavailableSince = nil
                self.isConnected = true
                self.fetchFailed = false
                UserDefaults.standard.set(true, forKey: codexUsageConnectedKey)
                if self.usageData.isAvailable {
                    self.usageData.lastActivityDate = data.lastActivityDate
                    self.usageData.plan = data.plan
                } else {
                    self.usageData = data
                }
                self.scheduleRefreshTimer()

            case .connected(let data):
                self.sourceUnavailableSince = nil
                self.isConnected = true
                self.fetchFailed = false
                self.usageData = data
                UserDefaults.standard.set(true, forKey: codexUsageConnectedKey)
                self.scheduleRefreshTimer()

            case .failed:
                if wasConnectedBefore, self.sourceUnavailableSince == nil {
                    self.sourceUnavailableSince = now
                }
                self.isConnected = wasConnectedBefore
                self.fetchFailed = !self.usageData.isAvailable && !self.shouldPreserveStateDuringSourceLoss(
                    now: now,
                    wasConnectedBefore: wasConnectedBefore
                )
                self.scheduleRefreshTimer()
            }

            self.isFetchInFlight = false
            if self.queuedRefresh {
                self.queuedRefresh = false
                self.scheduleDebouncedRefresh(delay: 0.2)
            }
        }
    }

    private func scheduleRefreshTimer() {
        refreshTimer?.invalidate()
        let timer = Timer(timeInterval: Self.refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.connectAndFetch()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        refreshTimer = timer
    }

    private func scheduleDebouncedRefresh(delay: TimeInterval? = nil) {
        pendingRefreshWorkItem?.cancel()
        let refreshDelay = delay ?? Self.fileWatchDebounceInterval

        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                self?.connectAndFetch()
            }
        }

        pendingRefreshWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + refreshDelay, execute: workItem)
    }

    private func updateWatchedPaths(_ paths: [String]) {
        let uniquePaths = Set(paths)
        guard uniquePaths != watchedPaths else { return }

        stopWatchingFiles()
        watchedPaths = uniquePaths

        for path in uniquePaths {
            let fileDescriptor = open(path, O_EVTONLY)
            guard fileDescriptor != -1 else { continue }

            let source = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: fileDescriptor,
                eventMask: [.write, .delete, .rename, .extend, .attrib, .link, .revoke],
                queue: DispatchQueue.global(qos: .utility)
            )
            source.setEventHandler { [weak self] in
                Task { @MainActor in
                    self?.scheduleDebouncedRefresh()
                }
            }
            source.setCancelHandler {
                close(fileDescriptor)
            }
            source.resume()
            fileWatchSources.append(source)
        }
    }

    private func stopWatchingFiles() {
        fileWatchSources.forEach { $0.cancel() }
        fileWatchSources.removeAll()
        watchedPaths.removeAll()
    }

    private func shouldPreserveStateDuringSourceLoss(now: Date, wasConnectedBefore: Bool) -> Bool {
        guard wasConnectedBefore else { return false }

        // Codex may rewrite local auth/session files transiently, so brief absence
        // should not be treated as a real disconnect.
        if sourceUnavailableSince == nil {
            sourceUnavailableSince = now
            return true
        }

        guard let sourceUnavailableSince else { return false }
        return now.timeIntervalSince(sourceUnavailableSince) <= Self.sourceUnavailableGraceInterval
    }

    nonisolated private static func loadUsage(planOverride: String?) -> CodexUsageLoadState {
        let codexHome = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex", isDirectory: true)
        let authURL = codexHome.appendingPathComponent("auth.json")
        let sessionsURL = codexHome.appendingPathComponent("sessions", isDirectory: true)

        let authResult = readAuthState(from: authURL)
        let auth: CodexAuthState

        switch authResult {
        case .missing:
            return .disconnected
        case .unreadable:
            return .failed
        case .loaded(let loadedAuth):
            auth = loadedAuth
        }

        let plan = resolvedPlan(
            override: planOverride,
            snapshotPlan: nil,
            authPlan: auth.plan
        )
        let cutoffDate = accountSwitchCutoffDate(for: auth)

        let activity = latestTokenActivity(in: sessionsURL)

        guard let snapshot = latestUsageSnapshot(in: sessionsURL, after: cutoffDate) else {
            var data = CodexUsageData(plan: plan)
            data.lastActivityDate = activity
            return .connectedWithoutSnapshot(data: data)
        }

        persistAccountFingerprintIfNeeded(auth)

        let primaryPercentage = bucketPercentage(snapshot.primary)
        let secondaryPercentage = bucketPercentage(snapshot.secondary)
        let data = CodexUsageData(
            primaryPercentage: primaryPercentage,
            primaryResetDate: bucketResetDate(snapshot.primary),
            primaryWindowMinutes: snapshot.primary?.windowMinutes ?? 0,
            secondaryPercentage: secondaryPercentage,
            secondaryResetDate: bucketResetDate(snapshot.secondary),
            secondaryWindowMinutes: snapshot.secondary?.windowMinutes ?? 0,
            plan: resolvedPlan(
                override: planOverride,
                snapshotPlan: snapshot.plan,
                authPlan: auth.plan
            ),
            lastUpdated: snapshot.timestamp,
            lastActivityDate: activity,
            isAvailable: true
        )
        return .connected(data: normalizedUsageData(data))
    }

    nonisolated private static func readAuthState(from authURL: URL) -> CodexAuthReadResult {
        var sawAuthFile = false

        for attempt in 0..<3 {
            if FileManager.default.fileExists(atPath: authURL.path) {
                sawAuthFile = true

                if let data = try? Data(contentsOf: authURL),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let authState = decodeAuthState(from: json) {
                    return .loaded(authState)
                }
            }

            if attempt < 2 {
                Thread.sleep(forTimeInterval: 0.2)
            }
        }

        return sawAuthFile ? .unreadable : .missing
    }

    nonisolated private static func decodeAuthState(from json: [String: Any]) -> CodexAuthState? {
        let authMode = json["auth_mode"] as? String
        if authMode == "apikey" || authMode == "api_key" {
            return CodexAuthState(
                plan: "API Key",
                accountID: nil,
                userID: nil,
                lastRefreshDate: parseTimestamp(json["last_refresh"] as? String ?? ""),
                subscriptionActiveStart: nil
            )
        }

        guard let tokens = json["tokens"] as? [String: Any] else {
            return nil
        }

        let accountID = tokens["account_id"] as? String
        let lastRefreshDate = parseTimestamp(json["last_refresh"] as? String ?? "")

        let candidateTokens = [
            tokens["id_token"] as? String,
            tokens["access_token"] as? String,
        ]

        for token in candidateTokens {
            guard let token,
                  let payload = decodeJWTPayload(token),
                  let auth = payload["https://api.openai.com/auth"] as? [String: Any],
                  let plan = auth["chatgpt_plan_type"] as? String,
                  !plan.isEmpty else {
                continue
            }
            return CodexAuthState(
                plan: plan,
                accountID: auth["chatgpt_account_id"] as? String ?? accountID,
                userID: auth["chatgpt_user_id"] as? String ?? auth["user_id"] as? String,
                lastRefreshDate: lastRefreshDate,
                subscriptionActiveStart: parseTimestamp(auth["chatgpt_subscription_active_start"] as? String ?? "")
            )
        }

        return nil
    }

    nonisolated private static func latestUsageSnapshot(in sessionsURL: URL, after cutoffDate: Date?) -> (primary: CodexSessionEvent.Bucket?, secondary: CodexSessionEvent.Bucket?, plan: String?, timestamp: Date)? {
        typealias Snapshot = (primary: CodexSessionEvent.Bucket?, secondary: CodexSessionEvent.Bucket?, plan: String?, timestamp: Date)

        var latestCanonicalSnapshot: Snapshot?
        var latestFallbackSnapshot: Snapshot?

        for fileURL in recentSessionFiles(in: sessionsURL) {
            guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
                continue
            }

            for line in content.split(separator: "\n").reversed() {
                guard line.contains(#""type":"token_count""#),
                      line.contains(#""rate_limits":"#) else {
                    continue
                }
                guard let event = decodeEvent(from: line),
                      event.type == "event_msg",
                      event.payload.type == "token_count",
                      let rateLimits = event.payload.rateLimits,
                      let timestamp = parseTimestamp(event.timestamp) else {
                    continue
                }

                if rateLimits.primary == nil, rateLimits.secondary == nil {
                    continue
                }

                if let cutoffDate, timestamp < cutoffDate {
                    continue
                }

                let snapshot = (
                    primary: rateLimits.primary,
                    secondary: rateLimits.secondary,
                    plan: rateLimits.planType,
                    timestamp: timestamp
                )
                if isCanonicalUsageSnapshot(rateLimits) {
                    if latestCanonicalSnapshot == nil || latestCanonicalSnapshot!.timestamp < timestamp {
                        latestCanonicalSnapshot = snapshot
                    }
                } else if latestFallbackSnapshot == nil || latestFallbackSnapshot!.timestamp < timestamp {
                    latestFallbackSnapshot = snapshot
                }
                break
            }
        }

        return latestCanonicalSnapshot ?? latestFallbackSnapshot
    }

    nonisolated private static func accountSwitchCutoffDate(for auth: CodexAuthState) -> Date? {
        guard let fingerprint = auth.fingerprint else {
            return nil
        }

        let defaults = UserDefaults.standard
        guard let previousFingerprint = defaults.string(forKey: codexUsageAccountFingerprintKey) else {
            return auth.switchCutoffDate
        }

        guard previousFingerprint == fingerprint else {
            return auth.switchCutoffDate
        }

        guard defaults.object(forKey: codexUsageAcceptedRefreshKey) != nil else {
            return auth.switchCutoffDate
        }

        return nil
    }

    nonisolated private static func persistAccountFingerprintIfNeeded(_ auth: CodexAuthState) {
        guard let fingerprint = auth.fingerprint else {
            return
        }

        UserDefaults.standard.set(fingerprint, forKey: codexUsageAccountFingerprintKey)
        if let refreshDate = auth.switchCutoffDate {
            UserDefaults.standard.set(refreshDate.timeIntervalSince1970, forKey: codexUsageAcceptedRefreshKey)
        }
    }

    nonisolated private static func latestTokenActivity(in sessionsURL: URL) -> Date? {
        var latestActivity: Date?

        for fileURL in recentSessionFiles(in: sessionsURL) {
            guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
                continue
            }

            for line in content.split(separator: "\n").reversed() {
                guard line.contains(#""type":"token_count""#) else { continue }
                guard let event = decodeEvent(from: line),
                      event.type == "event_msg",
                      event.payload.type == "token_count",
                      let timestamp = parseTimestamp(event.timestamp) else {
                    continue
                }

                if let latestActivity, latestActivity >= timestamp {
                    break
                }

                latestActivity = timestamp
                break
            }
        }

        return latestActivity
    }

    nonisolated private static func recentSessionFiles(in sessionsURL: URL) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: sessionsURL,
            includingPropertiesForKeys: [.isRegularFileKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return enumerator
            .compactMap { $0 as? URL }
            .filter { $0.pathExtension == "jsonl" }
            .sorted { lhs, rhs in
                let lhsDate = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                let rhsDate = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                if lhsDate == rhsDate {
                    return lhs.path > rhs.path
                }
                return lhsDate > rhsDate
            }
            .prefix(100)
            .map { $0 }
    }

    nonisolated private static func watchPaths(codexHome: URL, authURL: URL, sessionsURL: URL) -> [String] {
        let fileManager = FileManager.default
        let watchedSessionFileLimit = 8
        var paths = Set<String>()

        if fileManager.fileExists(atPath: codexHome.path) {
            paths.insert(codexHome.path)
        }

        if fileManager.fileExists(atPath: authURL.path) {
            paths.insert(authURL.path)
        }

        if fileManager.fileExists(atPath: sessionsURL.path) {
            paths.insert(sessionsURL.path)
        }

        for fileURL in recentSessionFiles(in: sessionsURL).prefix(watchedSessionFileLimit) {
            paths.insert(fileURL.path)

            var directoryURL = fileURL.deletingLastPathComponent()
            while directoryURL.path.hasPrefix(sessionsURL.path) {
                paths.insert(directoryURL.path)

                if directoryURL.path == sessionsURL.path {
                    break
                }

                directoryURL.deleteLastPathComponent()
            }
        }

        return Array(paths)
    }

    nonisolated private static func decodeEvent(from line: Substring) -> CodexSessionEvent? {
        guard let data = String(line).data(using: .utf8) else {
            return nil
        }

        return try? JSONDecoder().decode(CodexSessionEvent.self, from: data)
    }

    nonisolated private static func isCanonicalUsageSnapshot(_ rateLimits: CodexSessionEvent.RateLimits) -> Bool {
        rateLimits.limitID == "codex"
    }

    nonisolated private static func bucketPercentage(_ bucket: CodexSessionEvent.Bucket?) -> Double {
        guard let bucket else { return 0 }
        return max(0, min(bucket.usedPercent / 100, 1))
    }

    nonisolated private static func bucketResetDate(_ bucket: CodexSessionEvent.Bucket?) -> Date? {
        guard let bucket else { return nil }
        return Date(timeIntervalSince1970: bucket.resetsAt)
    }

    nonisolated private static func parseTimestamp(_ rawValue: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: rawValue)
    }

    nonisolated private static func decodeJWTPayload(_ token: String) -> [String: Any]? {
        let segments = token.split(separator: ".")
        guard segments.count >= 2 else { return nil }

        var payload = String(segments[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let padding = 4 - (payload.count % 4)
        if padding < 4 {
            payload += String(repeating: "=", count: padding)
        }

        guard let data = Data(base64Encoded: payload),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        return json
    }

    nonisolated private static func formatPlan(_ rawValue: String) -> String {
        switch rawValue.lowercased() {
        case "free":
            "Free"
        case "plus":
            "Plus"
        case "pro":
            "Pro"
        case "team":
            "Team"
        case "business":
            "Business"
        case "enterprise":
            "Enterprise"
        case "api key":
            "API Key"
        default:
            rawValue
                .replacingOccurrences(of: "-", with: " ")
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
        }
    }

    nonisolated private static func resolvedPlan(
        override: String?,
        snapshotPlan: String?,
        authPlan: String
    ) -> String {
        if let override = normalizedPlanValue(override) {
            return formatPlan(override)
        }

        if let snapshotPlan = normalizedPlanValue(snapshotPlan) {
            return formatPlan(snapshotPlan)
        }

        return formatPlan(authPlan)
    }

    nonisolated private static func normalizedPlanValue(_ rawValue: String?) -> String? {
        guard let rawValue else { return nil }

        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        switch trimmed.lowercased() {
        case "unknown", "null", "nil", "none":
            return nil
        default:
            return trimmed
        }
    }

    nonisolated private static func normalizedUsageData(
        _ data: CodexUsageData,
        now: Date = Date()
    ) -> CodexUsageData {
        var normalized = data

        let primary = normalizedBucketState(
            percentage: data.primaryPercentage,
            resetDate: data.primaryResetDate,
            windowMinutes: data.primaryWindowMinutes,
            now: now
        )
        normalized.primaryPercentage = primary.percentage
        normalized.primaryResetDate = primary.resetDate

        let secondary = normalizedBucketState(
            percentage: data.secondaryPercentage,
            resetDate: data.secondaryResetDate,
            windowMinutes: data.secondaryWindowMinutes,
            now: now
        )
        normalized.secondaryPercentage = secondary.percentage
        normalized.secondaryResetDate = secondary.resetDate

        return normalized
    }

    nonisolated private static func normalizedBucketState(
        percentage: Double,
        resetDate: Date?,
        windowMinutes: Int,
        now: Date
    ) -> NormalizedCodexBucketState {
        guard let resetDate else {
            return NormalizedCodexBucketState(percentage: percentage, resetDate: nil)
        }

        guard resetDate <= now else {
            return NormalizedCodexBucketState(percentage: percentage, resetDate: resetDate)
        }

        guard windowMinutes > 0 else {
            return NormalizedCodexBucketState(percentage: 0, resetDate: nil)
        }

        let windowInterval = TimeInterval(windowMinutes * 60)
        let elapsedWindows = Int(now.timeIntervalSince(resetDate) / windowInterval)
        let nextResetDate = resetDate.addingTimeInterval(
            windowInterval * Double(max(0, elapsedWindows) + 1)
        )

        return NormalizedCodexBucketState(percentage: 0, resetDate: nextResetDate)
    }
}
