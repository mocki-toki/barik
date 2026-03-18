import SwiftUI

struct SpacesWidget: View {
    @StateObject var viewModel = SpacesViewModel()

    @ObservedObject var configManager = ConfigManager.shared
    @EnvironmentObject var configProvider: ConfigProvider
    
    var foregroundHeight: CGFloat { configManager.config.experimental.foreground.resolveHeight() }
    
    var config: ConfigData { configProvider.config }
    var windowConfig: ConfigData { config["window"]?.dictionaryValue ?? [:] }
    var notchConfig: ConfigData {
        windowConfig["notch"]?.dictionaryValue ?? [:]
    }
    var notchWidth: Int { notchConfig["width"]?.intValue ?? 0 }
    
    @State private var firstSectionCount: Int = 0
    @State private var screenWidth: CGFloat = NSScreen.main?.frame.width ?? 1000
    
    
    // MARK: - Configurable Properties
    private var spacing: CGFloat { foregroundHeight < 30 ? 0 : 8 }
    private var firstSectionMaxWidth: CGFloat {
        notchWidth != 0 ?
            ((screenWidth - CGFloat(notchWidth)) / 2) - (configManager.config.rootToml.experimental?.foreground.horizontalPadding ?? 25)
        : .infinity
    }

    var body: some View {
        HStack(spacing: 0) {
            // First section (up to firstSectionMaxWidth)
            HStack (spacing: spacing) {
                ForEach(viewModel.spaces.prefix(firstSectionCount)) { space in
                    SpaceView(space: space)
                }
            }
            .frame(width: firstSectionMaxWidth, alignment: .leading)
            .experimentalConfiguration(horizontalPadding: 5, cornerRadius: 10)
            .animation(.smooth(duration: 0.3), value: viewModel.spaces)
            .foregroundStyle(Color.foreground)
            .environmentObject(viewModel)
            
            Spacer()
                .frame(width: CGFloat(notchWidth), height: 20)
                // Visualise notch here :
                .background(.clear)
            
            // Remaining items
            HStack (spacing: spacing) {
                ForEach(viewModel.spaces.dropFirst(firstSectionCount)) { space in
                    SpaceView(space: space)
                }
            }
            .experimentalConfiguration(horizontalPadding: 5, cornerRadius: 10)
            .animation(.smooth(duration: 0.3), value: viewModel.spaces)
            .foregroundStyle(Color.foreground)
            .environmentObject(viewModel)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in
            screenWidth = NSScreen.main?.frame.width ?? 1000
        }
        .background(
            // Hidden measuring HStack
            HStack(spacing: spacing) {
                ForEach(Array(viewModel.spaces.enumerated()), id: \.element.id) { index, space in
                    SpaceView(space: space)
                        .background(GeometryReader { geo in
                            Color.clear.preference(
                                key: SpaceWidthPreferenceKey.self,
                                value: [index: geo.size.width]
                            )
                        })
                }
            }
            .hidden()
        )
        .onPreferenceChange(SpaceWidthPreferenceKey.self) { widths in
            var total: CGFloat = 0
            
            for i in 0..<viewModel.spaces.count {
                let itemWidth = widths[i] ?? 0
                let newTotal = total + itemWidth + (i > 0 ? spacing : 0)
                
                if newTotal > firstSectionMaxWidth {
                    firstSectionCount = max(1, i)
                    return
                }
                total = newTotal
            }
            firstSectionCount = viewModel.spaces.count
        }
    }
}

private struct SpaceWidthPreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]
    
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue()) { $1 }
    }
}

/// This view shows a space with its windows.
private struct SpaceView: View {
    @EnvironmentObject var configProvider: ConfigProvider
    @EnvironmentObject var viewModel: SpacesViewModel

    var config: ConfigData { configProvider.config }
    var spaceConfig: ConfigData { config["space"]?.dictionaryValue ?? [:] }

    @ObservedObject var configManager = ConfigManager.shared
    var foregroundHeight: CGFloat { configManager.config.experimental.foreground.resolveHeight() }

    var showKey: Bool { spaceConfig["show-key"]?.boolValue ?? true }

    let space: AnySpace

    @State var isHovered = false

    var body: some View {
        let isFocused = space.windows.contains { $0.isFocused } || space.isFocused
        HStack(spacing: 0) {
            Spacer().frame(width: 10)
            if showKey {
                Text(space.id)
                    .font(.headline)
                    .frame(minWidth: 15)
                    .fixedSize(horizontal: true, vertical: false)
                Spacer().frame(width: 5)
            }
            HStack(spacing: 2) {
                ForEach(space.windows) { window in
                    WindowView(window: window, space: space)
                }
            }
            Spacer().frame(width: 10)
        }
        .frame(height: 30)
        .background(
            foregroundHeight < 30 ?
            (isFocused
             ? Color.noActive
             : Color.clear) :
                (isFocused
                 ? Color.active
                 : isHovered ? Color.noActive : Color.noActive)
        )
        .clipShape(RoundedRectangle(cornerRadius: foregroundHeight < 30 ? 0 : 8, style: .continuous))
        .shadow(color: .shadow, radius: foregroundHeight < 30 ? 0 : 2)
        .transition(.blurReplace)
        .onTapGesture {
            viewModel.switchToSpace(space, needWindowFocus: true)
        }
        .animation(.smooth, value: isHovered)
        .onHover { value in
            isHovered = value
        }
    }
}

/// This view shows a window and its icon.
private struct WindowView: View {
    @EnvironmentObject var configProvider: ConfigProvider
    @EnvironmentObject var viewModel: SpacesViewModel

    var config: ConfigData { configProvider.config }
    var windowConfig: ConfigData { config["window"]?.dictionaryValue ?? [:] }
    var titleConfig: ConfigData {
        windowConfig["title"]?.dictionaryValue ?? [:]
    }

    var showTitle: Bool { windowConfig["show-title"]?.boolValue ?? true }
    var maxLength: Int { titleConfig["max-length"]?.intValue ?? 50 }
    var alwaysDisplayAppTitleFor: [String] { titleConfig["always-display-app-name-for"]?.arrayValue?.filter({ $0.stringValue != nil }).map { $0.stringValue! } ?? [] }

    let window: AnyWindow
    let space: AnySpace

    @State var isHovered = false

    var body: some View {
        let titleMaxLength = maxLength
        let size: CGFloat = 21
        let sameAppCount = space.windows.filter { $0.appName == window.appName }
            .count
        let title = sameAppCount > 1 && !alwaysDisplayAppTitleFor.contains { $0 == window.appName } ? window.title : (window.appName ?? "")
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

            if window.isFocused, !title.isEmpty, showTitle {
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
        .padding(.all, 2)
        .background(isHovered || (!showTitle && window.isFocused) ? .selected : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .animation(.smooth, value: isHovered)
        .frame(height: 30)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.switchToSpace(space)
            usleep(100_000)
            viewModel.switchToWindow(window)
        }
        .onHover { value in
            isHovered = value
        }
    }
}
