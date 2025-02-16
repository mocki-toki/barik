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
                .preferredColorScheme(theme)
    }
}
