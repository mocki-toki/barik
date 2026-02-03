import SwiftUI

struct PomodoroPopup: View {
    @ObservedObject private var manager = PomodoroManager.shared
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 16) {
            // Header with settings toggle
            ZStack {
                Text(manager.isActive ? manager.phase.rawValue : "Pomodoro")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(phaseColor)
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showSettings.toggle()
                        }
                    } label: {
                        Image(systemName: showSettings ? "xmark" : "gearshape")
                            .font(.system(size: 11))
                            .foregroundStyle(.gray)
                    }
                    .buttonStyle(.plain)
                }
            }

            if showSettings {
                settingsView
            } else {
                timerView
            }
        }
        .frame(width: 180)
        .padding(24)
    }

    @ViewBuilder
    private var timerView: some View {
        // Circular progress ring
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 6)
            Circle()
                .trim(from: 0, to: manager.isActive ? manager.progress : 0)
                .stroke(
                    phaseColor,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: manager.progress)

            VStack(spacing: 2) {
                Text(manager.isActive ? manager.formattedTime : "0:00")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.default, value: manager.timeRemaining)

                if manager.isPaused {
                    Text("Paused")
                        .font(.system(size: 10))
                        .foregroundStyle(.gray)
                }
            }
        }
        .frame(width: 80, height: 80)

        // Session dots
        if manager.isActive || manager.completedSessions > 0 {
            HStack(spacing: 6) {
                ForEach(0..<manager.sessionsBeforeLongBreak, id: \.self) { i in
                    Circle()
                        .fill(i < manager.completedSessions ? phaseColor : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
        }

        // Controls
        HStack(spacing: 12) {
            if !manager.isActive {
                controlButton("play.fill", color: .green) {
                    manager.start()
                }
            } else {
                if manager.isPaused {
                    controlButton("play.fill", color: .green) {
                        manager.resume()
                    }
                } else {
                    controlButton("pause.fill", color: .yellow) {
                        manager.pause()
                    }
                }
                controlButton("forward.fill", color: .blue) {
                    manager.skip()
                }
                controlButton("stop.fill", color: .red) {
                    manager.reset()
                }
            }
        }
    }

    @ViewBuilder
    private var settingsView: some View {
        VStack(spacing: 12) {
            durationStepper("Work", value: $manager.workDuration, range: 1...60)
            durationStepper("Break", value: $manager.breakDuration, range: 1...30)
            durationStepper("Long Break", value: $manager.longBreakDuration, range: 1...60)
            durationStepper("Sessions", value: $manager.sessionsBeforeLongBreak, range: 1...10)
        }
        .frame(width: 160)
    }

    private var phaseColor: Color {
        switch manager.phase {
        case .idle: return .white
        case .working: return .red
        case .onBreak: return .green
        case .onLongBreak: return .blue
        }
    }

    private func controlButton(_ systemName: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.15))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func durationStepper(_ label: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.gray)
            Spacer()
            HStack(spacing: 8) {
                Button {
                    if value.wrappedValue > range.lowerBound {
                        value.wrappedValue -= 1
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Text("\(value.wrappedValue)")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
                    .frame(width: 28)

                Button {
                    if value.wrappedValue < range.upperBound {
                        value.wrappedValue += 1
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
