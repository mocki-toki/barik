import SwiftUI

struct CountdownPopup: View {
    @ObservedObject private var manager = CountdownManager.shared
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Text("Countdown")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
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
                countdownView
            }
        }
        .frame(width: 260)
        .padding(24)
    }

    @ViewBuilder
    private var countdownView: some View {
        VStack(spacing: 8) {
            Text("\(manager.daysRemaining)")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(manager.daysRemaining == 1
                 ? "day until \(manager.label)!"
                 : "days until \(manager.label)!")
                .font(.system(size: 13))
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)

            Text(formattedTargetDate)
                .font(.system(size: 11))
                .foregroundStyle(.gray.opacity(0.6))
                .padding(.top, 4)
        }
    }

    @ViewBuilder
    private var settingsView: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Label")
                    .font(.system(size: 11))
                    .foregroundStyle(.gray)
                TextField("Event name", text: $manager.label)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Target Date")
                    .font(.system(size: 11))
                    .foregroundStyle(.gray)
                HStack(spacing: 6) {
                    Stepper("", value: $manager.targetMonth, in: 1...12)
                        .labelsHidden()
                    Text("\(monthName)/\(String(format: "%02d", manager.targetDay))/\(String(manager.targetYear))")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.white)
                }

                HStack(spacing: 8) {
                    stepperRow("Month", value: $manager.targetMonth, range: 1...12)
                    stepperRow("Day", value: $manager.targetDay, range: 1...31)
                    stepperRow("Year", value: $manager.targetYear, range: 2025...2100)
                }
            }
        }
    }

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        var components = DateComponents()
        components.month = manager.targetMonth
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return ""
    }

    private var formattedTargetDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: manager.targetDate)
    }

    private func stepperRow(_ label: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.gray)
            HStack(spacing: 4) {
                Button {
                    if value.wrappedValue > range.lowerBound {
                        value.wrappedValue -= 1
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Text("\(value.wrappedValue)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .fixedSize()
                    .frame(minWidth: 20)

                Button {
                    if value.wrappedValue < range.upperBound {
                        value.wrappedValue += 1
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
