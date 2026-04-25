import SwiftUI

struct PieShape: Shape {
    var fillAmount: Double

    var animatableData: Double {
        get { fillAmount }
        set { fillAmount = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let startAngle = Angle(degrees: -90)
        let endAngle = Angle(degrees: -90 + 360 * fillAmount)

        var path = Path()
        if fillAmount >= 1.0 {
            path.addEllipse(in: rect)
        } else if fillAmount > 0 {
            path.move(to: center)
            path.addArc(
                center: center, radius: radius,
                startAngle: startAngle, endAngle: endAngle,
                clockwise: false)
            path.closeSubpath()
        }
        return path
    }
}

struct PomodoroWidget: View {
    @EnvironmentObject var configProvider: ConfigProvider
    var config: ConfigData { configProvider.config }

    @ObservedObject private var manager = PomodoroManager.shared

    @State private var rect: CGRect = .zero

    var body: some View {
        HStack(spacing: 4) {
            if manager.showTimerText {
                Image("TomatoIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(phaseColor)
            } else {
                progressIcon
            }

            if manager.isActive && manager.showTimerText {
                Text(manager.formattedTime)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.foregroundOutside)
                    .contentTransition(.numericText())
                    .animation(.default, value: manager.timeRemaining)
            }
        }
        .shadow(color: .foregroundShadowOutside, radius: 3)
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        rect = geometry.frame(in: .global)
                    }
                    .onChange(of: geometry.frame(in: .global)) { _, newState in
                        rect = newState
                    }
            }
        )
        .experimentalConfiguration(cornerRadius: 15)
        .frame(maxHeight: .infinity)
        .background(.black.opacity(0.001))
        .onTapGesture {
            MenuBarPopup.show(rect: rect, id: "pomodoro") {
                PomodoroPopup()
            }
        }
        .onAppear {
            applyConfig()
        }
    }

    private var progressIcon: some View {
        ZStack {
            if manager.isActive {
                // Dim filled body — always visible as the "empty" state
                Image("TomatoIconFilled")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(phaseColor.opacity(0.2))

                // Filled body masked by pie — shows remaining time as fill level
                Image("TomatoIconFilled")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(phaseColor)
                    .mask(
                        PieShape(fillAmount: 1.0 - manager.progress)
                            .frame(width: 20, height: 20)
                    )
                    .animation(.linear(duration: 1), value: manager.progress)
            }

            // Outline always visible on top
            Image("TomatoIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundStyle(phaseColor)
        }
    }

    private var phaseColor: Color {
        switch manager.phase {
        case .idle: return .foregroundOutside
        case .working: return .red
        case .onBreak: return .green
        case .onLongBreak: return .blue
        }
    }

    private func applyConfig() {
        manager.workDuration = config["work-duration"]?.intValue ?? 25
        manager.breakDuration = config["break-duration"]?.intValue ?? 5
        manager.longBreakDuration = config["long-break-duration"]?.intValue ?? 15
        manager.sessionsBeforeLongBreak = config["sessions-before-long-break"]?.intValue ?? 4
        manager.showTimerText = config["icon-style"]?.stringValue == "timer"
    }
}
