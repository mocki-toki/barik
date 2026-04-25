import SwiftUI

struct CodexUsagePopup: View {
    @EnvironmentObject var configProvider: ConfigProvider
    @ObservedObject private var usageManager = CodexUsageManager.shared

    private var hasSecondaryWindow: Bool {
        usageManager.usageData.secondaryWindowMinutes > 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !usageManager.isConnected {
                connectView
            } else if usageManager.usageData.isAvailable {
                titleBar
                Divider().background(Color.white.opacity(0.2))
                rateLimitSection(
                    icon: "clock",
                    title: windowTitle(for: usageManager.usageData.primaryWindowMinutes),
                    percentage: usageManager.usageData.primaryPercentage,
                    resetDate: usageManager.usageData.primaryResetDate,
                    resetPrefix: "Resets in"
                )
                if hasSecondaryWindow {
                    Divider().background(Color.white.opacity(0.2))
                    rateLimitSection(
                        icon: "calendar",
                        title: windowTitle(for: usageManager.usageData.secondaryWindowMinutes),
                        percentage: usageManager.usageData.secondaryPercentage,
                        resetDate: usageManager.usageData.secondaryResetDate,
                        resetPrefix: "Resets"
                    )
                }
                Divider().background(Color.white.opacity(0.2))
                footerSection
            } else if usageManager.fetchFailed {
                errorView
            } else {
                emptyView
            }
        }
        .frame(width: 280)
        .background(Color.black)
        .onAppear {
            usageManager.reconnectIfNeeded()
        }
    }

    // MARK: - Title Bar

    private var titleBar: some View {
        HStack(spacing: 8) {
            Image("CodexIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
            Text("Codex Usage")
                .font(.system(size: 14, weight: .semibold))
            Spacer()
            Text(usageManager.usageData.plan)
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(planBadgeColor.opacity(0.3))
                .foregroundColor(planBadgeColor)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var planBadgeColor: Color {
        switch usageManager.usageData.plan.lowercased() {
        case "pro": return .orange
        case "plus": return .green
        case "team": return .blue
        case "business", "enterprise": return .purple
        case "free": return .gray
        default: return .blue
        }
    }

    // MARK: - Rate Limit Section

    private func rateLimitSection(
        icon: String,
        title: String,
        percentage: Double,
        resetDate: Date?,
        resetPrefix: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .opacity(0.6)
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                Text("\(Int(min(percentage, 1.0) * 100))%")
                    .font(.system(size: 24, weight: .semibold))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(progressColor(for: percentage))
                        .frame(
                            width: geometry.size.width * min(percentage, 1.0),
                            height: 6
                        )
                        .animation(.easeOut(duration: 0.3), value: percentage)
                }
            }
            .frame(height: 6)

            if let resetDate = resetDate {
                Text("\(resetPrefix) \(resetTimeString(resetDate))")
                    .font(.system(size: 11))
                    .opacity(0.5)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private func progressColor(for percentage: Double) -> Color {
        if percentage >= 0.8 { return .red }
        if percentage >= 0.6 { return .orange }
        return .white
    }

    private func resetTimeString(_ date: Date) -> String {
        let interval = date.timeIntervalSince(Date())
        if interval <= 0 { return "soon" }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 24 {
            let formatter = DateFormatter()
            formatter.dateFormat = "E h:mm a"
            return formatter.string(from: date)
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private func windowTitle(for minutes: Int) -> String {
        guard minutes > 0 else { return "Usage Window" }
        if minutes == 10_080 { return "Weekly" }

        if minutes % 1_440 == 0 {
            let days = minutes / 1_440
            return "\(days)-Day Window"
        }

        if minutes % 60 == 0 {
            let hours = minutes / 60
            return "\(hours)-Hour Window"
        }

        return "\(minutes)-Minute Window"
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Usage updated \(timeAgoString(usageManager.usageData.lastUpdated))")
                .font(.system(size: 11))
                .opacity(0.4)

            if let activityDate = usageManager.usageData.lastActivityDate,
               activityDate.timeIntervalSince(usageManager.usageData.lastUpdated) > 60 {
                Text("Codex active \(timeAgoString(activityDate))")
                    .font(.system(size: 10))
                    .opacity(0.3)
            }

            HStack {
                Spacer()

                Button(action: {
                    usageManager.refresh()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                        .opacity(0.6)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private func timeAgoString(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "\(seconds) sec ago" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes) min ago" }
        return "\(minutes / 60)h ago"
    }

    // MARK: - Connect

    private var connectView: some View {
        VStack(spacing: 14) {
            Image("CodexIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)

            Text("Codex Usage")
                .font(.system(size: 14, weight: .semibold))

            Text("Sign in to Codex to view your rate-limit usage directly in the menu bar.")
                .font(.system(size: 11))
                .opacity(0.5)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: {
                usageManager.refresh()
            }) {
                Text("Check Again")
                    .font(.system(size: 12, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }

            Text("Reads `~/.codex/auth.json` and the latest Codex session rate-limit snapshot.")
                .font(.system(size: 10))
                .opacity(0.3)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 30)
        .padding(.vertical, 30)
    }

    // MARK: - Empty

    private var emptyView: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.pie")
                .font(.system(size: 24))
                .opacity(0.5)

            Text("No usage data yet")
                .font(.system(size: 12, weight: .medium))

            Text("Run a Codex task first. The widget reads the latest non-empty rate-limit snapshot from your local Codex sessions.")
                .font(.system(size: 11))
                .opacity(0.5)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let activityDate = usageManager.usageData.lastActivityDate {
                Text("Latest Codex activity \(timeAgoString(activityDate))")
                    .font(.system(size: 10))
                    .opacity(0.35)
            }

            Button(action: {
                usageManager.refresh()
            }) {
                Text("Refresh")
                    .font(.system(size: 12, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 30)
        .padding(.vertical, 30)
    }

    // MARK: - Error

    private var errorView: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 24))
                .opacity(0.5)

            Text("Unable to load usage data")
                .font(.system(size: 12, weight: .medium))

            Text("Reading local Codex auth or session files failed.")
                .font(.system(size: 11))
                .opacity(0.5)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: {
                usageManager.refresh()
            }) {
                Text("Retry")
                    .font(.system(size: 12, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 30)
        .padding(.vertical, 30)
    }
}
