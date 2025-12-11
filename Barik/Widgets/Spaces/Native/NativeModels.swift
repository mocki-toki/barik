import AppKit


struct NativeSpaceWindow: WindowModel {
    var id: Int
    var title: String
    var appName: String?
    var isFocused: Bool
    var appIcon: NSImage?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case appName = "app-name"
        case isFocused = "focused"
    }
    
    init(id: Int, title: String, appName: String?, isFocused: Bool, appIcon: NSImage? = nil) {
        self.id = id
        self.title = title
        self.appName = appName
        self.isFocused = isFocused
        self.appIcon = appIcon ?? (appName.flatMap { IconCache.shared.icon(for: $0) })
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        appName = try container.decodeIfPresent(String.self, forKey: .appName)
        isFocused = try container.decodeIfPresent(Bool.self, forKey: .isFocused) ?? false
        if let name = appName { appIcon = IconCache.shared.icon(for: name) }
    }
}


struct NativeSpace: SpaceModel {
    typealias WindowType = NativeSpaceWindow
    
    let id: Int
    var label: String
    var isFocused: Bool
    var windows: [WindowType] = []

    enum CodingKeys: String, CodingKey {
        case id
        case label
        case isFocused = "focused"
    }
}

