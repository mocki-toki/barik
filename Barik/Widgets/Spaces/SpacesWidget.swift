import SwiftUICore

struct SpacesWidget: View {
    @StateObject var viewModel = SpacesViewModel()

    var body: some View {
        HStack(spacing: 5) {
            LayoutWidget()
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
        HStack(spacing: 5) {
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
        .background(.ultraThinMaterial)
        .preferredColorScheme(.dark)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: .shadow, radius: 2)
        .transition(.blurReplace)
        
        
    }
}

/// This view shows a window and its icon.
private struct WindowView: View {
    @EnvironmentObject var configProvider: ConfigProvider
    var config: ConfigData { configProvider.config }
    var windowConfig: ConfigData { config["window"]?.dictionaryValue ?? [:] }
    var titleConfig: ConfigData {
        windowConfig["title"]?.dictionaryValue ?? [:]
    }

    var maxLength: Int { titleConfig["max-length"]?.intValue ?? 50 }

    let window: AnyWindow
    let space: AnySpace

    var body: some View {
        let titleMaxLength = maxLength
        let size: CGFloat = 21
        let title = (window.appName ?? "")
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
            .onTapGesture {
               print(space)
            }
            

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

