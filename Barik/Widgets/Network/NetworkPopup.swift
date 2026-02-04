import SwiftUI

/// Window displaying detailed network status information with WiFi controls.
struct NetworkPopup: View {
    @StateObject private var viewModel = NetworkStatusViewModel()
    @State private var showOtherNetworks = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // WiFi Toggle Header
            wifiToggleHeader

            Divider()
                .background(Color.gray.opacity(0.3))
                .padding(.vertical, 8)

            if viewModel.isWiFiEnabled {
                // Known Network (currently connected)
                if viewModel.ssid != "Not connected" && viewModel.ssid != "No interface" {
                    knownNetworkSection

                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.vertical, 8)
                }

                // Other Networks
                otherNetworksSection

                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.vertical, 8)
            }

            // WiFi Settings Button
            wifiSettingsButton
        }
        .padding(16)
        .frame(width: 280)
        .background(Color.black)
        .onAppear {
            if viewModel.isWiFiEnabled {
                viewModel.scanForNetworks()
            }
        }
    }

    // MARK: - WiFi Toggle Header

    private var wifiToggleHeader: some View {
        HStack {
            Text("Wi-Fi")
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            Toggle("", isOn: Binding(
                get: { viewModel.isWiFiEnabled },
                set: { _ in viewModel.toggleWiFi() }
            ))
            .toggleStyle(SwitchToggleStyle(tint: .blue))
            .labelsHidden()
        }
        .padding(.bottom, 4)
    }

    // MARK: - Known Network Section

    private var knownNetworkSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Known Network")
                .font(.subheadline)
                .foregroundColor(.gray)

            HStack(spacing: 12) {
                // WiFi icon with signal strength
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 32, height: 32)

                    Image(systemName: wifiIconName(for: viewModel.rssi))
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }

                Text(viewModel.ssid)
                    .font(.body)
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Other Networks Section

    private var otherNetworksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with expand/collapse
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showOtherNetworks.toggle()
                }
                if showOtherNetworks && viewModel.availableNetworks.isEmpty {
                    viewModel.scanForNetworks()
                }
            }) {
                HStack {
                    Text("Other Networks")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Spacer()

                    if viewModel.isScanning {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: showOtherNetworks ? "chevron.down" : "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(showOtherNetworks ? Color.blue.opacity(0.3) : Color.clear)
                    .padding(.horizontal, -8)
                    .padding(.vertical, -4)
            )

            // Network list
            if showOtherNetworks {
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(otherNetworks) { network in
                            networkRow(network)
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        }
    }

    private var otherNetworks: [WiFiNetwork] {
        viewModel.availableNetworks.filter { !$0.isConnected }
    }

    private func networkRow(_ network: WiFiNetwork) -> some View {
        Button(action: {
            viewModel.connectToNetwork(network)
        }) {
            HStack(spacing: 12) {
                Image(systemName: wifiIconName(for: network.rssi))
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .frame(width: 20)

                Text(network.ssid)
                    .font(.body)
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()

                if network.isSecure {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.001))
        )
        .onHover { hovering in
            // Could add hover effect here
        }
    }

    // MARK: - WiFi Settings Button

    private var wifiSettingsButton: some View {
        Button(action: {
            viewModel.openWiFiSettings()
        }) {
            Text("Wi-Fi Settings...")
                .font(.body)
                .foregroundColor(.white)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Helpers

    private func wifiIconName(for rssi: Int) -> String {
        if rssi >= -50 {
            return "wifi"
        } else if rssi >= -70 {
            return "wifi"
        } else {
            return "wifi"
        }
    }
}

struct NetworkPopup_Previews: PreviewProvider {
    static var previews: some View {
        NetworkPopup()
            .previewLayout(.sizeThatFits)
    }
}
