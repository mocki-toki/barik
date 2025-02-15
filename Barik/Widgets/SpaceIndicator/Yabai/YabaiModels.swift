import AppKit

struct YabaiWindow: WindowModel {
    let id: Int
    let title: String
    let appName: String?
    let isFocused: Bool
    let stackIndex: Int
    var appIcon: NSImage?
    let isHidden: Bool
    let isFloating: Bool
    let isSticky: Bool
    let spaceId: Int

    enum CodingKeys: String, CodingKey {
        case id
        case spaceId = "space"
        case title
        case appName = "app"
        case isFocused = "has-focus"
        case stackIndex = "stack-index"
        case isHidden = "is-hidden"
        case isFloating = "is-floating"
        case isSticky = "is-sticky"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        spaceId = try container.decode(Int.self, forKey: .spaceId)
        title =
            try container.decodeIfPresent(String.self, forKey: .title)
            ?? "Unnamed"
        appName = try container.decodeIfPresent(String.self, forKey: .appName)
        isFocused = try container.decode(Bool.self, forKey: .isFocused)
        stackIndex =
            try container.decodeIfPresent(Int.self, forKey: .stackIndex) ?? 0
        isHidden = try container.decode(Bool.self, forKey: .isHidden)
        isFloating = try container.decode(Bool.self, forKey: .isFloating)
        isSticky = try container.decode(Bool.self, forKey: .isSticky)
        if let name = appName {
            appIcon = IconCache.shared.icon(for: name)
        }
    }
}

struct YabaiSpace: SpaceModel {
    typealias WindowType = YabaiWindow
    let id: Int
    var isFocused: Bool
    var windows: [YabaiWindow] = []

    enum CodingKeys: String, CodingKey {
        case id = "index"
        case isFocused = "has-focus"
    }
}
