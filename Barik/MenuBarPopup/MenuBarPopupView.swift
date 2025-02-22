import SwiftUI

struct MenuBarPopupView<Content: View>: View {
    let content: Content
    let isPreview: Bool

    @State private var contentHeight: CGFloat = 0
    @State private var viewFrame: CGRect = .zero
    @State private var animationValue: Double = 0
    private var animated: Bool { isShowAnimation || isHideAnimation }
    @State private var isShowAnimation = false
    @State private var isHideAnimation = false

    private let willShowWindow = NotificationCenter.default.publisher(
        for: .willShowWindow)
    private let willHideWindow = NotificationCenter.default.publisher(
        for: .willHideWindow)
    private let willChangeContent = NotificationCenter.default.publisher(
        for: .willChangeContent)

    init(isPreview: Bool = false, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.isPreview = isPreview
        if isPreview {
            _animationValue = State(initialValue: 1.0)
        }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            content
                .background(Color.black)
                .cornerRadius(((1.0 - animationValue) * 1) + 40)
                .padding(.top, Constants.menuBarHeight)
                .offset(x: computedOffset, y: computedYOffset)
                .shadow(radius: 30)
                .blur(radius: (1.0 - (0.1 + 0.9 * animationValue)) * 20)
                .scaleEffect(x: 0.2 + 0.8 * animationValue, y: animationValue)
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
                        animationValue = 0.0
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
                        animationValue = 0.0
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
        ).foregroundStyle(.white)
    }

    var computedOffset: CGFloat {
        let screenWidth = NSScreen.main?.frame.width ?? 0
        let W = viewFrame.width
        let M = viewFrame.midX
        let newLeft = (M - W / 2) - 20
        let newRight = (M + W / 2) + 20

        if newRight > screenWidth {
            return screenWidth - newRight
        } else if newLeft < 0 {
            return -newLeft
        }
        return 0
    }

    var computedYOffset: CGFloat {
        return viewFrame.height / 2
    }
}

extension Notification.Name {
    static let willShowWindow = Notification.Name("willShowWindow")
    static let willHideWindow = Notification.Name("willHideWindow")
    static let willChangeContent = Notification.Name("willChangeContent")
}
