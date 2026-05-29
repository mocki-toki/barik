import CoreWLAN
import Foundation
import SwiftUI

final class WifiStatusViewModel: ObservableObject {
    @Published var ssid: String = "Not connected"
    @Published var ipAddress: String = ""
    @Published var isConnected: Bool = false
    @Published var isAvailable: Bool = true

    private var timer: Timer?

    func start(updateInterval: TimeInterval) {
        let interval = max(updateInterval, 1)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) {
            [weak self] _ in
            self?.update()
        }
        update()
    }

    deinit {
        timer?.invalidate()
    }

    private func update() {
        let client = CWWiFiClient.shared()
        guard let interface = client.interface() else {
            isAvailable = false
            isConnected = false
            ssid = "No interface"
            ipAddress = ""
            return
        }

        if let interfaceName = interface.interfaceName {
            ipAddress = resolveIPAddress(interfaceName: interfaceName) ?? ""
        } else {
            ipAddress = ""
        }

        isAvailable = true
        var currentSSID = interface.ssid()
        if (currentSSID == nil || currentSSID!.isEmpty), let interfaceName = interface.interfaceName {
            currentSSID = fetchSSIDFallback(interfaceName: interfaceName)
        }

        if let validSSID = currentSSID, !validSSID.isEmpty {
            ssid = validSSID
            isConnected = true
        } else if !ipAddress.isEmpty {
            ssid = "Wi-Fi"
            isConnected = true
        } else {
            ssid = "Not connected"
            isConnected = false
        }
    }

    private func fetchSSIDFallback(interfaceName: String) -> String? {
        guard let result = CommandRunner.run(
            executable: "/usr/sbin/networksetup",
            arguments: ["-getairportnetwork", interfaceName]
        ), result.exitCode == 0 else {
            return nil
        }
        let output = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
        if output.contains("Current Wi-Fi Network: ") {
            return output.replacingOccurrences(of: "Current Wi-Fi Network: ", with: "")
        }
        return nil
    }

    private func resolveIPAddress(interfaceName: String) -> String? {
        var address: String?
        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddrPtr) == 0, let firstAddr = ifaddrPtr else {
            return nil
        }

        defer { freeifaddrs(ifaddrPtr) }

        var ptr = firstAddr
        while true {
            let interface = ptr.pointee
            let name = String(cString: interface.ifa_name)

            if name == interfaceName,
                let addr = interface.ifa_addr,
                addr.pointee.sa_family == UInt8(AF_INET)
            {
                var addrCopy = addr.pointee
                var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                let result = getnameinfo(
                    &addrCopy,
                    socklen_t(addrCopy.sa_len),
                    &hostBuffer,
                    socklen_t(hostBuffer.count),
                    nil,
                    0,
                    NI_NUMERICHOST
                )

                if result == 0 {
                    address = String(cString: hostBuffer)
                    break
                }
            }

            if let next = interface.ifa_next {
                ptr = next
            } else {
                break
            }
        }

        return address
    }
}

struct WifiWidget: View {
    @EnvironmentObject var configProvider: ConfigProvider
    var config: ConfigData { configProvider.config }

    @StateObject private var viewModel = WifiStatusViewModel()
    @State private var showLabel: Bool = true
    @State private var rect: CGRect = .zero

    private var updateFrequency: TimeInterval {
        config["update_freq"]?.doubleValue
            ?? config["update-freq"]?.doubleValue
            ?? 5
    }

    private var labelText: String {
        return viewModel.ssid
    }

    var body: some View {
        HStack(spacing: 8) {
            wifiIcon
            if showLabel {
                Text(labelText)
                    .font(.system(size: 12))
                    .foregroundStyle(.foregroundOutside)
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
                showLabel.toggle()
            }
        }
        .onAppear {
            if let configured = config["show-label"]?.boolValue {
                showLabel = configured
            }
            viewModel.start(updateInterval: updateFrequency)
        }
        .onChange(of: updateFrequency) { _, newValue in
            viewModel.start(updateInterval: newValue)
        }
    }

    private var wifiIcon: some View {
        if !viewModel.isAvailable {
            return Image(systemName: "wifi.slash")
                .foregroundColor(.red)
        }
        if viewModel.isConnected {
            return Image(systemName: "wifi")
                .foregroundColor(.foregroundOutside)
        }
        return Image(systemName: "wifi.slash")
            .foregroundColor(.gray)
    }
}

struct WifiWidget_Previews: PreviewProvider {
    static var previews: some View {
        WifiWidget()
            .frame(width: 240, height: 60)
            .background(Color.black)
            .environmentObject(ConfigProvider(config: [:]))
    }
}
