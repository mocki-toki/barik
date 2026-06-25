import AppKit
import Combine
import Foundation

class SpacesViewModel: ObservableObject {
    @Published var spaces: [AnySpace] = []
    private var timer: Timer?
    private var provider: AnySpacesProvider?
    private let loadingStateQueue = DispatchQueue(
        label: "barik.spaces.loading-state")
    private var isLoadingSpaces = false

    init() {
        detectProvider()
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    private func detectProvider() {
        let runningApps = NSWorkspace.shared.runningApplications.compactMap {
            $0.localizedName?.lowercased()
        }
        if runningApps.contains("yabai") {
            provider = AnySpacesProvider(YabaiSpacesProvider())
            print("SpacesWidget: Yabai detected")
        } else if runningApps.contains("aerospace") {
            provider = AnySpacesProvider(AerospaceSpacesProvider())
            print("SpacesWidget: AeroSpace detected")
        } else if runningApps.contains("omniwm") {
            provider = AnySpacesProvider(OmniWMSpacesProvider())
            print("SpacesWidget: OmniWM detected")
        } else {
            if provider != nil {
                print("SpacesWidget: No window manager detected, clearing provider")
                provider = nil
            }
        }
    }

    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) {
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
        let shouldLoad = loadingStateQueue.sync { () -> Bool in
            guard !isLoadingSpaces else { return false }
            isLoadingSpaces = true
            return true
        }
        guard shouldLoad else { return }

        DispatchQueue.global(qos: .background).async {
            defer {
                self.loadingStateQueue.async {
                    self.isLoadingSpaces = false
                }
            }

            if self.provider == nil {
                self.detectProvider()
            }

            guard
                let provider = self.provider,
                let spaces = provider.getSpacesWithWindows()
            else {
                if self.provider != nil {
                    print("SpacesWidget: Failed to fetch spaces from provider")
                }
                return
            }

            let filteredSpaces = self.filterIgnoredApplications(from: spaces)
            let groupedSpaces = self.groupWindowsByAppIfNeeded(from: filteredSpaces)
            let sortedSpaces = groupedSpaces.sorted { $0.id < $1.id }
            DispatchQueue.main.async {
                self.spaces = sortedSpaces
            }
        }
    }

    private func filterIgnoredApplications(from spaces: [AnySpace]) -> [AnySpace] {
        let ignoredApplications = ignoredApplicationsSet
        guard !ignoredApplications.isEmpty else {
            return spaces
        }

        return spaces.compactMap { space in
            let visibleWindows = space.windows.filter { window in
                !self.shouldIgnore(window: window, ignoredApplications: ignoredApplications)
            }

            guard !visibleWindows.isEmpty || space.isFocused else {
                return nil
            }

            return AnySpace(
                id: space.id,
                isFocused: space.isFocused,
                windows: visibleWindows
            )
        }
    }

    private func groupWindowsByAppIfNeeded(from spaces: [AnySpace]) -> [AnySpace] {
        let widgetConfig = ConfigManager.shared.globalWidgetConfig(for: "default.spaces")
        let windowConfig = widgetConfig["window"]?.dictionaryValue ?? [:]
        let groupByApp = windowConfig["group-by-app"]?.boolValue ?? false

        guard groupByApp else {
            return spaces
        }

        return spaces.map { space in
            let groupedWindows = groupWindowsByApp(space.windows)
            return AnySpace(
                id: space.id,
                isFocused: space.isFocused,
                windows: groupedWindows
            )
        }
    }

    private func groupWindowsByApp(_ windows: [AnyWindow]) -> [AnyWindow] {
        var appGroups: [String: [AnyWindow]] = [:]

        for window in windows {
            let key = window.appName ?? "Unknown"
            if appGroups[key] == nil {
                appGroups[key] = []
            }
            appGroups[key]?.append(window)
        }

        var result: [AnyWindow] = []
        for (appName, windowsInGroup) in appGroups {
            if windowsInGroup.count == 1 {
                result.append(windowsInGroup[0])
            } else {
                // Create a grouped window representation
                let representativeWindow = windowsInGroup.first { $0.isFocused } ?? windowsInGroup.first!
                let groupedWindow = AnyWindow(
                    id: representativeWindow.id,
                    title: representativeWindow.title,
                    appName: appName,
                    appBundleId: representativeWindow.appBundleId,
                    processId: representativeWindow.processId,
                    isFocused: representativeWindow.isFocused,
                    appIcon: representativeWindow.appIcon,
                    windowCount: windowsInGroup.count,
                    groupedWindows: windowsInGroup
                )
                result.append(groupedWindow)
            }
        }

        return result.sorted { $0.appName ?? "" < $1.appName ?? "" }
    }

    private var ignoredApplicationsSet: Set<String> {
        let widgetConfig = ConfigManager.shared.globalWidgetConfig(for: "default.spaces")
        let windowConfig = widgetConfig["window"]?.dictionaryValue ?? [:]
        let rawItems = windowConfig["ignore-list"]?.arrayValue ?? []

        return Set(
            rawItems.compactMap { $0.stringValue?.normalizedApplicationIdentifier }
        )
    }

    private func shouldIgnore(window: AnyWindow, ignoredApplications: Set<String>) -> Bool {
        let appName = window.appName?.normalizedApplicationIdentifier
        let bundleId = window.appBundleId?.normalizedApplicationIdentifier

        let resolvedMetadata = RunningApplicationCache.shared.metadata(for: window.processId)
        let resolvedAppName = resolvedMetadata?.localizedName?.normalizedApplicationIdentifier
        let resolvedBundleId = resolvedMetadata?.bundleIdentifier?.normalizedApplicationIdentifier

        // Check app identifiers (app name or bundle ID) with exact matching
        let appIdentifiers = [appName, bundleId, resolvedAppName, resolvedBundleId].compactMap { $0 }
        for identifier in appIdentifiers {
            if ignoredApplications.contains(identifier) {
                return true
            }
        }

        return false
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

private extension AnySpace {
    init(id: String, isFocused: Bool, windows: [AnyWindow]) {
        self.id = id
        self.isFocused = isFocused
        self.windows = windows
    }
}

private extension String {
    var normalizedApplicationIdentifier: String {
        trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

private final class RunningApplicationCache {
    static let shared = RunningApplicationCache()

    private var cache: [Int: RunningApplicationMetadata] = [:]
    private let queue = DispatchQueue(label: "barik.spaces.running-application-cache")

    private init() {}

    func metadata(for processId: Int?) -> RunningApplicationMetadata? {
        guard let processId else { return nil }

        if let cached = queue.sync(execute: { cache[processId] }) {
            return cached
        }

        let metadata = fetchMetadata(for: processId)
        queue.sync {
            cache[processId] = metadata
        }
        return metadata
    }

    private func fetchMetadata(for processId: Int) -> RunningApplicationMetadata {
        guard
            let app = NSRunningApplication(processIdentifier: pid_t(processId))
        else {
            return RunningApplicationMetadata(localizedName: nil, bundleIdentifier: nil)
        }

        return RunningApplicationMetadata(
            localizedName: app.localizedName,
            bundleIdentifier: app.bundleIdentifier
        )
    }
}

private struct RunningApplicationMetadata {
    let localizedName: String?
    let bundleIdentifier: String?
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
