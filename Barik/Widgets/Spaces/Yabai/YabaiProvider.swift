import Combine
import Foundation

class YabaiSpacesProvider: SpacesProvider, SwitchableSpacesProvider, EventBasedSpacesProvider {
    typealias SpaceType = YabaiSpace
    let executablePath = ConfigManager.shared.config.yabai.path

    // MARK: - Event-Based Provider Support

    private let spacesSubject = PassthroughSubject<SpaceEvent, Never>()
    var spacesPublisher: AnyPublisher<SpaceEvent, Never> {
        spacesSubject.eraseToAnyPublisher()
    }

    private var socketFileDescriptor: Int32 = -1
    private var socketPath = "/tmp/barik-yabai.sock"
    private var isObserving = false
    private var socketQueue = DispatchQueue(label: "com.barik.yabai.socket", qos: .userInitiated)

    func startObserving() {
        guard !isObserving else { return }
        isObserving = true

        // Send initial state asynchronously to avoid blocking main thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            if let spaces = self.getSpacesWithWindows() {
                let anySpaces = spaces.map { AnySpace($0) }
                DispatchQueue.main.async {
                    self.spacesSubject.send(.initialState(anySpaces))
                }
            }
        }

        // Start socket listener
        socketQueue.async { [weak self] in
            self?.startSocketListener()
        }
    }

    func stopObserving() {
        isObserving = false
        if socketFileDescriptor >= 0 {
            close(socketFileDescriptor)
            socketFileDescriptor = -1
        }
        unlink(socketPath)
    }

    private func startSocketListener() {
        // Remove existing socket file
        unlink(socketPath)

        // Create Unix domain socket (SOCK_STREAM for nc -U compatibility)
        socketFileDescriptor = socket(AF_UNIX, SOCK_STREAM, 0)
        guard socketFileDescriptor >= 0 else {
            print("Failed to create socket")
            return
        }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let pathSize = MemoryLayout.size(ofValue: addr.sun_path)
        socketPath.withCString { ptr in
            withUnsafeMutablePointer(to: &addr.sun_path) { pathPtr in
                let pathBytes = UnsafeMutableRawPointer(pathPtr)
                    .assumingMemoryBound(to: CChar.self)
                strncpy(pathBytes, ptr, pathSize - 1)
            }
        }

        let bindResult = withUnsafePointer(to: &addr) { addrPtr in
            addrPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                bind(socketFileDescriptor, sockaddrPtr, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }

        guard bindResult >= 0 else {
            print("Failed to bind socket: \(String(cString: strerror(errno)))")
            close(socketFileDescriptor)
            socketFileDescriptor = -1
            return
        }

        // Listen for incoming connections
        guard listen(socketFileDescriptor, 5) >= 0 else {
            print("Failed to listen on socket: \(String(cString: strerror(errno)))")
            close(socketFileDescriptor)
            socketFileDescriptor = -1
            return
        }

        // Accept connections and read messages
        var buffer = [CChar](repeating: 0, count: 1024)
        while isObserving && socketFileDescriptor >= 0 {
            let clientFd = accept(socketFileDescriptor, nil, nil)
            if clientFd >= 0 {
                let bytesRead = recv(clientFd, &buffer, buffer.count - 1, 0)
                if bytesRead > 0 {
                    buffer[bytesRead] = 0
                    let message = String(cString: buffer)
                    handleSocketMessage(message.trimmingCharacters(in: .whitespacesAndNewlines))
                }
                close(clientFd)
            }
        }
    }

    private func handleSocketMessage(_ message: String) {
        // Parse message format: "event_type:data" or just "event_type"
        let parts = message.split(separator: ":", maxSplits: 1)
        let eventType = String(parts[0])
        let data = parts.count > 1 ? String(parts[1]) : nil

        switch eventType {
        case "space_changed":
            if let spaceId = data {
                spacesSubject.send(.focusChanged(spaceId))
            } else {
                // Fallback: query current focused space
                refreshSpaces()
            }

        case "window_focused", "window_created", "window_destroyed", "window_moved":
            // For window events, refresh the windows for affected space
            if let spaceIdStr = data, let spaces = getSpacesWithWindows() {
                if let space = spaces.first(where: { String($0.id) == spaceIdStr }) {
                    let windows = space.windows.map { AnyWindow($0) }
                    spacesSubject.send(.windowsUpdated(spaceIdStr, windows))
                }
            } else {
                refreshSpaces()
            }

        case "space_created":
            if let spaceId = data {
                spacesSubject.send(.spaceCreated(spaceId))
            } else {
                refreshSpaces()
            }

        case "space_destroyed":
            if let spaceId = data {
                spacesSubject.send(.spaceDestroyed(spaceId))
            } else {
                refreshSpaces()
            }

        default:
            // Unknown event, refresh all
            refreshSpaces()
        }
    }

    private func refreshSpaces() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            if let spaces = self.getSpacesWithWindows() {
                let anySpaces = spaces.map { AnySpace($0) }
                DispatchQueue.main.async {
                    self.spacesSubject.send(.initialState(anySpaces))
                }
            }
        }
    }

    // MARK: - Original Provider Methods

    private func runYabaiCommand(arguments: [String]) -> Data? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
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
        guard
            let data = runYabaiCommand(arguments: ["-m", "query", "--spaces"])
        else {
            return nil
        }
        let decoder = JSONDecoder()
        do {
            let spaces = try decoder.decode([YabaiSpace].self, from: data)
            return spaces
        } catch {
            print("Decode yabai spaces error: \(error)")
            return nil
        }
    }

    private func fetchWindows() -> [YabaiWindow]? {
        guard
            let data = runYabaiCommand(arguments: ["-m", "query", "--windows"])
        else {
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
        var spaceDict = Dictionary(
            uniqueKeysWithValues: spaces.map { ($0.id, $0) })
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

    func focusSpace(spaceId: String, needWindowFocus: Bool) {
        _ = runYabaiCommand(arguments: ["-m", "space", "--focus", spaceId])
        if !needWindowFocus { return }

        DispatchQueue.global(qos: .userInitiated).asyncAfter(
            deadline: .now() + 0.1
        ) {
            if let spaces = self.getSpacesWithWindows() {
                if let space = spaces.first(where: { $0.id == Int(spaceId) }) {
                    let hasFocused = space.windows.contains { $0.isFocused }
                    if !hasFocused, let firstWindow = space.windows.first {
                        _ = self.runYabaiCommand(arguments: [
                            "-m", "window", "--focus", String(firstWindow.id),
                        ])
                    }
                }
            }
        }
    }

    func focusWindow(windowId: String) {
        _ = runYabaiCommand(arguments: ["-m", "window", "--focus", windowId])
    }
}
