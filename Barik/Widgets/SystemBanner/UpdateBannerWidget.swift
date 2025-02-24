import SwiftUI

struct UpdateBannerWidget: View {
    @ObservedObject private var configManager = ConfigManager.shared
    @StateObject private var updater = AppUpdater()
    @State private var isUpdating = false

    var body: some View {
        if updater.updateAvailable {
            Button(action: handleUpdate) {
                Text(isUpdating ? "Updating" : "Update")
                    .fontWeight(.semibold)
            }
            .buttonStyle(BannerButtonStyle(color: .blue))
            .disabled(isUpdating)
            .opacity(isUpdating ? 0.5 : 1)
            .animation(.easeInOut, value: isUpdating)
        }
    }

    /// Downloads and installs the update, then terminates the application.
    private func handleUpdate() {
        isUpdating = true
        updater.downloadAndInstall(latest: updater.latestVersion ?? "") {
            DispatchQueue.main.async {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

struct UpdateBannerWidget_Previews: PreviewProvider {
    static var previews: some View {
        UpdateBannerWidget()
            .frame(width: 200, height: 100)
            .background(Color.black)
    }
}
