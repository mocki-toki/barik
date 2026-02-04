import Combine
import Foundation
import IOKit.ps

/// This class monitors the battery status.
class BatteryManager: ObservableObject {
    @Published var batteryLevel: Int = 0
    @Published var isCharging: Bool = false
    @Published var isPluggedIn: Bool = false
    private var runLoopSource: CFRunLoopSource?

    init() {
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    private func startMonitoring() {
        let context = UnsafeMutableRawPointer(
            Unmanaged.passUnretained(self).toOpaque())

        runLoopSource = IOPSNotificationCreateRunLoopSource(
            { context in
                guard let context = context else { return }
                let manager = Unmanaged<BatteryManager>.fromOpaque(context)
                    .takeUnretainedValue()
                DispatchQueue.main.async {
                    manager.updateBatteryStatus()
                }
            },
            context
        )?.takeRetainedValue()

        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .defaultMode)
        }

        updateBatteryStatus()
    }

    private func stopMonitoring() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .defaultMode)
            runLoopSource = nil
        }
    }

    /// This method updates the battery level and charging state.
    func updateBatteryStatus() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
            let sources = IOPSCopyPowerSourcesList(snapshot)?
                .takeRetainedValue() as? [CFTypeRef]
        else {
            return
        }

        for source in sources {
            if let description = IOPSGetPowerSourceDescription(
                snapshot, source)?.takeUnretainedValue() as? [String: Any],
                let currentCapacity = description[
                    kIOPSCurrentCapacityKey as String] as? Int,
                let maxCapacity = description[kIOPSMaxCapacityKey as String]
                    as? Int,
                let charging = description[kIOPSIsChargingKey as String]
                    as? Bool,
                let powerSourceState = description[
                    kIOPSPowerSourceStateKey as String] as? String
            {
                let isAC = (powerSourceState == kIOPSACPowerValue)

                DispatchQueue.main.async {
                    self.batteryLevel = (currentCapacity * 100) / maxCapacity
                    self.isCharging = charging
                    self.isPluggedIn = isAC
                }
            }
        }
    }
}
