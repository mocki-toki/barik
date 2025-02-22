import SwiftUI

private var panel: NSPanel?

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

    static func show<Content: View>(
        rect: CGRect, id: String, @ViewBuilder content: @escaping () -> Content
    ) {
        guard let panel = panel else { return }

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
        guard let screen = NSScreen.main?.visibleFrame else { return }
        let panelFrame = NSRect(
            x: 0,
            y: 0,
            width: screen.size.width,
            height: screen.size.height
        )

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

        panel = newPanel
    }
}
