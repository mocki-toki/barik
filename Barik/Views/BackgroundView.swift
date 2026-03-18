import SwiftUI

struct BackgroundView: View {
    @ObservedObject var configManager = ConfigManager.shared

    private func menuBarBlurView(_ geometry: GeometryProxy) -> some View {
        let theme: ColorScheme? = {
            switch configManager.config.rootToml.theme {
            case "dark": return .dark
            case "light": return .light
            default: return nil
            }
        }()
        
        // menu bar height // change the last number to change the height of the menu bar
        let menuBarHeight = (configManager.config.experimental.foreground.resolveHeight() ?? 32) - 6
        
        let isBottom = configManager.config.experimental.position == .bottom
        
        return VStack(spacing: 0) {
            if !isBottom {
                // Top positioning (original)
                // Smooth menu bar blur with rounded edges
                if configManager.config.experimental.background.black {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.6))
                        .frame(height: menuBarHeight)
                        .padding(.horizontal, 6)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 1)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.clear)
                        .background(
                            configManager.config.experimental.background.blur,
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .frame(height: menuBarHeight)
                        .padding(.horizontal, 6)
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                .padding(.horizontal, 6)
                        )
                }
                Spacer()
            } else {
                // Bottom positioning
                Spacer()
                if configManager.config.experimental.background.black {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.6))
                        .frame(height: menuBarHeight)
                        .padding(.horizontal, 6)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: -1)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.clear)
                        .background(
                            configManager.config.experimental.background.blur,
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .frame(height: menuBarHeight)
                        .padding(.horizontal, 6)
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: -2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                .padding(.horizontal, 6)
                        )
                }
            }
        }
        .preferredColorScheme(theme)
        .animation(.easeInOut(duration: 0.3), value: configManager.config.experimental.background.black)
    }
    
    var body: some View {
        if configManager.config.experimental.background.displayed {
            GeometryReader { geometry in
                menuBarBlurView(geometry)
                    .id("refined-blur")
            }
        }
    }
}
