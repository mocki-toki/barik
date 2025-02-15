import Foundation
import AppKit
import Combine

class SpaceViewModel: ObservableObject {
    @Published var spaces: [AnySpace] = []
    private var timer: Timer?
    private var provider: AnySpacesProvider?
    
    init() {
        let runningApps = NSWorkspace.shared.runningApplications.compactMap { $0.localizedName?.lowercased() }
        if runningApps.contains("yabai") {
            provider = AnySpacesProvider(YabaiSpacesProvider())
        } else if runningApps.contains("aerospace") {
            provider = AnySpacesProvider(AerospaceSpacesProvider())
        } else {
            provider = nil
        }
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
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
                  let spaces = provider.getSpacesWithWindows() else {
                DispatchQueue.main.async {
                    self.spaces = []
                }
                return
            }
            let sortedSpaces = spaces.sorted { $0.id < $1.id }
            DispatchQueue.main.async {
                self.spaces = sortedSpaces
            }
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
        if let app = workspace.runningApplications.first(where: { $0.localizedName == appName }),
           let bundleURL = app.bundleURL {
            let icon = workspace.icon(forFile: bundleURL.path)
            cache.setObject(icon, forKey: appName as NSString)
            return icon
        }
        return nil
    }
}
