import SwiftUI

private struct ExpandedGroupedApp: Equatable {
    let spaceID: String
    let appName: String
}

struct SpacesWidget: View {
    @StateObject var viewModel = SpacesViewModel()
    @State private var expandedGroupedApp: ExpandedGroupedApp?

    @ObservedObject var configManager = ConfigManager.shared
    var foregroundHeight: CGFloat { configManager.config.experimental.foreground.resolveHeight() }

    var body: some View {
        HStack(spacing: foregroundHeight < 30 ? 0 : 8) {
            ForEach(viewModel.spaces) { space in
                SpaceView(
                    space: space,
                    expandedGroupedApp: $expandedGroupedApp
                )
            }
        }
        .experimentalConfiguration(horizontalPadding: 5, cornerRadius: 10)
        .animation(.smooth(duration: 0.3), value: viewModel.spaces)
        .foregroundStyle(Color.foreground)
        .environmentObject(viewModel)
        .zIndex(expandedGroupedApp == nil ? 0 : 1)
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
    @Binding var expandedGroupedApp: ExpandedGroupedApp?

    @State var isHovered = false

    var body: some View {
        cardView(expandedContentEnabled: false)
            .overlay(alignment: .leading) {
                if expandedAppName != nil {
                    cardView(
                        expandedContentEnabled: true,
                        forceOpaqueBackground: true
                    )
                }
            }
            .animation(.smooth(duration: 0.25), value: expandedAppName)
            .zIndex(expandedAppName == nil ? 0 : 1)
    }

    private var expandedAppName: String? {
        guard expandedGroupedApp?.spaceID == space.id else { return nil }
        return expandedGroupedApp?.appName
    }

    private var groupedWindowsByApp: [String: [AnyWindow]] {
        Dictionary(grouping: space.windows) { $0.appName ?? "" }
            .filter { appName, windows in
                !appName.isEmpty && windows.count > 2
            }
    }

    private var displayItems: [SpaceDisplayItem] {
        var items: [SpaceDisplayItem] = []
        var handledGroupedApps: Set<String> = []

        for window in space.windows {
            guard let appName = window.appName,
                let groupedWindows = groupedWindowsByApp[appName]
            else {
                items.append(.window(window))
                continue
            }

            guard handledGroupedApps.insert(appName).inserted else {
                continue
            }

            items.append(
                .group(
                    GroupedAppDisplay(
                        appName: appName,
                        windows: groupedWindows,
                        icon: window.appIcon
                    )
                )
            )
        }

        return items
    }

    private func toggleGroupedApp(_ appName: String) {
        if expandedAppName == appName {
            expandedGroupedApp = nil
        } else {
            expandedGroupedApp = ExpandedGroupedApp(
                spaceID: space.id,
                appName: appName
            )
        }
    }

    private func collapseExpandedGroup() {
        guard expandedAppName != nil else { return }
        expandedGroupedApp = nil
    }

    @ViewBuilder
    private func cardView(
        expandedContentEnabled: Bool,
        forceOpaqueBackground: Bool = false
    ) -> some View {
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
                ForEach(displayItems) { item in
                    switch item {
                    case .window(let window):
                        WindowView(
                            window: window,
                            space: space,
                            onSelect: {
                                collapseExpandedGroup()
                            }
                        )
                    case .group(let group):
                        GroupedWindowView(
                            group: group,
                            space: space,
                            isExpanded: expandedContentEnabled
                                && expandedAppName == group.appName,
                            preserveCollapsedWidth: !expandedContentEnabled,
                            onToggle: {
                                toggleGroupedApp(group.appName)
                            }
                        )
                    }
                }
            }
            Spacer().frame(width: 10)
        }
        .frame(height: 30)
        .background {
            backgroundSurface(
                isFocused: isFocused,
                forceOpaque: forceOpaqueBackground
            )
        }
        .onTapGesture {
            viewModel.switchToSpace(space, needWindowFocus: true)
        }
        .animation(.smooth, value: isHovered)
        .onHover { value in
            isHovered = value
        }
    }

    @ViewBuilder
    private func backgroundSurface(
        isFocused: Bool,
        forceOpaque: Bool
    ) -> some View {
        let cornerRadius: CGFloat = foregroundHeight < 30 ? 0 : 8
        let shadowRadius: CGFloat = foregroundHeight < 30 ? 0 : 2
        let tint: Color =
            if foregroundHeight < 30 {
                isFocused ? Color.noActive : Color.clear
            } else {
                isFocused ? Color.active : Color.noActive
            }

        if forceOpaque {
            MaskedGlassSurface(
                cornerRadius: cornerRadius,
                tint: tint,
                shadowRadius: shadowRadius,
                showStroke: foregroundHeight >= 30
            )
        } else {
            RoundedRectangle(
                cornerRadius: cornerRadius,
                style: .continuous
            )
            .fill(tint)
            .shadow(color: .shadow, radius: shadowRadius)
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
    var onSelect: (() -> Void)?

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
            onSelect?()
        }
        .onHover { value in
            isHovered = value
        }
    }
}

private enum SpaceDisplayItem: Identifiable {
    case window(AnyWindow)
    case group(GroupedAppDisplay)

