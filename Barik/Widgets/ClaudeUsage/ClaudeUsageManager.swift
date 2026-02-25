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
        let resetsAt: String

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

    private var refreshTimer: Timer?
    private var cachedCredentials: (accessToken: String, plan: String)?
    private var currentConfig: ConfigData = [:]

    private static let connectedKey = "claude-usage-connected"

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
        if cachedCredentials == nil {
            connectAndFetch()
        } else {
            fetchData()
        }
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
            UserDefaults.standard.set(false, forKey: Self.connectedKey)
            return
        }

        cachedCredentials = creds
        isConnected = true
        UserDefaults.standard.set(true, forKey: Self.connectedKey)
        fetchData()

        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
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
            guard let response = await fetchUsageFromAPI(token: creds.accessToken) else { return }

            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            var data = ClaudeUsageData()
            data.fiveHourPercentage = (response.fiveHour?.utilization ?? 0) / 100
            data.fiveHourResetDate = response.fiveHour.flatMap { isoFormatter.date(from: $0.resetsAt) }
            data.weeklyPercentage = (response.sevenDay?.utilization ?? 0) / 100
            data.weeklyResetDate = response.sevenDay.flatMap { isoFormatter.date(from: $0.resetsAt) }
            data.plan = plan.capitalized
            data.lastUpdated = Date()
            data.isAvailable = true

            self.usageData = data
        }
    }

    // MARK: - API

    private func fetchUsageFromAPI(token: String) async -> UsageResponse? {
        guard let url = URL(string: "https://api.anthropic.com/api/oauth/usage") else { return nil }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.timeoutInterval = 5

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              http.statusCode == 200 else { return nil }

        return try? JSONDecoder().decode(UsageResponse.self, from: data)
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
