import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        MenuBarPopup.setup()
        setupAndShowBackground()
        setupAndShowMenuBar()
    }

    private func setupAndShowBackground() {
        guard let screen = NSScreen.main?.frame else { return }
        let panelFrame = NSRect(
            x: 0, y: 0, width: screen.size.width, height: screen.size.height)

        let panel = NSPanel(
            contentRect: panelFrame,
            styleMask: [.nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.level = NSWindow.Level(
            rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces]
        panel.contentView = NSHostingView(rootView: BackgroundView())

        panel.orderFront(nil)
    }

    private func setupAndShowMenuBar() {
        guard let screen = NSScreen.main?.frame else { return }
        let panelFrame = NSRect(
            x: 0, y: 0, width: screen.size.width, height: screen.size.height)

        let panel = NSPanel(
            contentRect: panelFrame,
            styleMask: [.nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.level = NSWindow.Level(
            rawValue: Int(CGWindowLevelForKey(.backstopMenu)))
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces]
        panel.contentView = NSHostingView(rootView: MenuBarView())

        panel.orderFront(nil)
    }
}
