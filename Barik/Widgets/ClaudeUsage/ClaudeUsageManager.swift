import Foundation
import Security
import SwiftUI

// MARK: - Data Models

struct ClaudeUsageData {
    var fiveHourPercentage: Double = 0
    var fiveHourResetDate: Date?

    var weeklyPercentage: Double = 0
    var weeklyResetDate: Date?

    var plan: String = "Pro"
    var lastUpdated: Date = Date()
    var isAvailable: Bool = false
}

private struct UsageResponse: Codable {
    let fiveHour: UsageBucket?
    let sevenDay: UsageBucket?
    let sevenDaySonnet: UsageBucket?

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
        case sevenDaySonnet = "seven_day_sonnet"
    }

    struct UsageBucket: Codable {
        let utilization: Double
        let resetsAt: String?

        enum CodingKeys: String, CodingKey {
            case utilization
            case resetsAt = "resets_at"
        }
    }
}

// MARK: - Manager

@MainActor
final class ClaudeUsageManager: ObservableObject {
    static let shared = ClaudeUsageManager()

    @Published private(set) var usageData = ClaudeUsageData()
    @Published private(set) var isConnected: Bool = false
    @Published private(set) var fetchFailed: Bool = false
    @Published private(set) var errorMessage: String?

    private var refreshTimer: Timer?
    private var cachedCredentials: (accessToken: String, plan: String)?
    private var currentConfig: ConfigData = [:]

    private static let connectedKey = "claude-usage-connected"
    private static let refreshInterval: TimeInterval = 120

    private init() {
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
        reconnectIfNeeded()
    }

    /// Called when the popup appears. Reconnects silently if the user previously granted access,
    /// deferring keychain access until the user actually interacts with the widget.
    func reconnectIfNeeded() {
        if !isConnected && UserDefaults.standard.bool(forKey: Self.connectedKey) {
            connectAndFetch()
        }
    }

    func stopUpdating() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    func refresh() {
        fetchFailed = false
        errorMessage = nil
        // Re-read keychain on manual retry — the token may have been refreshed by Claude Code.
        connectAndFetch()
    }

    /// Called when user explicitly clicks "Allow Access" in the popup.
    /// Triggers the macOS Keychain permission dialog.
    func requestAccess() {
        connectAndFetch()
    }

    private func handleWake() {
        guard isConnected else { return }
        refreshTimer?.invalidate()
        // Delay briefly to allow the network stack to reconnect after sleep,
        // then re-read keychain credentials (the token may have been refreshed).
        Task {
            try? await Task.sleep(for: .seconds(2))
            connectAndFetch()
        }
    }

    private func connectAndFetch() {
        guard let creds = readKeychainCredentials() else {
            isConnected = false
            cachedCredentials = nil
            errorMessage = nil
            UserDefaults.standard.set(false, forKey: Self.connectedKey)
            return
        }

        cachedCredentials = creds
        isConnected = true
        UserDefaults.standard.set(true, forKey: Self.connectedKey)
        fetchData()

        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: Self.refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.fetchData()
            }
        }
    }

    // MARK: - Data Fetching

    private func fetchData() {
        guard let creds = cachedCredentials else { return }

        let plan = currentConfig["plan"]?.stringValue ?? creds.plan

        Task {
            let result = await fetchUsageWithRetry(token: creds.accessToken)

            switch result {
            case .success(let response):
                let isoFormatter = ISO8601DateFormatter()
                isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

                var data = ClaudeUsageData()
                data.fiveHourPercentage = (response.fiveHour?.utilization ?? 0) / 100
                data.fiveHourResetDate = response.fiveHour.flatMap { bucket in
                    bucket.resetsAt.flatMap { isoFormatter.date(from: $0) }
                }
                data.weeklyPercentage = (response.sevenDay?.utilization ?? 0) / 100
                data.weeklyResetDate = response.sevenDay.flatMap { bucket in
                    bucket.resetsAt.flatMap { isoFormatter.date(from: $0) }
                }
                data.plan = plan.capitalized
                data.lastUpdated = Date()
                data.isAvailable = true

                self.fetchFailed = false
                self.errorMessage = nil
                self.usageData = data

            case .rateLimited:
                self.fetchFailed = true
                self.errorMessage = "Claude is rate limiting usage checks right now. Try again later."

            case .failed:
                self.fetchFailed = true
                self.errorMessage = "The request failed. Your token may have expired."
            }
        }
    }

    // MARK: - API

    private func fetchUsageWithRetry(token: String) async -> FetchResult {
        // Try up to 2 times: initial + 1 retry if rate-limited.
        for attempt in 0..<2 {
            let result = await fetchUsageFromAPI(token: token)
            switch result {
            case .success:
                return result
            case .rateLimited(let retryAfter):
                guard attempt == 0, retryAfter > 0, retryAfter <= 180 else { return .rateLimited(retryAfter: retryAfter) }
                try? await Task.sleep(for: .seconds(retryAfter))
                continue
            case .failed:
                return .failed
            }
        }
        return .failed
    }

    private enum FetchResult {
        case success(UsageResponse)
        case rateLimited(retryAfter: Int)
        case failed
    }

    private func fetchUsageFromAPI(token: String) async -> FetchResult {
        guard let url = URL(string: "https://api.anthropic.com/api/oauth/usage") else { return .failed }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.setValue("claude-code/2.1.69", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return .failed }

            if http.statusCode == 429 {
                let retryAfter = http.value(forHTTPHeaderField: "retry-after")
                    .flatMap(Int.init) ?? 0
                return .rateLimited(retryAfter: retryAfter)
            }
            guard http.statusCode == 200 else { return .failed }

            if let decoded = try? JSONDecoder().decode(UsageResponse.self, from: data) {
                return .success(decoded)
            }
            return .failed
        } catch {
            return .failed
        }
    }

    // MARK: - Keychain

    private func readKeychainCredentials() -> (accessToken: String, plan: String)? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "Claude Code-credentials",
            kSecReturnData as String: true,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let oauth = json["claudeAiOauth"] as? [String: Any],
              let token = oauth["accessToken"] as? String else {
            return nil
        }
        let plan = oauth["subscriptionType"] as? String ?? "pro"
        return (token, plan)
    }
}
