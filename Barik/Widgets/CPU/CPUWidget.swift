import Darwin
import Foundation
import SwiftUI

final class CPUUsageViewModel: ObservableObject {
    @Published var totalUsage: Double = 0
    @Published var userUsage: Double = 0
    @Published var systemUsage: Double = 0
    @Published var userHistory: [Double] = []
    @Published var systemHistory: [Double] = []
    @Published var topProcess: String = "CPU"

    private var timer: Timer?
    private var previousLoad: host_cpu_load_info?
    private let maxSamples = 60

    func start(updateInterval: TimeInterval) {
        let interval = max(updateInterval, 1)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) {
            [weak self] _ in
            self?.refresh()
        }
        refresh()
    }

    deinit {
        timer?.invalidate()
    }

    private func refresh() {
        DispatchQueue.global(qos: .utility).async {
            var load = host_cpu_load_info()
            var count = mach_msg_type_number_t(
                MemoryLayout.size(ofValue: load) / MemoryLayout<integer_t>.size
            )

            let result = withUnsafeMutablePointer(to: &load) { ptr in
                ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                    host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
                }
            }

            guard result == KERN_SUCCESS else { return }

            guard let previous = self.previousLoad else {
                self.previousLoad = load
                return
            }

            let user = Double(load.cpu_ticks.0 - previous.cpu_ticks.0)
            let system = Double(load.cpu_ticks.1 - previous.cpu_ticks.1)
            let idle = Double(load.cpu_ticks.2 - previous.cpu_ticks.2)
            let nice = Double(load.cpu_ticks.3 - previous.cpu_ticks.3)

            let total = user + system + idle + nice
            guard total > 0 else {
                self.previousLoad = load
                return
            }

            let userPercent = max(0, min(1, user / total))
            let systemPercent = max(0, min(1, system / total))
            let totalPercent = max(0, min(1, userPercent + systemPercent))

            let topProcess = self.readTopProcessLabel()

            DispatchQueue.main.async {
                self.userUsage = userPercent
                self.systemUsage = systemPercent
                self.totalUsage = totalPercent
                self.topProcess = topProcess

                var userHistory = self.userHistory
                var systemHistory = self.systemHistory

                userHistory.append(userPercent)
                systemHistory.append(systemPercent)

                if userHistory.count > self.maxSamples {
                    userHistory.removeFirst(userHistory.count - self.maxSamples)
                }
                if systemHistory.count > self.maxSamples {
                    systemHistory.removeFirst(systemHistory.count - self.maxSamples)
                }

                self.userHistory = userHistory
                self.systemHistory = systemHistory
            }

            self.previousLoad = load
        }
    }

    private func readTopProcessLabel() -> String {
        guard
            let result = CommandRunner.run(
                executable: "/bin/ps",
                arguments: ["-Aceo", "pid,pcpu,comm", "-r"]
            ),
            result.exitCode == 0
        else {
            return "CPU"
        }

        let lines = result.output.split(whereSeparator: \.isNewline)
        guard lines.count >= 2 else {
            return "CPU"
        }

        let line = lines[1]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = line.split(whereSeparator: \.isWhitespace)
        guard parts.count >= 3 else {
            return "CPU"
        }

        let pid = parts[0]
        let nameParts = parts.dropFirst(2)
        let rawName = nameParts.joined(separator: " ")
        let cleaned = rawName.replacingOccurrences(of: "com.apple.", with: "")
        let label = "\(pid) \(cleaned)"
        return String(label.prefix(28))
    }
}

struct CPUWidget: View {
    @EnvironmentObject var configProvider: ConfigProvider
    var config: ConfigData { configProvider.config }

    @StateObject private var viewModel = CPUUsageViewModel()
    @State private var rect: CGRect = .zero

    private var updateFrequency: TimeInterval {
        config["update_freq"]?.doubleValue
            ?? config["update-freq"]?.doubleValue
            ?? 2
    }

    private var usageColor: Color {
        let usage = viewModel.totalUsage
        if usage >= 0.7 {
            return .red
        }
        if usage >= 0.3 {
            return .orange
        }
        if usage >= 0.1 {
            return .yellow
        }
        return .green
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(alignment: .center, spacing: 4) {
                CPUUsageGraph(
                    userValues: viewModel.userHistory,
                    systemValues: viewModel.systemHistory
                )
                .frame(width: 75, height: 22)
                .padding(.bottom, 6)
                .padding(.leading, 4)

                Text("\(Int(viewModel.totalUsage * 100))%")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(usageColor)
                    .frame(minWidth: 35, alignment: .trailing)
            }
             .padding(.top, 12)

            Text(viewModel.topProcess)
                .font(.system(size: 7, weight: .semibold))
                .foregroundStyle(.foregroundOutside)
                .opacity(0.8)
                .padding(.top, 4)
        }
        .monospacedDigit()
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear { rect = geometry.frame(in: .global) }
                    .onChange(of: geometry.frame(in: .global)) { _, newValue in
                        rect = newValue
                    }
            }
        )
        .experimentalConfiguration(cornerRadius: 15)
        .frame(maxHeight: .infinity)
        .background(.black.opacity(0.001))
        .onAppear {
            viewModel.start(updateInterval: updateFrequency)
        }
        .onChange(of: updateFrequency) { _, newValue in
            viewModel.start(updateInterval: newValue)
        }
    }
}

struct CPUUsageGraph: View {
    let userValues: [Double]
    let systemValues: [Double]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                areaPath(for: systemValues, in: geometry.size)
                    .fill(Color.red.opacity(0.5))
                areaPath(for: userValues, in: geometry.size)
                    .fill(Color.blue.opacity(0.5))
                linePath(for: systemValues, in: geometry.size)
                    .stroke(Color.red, lineWidth: 1)
                linePath(for: userValues, in: geometry.size)
                    .stroke(Color.blue, lineWidth: 1)
            }
        }
    }

    private func linePath(for values: [Double], in size: CGSize) -> Path {
        var path = Path()
        guard values.count > 1 else { return path }

        let stepX = size.width / CGFloat(values.count - 1)
        for (index, value) in values.enumerated() {
            let x = CGFloat(index) * stepX
            let y = size.height - (CGFloat(min(max(value, 0), 1)) * size.height)
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }

    private func areaPath(for values: [Double], in size: CGSize) -> Path {
        var path = Path()
        guard values.count > 1 else { return path }

        let stepX = size.width / CGFloat(values.count - 1)
        path.move(to: CGPoint(x: 0, y: size.height))

        for (index, value) in values.enumerated() {
            let x = CGFloat(index) * stepX
            let y = size.height - (CGFloat(min(max(value, 0), 1)) * size.height)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.closeSubpath()
        return path
    }
}

struct CPUWidget_Previews: PreviewProvider {
    static var previews: some View {
        CPUWidget()
            .frame(width: 180, height: 60)
            .background(Color.black)
            .environmentObject(ConfigProvider(config: [:]))
    }
}
