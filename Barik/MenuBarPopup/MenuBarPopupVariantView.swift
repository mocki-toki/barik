import SwiftUI

enum MenuBarPopupVariant: String, Equatable {
    case box, vertical, horizontal, dayView, settings
}

struct MenuBarPopupVariantView: View {
    private let box: AnyView?
    private let vertical: AnyView?
    private let horizontal: AnyView?
    private let dayView: AnyView?
    private let settings: AnyView?

    var selectedVariant: MenuBarPopupVariant
    @State private var hovered = false
    @State private var animationValue = 0.0

    var onVariantSelected: ((MenuBarPopupVariant) -> Void)?

    init(
        selectedVariant: MenuBarPopupVariant,
        onVariantSelected: ((MenuBarPopupVariant) -> Void)? = nil,
        @ViewBuilder box: () -> some View = { EmptyView() },
        @ViewBuilder vertical: () -> some View = { EmptyView() },
        @ViewBuilder horizontal: () -> some View = { EmptyView() },
        @ViewBuilder dayView: () -> some View = { EmptyView() },
        @ViewBuilder settings: () -> some View = { EmptyView() }
    ) {
        self.selectedVariant = selectedVariant
        self.onVariantSelected = onVariantSelected

        let boxView = box()
        let verticalView = vertical()
        let horizontalView = horizontal()
        let dayViewView = dayView()
        let settingsView = settings()

        self.box = (boxView is EmptyView) ? nil : AnyView(boxView)
        self.vertical =
            (verticalView is EmptyView) ? nil : AnyView(verticalView)
        self.horizontal =
            (horizontalView is EmptyView) ? nil : AnyView(horizontalView)
        self.dayView =
            (dayViewView is EmptyView) ? nil : AnyView(dayViewView)
        self.settings =
            (settingsView is EmptyView) ? nil : AnyView(settingsView)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            content(for: selectedVariant)
                .blur(radius: animationValue * 30)
                .transition(.opacity)
        }
        .overlay(alignment: .bottomTrailing) {
            HStack(spacing: 3) {
                if box != nil {
                    variantButton(
                        variant: .box, systemImageName: "square.inset.filled")
                }
                if vertical != nil {
                    variantButton(
                        variant: .vertical,
                        systemImageName: "rectangle.portrait.inset.filled")
                }
                if horizontal != nil {
                    variantButton(
                        variant: .horizontal,
                        systemImageName: "rectangle.inset.filled")
                }
                if dayView != nil {
                    variantButton(
                        variant: .dayView,
                        systemImageName: "calendar.day.timeline.left")
                }
                if settings != nil {
                    variantButton(
                        variant: .settings, systemImageName: "gearshape.fill")
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 5)
            .contentShape(Rectangle())
            .opacity(hovered ? 1 : 0.0)
            .onHover { value in
                withAnimation(.easeIn(duration: 0.3)) {
                    hovered = value
                }
            }
        }
    }

    @ViewBuilder
    private func content(for variant: MenuBarPopupVariant) -> some View {
        switch variant {
        case .box:
            if let view = box { view }
        case .vertical:
            if let view = vertical { view }
        case .horizontal:
            if let view = horizontal { view }
        case .dayView:
            if let view = dayView { view }
        case .settings:
            if let view = settings { view }
        }
    }

    private func variantButton(
        variant: MenuBarPopupVariant, systemImageName: String
    ) -> some View {
        Button {
            if selectedVariant != variant {
                withAnimation(.smooth(duration: 0.3)) {
                    animationValue = 1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.smooth(duration: 0.3)) {
                        onVariantSelected?(variant)
                    }
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.smooth(duration: 0.3)) {
                        animationValue = 0
                    }
                }
            }
        } label: {
            Image(systemName: systemImageName)
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 13, height: 10)
        }
        .buttonStyle(HoverButtonStyle())
        .overlay(
            Group {
                if selectedVariant == variant {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        .opacity(1 - animationValue * 10)
                }
            }
        )
    }
}

private struct HoverButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HoverButton(configuration: configuration)
    }

    struct HoverButton: View {
        let configuration: Configuration
        @State private var isHovered = false

        var body: some View {
            configuration.label
                .padding(8)
                .background(isHovered ? Color.gray.opacity(0.4) : Color.clear)
                .cornerRadius(8)
                .onHover { hovering in
                    isHovered = hovering
                }
        }
    }
}
