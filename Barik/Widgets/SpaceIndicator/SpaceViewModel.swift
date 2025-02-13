import Foundation
import AppKit
import Combine

class IconCache {
    static let shared = IconCache()
    private let cache = NSCache<NSString, NSImage>()
    private init() {}
    func icon(for appName: String) -> NSImage? {
        if let cachedIcon = cache.object(forKey: appName as NSString) {
            return cachedIcon
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

protocol SpacesProvider {
    associatedtype SpaceType: SpaceModel
    func getSpacesWithWindows() -> [SpaceType]?
}

class SpaceViewModel<Provider: SpacesProvider>: ObservableObject {
    @Published var spaces: [Provider.SpaceType] = []
    private var timer: Timer?
    private var provider: Provider
    
    init(provider: Provider) {
        self.provider = provider
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
            if let spaces = self.provider.getSpacesWithWindows() {
                let sortedSpaces = spaces.sorted { "\($0.id)" < "\($1.id)" }
                DispatchQueue.main.async {
                    self.spaces = sortedSpaces
                }
            }
        }
    }
}
