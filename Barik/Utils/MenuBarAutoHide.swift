import Foundation

struct MenuBarAutoHide {
    private static var lastState: Bool?

    static func setAutoHide(_ enabled: Bool) {
        // Skip if state unchanged
        if lastState == enabled {
            return
        }
        lastState = enabled

        print("[Barik] MenuBarAutoHide: Setting auto-hide to \(enabled)")

        let script = """
        tell application "System Events"
            tell dock preferences to set autohide menu bar to \(enabled)
        end tell
        """

        guard let appleScript = NSAppleScript(source: script) else {
            print("[Barik] MenuBarAutoHide: Failed to create AppleScript")
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)

            if let error = error {
                print("[Barik] MenuBarAutoHide: AppleScript error: \(error)")
            } else {
                print("[Barik] MenuBarAutoHide: Success")
            }
        }
    }
}
