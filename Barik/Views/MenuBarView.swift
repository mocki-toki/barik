import SwiftUI

struct MenuBarView: View {
    @ObservedObject var configManager = ConfigManager.shared

    private struct SectionChunk {
        let items: [TomlWidgetItem]
        let separatorID: String?
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

        let items = configManager.config.rootToml.widgets.displayed

        VStack(spacing: 0) {
            HStack(spacing: 0) {
                HStack(spacing: 0) {
                    renderItems(items)
                }

                if !items.contains(where: { $0.id == "system-banner" }) {
                    SystemBannerWidget(withLeftPadding: true)
                }
            }
            .foregroundStyle(Color.foregroundOutside)
            .frame(height: max(configManager.config.experimental.foreground.resolveHeight(), 1.0))
            .frame(maxWidth: .infinity)
            .padding(.horizontal, configManager.config.experimental.foreground.horizontalPadding)
        }
        .preferredColorScheme(theme)
    }

    @ViewBuilder
    private func renderItems(_ items: [TomlWidgetItem]) -> some View {
        let chunks = sectionChunks(from: items)
        ForEach(0..<chunks.count, id: \.self) { index in
            let chunk = chunks[index]
            renderSection(chunk.items)

            switch chunk.separatorID {
            case "divider":
                Rectangle()
                    .fill(Color.active)
                    .frame(width: 2, height: 15)
                    .clipShape(Capsule())
                    .padding(.horizontal, configManager.config.experimental.foreground.spacing)

            case "invisible-divider", "zero-width-spacer":
                Color.clear
                    .frame(width: configManager.config.experimental.foreground.spacing)

            default:
                EmptyView()
            }
        }
    }

    private func sectionChunks(from items: [TomlWidgetItem]) -> [SectionChunk] {
        var chunks: [SectionChunk] = []
        var currentItems: [TomlWidgetItem] = []

        for item in items {
            if isSectionSeparator(item.id) {
                if !currentItems.isEmpty {
                    chunks.append(SectionChunk(items: currentItems, separatorID: item.id))
                    currentItems = []
                }
            } else {
                currentItems.append(item)
            }
        }

        if !currentItems.isEmpty {
            chunks.append(SectionChunk(items: currentItems, separatorID: nil))
        }

        return chunks
    }

    private func isSectionSeparator(_ id: String) -> Bool {
        id == "divider" || id == "invisible-divider" || id == "zero-width-spacer"
    }

    @ViewBuilder
    private func renderSection(_ items: [TomlWidgetItem]) -> some View {
        let subGroups = items.split(whereSeparator: { $0.id == "spacer" })
        ForEach(0..<subGroups.count, id: \.self) { subIndex in
            let subGroup = Array(subGroups[subIndex])
            if subIndex > 0 {
                Spacer().frame(minWidth: 50, maxWidth: .infinity)
            }
            renderWidgetGroup(subGroup)
        }
    }

    @ViewBuilder
    private func renderWidgetGroup(_ items: [TomlWidgetItem]) -> some View {
        if items.isEmpty {
            EmptyView()
        } else if items.count == 1 && items[0].id == "default.spaces" {
            buildView(for: items[0])
        } else if items.count == 1 {
            buildView(for: items[0])
                .padding(.horizontal, 10)
                .frame(height: 30)
                .background(Color.noActive)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            HStack(spacing: configManager.config.experimental.foreground.spacing) {
                ForEach(0..<items.count, id: \.self) { i in
                    buildView(for: items[i])
                }
            }
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background(Color.noActive)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
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
            TimeWidget(calendarManager: CalendarManager(configProvider: config))
                .environmentObject(config)

        case "default.nowplaying":
            NowPlayingWidget()
                .environmentObject(config)

        case "spacer":
            Spacer().frame(minWidth: 50, maxWidth: .infinity)

        case "divider":
            Rectangle()
                .fill(Color.active)
                .frame(width: 2, height: 15)
                .clipShape(Capsule())

        case "invisible-divider", "zero-width-spacer":
            EmptyView()

        case "system-banner":
            SystemBannerWidget()

        default:
            Text("?\(item.id)?").foregroundColor(.red)
        }
    }
}
