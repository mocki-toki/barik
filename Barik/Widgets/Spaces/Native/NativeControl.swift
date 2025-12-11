import AppKit
import CoreGraphics
import AXSwift

final class NativeControl {
    
    static func requestAccess() {
        _ = UIElement.isProcessTrusted(withPrompt: true)
    }
    
    final class Display {
        let id: CGSDirectDisplayID
        private let cid: CGSConnectionID
        
        lazy private(set) var uuid: String? = {
            guard let uuid = CGDisplayCreateUUIDFromDisplayID(id)?.takeRetainedValue() else {
                return nil
            }
            return CFUUIDCreateString(nil, uuid) as String?
        }()
        
        static func main() -> Display {
            return Display(id: CGSInternal.mainDisplayID())
        }
        
        init(
            id: CGSDirectDisplayID,
            cid: CGSConnectionID = CGSInternal.mainConnectionID()
        ) {
            self.id = id
            self.cid = cid
        }
        
        // NOTE: The order of the returned `NCSpace` array matches the visual order
        //   of the spaces in Mission Control. This behavior is derived from the `CGSCopyManagedDisplaySpaces`
        //   private API, which provides pre-sorted spaces per display.
        func getSpaces() -> [Space] {
            guard uuid != nil, let info = cgInfo else { return [] }
            
            return info.spaces.compactMap { si -> Space? in
                guard let spaceID = si.id else { return nil }
                return Space(id: spaceID, cid: cid)
            }
        }
        
        func getWindows() -> [Window] {
            let spaces = getSpaces()
            if spaces.isEmpty { return [] }
            
            let windowIDs = CGSInternal.copyWindows(connection: cid, spaces: spaces.map(\.id)) ?? []
            return windowIDs.map { Window(id: $0, cid: cid) }
        }
        
        lazy private(set) var cgInfo: CGSInternal.DispalyInfo? = {
            return CGSInternal.copyManagedDisplaySpaces(connection: cid)?
                .compactMap({ CGSInternal.DispalyInfo(rawValue: $0) })
                .first(where: { $0.uuid == uuid })
        }()
    }
    
    
    final class Space {
        let id: CGSSpaceID
        private let cid: CGSConnectionID
        
        static func active(cid: CGSConnectionID = CGSInternal.mainConnectionID()) -> Space {
            let sid = CGSInternal.getActiveSpace(connection: cid)
            return Space(id: sid)
        }
        
        init(
            id: CGSSpaceID,
            cid: CGSConnectionID = CGSInternal.mainConnectionID()
        ) {
            self.id = id
            self.cid = cid
        }
        
        func getWindows() -> [Window] {
            let windowIDs = CGSInternal.copyWindows(connection: cid, spaces: [id]) ?? []
            return windowIDs.map { Window(id: $0, cid: cid) }
        }
    }
    
    
    final class Window {
        let id: CGSWindowID
        private let cid: CGSConnectionID
        
        static func list(
            of displayID: CGSDirectDisplayID,
            cid: CGSConnectionID = CGSInternal.mainConnectionID()
        ) -> [Window] {
            let display = Display(id: displayID, cid: cid)
            return display.getWindows()
        }
        
        static func list(
            of spaceID: CGSSpaceID,
            cid: CGSConnectionID = CGSInternal.mainConnectionID()
        ) -> [Window] {
            let space = Space(id: spaceID, cid: cid)
            return space.getWindows()
        }
        
        static func focused() -> Window? {
            guard UIElement.isProcessTrusted(withPrompt: false) else { return nil }
            guard
                let axapp: UIElement = try? systemWideElement.attribute(.focusedApplication),
                let axwin: UIElement = try? axapp.attribute(.focusedWindow),
                let wid = AXSInternal.getWindowID(for: axwin.element)
            else { return nil }
            return Window(id: wid)
        }
        
        init(
            id: CGSWindowID,
            cid: CGSConnectionID = CGSInternal.mainConnectionID()
        ) {
            self.id = id
            self.cid = cid
        }
        
        lazy private(set) var app: NSRunningApplication? = {
            guard let pid = cgInfo?.ownerPID else { return nil }
            return NSRunningApplication(processIdentifier: pid)
        }()
        
