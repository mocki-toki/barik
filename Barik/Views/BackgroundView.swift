import SwiftUI

struct BackgroundView: View {
    @ObservedObject var configManager = ConfigManager.shared

    private func spacer(_ geometry: GeometryProxy) -> some View {
        let theme: ColorScheme? = {
            switch configManager.config.rootToml.theme {
            case "dark": return .dark
            case "light": return .light
            default: return nil
            }
        }()

        let height = configManager.config.experimental.background.resolveHeight()

        return Color.clear
            .frame(height: height ?? geometry.size.height)
            .frame(maxWidth: .infinity)
            .preferredColorScheme(theme)
    }

    var body: some View {
        let position = configManager.config.experimental.foreground.position
        let alignment: Alignment = switch position {
        case .top: .top
        case .bottom: .bottom
        }

        if configManager.config.experimental.background.displayed {
            GeometryReader { geometry in
                if configManager.config.experimental.background.black {
                    spacer(geometry)
                        .background(.black)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
                        .id("black")
                } else {
                    spacer(geometry)
                        .background(configManager.config.experimental.background.blur)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
                        .id("blur")
                }
            }
        }
    }
}
