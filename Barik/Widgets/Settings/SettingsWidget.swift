import SwiftUI

struct SettingsWidget: View {
    var body: some View {
        Image(systemName: "gearshape.fill")
            .font(.system(size: 14))
            .foregroundStyle(Color.icon)
            .frame(maxHeight: .infinity)
            .background(.black.opacity(0.001))
            .onTapGesture {
                SettingsWindowController.shared.showSettings()
            }
    }
}