    var id: String {
        switch self {
        case .window(let window):
            return "window-\(window.id)"
        case .group(let group):
            return "group-\(group.appName)"
        }
    }
}

private struct GroupedAppDisplay {
    let appName: String
    let windows: [AnyWindow]
    let icon: NSImage?

    var isFocused: Bool {
        windows.contains { $0.isFocused }
    }
}

private struct GroupedWindowView: View {
    let group: GroupedAppDisplay
    let space: AnySpace
    let isExpanded: Bool
    let preserveCollapsedWidth: Bool
    let onToggle: () -> Void

    private let collapsedWidth: CGFloat = 25

    @State private var isHovered = false

    var body: some View {
        Group {
            if preserveCollapsedWidth || !isExpanded {
                content
                    .frame(width: collapsedWidth, height: 30, alignment: .leading)
            } else {
                content
                    .frame(height: 30, alignment: .leading)
            }
        }
        .zIndex(isExpanded ? 1 : 0)
        .animation(.smooth(duration: 0.25), value: isExpanded)
    }

    @ViewBuilder
    private var content: some View {
        if isExpanded {
            HStack(spacing: 0) {
                headerView
                AccordionChildTrayView {
                    ForEach(group.windows) { window in
                        WindowView(
                            window: window,
                            space: space,
                            onSelect: {
                                onToggle()
                            }
                        )
                    }
                }
            }
            .padding(.leading, 4)
            .padding(.trailing, 6)
            .background(expandedSurface)
        } else {
            headerView
        }
    }

    private var headerView: some View {
        AccordionStackHeaderView(
            icon: group.icon,
            appName: group.appName,
            windowCount: group.windows.count,
            isFocused: group.isFocused,
            isExpanded: isExpanded,
            isHovered: isHovered
        )
        .frame(width: collapsedWidth, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
        .onHover { value in
            isHovered = value
        }
        .accessibilityLabel(
            Text(
                isExpanded
                    ? "\(group.appName) windows expanded"
                    : "\(group.appName) windows collapsed"
            )
        )
    }

    private var expandedSurface: some View {
        MaskedGlassSurface(
            cornerRadius: 12,
            tint: group.isFocused ? Color.active : Color.noActive,
            shadowRadius: 0,
            showStroke: true
        )
    }
}

private struct AccordionStackHeaderView: View {
    let icon: NSImage?
    let appName: String
    let windowCount: Int
    let isFocused: Bool
    let isExpanded: Bool
    let isHovered: Bool

    var body: some View {
        let cardOffsets: [CGFloat] = [-4, -2, 0]

        ZStack(alignment: .trailing) {
            ForEach(Array(cardOffsets.enumerated()), id: \.offset) {
                _, xOffset in
                stackChip
                    .offset(x: xOffset, y: 0)
            }
        }
        .frame(width: 25, alignment: .trailing)
        .animation(.smooth, value: isHovered)
        .frame(height: 30)
        .contentShape(Rectangle())
        .accessibilityLabel(Text("\(appName), \(windowCount) windows"))
    }

    private var headerIcon: some View {
        ZStack {
            if let icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 21, height: 21)
                    .shadow(color: .iconShadow, radius: 2)
            } else {
                Image(systemName: "questionmark.circle")
                    .resizable()
                    .frame(width: 21, height: 21)
            }
        }
    }

    private var stackChip: some View {
        headerIcon
            .padding(.all, 2)
            .background(headerBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(headerBorder, lineWidth: 1)
            )
            .frame(width: 25, height: 30)
    }

    private var headerBackground: Color {
        if isExpanded {
            return .selected
        }
        if isHovered || isFocused {
            return .selected.opacity(0.8)
        }
        return .clear
    }

    private var headerBorder: Color {
        if isExpanded || isFocused {
            return Color.active.opacity(0.7)
        }
        if isHovered {
            return Color.foreground.opacity(0.3)
        }
        return .clear
    }
}

private struct AccordionChildTrayView<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color.active.opacity(0.45))
                .frame(width: 3, height: 20)

            HStack(spacing: 2) {
                content
            }
        }
        .padding(.leading, 8)
        .padding(.trailing, 2)
        .frame(height: 30)
    }
}

private struct MaskedGlassSurface: View {
    @ObservedObject private var configManager = ConfigManager.shared

    let cornerRadius: CGFloat
    let tint: Color
    let shadowRadius: CGFloat
    let showStroke: Bool

    var body: some View {
        let shape = RoundedRectangle(
            cornerRadius: cornerRadius,
            style: .continuous
        )

        shape
            .fill(Color(nsColor: .controlBackgroundColor))
            .overlay {
                shape.fill(tint)
            }
            .overlay {
                if configManager.config.experimental.foreground.widgetsBackground.displayed {
                    shape.fill(
                        configManager.config.experimental.foreground.widgetsBackground.blur
                    )
                }
            }
            .overlay {
                if showStroke {
                    shape.strokeBorder(Color.noActive, lineWidth: 1)
                }
            }
            .shadow(color: .shadow, radius: shadowRadius)
    }
}
