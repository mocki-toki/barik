import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var backgroundPanels: [NSPanel] = []
    private var menuBarPanels: [NSPanel] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let error = ConfigManager.shared.initError {
            showFatalConfigError(message: error)
            return
        }
        
        // Show "What's New" banner if the app version is outdated
        if !VersionChecker.isLatestVersion() {
            VersionChecker.updateVersionFile()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                NotificationCenter.default.post(
                    name: Notification.Name("ShowWhatsNewBanner"), object: nil)
            }
        }
        
        MenuBarPopup.setup()
        setupPanels()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange(_:)),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil)
    }

    @objc private func screenParametersDidChange(_ notification: Notification) {
        setupPanels()
    }

    /// Configures and displays the background and menu bar panels.
    private func setupPanels() {
        let monitorMode = ConfigManager.shared.config.monitors.mode
        let screens: [NSScreen]

        switch monitorMode {
        case .main:
            if let mainScreen = NSScreen.main {
                screens = [mainScreen]
            } else {
                return
            }
        case .all:
            screens = NSScreen.screens
        }

        // Remove excess panels if screens were reduced
        while backgroundPanels.count > screens.count {
            backgroundPanels.removeLast().close()
        }
        while menuBarPanels.count > screens.count {
            menuBarPanels.removeLast().close()
        }

        // Create or update panels for each screen
        for (index, screen) in screens.enumerated() {
            let screenFrame = screen.frame

            if index < backgroundPanels.count {
                // Update existing panel
                backgroundPanels[index].setFrame(screenFrame, display: true)
                menuBarPanels[index].setFrame(screenFrame, display: true)
            } else {
                // Create new panels
                let backgroundPanel = createPanel(
                    frame: screenFrame,
                    level: Int(CGWindowLevelForKey(.desktopWindow)),
                    hostingRootView: AnyView(BackgroundView())
                )
                let menuBarPanel = createPanel(
                    frame: screenFrame,
                    level: Int(CGWindowLevelForKey(.backstopMenu)),
                    hostingRootView: AnyView(MenuBarView())
                )
                backgroundPanels.append(backgroundPanel)
                menuBarPanels.append(menuBarPanel)
            }
        }
    }

    /// Creates an NSPanel with the provided parameters.
    private func createPanel(
        frame: CGRect, level: Int, hostingRootView: AnyView
    ) -> NSPanel {
        let newPanel = NSPanel(
            contentRect: frame,
            styleMask: [.nonactivatingPanel],
            backing: .buffered,
            defer: false)
        newPanel.level = NSWindow.Level(rawValue: level)
        newPanel.backgroundColor = .clear
        newPanel.hasShadow = false
        newPanel.collectionBehavior = [.canJoinAllSpaces]
        newPanel.contentView = NSHostingView(rootView: hostingRootView)
        newPanel.orderFront(nil)
        return newPanel
    }
    
    private func showFatalConfigError(message: String) {
        let alert = NSAlert()
        alert.messageText = "Configuration Error"
        alert.informativeText = "\(message)\n\nPlease double check ~/.barik-config.toml and try again."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Quit")
        
        alert.runModal()
        NSApplication.shared.terminate(nil)
    }
}
