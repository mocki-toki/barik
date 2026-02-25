import SwiftUI

struct ClaudeUsageWidget: View {
    @EnvironmentObject var configProvider: ConfigProvider
    @ObservedObject private var usageManager = ClaudeUsageManager.shared

    @State private var widgetFrame: CGRect = .zero

    private var percentage: Double {
        usageManager.usageData.fiveHourPercentage
    }

    private var weeklyRemaining: Double {
        max(0, min(1, 1 - usageManager.usageData.weeklyPercentage))
    }

    private var claudeOrange: Color {
        Color(red: 0.89, green: 0.45, blue: 0.29)
    }

    private var ringColor: Color {
        if percentage >= 0.8 { return .red }
        if percentage >= 0.6 { return .orange }
        return .white
    }

    var body: some View {
        ZStack {
            if usageManager.usageData.isAvailable {
                Circle()
                    .trim(from: 0.5 - min(percentage, 1.0) / 2, to: 0.5 + min(percentage, 1.0) / 2)
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .rotationEffect(.degrees(90))
                    .animation(.easeOut(duration: 0.3), value: percentage)
            }

            drainableIcon
        }
        .frame(width: 28, height: 28)
        .foregroundStyle(.foregroundOutside)
        .shadow(color: .foregroundShadowOutside, radius: 3)
        .experimentalConfiguration(cornerRadius: 15)
        .frame(maxHeight: .infinity)
        .background(.black.opacity(0.001))
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        widgetFrame = geometry.frame(in: .global)
                    }
                    .onChange(of: geometry.frame(in: .global)) { _, newFrame in
                        widgetFrame = newFrame
                    }
            }
        )
        .onTapGesture {
            MenuBarPopup.show(rect: widgetFrame, id: "claude-usage") {
                ClaudeUsagePopup()
                    .environmentObject(configProvider)
            }
        }
        .onAppear {
            usageManager.startUpdating(config: configProvider.config)
        }
    }

    private var drainableIcon: some View {
        let iconSize: CGFloat = 16

        return ZStack {
            Image("ClaudeIcon")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .foregroundStyle(.white)
                .frame(width: iconSize, height: iconSize)

            Rectangle()
                .fill(claudeOrange)
                .frame(width: iconSize, height: iconSize * weeklyRemaining)
                .frame(width: iconSize, height: iconSize, alignment: .bottom)
                .animation(.easeOut(duration: 0.8), value: weeklyRemaining)
                .mask(
                    Image("ClaudeIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: iconSize, height: iconSize)
                )
        }
    }
}
