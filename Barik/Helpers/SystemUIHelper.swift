import AppKit
import Foundation

/// Helper for triggering macOS system UI elements
final class SystemUIHelper {

    /// Opens the macOS Notification Center by simulating Ctrl+Option+N keypress
    static func openNotificationCenter() {
        // Simulate Ctrl+Option+N keyboard shortcut
        let keyCode: CGKeyCode = 45  // 'n' key
        let flags: CGEventFlags = [.maskControl, .maskAlternate]

        // Create and post key down event
        if let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true) {
            keyDown.flags = flags
            keyDown.post(tap: .cghidEventTap)
        }

        // Create and post key up event
        if let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) {
            keyUp.flags = flags
            keyUp.post(tap: .cghidEventTap)
        }
    }

    /// Opens the macOS Weather menu bar dropdown
    static func openWeatherDropdown() {
        let script = """
            tell application "System Events"
                tell process "ControlCenter"
                    try
                        click menu bar item "Weather" of menu bar 1
                    on error
                        -- Weather might not be in menu bar, try to open Weather app instead
                        tell application "Weather" to activate
                    end try
                end tell
            end tell
            """
        runAppleScript(script)
    }

    /// Opens the Weather app
    static func openWeatherApp() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Weather")!)
        // Fallback to opening Weather app directly
        if let weatherURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.weather") {
            NSWorkspace.shared.open(weatherURL)
        }
    }

    /// Runs an AppleScript
    @discardableResult
    private static func runAppleScript(_ script: String) -> String? {
        guard let appleScript = NSAppleScript(source: script) else {
            return nil
        }
        var error: NSDictionary?
        let result = appleScript.executeAndReturnError(&error)
        if let error = error {
            print("AppleScript Error: \(error)")
            return nil
        }
        return result.stringValue
    }
}
