import SwiftUI

struct MenuBarView: View {
    let monitorName: String?
    @ObservedObject var configManager = ConfigManager.shared

    init(monitorName: String? = nil) {
        self.monitorName = monitorName
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

        let position = configManager.config.experimental.foreground.position
        let padding = configManager.config.experimental.foreground.horizontalPadding

        // Hide system widgets when bar is at bottom (already in macOS top menu bar)
        let systemWidgetsToHide: Set<String> = position == .bottom
            ? ["default.network", "default.battery", "default.time"]
            : []
        let items = configManager.config.rootToml.widgets.displayed.filter {
            !systemWidgetsToHide.contains($0.id)
        }

        let alignment: Alignment = switch position {
        case .top: .top
        case .bottom: .bottom
        }

        HStack(spacing: 0) {
            HStack(spacing: configManager.config.experimental.foreground.spacing) {
                ForEach(0..<items.count, id: \.self) { index in
                    let item = items[index]
                    buildView(for: item)
                }
            }

            if !items.contains(where: { $0.id == "system-banner" }) {
                SystemBannerWidget(withLeftPadding: true)
            }
        }
        .foregroundStyle(Color.foregroundOutside)
        .frame(height: max(configManager.config.experimental.foreground.resolveHeight(), 1.0))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
        .padding(.horizontal, padding)
        .background(.black.opacity(0.001))
        .preferredColorScheme(theme)
    }

    @ViewBuilder
    private func buildView(for item: TomlWidgetItem) -> some View {
        let config = ConfigProvider(
            config: configManager.resolvedWidgetConfig(for: item))

        switch item.id {
        case "default.spaces":
            SpacesWidget(monitorName: monitorName).environmentObject(config)

        case "default.network":
            NetworkWidget().environmentObject(config)

        case "default.battery":
            BatteryWidget().environmentObject(config)

        case "default.time":
            TimeWidget(calendarManager: CalendarManager.shared)
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

        case "system-banner":
            SystemBannerWidget()

        case "default.settings":
            SettingsWidget()

        default:
            Text("?\(item.id)?").foregroundColor(.red)
        }
    }
}
