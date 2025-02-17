import SwiftUI

struct MenuBarView: View {
    @ObservedObject var configManager = ConfigManager.shared

    private func dockHeight(for screen: NSScreen) -> CGFloat {
        // When the dock is at the bottom, the y-origin of the visibleFrame is equal to the dock height.
        return screen.visibleFrame.origin.y
    }
    
    var body: some View {
        let theme: ColorScheme? = {
            switch configManager.config.rootToml.theme {
            case "dark":
                return .dark
            case "light":
                return .light
            default:
                return nil
            }
        }()
        
        let items = configManager.config.rootToml.widgets.displayed
        // Compute the dock height using NSScreen.main, fallback to 70 if unavailable.
        let menuBarHeight: CGFloat = {
            if let screen = NSScreen.main {
                return dockHeight(for: screen)
            } else {
                return 70
            }
        }()

        HStack(spacing: 0) {
            HStack(spacing: 15) {
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
        .frame(height: menuBarHeight)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 15)
        .preferredColorScheme(theme)
    }
    
    @ViewBuilder
    private func buildView(for item: TomlWidgetItem) -> some View {
        let config = ConfigProvider(config: configManager.resolvedWidgetConfig(for: item))
        
        switch item.id {
        case "default.spaces":
            SpacesWidget().environmentObject(config)
        case "default.network":
            SpotifyView()
            Rectangle()
                .fill(Color.active)
                .frame(width: 2, height: 15)
                .clipShape(Capsule())
            NetworkWidget().environmentObject(config)
        case "default.battery":
            BatteryWidget().environmentObject(config)
        case "default.time":
            TimeWidget(calendarManager: CalendarManager(configProvider: config))
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


struct MenuBarView_Previews: PreviewProvider {
    static var previews: some View {
        MenuBarView()
            .frame(width: 1000, height: 100)
            .background(.black)
            .environmentObject(ConfigProvider(config: [:]))
    }
}
