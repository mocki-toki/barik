import SwiftUI
import Network
import CoreWLAN
import CoreLocation

enum NetworkState: String {
    case connected = "Connected"
    case connectedWithoutInternet = "No Internet"
    case connecting = "Connecting"
    case disconnected = "Disconnected"
    case disabled = "Disabled"
    case notSupported = "Not Supported"
}

enum WifiSignalStrength: String {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case unknown = "Unknown"
}

/// Unified view model for monitoring network and Wi‑Fi status.
final class NetworkStatusViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    // States for Wi‑Fi and Ethernet obtained via NWPathMonitor.
    @Published var wifiState: NetworkState = .disconnected
    @Published var ethernetState: NetworkState = .disconnected
    
    // Wi‑Fi details obtained via CoreWLAN.
    @Published var ssid: String = "Not connected"
    @Published var rssi: Int = 0
    @Published var noise: Int = 0
    @Published var channel: String = "N/A"
    
    /// Computed property for signal strength.
    var wifiSignalStrength: WifiSignalStrength {
        // If Wi‑Fi is not connected or the interface is missing – return unknown.
        if ssid == "Not connected" || ssid == "No interface" {
            return .unknown
        }
        if rssi >= -50 {
            return .high
        } else if rssi >= -70 {
            return .medium
        } else {
            return .low
        }
    }
    
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    
    private var timer: Timer?
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        startNetworkMonitoring()
        startWiFiMonitoring()
    }
    
    deinit {
        stopNetworkMonitoring()
        stopWiFiMonitoring()
    }
    
    // MARK: — NWPathMonitor for overall network status.
    
    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            DispatchQueue.main.async {
                // Wi‑Fi
                if path.availableInterfaces.contains(where: { $0.type == .wifi }) {
                    if path.usesInterfaceType(.wifi) {
                        switch path.status {
                        case .satisfied:
                            self.wifiState = .connected
                        case .requiresConnection:
                            self.wifiState = .connecting
                        default:
                            self.wifiState = .connectedWithoutInternet
                        }
                    } else {
                        // If the Wi‑Fi interface is available but not in use – consider it enabled but not connected.
                        self.wifiState = .disconnected
                    }
                } else {
                    self.wifiState = .notSupported
                }
                
                // Ethernet
                if path.availableInterfaces.contains(where: { $0.type == .wiredEthernet }) {
                    if path.usesInterfaceType(.wiredEthernet) {
                        switch path.status {
                        case .satisfied:
                            self.ethernetState = .connected
                        case .requiresConnection:
                            self.ethernetState = .connecting
                        default:
                            self.ethernetState = .disconnected
                        }
                    } else {
                        self.ethernetState = .disconnected
                    }
                } else {
                    self.ethernetState = .notSupported
                }
            }
        }
        monitor.start(queue: monitorQueue)
    }
    
    private func stopNetworkMonitoring() {
        monitor.cancel()
    }
    
    // MARK: — Updating Wi‑Fi information via CoreWLAN.
    
    private func startWiFiMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateWiFiInfo()
        }
        updateWiFiInfo()
    }
    
    private func stopWiFiMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateWiFiInfo() {
        let client = CWWiFiClient.shared()
        if let interface = client.interface() {
            self.ssid = interface.ssid() ?? "Not connected"
            self.rssi = interface.rssiValue()
            self.noise = interface.noiseMeasurement()
            if let wlanChannel = interface.wlanChannel() {
                let band: String
                switch wlanChannel.channelBand {
                case .bandUnknown:
                    band = "unknown"
                case .band2GHz:
                    band = "2GHz"
                case .band5GHz:
                    band = "5GHz"
                case .band6GHz:
                    band = "6GHz"
                @unknown default:
                    band = "unknown"
                }
                self.channel = "\(wlanChannel.channelNumber) (\(band))"
            } else {
                self.channel = "N/A"
            }
        } else {
            // Interface not available – Wi‑Fi is off.
            self.ssid = "No interface"
            self.rssi = 0
            self.noise = 0
            self.channel = "N/A"
        }
    }
    
    // MARK: — CLLocationManagerDelegate.
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        updateWiFiInfo()
    }
}
