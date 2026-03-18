import Combine
import Foundation
import IOKit.ps

/// This class monitors the battery status.
class BatteryManager: ObservableObject, ConditionallyActivatableWidget {
    @Published var batteryLevel: Int = 0
    @Published var isCharging: Bool = false
    @Published var isPluggedIn: Bool = false
    private var timer: Timer?
    
    private var currentInterval: TimeInterval = 30.0
    let widgetId = "default.battery"
    
    private var isActive = false

    init() {
        setupNotifications()
        // For now, always activate to ensure widgets work
        activate()
    }

    deinit {
        stopMonitoring()
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupNotifications() {
        // Listen for performance mode changes
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PerformanceModeChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let intervals = notification.object as? [String: TimeInterval],
               let newInterval = intervals["battery"] {
                self?.updateTimerInterval(newInterval)
            }
        }
        
        // Listen for widget activation changes
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("WidgetActivationChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let activeWidgets = notification.object as? Set<String> {
                if activeWidgets.contains(self?.widgetId ?? "") {
                    self?.activate()
                } else {
                    self?.deactivate()
                }
            }
        }
    }
    
    func activate() {
        guard !isActive else { 
            return 
        }
        
        isActive = true
        
        // Get current performance mode interval
        let performanceManager = PerformanceModeManager.shared
        let intervals = performanceManager.getTimerIntervals(for: performanceManager.currentMode)
        currentInterval = intervals["battery"] ?? 30.0
        
        startMonitoring()
    }
    
    func deactivate() {
        guard isActive else { return }
        isActive = false
        stopMonitoring()
    }
    
    private func updateTimerInterval(_ newInterval: TimeInterval) {
        guard isActive else { return }
        currentInterval = newInterval
        
        // Restart timer with new interval
        stopMonitoring()
        startMonitoring()
    }

    private func startMonitoring() {
        // Update every X seconds based on performance mode
        timer = Timer.scheduledTimer(withTimeInterval: currentInterval, repeats: true) {
            [weak self] _ in
            self?.updateBatteryStatus()
        }
        updateBatteryStatus()
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
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
