import AppKit

struct OmniWMWindow: WindowModel {
    let id: Int
    let opaqueId: String
    let title: String
    let appName: String?
    let appBundleId: String?
    let processId: Int?
    var isFocused: Bool
    var appIcon: NSImage?

    // Top-level keys on a window object
    enum CodingKeys: String, CodingKey {
        case opaqueId = "id"
        case title
        case appObj = "app"
        case isFocused
        case pid
    }

    // Keys inside the nested "app" object
    enum AppCodingKeys: String, CodingKey {
        case name
        case bundleId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        opaqueId = try container.decode(String.self, forKey: .opaqueId)
        // Derive a stable non-negative Int id from the opaque string.
        id = opaqueId.stableWindowId
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        isFocused = try container.decodeIfPresent(Bool.self, forKey: .isFocused) ?? false
        processId = try container.decodeIfPresent(Int.self, forKey: .pid)

        // "app" is a nested object: { "name": "Firefox", "bundleId": "..." }
        if let appContainer = try? container.nestedContainer(keyedBy: AppCodingKeys.self, forKey: .appObj) {
            appName = try appContainer.decodeIfPresent(String.self, forKey: .name)
            appBundleId = try appContainer.decodeIfPresent(String.self, forKey: .bundleId)
        } else {
            appName = nil
            appBundleId = nil
        }

        if let name = appName {
            appIcon = IconCache.shared.icon(for: name)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(opaqueId, forKey: .opaqueId)
        try container.encode(title, forKey: .title)
        try container.encode(isFocused, forKey: .isFocused)
    }
}

struct OmniWMSpace: SpaceModel {
    typealias WindowType = OmniWMWindow
    let rawName: String
    let number: Int?
    let layout: String?
    var id: String { rawName }
    var isFocused: Bool
    var windows: [OmniWMWindow] = []

    enum CodingKeys: String, CodingKey {
        case rawName
        case number
        case layout
        case isFocused
        case displayName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rawName = try container.decode(String.self, forKey: .rawName)
        number = try container.decodeIfPresent(Int.self, forKey: .number)
        layout = try container.decodeIfPresent(String.self, forKey: .layout)
        isFocused = try container.decodeIfPresent(Bool.self, forKey: .isFocused) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rawName, forKey: .rawName)
        try container.encodeIfPresent(number, forKey: .number)
        try container.encodeIfPresent(layout, forKey: .layout)
        try container.encode(isFocused, forKey: .isFocused)
    }

    init(rawName: String, number: Int? = nil, layout: String? = nil, isFocused: Bool = false, windows: [OmniWMWindow] = []) {
        self.rawName = rawName
        self.number = number
        self.layout = layout
        self.isFocused = isFocused
        self.windows = windows
    }
}

private extension String {
    var stableWindowId: Int {
        var hash: UInt64 = 14695981039346656037
        for byte in utf8 {
            hash ^= UInt64(byte)
            hash &*= 1099511628211
        }
        return Int(hash & 0x7FFF_FFFF_FFFF_FFFF)
    }
}
