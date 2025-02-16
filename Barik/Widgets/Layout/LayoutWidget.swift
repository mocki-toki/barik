import SwiftUI

struct LayoutWidget: View {
    @StateObject private var layoutManager = LayoutManager()
    @State private var isHovered: Bool = false

    let iconSize: CGFloat = 15
    let compactWidth: CGFloat = 30

    var body: some View {
        content
            .onHover { hovering in
                withAnimation {
                    isHovered = hovering
                }
            }
    }

    @ViewBuilder
    
    private var content: some View {
        HStack(spacing: 6) {
            Image(systemName: iconName(for: layoutManager.layout))
                .resizable()
                .frame(width: iconSize, height: iconSize)
                .shadow(color: .iconShadow, radius: 2)
            if isHovered {
                Text(layoutManager.layout.capitalized)
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)   
        .frame(height: 30)
        .background(Color.active)
        .background(.ultraThinMaterial)
        .preferredColorScheme(.dark)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: .shadow, radius: 2)
        .transition(.opacity)
    }

    private func iconName(for layout: String) -> String {
        switch layout.lowercased() {
        case "bsp":
            return "square.split.2x2"
        case "stack":
            return "rectangle.stack"
        case "float":
            return "rectangle.on.rectangle"
        default:
            return "questionmark.circle"
        }
    }
}

struct LayoutWidget_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LayoutWidget()
        }.frame(width: 200, height: 100)
            .background(.yellow)
            .environmentObject(ConfigProvider(config: [:]))
    }
}
