import AppKit
import Combine

protocol SpaceModel: Identifiable, Equatable, Codable {
    associatedtype WindowType: WindowModel
    var isFocused: Bool { get set }
    var windows: [WindowType] { get set }
}

protocol WindowModel: Identifiable, Equatable, Codable {
    var id: Int { get }
    var title: String { get }
    var appName: String? { get }
    var isFocused: Bool { get }
    var appIcon: NSImage? { get set }
}

protocol SpacesProvider {
    associatedtype SpaceType: SpaceModel
    func getSpacesWithWindows() -> [SpaceType]?
}

// MARK: - Event-Based Provider Support

enum SpaceEvent {
    case initialState([AnySpace])
    case focusChanged(String)
    case windowsUpdated(String, [AnyWindow])
    case spaceCreated(String)
    case spaceDestroyed(String)
}

protocol EventBasedSpacesProvider {
    var spacesPublisher: AnyPublisher<SpaceEvent, Never> { get }

    func startObserving()
    func stopObserving()
}

protocol SwitchableSpacesProvider: SpacesProvider {
    func focusSpace(spaceId: String, needWindowFocus: Bool)
    func focusWindow(windowId: String)
}

struct AnyWindow: Identifiable, Equatable {
    let id: Int
    let title: String
    let appName: String?
    let isFocused: Bool
    let appIcon: NSImage?

    init<W: WindowModel>(_ window: W) {
        self.id = window.id
        self.title = window.title
        self.appName = window.appName
        self.isFocused = window.isFocused
        self.appIcon = window.appIcon
    }

    static func == (lhs: AnyWindow, rhs: AnyWindow) -> Bool {
        return lhs.id == rhs.id && lhs.title == rhs.title
            && lhs.appName == rhs.appName && lhs.isFocused == rhs.isFocused
    }
}

struct AnySpace: Identifiable, Equatable {
    let id: String
    let isFocused: Bool
    let windows: [AnyWindow]

    init<S: SpaceModel>(_ space: S) {
        if let aero = space as? AeroSpace {
            self.id = aero.workspace
        } else if let yabai = space as? YabaiSpace {
            self.id = String(yabai.id)
        } else {
            self.id = "0"
        }
        self.isFocused = space.isFocused
        self.windows = space.windows.map { AnyWindow($0) }
    }

    init(id: String, isFocused: Bool, windows: [AnyWindow]) {
        self.id = id
        self.isFocused = isFocused
        self.windows = windows
    }

    static func == (lhs: AnySpace, rhs: AnySpace) -> Bool {
        return lhs.id == rhs.id && lhs.isFocused == rhs.isFocused
            && lhs.windows == rhs.windows
    }
}

class AnySpacesProvider {
    private let _getSpacesWithWindows: () -> [AnySpace]?
    private let _focusSpace: ((String, Bool) -> Void)?
    private let _focusWindow: ((String) -> Void)?

    private let _isEventBased: Bool
    private let _startObserving: (() -> Void)?
    private let _stopObserving: (() -> Void)?
    private let _spacesPublisher: AnyPublisher<SpaceEvent, Never>?

    var isEventBased: Bool { _isEventBased }
    var spacesPublisher: AnyPublisher<SpaceEvent, Never>? { _spacesPublisher }

    init<P: SpacesProvider>(_ provider: P) {
        _getSpacesWithWindows = {
            provider.getSpacesWithWindows()?.map { AnySpace($0) }
        }

        if let switchable = provider as? any SwitchableSpacesProvider {
            _focusSpace = { spaceId, needWindowFocus in
                switchable.focusSpace(
                    spaceId: spaceId, needWindowFocus: needWindowFocus)
            }
            _focusWindow = { windowId in
                switchable.focusWindow(windowId: windowId)
            }
        } else {
            _focusSpace = nil
            _focusWindow = nil
        }

        if let eventBased = provider as? any EventBasedSpacesProvider {
            _isEventBased = true
            _startObserving = eventBased.startObserving
            _stopObserving = eventBased.stopObserving
            _spacesPublisher = eventBased.spacesPublisher
        } else {
            _isEventBased = false
            _startObserving = nil
            _stopObserving = nil
            _spacesPublisher = nil
        }
    }

    func getSpacesWithWindows() -> [AnySpace]? {
        _getSpacesWithWindows()
    }

    func focusSpace(spaceId: String, needWindowFocus: Bool) {
        _focusSpace?(spaceId, needWindowFocus)
    }

    func focusWindow(windowId: String) {
        _focusWindow?(windowId)
    }

    func startObserving() {
        _startObserving?()
    }

    func stopObserving() {
        _stopObserving?()
    }
}
