import Foundation
import SwiftUI

final class BrewStatusViewModel: ObservableObject {
    @Published var outdatedCount: Int?
    @Published var isAvailable: Bool = true

    private var timer: Timer?
    private let brewPath: String?

    init() {
        brewPath = ExecutableLocator.resolve(
            "brew",
            preferred: [
                "/opt/homebrew/bin/brew",
                "/usr/local/bin/brew",
                "/usr/bin/brew",
            ]
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

    private func refresh() {
        guard let path = brewPath else {
            isAvailable = false
            outdatedCount = nil
            return
        }

        DispatchQueue.global(qos: .utility).async {
            let env = [
                "HOMEBREW_NO_AUTO_UPDATE": "1",
                "HOMEBREW_NO_ENV_HINTS": "1",
            ]
            let result = CommandRunner.run(
                executable: path,
                arguments: ["outdated", "--quiet"],
                environment: env
            )

            if let result = result, result.exitCode == 0 {
                let count = result.output
                    .split(whereSeparator: \.isNewline)
                    .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                    .count

                DispatchQueue.main.async {
                    self.isAvailable = true
                    self.outdatedCount = count
                }
            } else {
                DispatchQueue.main.async {
                    self.isAvailable = true
                    self.outdatedCount = nil
                }
            }
        }
    }
}

struct BrewWidget: View {
    @EnvironmentObject var configProvider: ConfigProvider
    var config: ConfigData { configProvider.config }

    @StateObject private var viewModel = BrewStatusViewModel()
    @State private var showIcon: Bool = true
    @State private var rect: CGRect = .zero

    private var updateFrequency: TimeInterval {
        config["update_freq"]?.doubleValue
            ?? config["update-freq"]?.doubleValue
            ?? 300
    }

    private var statusColor: Color {
        guard let count = viewModel.outdatedCount else {
            return .red
        }
        if count >= 30 {
            return .red
        }
        if count >= 10 {
            return .orange
        }
        if count >= 1 {
            return .yellow
        }
        return .green
    }

    private var labelText: String {
        if let count = viewModel.outdatedCount {
            return "\(count)"
        }
        return "N/A"
    }

    var body: some View {
        HStack(spacing: 6) {
            if showIcon {
                Image(systemName: "cup.and.saucer.fill")
                    .foregroundColor(statusColor)
            } else {
                Text(labelText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(statusColor)
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
            withAnimation(.smooth) {
                showIcon.toggle()
            }
        }
        .onAppear {
            viewModel.start(updateInterval: updateFrequency)
        }
        .onChange(of: updateFrequency) { _, newValue in
            viewModel.start(updateInterval: newValue)
        }
    }
}

struct BrewWidget_Previews: PreviewProvider {
    static var previews: some View {
        BrewWidget()
            .frame(width: 100, height: 60)
            .background(Color.black)
            .environmentObject(ConfigProvider(config: [:]))
    }
}
