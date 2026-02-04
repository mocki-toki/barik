import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var backgroundPanel: NSPanel?
    private var menuBarPanel: NSPanel?
    private let contextMenu = MenuBarContextMenu()
    private var eventMonitor: Any?

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
        setupContextMenuMonitor()

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
        guard let screenFrame = NSScreen.main?.frame else { return }
        setupPanel(
            &backgroundPanel,
            frame: screenFrame,
            level: Int(CGWindowLevelForKey(.desktopWindow)),
            hostingRootView: AnyView(BackgroundView()))
        setupPanel(
            &menuBarPanel,
            frame: screenFrame,
            level: Int(CGWindowLevelForKey(.backstopMenu)),
            hostingRootView: AnyView(MenuBarView()))
    }

    /// Sets up an NSPanel with the provided parameters.
    private func setupPanel(
        _ panel: inout NSPanel?, frame: CGRect, level: Int,
        hostingRootView: AnyView
    ) {
        if let existingPanel = panel {
            existingPanel.setFrame(frame, display: true)
            return
        }

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
        panel = newPanel
    }
    
    private func setupContextMenuMonitor() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) {
            [weak self] event in
            guard let self,
                  let panel = self.menuBarPanel,
                  event.window === panel,
                  let contentView = panel.contentView
            else {
                return event
            }
            let locationInView = contentView.convert(event.locationInWindow, from: nil)
            self.contextMenu.popUp(
                positioning: nil, at: locationInView, in: contentView)
            return nil
        }
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
