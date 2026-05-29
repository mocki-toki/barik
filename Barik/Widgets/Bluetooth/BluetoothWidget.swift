import Foundation
import SwiftUI

final class BluetoothStatusViewModel: ObservableObject {
    @Published var isAvailable: Bool = true
    @Published var isOn: Bool = false
    @Published var connectedCount: Int = 0

    private var timer: Timer?
    private let blueutilPath: String?

    init() {
        blueutilPath = ExecutableLocator.resolve(
            "blueutil",
            preferred: ["/opt/homebrew/bin/blueutil", "/usr/local/bin/blueutil"]
        )
    }

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

    func togglePower() {
        guard let path = blueutilPath else { return }
        DispatchQueue.global(qos: .utility).async {
            let desired = self.isOn ? "0" : "1"
            _ = CommandRunner.run(executable: path, arguments: ["-p", desired])
            DispatchQueue.main.async {
                self.refresh()
            }
        }
    }

    private func refresh() {
        guard let path = blueutilPath else {
            isAvailable = false
            isOn = false
            connectedCount = 0
            return
        }

        DispatchQueue.global(qos: .utility).async {
            let powerResult = CommandRunner.run(executable: path, arguments: ["-p"])
            let powerValue = powerResult?.output.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            let powerOn = powerValue == "1"
            var count = 0

            if powerOn {
                let connectedResult = CommandRunner.run(
                    executable: path,
                    arguments: ["--connected"]
                )
                let raw = connectedResult?.output
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                if raw.isEmpty || raw == "[]" {
                    count = 0
                } else {
                    count = raw.split(whereSeparator: \.isNewline)
                        .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                        .count
                }
            }

            DispatchQueue.main.async {
                self.isAvailable = true
                self.isOn = powerOn
                self.connectedCount = count
            }
        }
    }
}

struct BluetoothWidget: View {
    @EnvironmentObject var configProvider: ConfigProvider
    var config: ConfigData { configProvider.config }

    @StateObject private var viewModel = BluetoothStatusViewModel()
    @State private var rect: CGRect = .zero

    private var updateFrequency: TimeInterval {
        config["update_freq"]?.doubleValue
            ?? config["update-freq"]?.doubleValue
            ?? 5
    }

    var body: some View {
        HStack(spacing: 6) {
            bluetoothIcon
            if viewModel.isAvailable && viewModel.isOn && viewModel.connectedCount > 0 {
                Text("\(viewModel.connectedCount)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.foregroundOutside)
            } else if !viewModel.isAvailable {
                Text("N/A")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.gray)
            }
        }
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
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.togglePower()
        }
        .onAppear {
            viewModel.start(updateInterval: updateFrequency)
        }
        .onChange(of: updateFrequency) { _, newValue in
            viewModel.start(updateInterval: newValue)
        }
    }

    private var bluetoothIcon: some View {
        if !viewModel.isAvailable {
            return Image(systemName: "bluetooth.slash")
                .foregroundColor(.gray)
        }

        if viewModel.isOn {
            if viewModel.connectedCount > 0 {
                return Image(systemName: "bluetooth")
                    .foregroundColor(.blue)
            }
            return Image(systemName: "bluetooth")
                .foregroundColor(.foregroundOutside)
        }

        return Image(systemName: "bluetooth.slash")
            .foregroundColor(.red)
    }
}

struct BluetoothWidget_Previews: PreviewProvider {
    static var previews: some View {
        BluetoothWidget()
            .frame(width: 140, height: 60)
            .background(Color.black)
            .environmentObject(ConfigProvider(config: [:]))
    }
}
