import AppKit
import Combine
import Foundation

class SpacesViewModel: ObservableObject {
    @Published var spaces: [AnySpace] = []
    private var timer: Timer?
    private var provider: AnySpacesProvider?
    private var cancellables: Set<AnyCancellable> = []
    private var spacesById: [String: AnySpace] = [:]

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
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    private func startMonitoring() {
        if let provider = provider {
            if provider.isEventBased {
                startMonitoringEventBasedProvider()
            } else {
                startMonitoringPollingBasedProvider()
            }
        }
    }

    private func stopMonitoring() {
        if let provider = provider {
            if provider.isEventBased {
                stopMonitoringEventBasedProvider()
            } else {
                stopMonitoringPollingBasedProvider()
            }
        }
    }

    private func startMonitoringPollingBasedProvider() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) {
            [weak self] _ in
            self?.loadSpaces()
        }
        loadSpaces()
    }

    private func stopMonitoringPollingBasedProvider() {
        timer?.invalidate()
        timer = nil
    }

    private func startMonitoringEventBasedProvider() {
        guard let provider = provider else { return }
        provider.spacesPublisher?
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleSpaceEvent(event)
            }
            .store(in: &cancellables)
        provider.startObserving()
    }

    private func stopMonitoringEventBasedProvider() {
        provider?.stopObserving()
        cancellables.removeAll()
    }

    private func handleSpaceEvent(_ event: SpaceEvent) {
        switch event {
        case .initialState(let spaces):
            spacesById = Dictionary(uniqueKeysWithValues: spaces.map { ($0.id, $0) })
            updatePublishedSpaces()
        case .focusChanged(let spaceId):
            for (id, space) in spacesById {
                let newFocused = id == spaceId
                if space.isFocused != newFocused {
                    spacesById[id] = AnySpace(
                        id: space.id, isFocused: newFocused, windows: space.windows)
                }
            }
            updatePublishedSpaces()
        case .windowsUpdated(let spaceId, let windows):
            if let space = spacesById[spaceId] {
                spacesById[spaceId] = AnySpace(
                    id: space.id, isFocused: space.isFocused, windows: windows)
            }
            updatePublishedSpaces()
        case .spaceCreated(let spaceId):
            spacesById[spaceId] = AnySpace(id: spaceId, isFocused: false, windows: [])
            updatePublishedSpaces()
        case .spaceDestroyed(let spaceId):
            spacesById.removeValue(forKey: spaceId)
            updatePublishedSpaces()
        }
    }

    private func updatePublishedSpaces() {
        let sortedSpaces = spacesById.values.sorted { $0.id < $1.id }
        if sortedSpaces != spaces {
            spaces = sortedSpaces
        }
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
            let sortedSpaces = spaces.sorted { $0.id < $1.id }
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
