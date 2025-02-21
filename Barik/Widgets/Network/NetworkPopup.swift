import SwiftUI

/// Window displaying detailed network status information.
struct NetworkPopup: View {
    @StateObject private var viewModel = NetworkStatusViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if viewModel.wifiState != .notSupported {
                HStack(spacing: 8) {
                    wifiIcon
                    Text(viewModel.ssid)
                        .foregroundColor(.white)
                        .font(.headline)
                }

                if viewModel.ssid != "Not connected" && viewModel.ssid != "No interface" {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Signal strength: \(viewModel.wifiSignalStrength.rawValue)")
                        Text("RSSI: \(viewModel.rssi)")
                        Text("Noise: \(viewModel.noise)")
                        Text("Channel: \(viewModel.channel)")
                    }
                    .font(.subheadline)
                }
            }
            
            // Ethernet section
            if viewModel.ethernetState != .notSupported {
                HStack(spacing: 8) {
                    ethernetIcon
                    Text("Ethernet: \(viewModel.ethernetState.rawValue)")
                        .foregroundColor(.white)
                        .font(.headline)
                }
            }
        }
        .padding(30)
        .background(Color.black)
    }
    
    /// Chooses the Wi‑Fi icon based on the status and connection availability.
    private var wifiIcon: some View {
        if viewModel.ssid == "Not connected" {
            return Image(systemName: "wifi.slash")
                .padding(8)
                .background(Color.red.opacity(0.8))
                .clipShape(Circle())
                .foregroundStyle(.white)
        }
        switch viewModel.wifiState {
        case .connected:
            return Image(systemName: "wifi")
                .padding(8)
                .background(Color.blue.opacity(0.8))
                .clipShape(Circle())
                .foregroundStyle(.white)
        case .connecting:
            return Image(systemName: "wifi")
                .padding(8)
                .background(Color.yellow.opacity(0.8))
                .clipShape(Circle())
                .foregroundStyle(.white)
        case .connectedWithoutInternet:
            return Image(systemName: "wifi.exclamationmark")
                .padding(8)
                .background(Color.yellow.opacity(0.8))
                .clipShape(Circle())
                .foregroundStyle(.white)
        case .disconnected:
            return Image(systemName: "wifi.slash")
                .padding(8)
                .background(Color.gray.opacity(0.8))
                .clipShape(Circle())
                    .foregroundStyle(.white)
        case .disabled:
            return Image(systemName: "wifi.slash")
                .padding(8)
                .background(Color.red.opacity(0.8))
                .clipShape(Circle())
                .foregroundStyle(.white)
        case .notSupported:
            return Image(systemName: "wifi.exclamationmark")
                .padding(8)
                .background(Color.gray.opacity(0.8))
                .clipShape(Circle())
                .foregroundStyle(.white)
        }
    }
    
    private var ethernetIcon: some View {
        switch viewModel.ethernetState {
        case .connected:
            return Image(systemName: "network")
                .padding(8)
                .background(Color.blue.opacity(0.8))
                .clipShape(Circle())
        case .connectedWithoutInternet:
            return Image(systemName: "network")
                .padding(8)
                .background(Color.yellow.opacity(0.8))
                .clipShape(Circle())
        case .connecting:
            return Image(systemName: "network.slash")
                .padding(8)
                .background(Color.yellow.opacity(0.8))
                .clipShape(Circle())
        case .disconnected:
            return Image(systemName: "network.slash")
                .padding(8)
                .background(Color.gray.opacity(0.8))
                .clipShape(Circle())
        case .disabled:
            return Image(systemName: "network.slash")
                .padding(8)
                .background(Color.red.opacity(0.8))
                .clipShape(Circle())
        case .notSupported:
            return Image(systemName: "questionmark.circle")
                .padding(8)
                .background(Color.gray.opacity(0.8))
                .clipShape(Circle())
        }
    }
}

struct NetworkPopup_Previews: PreviewProvider {
    static var previews: some View {
        NetworkPopup()
            .previewLayout(.sizeThatFits)
    }
}
