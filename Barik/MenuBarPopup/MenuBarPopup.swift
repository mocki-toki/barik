import SwiftUI

private var panels: [CGDirectDisplayID: NSPanel] = [:]

class HidingPanel: NSPanel, NSWindowDelegate {
    var hideTimer: Timer?

    override var canBecomeKey: Bool {
        return true
    }

    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing bufferingType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: contentRect, styleMask: style, backing: bufferingType,
            defer: flag)
        self.delegate = self
    }

    func windowDidResignKey(_ notification: Notification) {
        NotificationCenter.default.post(name: .willHideWindow, object: nil)
        hideTimer = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(
                Constants.menuBarPopupAnimationDurationInMilliseconds) / 1000.0,
            repeats: false
        ) { [weak self] _ in
            self?.orderOut(nil)
        }
    }
}

class MenuBarPopup {
    static var lastContentIdentifier: String? = nil
    static var lastDisplayID: CGDirectDisplayID? = nil

    static func show<Content: View>(
        rect: CGRect, id: String, @ViewBuilder content: @escaping () -> Content
    ) {
        print("[DEBUG] MenuBarPopup.show called - id: \(id), rect: \(rect)")

        // Find which screen the widget rect is on
        let targetScreen = NSScreen.screens.first { screen in
            screen.frame.contains(CGPoint(x: rect.midX, y: rect.midY))
        } ?? NSScreen.main

        guard let screen = targetScreen else {
            print("[DEBUG] No screen found!")
            return
        }
        let displayID = screen.displayID
        print("[DEBUG] Screen: \(screen.frame), displayID: \(displayID)")

        guard let panel = panels[displayID] else {
            print("[DEBUG] No panel for displayID: \(displayID), available: \(panels.keys)")
            return
        }
        print("[DEBUG] Panel found, frame: \(panel.frame), level: \(panel.level.rawValue)")

        let position = ConfigManager.shared.config.experimental.foreground.position
        print("[DEBUG] Position: \(position)")

        // Hide other screen popups
        for (otherID, otherPanel) in panels where otherID != displayID {
            if otherPanel.isKeyWindow {
                otherPanel.orderOut(nil)
            }
        }

        if panel.isKeyWindow, lastContentIdentifier == id, lastDisplayID == displayID {
            NotificationCenter.default.post(name: .willHideWindow, object: nil)
            let duration =
                Double(Constants.menuBarPopupAnimationDurationInMilliseconds)
                / 1000.0
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                panel.orderOut(nil)
                lastContentIdentifier = nil
                lastDisplayID = nil
            }
            return
        }

        let isContentChange =
            panel.isKeyWindow
            && (lastContentIdentifier != nil && lastContentIdentifier != id)
        lastContentIdentifier = id
        lastDisplayID = displayID

        if let hidingPanel = panel as? HidingPanel {
            hidingPanel.hideTimer?.invalidate()
            hidingPanel.hideTimer = nil
        }

        // Position the panel at the correct location
        let popupSize = CGSize(width: 400, height: 500)

        // Panel X: centered on widget, clamped to screen
        let panelX = max(screen.frame.minX + 10,
                         min(rect.midX - popupSize.width / 2,
                             screen.frame.maxX - popupSize.width - 10))

        // rect is in flipped coords (origin top-left), convert to macOS (origin bottom-left)
        let screenHeight = screen.frame.height
        let widgetTopMacOS = screen.frame.origin.y + screenHeight - rect.minY
        let widgetBottomMacOS = screen.frame.origin.y + screenHeight - rect.maxY

        // Panel Y: above widget for bottom bar, below widget for top bar
        let panelY: CGFloat = switch position {
        case .top: widgetBottomMacOS - popupSize.height - 5   // Popup below widget
        case .bottom: widgetTopMacOS + 5                       // Popup above widget
        }
        print("[DEBUG] widgetTopMacOS: \(widgetTopMacOS), widgetBottomMacOS: \(widgetBottomMacOS)")

        let panelFrame = CGRect(origin: CGPoint(x: panelX, y: panelY), size: popupSize)
        panel.setFrame(panelFrame, display: false)
        print("[DEBUG] Panel frame set to: \(panelFrame)")

        let popupView = AnyView(
            MenuBarPopupView(position: position) {
                content()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        )

        if panel.isKeyWindow {
            NotificationCenter.default.post(
                name: .willChangeContent, object: nil)
            let baseDuration =
                Double(Constants.menuBarPopupAnimationDurationInMilliseconds)
                / 1000.0
            let duration = isContentChange ? baseDuration / 2 : baseDuration
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                panel.contentView = NSHostingView(rootView: popupView.id(UUID()))
                panel.makeKeyAndOrderFront(nil)
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .willShowWindow, object: nil)
                }
            }
        } else {
            print("[DEBUG] Showing popup panel (not key)")
            panel.contentView = NSHostingView(rootView: popupView)
            panel.makeKeyAndOrderFront(nil)
            print("[DEBUG] makeKeyAndOrderFront called, isVisible: \(panel.isVisible), isKey: \(panel.isKeyWindow)")
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .willShowWindow, object: nil)
            }
        }
    }

    static func setup() {
        setupAllScreens()
    }

    static func setupAllScreens() {
        let screens = NSScreen.screens
        var activeDisplayIDs = Set<CGDirectDisplayID>()

        for screen in screens {
            let displayID = screen.displayID
            activeDisplayIDs.insert(displayID)

            if let existingPanel = panels[displayID] {
                // Just update the level, frame is set in show()
                existingPanel.level = NSWindow.Level(
                    rawValue: Int(CGWindowLevelForKey(.popUpMenuWindow)))
                continue
            }

            // Create with minimal frame - actual position set in show()
            let newPanel = HidingPanel(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
                styleMask: [.nonactivatingPanel],
                backing: .buffered,
                defer: false
            )

            newPanel.level = NSWindow.Level(
                rawValue: Int(CGWindowLevelForKey(.popUpMenuWindow)))
            newPanel.backgroundColor = .clear
            newPanel.hasShadow = false
            newPanel.collectionBehavior = [.canJoinAllSpaces]

            panels[displayID] = newPanel
        }

        // Remove panels for disconnected screens
        for displayID in panels.keys where !activeDisplayIDs.contains(displayID) {
            panels[displayID]?.orderOut(nil)
            panels.removeValue(forKey: displayID)
        }
    }
}
