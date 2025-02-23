import AppKit
import SwiftUI

struct BlueButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(
                configuration.isPressed ? Color.blue.opacity(0.7) : Color.blue
            )
            .clipShape(.capsule)
    }
}

struct SystemBannerWidget: View {
    let withLeftPadding: Bool

    init(withLeftPadding: Bool = false) {
        self.withLeftPadding = withLeftPadding
    }

    var body: some View {
        HStack(spacing: 15) {
            if withLeftPadding {
                Color.clear.frame(width: 0)
            }
            UpdateBannerWidget()
        }
    }
}

struct SystemBannerWidget_Previews: PreviewProvider {
    static var previews: some View {
        SystemBannerWidget()
            .frame(width: 200, height: 100)
            .background(Color.black)
    }
}
