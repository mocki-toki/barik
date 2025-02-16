import SwiftUI
import Cocoa


enum MenuBarPanelAlignment {
    case top
    case bottom
}

class AppDelegate: NSObject, NSApplicationDelegate {
    // Store the status item so it persists during the app’s lifetime.
    var statusItem: NSStatusItem?
    
    // Optional: Keep a reference to the menu bar panel if needed.
    var menuPanel: NSPanel?
    
    // Set your desired initial alignment here:
    var menuBarAlignment: MenuBarPanelAlignment = .bottom {
        didSet {
            // Update the toggle menu item's title to reflect the new state.
            updateToggleAlignmentMenuItem()
        }
    }
    
    // Keep a reference to the toggle menu item so we can update its title.
    var toggleAlignmentMenuItem: NSMenuItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupAndShowBackground()
        setupAndShowMenuBar()
    }
    
    // MARK: - Status Item Setup
    
    private func setupStatusItem() {
        // Create a status item with a fixed square length.
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            // Optionally, set an image or title.
            button.image = NSImage(systemSymbolName: "star.fill", accessibilityDescription: "App Icon")
        }
        
        // Create the status item menu.
        let menu = NSMenu()
        
        // Add a toggle alignment menu item.
        let toggleAlignment = NSMenuItem(
            title: alignmentMenuItemTitle(),
            action: #selector(toggleMenuBarAlignment),
            keyEquivalent: "t"
        )
        toggleAlignment.target = self
        menu.addItem(toggleAlignment)
        toggleAlignmentMenuItem = toggleAlignment
        
        // Add a separator.
        menu.addItem(NSMenuItem.separator())
        
        // Add a Quit menu item.
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    private func alignmentMenuItemTitle() -> String {
        // Returns a title based on the current alignment.
        switch menuBarAlignment {
        case .bottom:
            return "Align to Top"
        case .top:
            return "Align to Bottom"
        }
    }
    
    private func updateToggleAlignmentMenuItem() {
        // Update the toggle alignment menu item's title.
        toggleAlignmentMenuItem?.title = alignmentMenuItemTitle()
    }
    
    @objc private func toggleMenuBarAlignment() {
        // Toggle the alignment value.
        menuBarAlignment = (menuBarAlignment == .bottom) ? .top : .bottom
        // Reposition the menu bar panel.
        repositionMenuPanel()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Panel Setup
    
    /// Helper function to compute the height for the panel.
    /// Currently, it uses the dock height (assumed to be at the bottom) as the panel height.
    /// You can also set a constant value if needed.
    private func panelHeight(for screen: NSScreen) -> CGFloat {
        // This example uses the dock height.
        return screen.visibleFrame.origin.y
    }
    
    private func setupAndShowBackground() {
        guard let screen = NSScreen.main else { return }
        let height = panelHeight(for: screen)
        let panelFrame = NSRect(x: 0, y: 0, width: screen.visibleFrame.width, height: height)
        
        let panel = NSPanel(
            contentRect: panelFrame,
            styleMask: [.nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        // Set the panel level so it appears behind other windows.
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces]
        // Replace BackgroundView() with your actual SwiftUI view.
        panel.contentView = NSHostingView(rootView: BackgroundView())
        
        panel.orderFront(nil)
    }
    
    private func setupAndShowMenuBar() {
        guard let screen = NSScreen.main else { return }
        let height = panelHeight(for: screen)
        let panelFrame = calculatePanelFrame(for: screen, height: height)
        
        let panel = NSPanel(
            contentRect: panelFrame,
            styleMask: [.nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        // Set the panel level so it appears above the menu bar background.
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.backstopMenu)))
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces]
        // Replace MenuBarView() with your actual SwiftUI view.
        panel.contentView = NSHostingView(rootView: MenuBarView())
        
        panel.orderFront(nil)
        // Store a reference so we can reposition it later.
        menuPanel = panel
    }
    
    /// Calculates the panel frame based on the desired alignment.
    private func calculatePanelFrame(for screen: NSScreen, height: CGFloat) -> NSRect {
        switch menuBarAlignment {
        case .bottom:
            return NSRect(x: 0, y: 0, width: screen.visibleFrame.width, height: height)
        case .top:
            return NSRect(
                x: 0,
                y: screen.visibleFrame.height,
                width: screen.visibleFrame.width,
                height: 55
            )
        }
    }
    
    /// Repositions the menu bar panel according to the current alignment.
    private func repositionMenuPanel() {
        guard let screen = NSScreen.main, let panel = menuPanel else { return }
        let height = panelHeight(for: screen)
        let newFrame = calculatePanelFrame(for: screen, height: height)
        panel.setFrame(newFrame, display: true, animate: true)
    }
}
