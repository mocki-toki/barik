import Foundation

struct CommandResult {
    let output: String
    let exitCode: Int32
}

enum CommandRunner {
    static func run(
        executable: String,
        arguments: [String] = [],
        environment: [String: String] = [:]
    ) -> CommandResult? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        if !environment.isEmpty {
            var merged = ProcessInfo.processInfo.environment
            for (key, value) in environment {
                merged[key] = value
            }
            process.environment = merged
        }

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
        } catch {
            print("Command error: \(error)")
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        let output = String(data: data, encoding: .utf8) ?? ""
        return CommandResult(output: output, exitCode: process.terminationStatus)
    }
}

enum ExecutableLocator {
    static let homebrewBinPaths = ["/opt/homebrew/bin", "/usr/local/bin"]

    static func resolve(_ name: String, preferred: [String] = []) -> String? {
        for path in preferred {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }

        var candidates: [String] = []
        for prefix in homebrewBinPaths {
            candidates.append("\(prefix)/\(name)")
        }
        return locateInPath(name, extraCandidates: candidates)
    }

    private static func locateInPath(
        _ name: String,
        extraCandidates: [String] = []
    ) -> String? {
        for path in extraCandidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        let pathValue = ProcessInfo.processInfo.environment["PATH"] ?? ""
        for entry in pathValue.split(separator: ":") {
            let candidate = String(entry) + "/" + name
            if FileManager.default.isExecutableFile(atPath: candidate) {
                return candidate
            }
        }
        return nil
    }
}
