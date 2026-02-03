import SwiftUI

struct MenuBarPopupView<Content: View>: View {
    let content: Content
    let isPreview: Bool
    let widgetRect: CGRect

    @ObservedObject var configManager = ConfigManager.shared
    var foregroundHeight: CGFloat { configManager.config.experimental.foreground.resolveHeight() }

    @State private var contentHeight: CGFloat = 0
    @State private var viewFrame: CGRect = .zero
    @State private var animationValue: Double = 0.01
    private var animated: Bool { isShowAnimation || isHideAnimation }
    @State private var isShowAnimation = false
    @State private var isHideAnimation = false

    private let willShowWindow = NotificationCenter.default.publisher(
        for: .willShowWindow)
    private let willHideWindow = NotificationCenter.default.publisher(
        for: .willHideWindow)
    private let willChangeContent = NotificationCenter.default.publisher(
        for: .willChangeContent)

    init(widgetRect: CGRect = .zero, isPreview: Bool = false, @ViewBuilder content: () -> Content) {
        self.widgetRect = widgetRect
        self.content = content()
        self.isPreview = isPreview
        if isPreview {
            _animationValue = State(initialValue: 1.0)
        }
    }

    // Position popup directly below the Barik menu bar
    // foregroundHeight is the exact height of the Barik bar, which overlays the system menu bar
    var popupTopPosition: CGFloat {
        return foregroundHeight
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            content
                .background(Color.black)
                .cornerRadius(((1.0 - animationValue) * 1) + 40)
                .shadow(radius: 30)
                .blur(radius: (1.0 - (0.1 + 0.9 * animationValue)) * 20)
                .scaleEffect(x: 0.2 + 0.8 * animationValue, y: animationValue, anchor: .top)
                .offset(x: computedOffset, y: popupTopPosition)
                .opacity(animationValue)
                .transaction { transaction in
                    if isHideAnimation {
                        transaction.animation = .linear(duration: 0.1)
                    }
                }
                .onReceive(willShowWindow) { _ in
                    isShowAnimation = true
                    withAnimation(
                        .smooth(
                            duration: Double(
                                Constants
                                    .menuBarPopupAnimationDurationInMilliseconds
                            ) / 1000.0, extraBounce: 0.3)
                    ) {
                        animationValue = 1.0
                    }
                    DispatchQueue.main.asyncAfter(
                        deadline: .now()
                            + .milliseconds(
                                Constants
                                    .menuBarPopupAnimationDurationInMilliseconds
                            )
                    ) {
                        isShowAnimation = false
                    }
                }
                .onReceive(willHideWindow) { _ in
                    isHideAnimation = true
                    withAnimation(
                        .interactiveSpring(
                            duration: Double(
                                Constants
                                    .menuBarPopupAnimationDurationInMilliseconds
                            ) / 1000.0)
                    ) {
                        animationValue = 0.01
                    }
                    DispatchQueue.main.asyncAfter(
                        deadline: .now()
                            + .milliseconds(
                                Constants
                                    .menuBarPopupAnimationDurationInMilliseconds
                            )
                    ) {
                        isHideAnimation = false
                    }
                }
                .onReceive(willChangeContent) { _ in
                    isHideAnimation = true
                    withAnimation(
                        .spring(
                            duration: Double(
                                Constants
                                    .menuBarPopupAnimationDurationInMilliseconds
                            ) / 1000.0)
                    ) {
                        animationValue = 0.01
                    }
                    DispatchQueue.main.asyncAfter(
                        deadline: .now()
                            + .milliseconds(
                                Constants
                                    .menuBarPopupAnimationDurationInMilliseconds
                            )
                    ) {
                        isHideAnimation = false
                    }
                }
                .animation(
                    .smooth(duration: 0.3), value: animated ? 0 : computedOffset
                )
                .animation(
                    .smooth(duration: 0.3),
                    value: animated ? 0 : computedYOffset
                )
        }
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        DispatchQueue.main.async {
                            viewFrame = geometry.frame(in: .global)
                            contentHeight = geometry.size.height
                        }
                    }
                    .onChange(of: geometry.size) { _, __ in
                        viewFrame = geometry.frame(in: .global)
                        contentHeight = geometry.size.height
                    }
            }
        )
        .foregroundStyle(.white)
        .preferredColorScheme(.dark)
    }

    // Calculate X offset to center popup under widget, with edge constraints
    var computedOffset: CGFloat {
        let screenWidth = NSScreen.main?.frame.width ?? 0
        let contentWidth = viewFrame.width > 0 ? viewFrame.width : 200  // Fallback width

        // Start by centering under the widget
        var xOffset = widgetRect.midX - contentWidth / 2

        // Constrain to screen edges with 20pt margin
        let rightEdge = xOffset + contentWidth + 20
        let leftEdge = xOffset - 20

        if rightEdge > screenWidth {
            xOffset -= (rightEdge - screenWidth)
        } else if leftEdge < 0 {
            xOffset -= leftEdge
        }

        return xOffset
    }

    var computedYOffset: CGFloat {
        return 0
    }
}

extension Notification.Name {
    static let willShowWindow = Notification.Name("willShowWindow")
    static let willHideWindow = Notification.Name("willHideWindow")
    static let willChangeContent = Notification.Name("willChangeContent")
}
