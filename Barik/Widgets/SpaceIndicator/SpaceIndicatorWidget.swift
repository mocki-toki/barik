import SwiftUICore

struct SpaceIndicatorWidget: View {
    @ObservedObject var viewModel = SpaceViewModel()

    var body: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.spaces) { space in
                SpaceView(space: space)
            }
        }.animation(.smooth(duration: 0.3), value: viewModel.spaces)
            .foregroundStyle(Color.foreground)
    }
}

/// This view shows a space with its windows.
private struct SpaceView: View {
    let space: AnySpace

    var body: some View {
        let isFocused = space.windows.contains { $0.isFocused }
        HStack(spacing: 8) {
            Spacer().frame(width: 2)
            Text(space.id)
                .font(.headline)
                .frame(minWidth: 15)
                .fixedSize(horizontal: true, vertical: false)
            ForEach(space.windows) { window in
                WindowView(window: window, space: space)
            }
            Spacer().frame(width: 2)
        }
        .frame(height: 30)
        .background(
            isFocused ? Color.active : Color.noActive
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: .shadow, radius: 2)
        .transition(.blurReplace)
    }
}

/// This view shows a window and its icon.
private struct WindowView: View {
    let window: AnyWindow
    let space: AnySpace

    var body: some View {
        let titleMaxLength = 50
        let size: CGFloat = 21
        let sameAppCount = space.windows.filter { $0.appName == window.appName }
            .count
        let title = sameAppCount > 1 ? window.title : (window.appName ?? "")
        let spaceIsFocused = space.windows.contains { $0.isFocused }
        HStack {
            ZStack {
                if let icon = window.appIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: size, height: size)
                        .shadow(
                            color: .iconShadow,
                            radius: 2
                        )
                } else {
                    Image(systemName: "questionmark.circle")
                        .resizable()
                        .frame(width: size, height: size)
                }
            }
            .opacity(spaceIsFocused && !window.isFocused ? 0.5 : 1)
            .transition(.blurReplace)

            if window.isFocused, !title.isEmpty {
                HStack {
                    Text(
                        title.count > titleMaxLength
                            ? String(title.prefix(titleMaxLength)) + "..."
                            : title
                    )
                    .fixedSize(horizontal: true, vertical: false)
                    .shadow(color: .foregroundShadow, radius: 3)
                    .fontWeight(.semibold)
                    Spacer().frame(width: 5)
                }
                .transition(.blurReplace)
            }
        }
    }
}
