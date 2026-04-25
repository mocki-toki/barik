import SwiftUI

struct CodexUsageWidget: View {
    @EnvironmentObject var configProvider: ConfigProvider
    @ObservedObject private var usageManager = CodexUsageManager.shared

    @State private var widgetFrame: CGRect = .zero

    private var percentage: Double {
        usageManager.usageData.primaryPercentage
    }

    private var weeklyPercentage: Double {
        let usageData = usageManager.usageData
        if usageData.secondaryWindowMinutes > 0 {
            return usageData.secondaryPercentage
        }
        return usageData.primaryPercentage
    }

    private var weeklyRemaining: Double {
        max(0, min(1, 1 - weeklyPercentage))
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
            MenuBarPopup.show(rect: widgetFrame, id: "codex-usage") {
                CodexUsagePopup()
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
            Image("CodexIcon")
                .resizable()
                .scaledToFit()
                .opacity(0.28)
                .frame(width: iconSize, height: iconSize)

            Image("CodexIcon")
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .mask(
                    Rectangle()
                        .frame(width: iconSize, height: iconSize * weeklyRemaining)
                        .frame(width: iconSize, height: iconSize, alignment: .bottom)
                )
                .animation(.easeOut(duration: 0.8), value: weeklyRemaining)
        }
    }
}
