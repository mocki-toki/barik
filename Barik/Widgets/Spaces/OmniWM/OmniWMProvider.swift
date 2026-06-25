import Foundation

class OmniWMSpacesProvider: SpacesProvider, SwitchableSpacesProvider {
    typealias SpaceType = OmniWMSpace
    let executablePath = ConfigManager.shared.config.omniwm.path

    /// Mapping from hashed Int id back to opaque string id for focus commands.
    private var windowIdMap: [Int: String] = [:]
    private let windowIdMapQueue = DispatchQueue(label: "barik.omniwm.window-id-map")

    func getSpacesWithWindows() -> [OmniWMSpace]? {
        guard let spaces = fetchSpaces() else { return nil }

        guard let windowData = runOmniWMCommand(arguments: [
            "query", "windows", "--format", "json",
        ]) else {
            return nil
        }

        // Extract the windows array from result.payload.windows
        guard let windowsArrayData = extractArrayPayload(from: windowData, arrayKey: "windows") else {
            return nil
        }

        // Decode the window-to-workspace mapping
        guard let windowsWithWs = try? JSONDecoder().decode(
            [OmniWMWindowWithWorkspace].self, from: windowsArrayData
        ) else {
            return nil
        }

        // Decode full window models
        guard let windows = decodeWindows(from: windowsArrayData) else {
            return nil
        }

        // Build workspace mapping: opaqueId -> rawName of workspace
        var wsMap: [String: String] = [:]
        for wws in windowsWithWs {
            if let ws = wws.workspaceRawName {
                wsMap[wws.opaqueId] = ws
            }
        }

        var spaceDict = Dictionary(
            uniqueKeysWithValues: spaces.map { ($0.rawName, $0) })

        var nextWindowIdMap: [Int: String] = [:]
        for window in windows {
            var mutableWindow = window
            nextWindowIdMap[window.id] = window.opaqueId
            // isFocused is already set from the JSON

            if let ws = wsMap[window.opaqueId], !ws.isEmpty {
                if var space = spaceDict[ws] {
                    space.windows.append(mutableWindow)
                    spaceDict[ws] = space
                }
            }
        }

        var resultSpaces = Array(spaceDict.values)
        for i in 0..<resultSpaces.count {
            resultSpaces[i].windows.sort { $0.id < $1.id }
        }
        
        // Hide empty workspaces unless they are currently focused
        let activeSpaces = resultSpaces.filter { !$0.windows.isEmpty || $0.isFocused }

        windowIdMapQueue.sync {
            windowIdMap = nextWindowIdMap
        }
        
        return activeSpaces.sorted { ($0.number ?? 0) < ($1.number ?? 0) }
    }

    func focusSpace(spaceId: String, needWindowFocus: Bool) {
        _ = runOmniWMCommand(arguments: ["command", "switch-workspace", spaceId])
    }

    func focusWindow(windowId: String) {
        // windowId comes in as a String representation of the hashed Int id.
        // Look up the original opaque id.
        let opaqueId = windowIdMapQueue.sync {
            Int(windowId).flatMap { windowIdMap[$0] }
        }
        if let opaqueId {
            _ = runOmniWMCommand(arguments: ["window", "focus", opaqueId])
        }
    }

    // MARK: - Private helpers

    private func runOmniWMCommand(arguments: [String]) -> Data? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
        } catch {
            print("OmniWM error: \(error)")
            return nil
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            return nil
        }
        return data
    }

    /// Extracts a named array from omniwmctl's JSON envelope:
    /// { "result": { "payload": { "<arrayKey>": [...] } } }
    private func extractArrayPayload(from data: Data, arrayKey: String) -> Data? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = json["result"] as? [String: Any],
              let payload = result["payload"] as? [String: Any],
              let array = payload[arrayKey] else {
            return nil
        }
        return try? JSONSerialization.data(withJSONObject: array)
    }

    private func fetchSpaces() -> [OmniWMSpace]? {
        guard let data = runOmniWMCommand(arguments: [
            "query", "workspaces", "--format", "json",
        ]) else {
            return nil
        }
        guard let payloadData = extractArrayPayload(from: data, arrayKey: "workspaces") else {
            return nil
        }
        return decodeSpaces(from: payloadData)
    }

    private func decodeSpaces(from data: Data) -> [OmniWMSpace]? {
        do {
            return try JSONDecoder().decode([OmniWMSpace].self, from: data)
        } catch {
            print("OmniWM decode spaces error: \(error)")
            return nil
        }
    }

    private func decodeWindows(from data: Data) -> [OmniWMWindow]? {
        do {
            return try JSONDecoder().decode([OmniWMWindow].self, from: data)
        } catch {
            print("OmniWM decode windows error: \(error)")
            return nil
        }
    }
}

/// Helper struct to decode which workspace each window belongs to.
/// The "workspace" field on each window is a nested object: { "rawName": "1", ... }
private struct OmniWMWindowWithWorkspace: Decodable {
    let opaqueId: String
    let workspaceRawName: String?

    enum CodingKeys: String, CodingKey {
        case opaqueId = "id"
        case workspace
    }

    enum WorkspaceCodingKeys: String, CodingKey {
        case rawName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        opaqueId = try container.decode(String.self, forKey: .opaqueId)
        if let wsContainer = try? container.nestedContainer(keyedBy: WorkspaceCodingKeys.self, forKey: .workspace) {
            workspaceRawName = try wsContainer.decodeIfPresent(String.self, forKey: .rawName)
        } else {
            workspaceRawName = nil
        }
    }
}
