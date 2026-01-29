import Foundation

/// Configures tiling window managers (AeroSpace, Yabai) to respect Barik's space
class TilingWMConfigurator {

    static func configureOnLaunch(barSize: Int, position: BarPosition) {
        DispatchQueue.global(qos: .userInitiated).async {
            configureAeroSpace(barSize: barSize, position: position)
            configureYabai(barSize: barSize, position: position)
        }
    }

    // MARK: - AeroSpace

    private static func configureAeroSpace(barSize: Int, position: BarPosition) {
        let configPath = NSString(string: "~/.aerospace.toml").expandingTildeInPath

        guard FileManager.default.fileExists(atPath: configPath) else { return }
        guard let content = try? String(contentsOfFile: configPath, encoding: .utf8) else { return }

        // Update both outer gaps: active position gets barSize, other gets default
        let allPositions: [BarPosition] = [.top, .bottom]
        let defaultGap = 10
        var updated = content

        for pos in allPositions {
            let gapKey = aerospaceGapKey(for: pos)
            let value = (pos == position) ? barSize : defaultGap
            updated = setAeroSpaceGap(in: updated, gapKey: gapKey, value: value, position: pos)
        }

        // Reset left/right gaps to default (cleanup from old vertical support)
        updated = resetAeroSpaceGap(in: updated, gapKey: "outer.left", value: defaultGap)
        updated = resetAeroSpaceGap(in: updated, gapKey: "outer.right", value: defaultGap)

        do {
            try updated.write(toFile: configPath, atomically: true, encoding: .utf8)
            reloadAeroSpace()
        } catch {
            // Silent failure - user can't act on this from console
        }
    }

    private static func aerospaceGapKey(for position: BarPosition) -> String {
        switch position {
        case .top: return "outer.top"
        case .bottom: return "outer.bottom"
        }
    }

    /// Sets a single AeroSpace gap in the config content.
    /// For .top position: uses per-monitor format to handle MacBook notch
    /// For others: uses simple value format
    private static func setAeroSpaceGap(in content: String, gapKey: String, value: Int, position: BarPosition) -> String {
        var lines = content.components(separatedBy: .newlines)
        var inGapsSection = false
        var gapsSectionEndIndex: Int?

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("[gaps]") {
                inGapsSection = true
                gapsSectionEndIndex = index
                continue
            }

            if inGapsSection && trimmed.hasPrefix("[") && !trimmed.hasPrefix("[gaps") {
                inGapsSection = false
                continue
            }

            if inGapsSection {
                gapsSectionEndIndex = index

                if trimmed.hasPrefix(gapKey) {
                    let indent = String(line.prefix(while: { $0.isWhitespace }))
                    lines[index] = formatAeroSpaceGapLine(indent: indent, gapKey: gapKey, value: value, position: position)
                    return lines.joined(separator: "\n")
                }
            }
        }

        // Gap key not found - add to [gaps] section
        var gapsIndex = lines.firstIndex { $0.trimmingCharacters(in: .whitespaces).hasPrefix("[gaps]") }

        if gapsIndex == nil {
            lines.append("")
            lines.append("[gaps]")
            gapsIndex = lines.count - 1
        }

        // Insert after last line in [gaps] section, or right after [gaps] header
        let insertIndex = (gapsSectionEndIndex ?? gapsIndex!) + 1
        lines.insert(formatAeroSpaceGapLine(indent: "", gapKey: gapKey, value: value, position: position), at: insertIndex)

        return lines.joined(separator: "\n")
    }

    private static func formatAeroSpaceGapLine(indent: String, gapKey: String, value: Int, position: BarPosition) -> String {
        // Per-monitor format for .top to handle MacBook notch (Built-in display uses default, externals use value)
        if position == .top {
            return "\(indent)\(gapKey) = [{ monitor.\"^Built-in.*\" = 10 }, \(value)]"
        } else {
            return "\(indent)\(gapKey) = \(value)"
        }
    }

    /// Resets a gap to a simple value (used for cleaning up old left/right gaps)
    private static func resetAeroSpaceGap(in content: String, gapKey: String, value: Int) -> String {
        var lines = content.components(separatedBy: .newlines)
        var inGapsSection = false

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("[gaps]") {
                inGapsSection = true
                continue
            }

            if inGapsSection && trimmed.hasPrefix("[") && !trimmed.hasPrefix("[gaps") {
                inGapsSection = false
                continue
            }

            if inGapsSection && trimmed.hasPrefix(gapKey) {
                let indent = String(line.prefix(while: { $0.isWhitespace }))
                lines[index] = "\(indent)\(gapKey) = \(value)"
                return lines.joined(separator: "\n")
            }
        }

        // Gap not found, nothing to reset
        return content
    }

    private static func reloadAeroSpace() {
        let aerospacePathBrew = "/opt/homebrew/bin/aerospace"
        let aerospacePathLocal = "/usr/local/bin/aerospace"

        let path: String
        if FileManager.default.fileExists(atPath: aerospacePathBrew) {
            path = aerospacePathBrew
        } else if FileManager.default.fileExists(atPath: aerospacePathLocal) {
            path = aerospacePathLocal
        } else {
            return
        }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: path)
        task.arguments = ["reload-config"]

        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            // Silent failure
        }
    }

    // MARK: - Yabai

    private static func configureYabai(barSize: Int, position: BarPosition) {
        let yabaiPathBrew = "/opt/homebrew/bin/yabai"
        let yabaiPathLocal = "/usr/local/bin/yabai"

        let path: String
        if FileManager.default.fileExists(atPath: yabaiPathBrew) {
            path = yabaiPathBrew
        } else if FileManager.default.fileExists(atPath: yabaiPathLocal) {
            path = yabaiPathLocal
        } else {
            return
        }

        // Check if yabai is running
        let checkTask = Process()
        checkTask.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        checkTask.arguments = ["-x", "yabai"]

        let pipe = Pipe()
        checkTask.standardOutput = pipe

        do {
            try checkTask.run()
            checkTask.waitUntilExit()

            if checkTask.terminationStatus != 0 {
                return
            }
        } catch {
            return
        }

        // Configure based on position
        switch position {
        case .top:
            configureYabaiExternalBar(path: path, topPadding: barSize, bottomPadding: 0)
        case .bottom:
            configureYabaiExternalBar(path: path, topPadding: 0, bottomPadding: barSize)
        }
    }

    private static func configureYabaiExternalBar(path: String, topPadding: Int, bottomPadding: Int) {
        // Format: yabai -m config external_bar all:TOP_PADDING:BOTTOM_PADDING
        let task = Process()
        task.executableURL = URL(fileURLWithPath: path)
        task.arguments = ["-m", "config", "external_bar", "all:\(topPadding):\(bottomPadding)"]

        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            // Silent failure
        }
    }

}
