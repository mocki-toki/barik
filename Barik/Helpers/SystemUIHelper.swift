import AppKit
import Foundation

/// Helper for triggering macOS system UI elements
final class SystemUIHelper {
    /// Opens the macOS Notification Center by simulating the configured keypress
    static func openNotificationCenter() {
        // Check for accessibility permissions first
        guard checkAccessibilityPermissions() else {
            print("Accessibility permissions not granted")
            return
        }
        
        let keyCode: CGKeyCode = ConfigManager.shared.config.keybinds.notifications.keyCode
        let flags: CGEventFlags = ConfigManager.shared.config.keybinds.notifications.flags
        
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
    
    /// Quick way to check for accessibility permissions
    static func checkAccessibilityPermissions() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        return accessEnabled
    }
}
