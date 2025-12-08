import SwiftUI

private var panels: [NSPanel] = []

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
    static var currentScreenIndex: Int? = nil

    static func show<Content: View>(
        rect: CGRect, id: String, @ViewBuilder content: @escaping () -> Content
    ) {
        // Determine which screen the widget is on
        let screenIndex = getScreenIndex(for: rect)
        guard screenIndex < panels.count else { return }

        let panel = panels[screenIndex]
        currentScreenIndex = screenIndex

        if panel.isKeyWindow, lastContentIdentifier == id {
            NotificationCenter.default.post(name: .willHideWindow, object: nil)
            let duration =
                Double(Constants.menuBarPopupAnimationDurationInMilliseconds)
                / 1000.0
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                panel.orderOut(nil)
                lastContentIdentifier = nil
            }
            return
        }

        let isContentChange =
            panel.isKeyWindow
            && (lastContentIdentifier != nil && lastContentIdentifier != id)
        lastContentIdentifier = id

        if let hidingPanel = panel as? HidingPanel {
            hidingPanel.hideTimer?.invalidate()
            hidingPanel.hideTimer = nil
        }

        if panel.isKeyWindow {
            NotificationCenter.default.post(
                name: .willChangeContent, object: nil)
            let baseDuration =
                Double(Constants.menuBarPopupAnimationDurationInMilliseconds)
                / 1000.0
            let duration = isContentChange ? baseDuration / 2 : baseDuration
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                panel.contentView = NSHostingView(
                    rootView:
                        ZStack {
                            MenuBarPopupView {
                                content()
                            }
                            .position(x: rect.midX)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .id(UUID())
                )
                panel.makeKeyAndOrderFront(nil)
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .willShowWindow, object: nil)
                }
            }
        } else {
            panel.contentView = NSHostingView(
                rootView:
                    ZStack {
                        MenuBarPopupView {
                            content()
                        }
                        .position(x: rect.midX)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            )
            panel.makeKeyAndOrderFront(nil)
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .willShowWindow, object: nil)
            }
        }
    }

    static func setup() {
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
        while panels.count > screens.count {
            panels.removeLast().close()
        }

        // Create panels for each screen
        for (index, screen) in screens.enumerated() {
            let panelFrame = NSRect(
                x: 0,
                y: 0,
                width: screen.visibleFrame.width,
                height: screen.visibleFrame.height
            )

            if index < panels.count {
                // Update existing panel
                panels[index].setFrame(panelFrame, display: true)
            } else {
                // Create new panel
                let newPanel = HidingPanel(
                    contentRect: panelFrame,
                    styleMask: [.nonactivatingPanel],
                    backing: .buffered,
                    defer: false
                )

                newPanel.level = NSWindow.Level(
                    rawValue: Int(CGWindowLevelForKey(.floatingWindow)))
                newPanel.backgroundColor = .clear
                newPanel.hasShadow = false
                newPanel.collectionBehavior = [.canJoinAllSpaces]

                panels.append(newPanel)
            }
        }
    }

    private static func getScreenIndex(for rect: CGRect) -> Int {
        let monitorMode = ConfigManager.shared.config.monitors.mode

        switch monitorMode {
        case .main:
            return 0
        case .all:
            let screens = NSScreen.screens

            // Find which screen contains the rect (based on the midpoint)
            let midX = rect.midX
            let midY = rect.midY

            for (index, screen) in screens.enumerated() {
                let frame = screen.frame
                if midX >= frame.minX && midX <= frame.maxX &&
                   midY >= frame.minY && midY <= frame.maxY {
                    return index
                }
            }

            // Default to main screen (index 0) if not found
            return 0
        }
    }
}
