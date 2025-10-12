import SwiftUI
import Combine

@MainActor
class SpacesViewModel: ObservableObject {
    
    @Published private(set) var spaces: [AnySpace] = []
    
    private let provider: AnySpacesProvider?
    private var monitoring: Task<Void, Never>?

    init() {
        defer { startMonitoring() }
        
        let runningApps = NSWorkspace.shared.runningApplications.compactMap { $0.localizedName?.lowercased() }
        
        if runningApps.contains("yabai") {
            provider = AnySpacesProvider(YabaiSpacesProvider())
        } else if runningApps.contains("aerospace") {
            provider = AnySpacesProvider(AerospaceSpacesProvider())
        } else {
            provider = AnySpacesProvider(NativeSpaceProvider())
        }
    }
        
    deinit {
        monitoring?.cancel()
    }

    private func startMonitoring() {
        monitoring?.cancel()
        monitoring = Task { [weak self] in
            while !Task.isCancelled {
                await self?.loadSpaces()
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }

    private func loadSpaces() async {
        spaces = await Task.detached { [weak provider] in provider?.getSpacesWithWindows() ?? [] }.value
    }

    func switchToSpace(_ space: AnySpace, needWindowFocus: Bool = false) {
        Task.detached(priority: .userInitiated) { [ weak provider ] in
            provider?.focusSpace(spaceId: space.id, needWindowFocus: needWindowFocus)
        }
    }

    func switchToWindow(_ window: AnyWindow) {
        Task.detached(priority: .userInitiated) { [ weak provider ] in
            provider?.focusWindow(windowId: String(window.id))
        }
    }
}


class IconCache {
    
    static let shared = IconCache()
    
    private let cache = NSCache<NSString, NSImage>()
    
    func icon(for appName: String) -> NSImage? {
        if let cached = cache.object(forKey: appName as NSString) {
            return cached
        }
        
        let workspace = NSWorkspace.shared
        guard
            let app = workspace.runningApplications.first(where: {
                $0.localizedName == appName
            }),
            let bundleURL = app.bundleURL
        else { return nil }
        
        let icon = workspace.icon(forFile: bundleURL.path)
        cache.setObject(icon, forKey: appName as NSString)
        
        return icon
    }
}
