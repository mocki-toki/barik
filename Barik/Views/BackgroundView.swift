import SwiftUI

struct BackgroundView: View {
    @ObservedObject var configManager = ConfigManager.shared

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
        
        Spacer()
            .background(.regularMaterial)
            .preferredColorScheme(theme)
            .opacity(configManager.config.rootToml.background.enabled ? 1 : 0)
            .frame(height: configManager.config.rootToml.background.resolveHeight())
    }
}
