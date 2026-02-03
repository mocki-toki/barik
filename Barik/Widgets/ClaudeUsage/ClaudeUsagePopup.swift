import SwiftUI

struct ClaudeUsagePopup: View {
    @EnvironmentObject var configProvider: ConfigProvider
    @ObservedObject private var usageManager = ClaudeUsageManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !usageManager.isConnected {
                connectView
            } else if usageManager.usageData.isAvailable {
                titleBar
                Divider().background(Color.white.opacity(0.2))
                rateLimitSection(
                    icon: "clock",
                    title: "5-Hour Window",
                    percentage: usageManager.usageData.fiveHourPercentage,
                    resetDate: usageManager.usageData.fiveHourResetDate,
                    resetPrefix: "Resets in"
                )
                Divider().background(Color.white.opacity(0.2))
                rateLimitSection(
                    icon: "calendar",
                    title: "Weekly",
                    percentage: usageManager.usageData.weeklyPercentage,
                    resetDate: usageManager.usageData.weeklyResetDate,
                    resetPrefix: "Resets"
                )
                Divider().background(Color.white.opacity(0.2))
                footerSection
            } else {
                loadingView
            }
        }
        .frame(width: 280)
        .background(Color.black)
    }

    // MARK: - Title Bar

    private var titleBar: some View {
        HStack(spacing: 8) {
            Image("ClaudeIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
            Text("Claude Usage")
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
        case "max": return .purple
        case "team": return .blue
        case "free": return .gray
        default: return .orange
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

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            Text("Updated \(timeAgoString(usageManager.usageData.lastUpdated))")
                .font(.system(size: 11))
                .opacity(0.4)

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
            Image("ClaudeIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)

            Text("Claude Usage")
                .font(.system(size: 14, weight: .semibold))

            Text("View your Claude rate limit usage directly in the menu bar.")
                .font(.system(size: 11))
                .opacity(0.5)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: {
                usageManager.requestAccess()
            }) {
                Text("Allow Access")
                    .font(.system(size: 12, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.89, green: 0.45, blue: 0.29))
            .onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }

            Text("Reads credentials from your Claude Code keychain entry.")
                .font(.system(size: 10))
                .opacity(0.3)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 30)
        .padding(.vertical, 30)
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Loading usage data...")
                .font(.system(size: 11))
                .opacity(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}
