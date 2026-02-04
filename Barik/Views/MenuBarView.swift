import SwiftUI
import UniformTypeIdentifiers

struct MenuBarView: View {
    @ObservedObject var configManager = ConfigManager.shared
    @State private var widgetItems: [TomlWidgetItem] = []
    @State private var draggingItem: TomlWidgetItem?

    private var displayedFingerprint: String {
        configManager.config.rootToml.widgets.displayed
            .map { $0.id }
            .joined(separator: "|")
    }

    var body: some View {
        let theme: ColorScheme? =
            switch configManager.config.rootToml.theme {
            case "dark":
                .dark
            case "light":
                .light
            default:
                .none
            }

        HStack(spacing: 0) {
            HStack(spacing: configManager.config.experimental.foreground.spacing) {
                Color.clear
                    .frame(width: 1)
                    .onDrop(
                        of: [UTType.text],
                        delegate: EdgeDropDelegate(
                            targetIndex: 0,
                            items: $widgetItems,
                            draggingItem: $draggingItem,
                            onReorderComplete: persistWidgetOrder
                        )
                    )

                ForEach(widgetItems, id: \.instanceID) { item in
                    buildView(for: item)
                        .opacity(draggingItem?.instanceID == item.instanceID ? 0.5 : 1.0)
                        .onDrag {
                            draggingItem = item
                            return NSItemProvider(object: item.instanceID.uuidString as NSString)
                        }
                        .onDrop(
                            of: [UTType.text],
                            delegate: WidgetDropDelegate(
                                item: item,
                                items: $widgetItems,
                                draggingItem: $draggingItem,
                                onReorderComplete: persistWidgetOrder
                            )
                        )
                }
            }

            if !widgetItems.contains(where: { $0.id == "system-banner" }) {
                SystemBannerWidget(withLeftPadding: true)
            }
        }
        .foregroundStyle(Color.foregroundOutside)
        .frame(height: max(configManager.config.experimental.foreground.resolveHeight(), 1.0))
        .frame(maxWidth: .infinity)
        .padding(.horizontal, configManager.config.experimental.foreground.horizontalPadding)
        .background(.black.opacity(0.001))
        .preferredColorScheme(theme)
        .onAppear {
            widgetItems = configManager.config.rootToml.widgets.displayed
        }
        .onChange(of: displayedFingerprint) {
            if draggingItem == nil {
                widgetItems = configManager.config.rootToml.widgets.displayed
            }
        }
    }

    private func persistWidgetOrder() {
        configManager.updateDisplayedWidgets(widgetItems)
    }

    @ViewBuilder
    private func buildView(for item: TomlWidgetItem) -> some View {
        let config = ConfigProvider(
            config: configManager.resolvedWidgetConfig(for: item))

        switch item.id {
        case "default.spaces":
            SpacesWidget().environmentObject(config)

        case "default.network":
            NetworkWidget().environmentObject(config)

        case "default.battery":
            BatteryWidget().environmentObject(config)

        case "default.time":
            TimeWidget(configProvider: config)
                .environmentObject(config)

        case "default.nowplaying", "default.spotify":
            NowPlayingWidget()
                .environmentObject(config)

        case "default.weather":
            WeatherWidget()
                .environmentObject(config)

        case "default.claude-usage":
            ClaudeUsageWidget()
                .environmentObject(config)

        case "default.pomodoro":
            PomodoroWidget()
                .environmentObject(config)

        case "spacer":
            Spacer().frame(minWidth: 50, maxWidth: .infinity)

        case "divider":
            Rectangle()
                .fill(Color.active)
                .frame(width: 2, height: 15)
                .clipShape(Capsule())

        case "system-banner":
            SystemBannerWidget()

        default:
            Text("?\(item.id)?").foregroundColor(.red)
        }
    }
}

struct EdgeDropDelegate: DropDelegate {
    let targetIndex: Int
    @Binding var items: [TomlWidgetItem]
    @Binding var draggingItem: TomlWidgetItem?
    let onReorderComplete: () -> Void

    func performDrop(info: DropInfo) -> Bool {
        draggingItem = nil
        onReorderComplete()
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let dragging = draggingItem,
              let fromIndex = items.firstIndex(where: { $0.instanceID == dragging.instanceID }),
              fromIndex != targetIndex
        else { return }

        withAnimation(.smooth(duration: 0.2)) {
            items.move(
                fromOffsets: IndexSet(integer: fromIndex),
                toOffset: targetIndex
            )
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func validateDrop(info: DropInfo) -> Bool {
        draggingItem != nil
    }
}

struct WidgetDropDelegate: DropDelegate {
    let item: TomlWidgetItem
    @Binding var items: [TomlWidgetItem]
    @Binding var draggingItem: TomlWidgetItem?
    let onReorderComplete: () -> Void

    func performDrop(info: DropInfo) -> Bool {
        draggingItem = nil
        onReorderComplete()
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let dragging = draggingItem,
              dragging.instanceID != item.instanceID,
              let fromIndex = items.firstIndex(where: { $0.instanceID == dragging.instanceID }),
              let toIndex = items.firstIndex(where: { $0.instanceID == item.instanceID })
        else { return }

        withAnimation(.smooth(duration: 0.2)) {
            items.move(
                fromOffsets: IndexSet(integer: fromIndex),
                toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
            )
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func validateDrop(info: DropInfo) -> Bool {
        draggingItem != nil
    }
}