        lazy private(set) var cgInfo: CGSInternal.WindowInfo? = {
            guard
                let wlis = CGWindowListCopyWindowInfo(CGWindowListOption.optionIncludingWindow, id) as? [[String: Any]],
                let raw = wlis.first
            else { return nil }
            return CGSInternal.WindowInfo(rawValue: raw)
        }()
        
        lazy private(set) var title: String? = {
            if let title = cgInfo?.title {
                return title
            }
            
            guard let e = element else { return nil }
            return try? e.attribute(.title)
        }()
        
        lazy private(set) var isFullscreen: Bool? = {
            if let layer = cgInfo?.layer, layer == CGSInternal.WindowInfo.Layer.fullscreen {
                return true
            }
            
            guard let e = element else { return nil }
            return try? e.attribute(.fullScreen)
        }()
        
        lazy private var element: UIElement? = {
            guard UIElement.isProcessTrusted(withPrompt: false) else { return nil }
            guard
                let app = app,
                let wins = try? Application(app)?.windows()
            else { return nil }
            
            return wins.first(where: { AXSInternal.getWindowID(for: $0.element) == id })
        }()
    }
}


extension CGSInternal {
    struct DispalyInfo: RawRepresentable, ExpressibleByDictionaryLiteral {
        typealias Key = String
        typealias Value = Any
        typealias RawValue = [Key: Value]
        
        var rawValue: [Key : Value]
        
        private enum Keys: String {
            case Identifier = "Display Identifier"
            case Spaces = "Spaces"
        }
        
        var uuid: String? { rawValue[Keys.Identifier.rawValue] as? String }
        var spaces: [SpaceInfo] {
            guard let raw = rawValue[Keys.Spaces.rawValue] as? [[String: Any]] else { return [] }
            return raw.compactMap { SpaceInfo(rawValue: $0) }
        }
        
        init?(rawValue: [Key : Value]) {
            self.rawValue = rawValue
        }
        
        init(dictionaryLiteral elements: (Key, Value)...) {
            self.rawValue = Dictionary(uniqueKeysWithValues: elements)
        }
    }
    
    struct SpaceInfo: RawRepresentable, ExpressibleByDictionaryLiteral {
        typealias Key = String
        typealias Value = Any
        typealias RawValue = [Key: Value]
        
        var rawValue: [Key : Value]
        
        private enum Keys: String {
            case ID = "id64"
        }
        
        var id: CGSSpaceID? { rawValue[Keys.ID.rawValue] as? CGSSpaceID }
        
        init?(rawValue: [Key : Value]) {
            self.rawValue = rawValue
        }
        
        init(dictionaryLiteral elements: (Key, Value)...) {
            rawValue = Dictionary(uniqueKeysWithValues: elements)
        }
    }
    
    struct WindowInfo: RawRepresentable, ExpressibleByDictionaryLiteral {
        typealias Key = String
        typealias Value = Any
        typealias RawValue = [Key: Value]
        
        var rawValue: [Key : Value]
        
        private enum Keys: String {
            case Title = "kCGWindowName"
            case OwnerPID = "kCGWindowOwnerPID"
            case Layer = "kCGWindowLayer"
            case IsOnScreen = "kCGWindowIsOnscreen"
        }
        
        /// Layers aren't documented well, so values were found heuristically
        enum Layer: Int {
            case base = 0
            case fullscreen = 26
        }
        
        var title: String? { rawValue[Keys.Title.rawValue] as? String }
        var ownerPID: pid_t? { rawValue[Keys.OwnerPID.rawValue] as? pid_t }
        var layer: Layer? {
            (rawValue[Keys.Layer.rawValue] as? Int).flatMap { Layer(rawValue: $0) }
        }
        var isOnScreen: Bool? { rawValue[Keys.IsOnScreen.rawValue] as? Bool }
        
        init?(rawValue: [Key : Value]) {
            self.rawValue = rawValue
        }
        
        init(dictionaryLiteral elements: (String, Value)...) {
            rawValue = Dictionary(uniqueKeysWithValues: elements)
        }
    }
}
