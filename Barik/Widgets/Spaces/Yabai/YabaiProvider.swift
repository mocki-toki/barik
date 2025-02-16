import Foundation

class YabaiSpacesProvider: SpacesProvider {
    typealias SpaceType = YabaiSpace

    private func runYabaiCommand(arguments: [String]) -> Data? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/yabai")
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        do {
            try process.run()
        } catch {
            print("Yabai error: \(error)")
            return nil
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return data
    }

    private func fetchSpaces() -> [YabaiSpace]? {
        guard let data = runYabaiCommand(arguments: ["-m", "query", "--spaces"]) else {
            return nil
        }
        let decoder = JSONDecoder()
        do {
            let spaces = try decoder.decode([YabaiSpace].self, from: data)
            return spaces
        } catch {
            return nil
        }
    }
    
    private func switchToSpace(index: Int) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            if let _ = self.runYabaiCommand(arguments: ["-m", "space", "--focus", "\(index)"]) {
                print("Successfully switched to space \(index)")
            } else {
                print("Failed to switch to space \(index)")
            }
        }
    }

    func switchToSpace(space: YabaiSpace) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            if let _ = self.runYabaiCommand(arguments: ["-m", "space", "--focus", "\(space.id)"]) {
                print("Successfully switched to space \(space.id)")
            } else {
                print("Failed to switch to space \(space.id)")
            }
        }
    }

    private func fetchWindows() -> [YabaiWindow]? {
        guard let data = runYabaiCommand(arguments: ["-m", "query", "--windows"]) else {
            return nil
        }
        let decoder = JSONDecoder()
        do {
            let windows = try decoder.decode([YabaiWindow].self, from: data)
            return windows
        } catch {
            print("Decode yabai windows error: \(error)")
            return nil
        }
    }

    func getSpacesWithWindows() -> [YabaiSpace]? {
        guard let spaces = fetchSpaces(), let windows = fetchWindows() else {
            return nil
        }
        let filteredWindows = windows.filter {
            !($0.isHidden || $0.isFloating || $0.isSticky)
        }
        var spaceDict = Dictionary(uniqueKeysWithValues: spaces.map { ($0.id, $0) })
        for window in filteredWindows {
            if var space = spaceDict[window.spaceId] {
                space.windows.append(window)
                spaceDict[window.spaceId] = space
            }
        }
        var resultSpaces = Array(spaceDict.values)
        for i in 0..<resultSpaces.count {
            resultSpaces[i].windows.sort { $0.stackIndex < $1.stackIndex }
        }
        return resultSpaces.filter { !$0.windows.isEmpty }
    }
    
    
    func getSpaceLayout(for space: YabaiSpace) -> String {
            guard let data = runYabaiCommand(arguments: ["-m", "query", "--spaces", "--space"]) else {
                print("Failed to fetch space layout")
                return "Unknown"
            }
            
            do {
                if let spaceInfo = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                 
                   let type = spaceInfo["type"] as? String {
                    return type
                }
                
                return "Unknown"
            } catch {
                print("Error parsing space layout data: \(error)")
                return "Unknown"
            }
        }
    func toggleLayout(for space: YabaiSpace) {
        let currentLayout = getSpaceLayout(for: space)
            let newLayout: String
            switch currentLayout.lowercased() {
            case "bsp":
                newLayout = "stack"
            case "stack":
                newLayout = "bsp"
            default:
                newLayout = "bsp"
            }
            
            
            if let _ = runYabaiCommand(arguments: ["-m", "space", "\(space.id)", "--layout", newLayout]) {
                print("Successfully toggled layout for space \(space.id) to \(newLayout)")
            } else {
                print("Failed to toggle layout for space \(space.id)")
            }
        }
        
}

