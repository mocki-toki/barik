import AppKit
import Combine
import Foundation

class SpacesViewModel: ObservableObject, ConditionallyActivatableWidget {
    @Published var spaces: [AnySpace] = []
    private var timer: Timer?
    private var provider: AnySpacesProvider?
    private var currentInterval: TimeInterval = 5.0
    let widgetId = "default.spaces"
    
    private var isActive = false

    init() {
        let runningApps = NSWorkspace.shared.runningApplications.compactMap {
            $0.localizedName?.lowercased()
        }
        if runningApps.contains("yabai") {
            provider = AnySpacesProvider(YabaiSpacesProvider())
        } else if runningApps.contains("aerospace") {
            provider = AnySpacesProvider(AerospaceSpacesProvider())
        } else {
            provider = nil
        }
        
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
               let newInterval = intervals["spaces"] {
                self?.updateTimerInterval(newInterval)
            }
        }
        
        // For future use - widget activation/deactivation
        // NotificationCenter.default.addObserver(
        //     forName: NSNotification.Name("WidgetActivationChanged"),
        //     object: nil,
        //     queue: .main
        // ) { [weak self] notification in
        //     if let activeWidgets = notification.object as? Set<String> {
        //         if activeWidgets.contains(self?.widgetId ?? "") {
        //             self?.activate()
        //         } else {
        //             self?.deactivate()
        //         }
        //     }
        // }
    }
    
    func activate() {
        guard !isActive else { 
            return 
        }
        
        isActive = true
        
        // Get current performance mode interval
        let performanceManager = PerformanceModeManager.shared
        let intervals = performanceManager.getTimerIntervals(for: performanceManager.currentMode)
        currentInterval = intervals["spaces"] ?? 5.0
        
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
        timer = Timer.scheduledTimer(withTimeInterval: currentInterval, repeats: true) {
            [weak self] _ in
            self?.loadSpaces()
        }
        loadSpaces()
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func loadSpaces() {
        DispatchQueue.global(qos: .background).async {
            guard let provider = self.provider,
                let spaces = provider.getSpacesWithWindows()
            else {
                DispatchQueue.main.async {
                    self.spaces = []
                }
                return
            }
            let sortedSpaces = spaces.sorted { a, b in
                // Important to avoid 1, 10, 11, 2 as the sorted order
                if let intA = Int(a.id), let intB = Int(b.id) {
                    return intA < intB
                }
                // Else return to string comparison
                return a.id < b.id
            }
            DispatchQueue.main.async {
                self.spaces = sortedSpaces
            }
        }
    }

    func switchToSpace(_ space: AnySpace, needWindowFocus: Bool = false) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.provider?.focusSpace(
                spaceId: space.id, needWindowFocus: needWindowFocus)
        }
    }

    func switchToWindow(_ window: AnyWindow) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.provider?.focusWindow(windowId: String(window.id))
        }
    }
}

class IconCache {
    static let shared = IconCache()
    private let cache = NSCache<NSString, NSImage>()
    private init() {}
    func icon(for appName: String) -> NSImage? {
        if let cached = cache.object(forKey: appName as NSString) {
            return cached
        }
        let workspace = NSWorkspace.shared
        if let app = workspace.runningApplications.first(where: {
            $0.localizedName == appName
        }),
            let bundleURL = app.bundleURL
        {
            let icon = workspace.icon(forFile: bundleURL.path)
            cache.setObject(icon, forKey: appName as NSString)
            return icon
        }
        return nil
    }
}
