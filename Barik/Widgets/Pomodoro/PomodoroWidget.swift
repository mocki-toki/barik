import SwiftUI

struct PomodoroWidget: View {
    @EnvironmentObject var configProvider: ConfigProvider
    var config: ConfigData { configProvider.config }

    @ObservedObject private var manager = PomodoroManager.shared

    @State private var rect: CGRect = .zero

    var body: some View {
        HStack(spacing: 4) {
            Image("TomatoIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundStyle(phaseColor)

            if manager.isActive {
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
    }
}
