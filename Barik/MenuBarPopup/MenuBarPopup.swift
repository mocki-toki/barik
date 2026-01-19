import SwiftUI

private var panel: NSPanel?

class HidingPanel: NSPanel, NSWindowDelegate {
    var hideWorkItem: DispatchWorkItem?

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
        let workItem = DispatchWorkItem { [weak self] in
            self?.orderOut(nil)
        }
        hideWorkItem = workItem
        let duration = Double(Constants.menuBarPopupAnimationDurationInMilliseconds) / 1000.0
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
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
            hidingPanel.hideWorkItem?.cancel()
            hidingPanel.hideWorkItem = nil
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
                        MenuBarPopupView(widgetRect: rect) {
                            content()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
                    MenuBarPopupView(widgetRect: rect) {
                        content()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            )
            panel.makeKeyAndOrderFront(nil)
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .willShowWindow, object: nil)
            }
        }
    }

    static func setup() {
        guard let screen = NSScreen.main else { return }

        // Use full screen frame so the panel covers the entire screen including menu bar area
        // This ensures consistent positioning regardless of dock position or menu bar configuration
        let panelFrame = screen.frame

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
