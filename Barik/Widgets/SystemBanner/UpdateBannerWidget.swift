import SwiftUI

struct UpdateBannerWidget: View {
    @StateObject var updater = AppUpdater()
    @State private var isUpdating = false

    var body: some View {
        if updater.updateAvailable, let latest = updater.latestVersion {
            Button(action: {
                isUpdating = true
                performUpdate(latest: latest)
            }) {
                Text(isUpdating ? "Updating" : "Update")
                    .fontWeight(.semibold)
            }
            .buttonStyle(BlueButtonStyle())
            .disabled(isUpdating)
            .opacity(isUpdating ? 0.5 : 1)
            .transition(.blurReplace)
            .animation(.smooth, value: updater.updateAvailable)
            .animation(.smooth, value: isUpdating)
        }
    }

    func performUpdate(latest: String) {
        guard
            let downloadURL = URL(
                string:
                    "https://github.com/mocki-toki/barik/releases/download/\(latest)/barik-v\(latest).zip"
            )
        else {
            DispatchQueue.main.async {
                isUpdating = false
            }
            return
        }
        let task = URLSession.shared.downloadTask(with: downloadURL) {
            localURL, _, error in
            if error != nil {
                DispatchQueue.main.async {
                    isUpdating = false
                }
                return
            }
            guard let localURL = localURL else {
                DispatchQueue.main.async {
                    isUpdating = false
                }
                return
            }
            let fileManager = FileManager.default
            let tempDir = fileManager.temporaryDirectory.appendingPathComponent(
                UUID().uuidString)
            do {
                try fileManager.createDirectory(
                    at: tempDir, withIntermediateDirectories: true,
                    attributes: nil)
                let unzipProcess = Process()
                unzipProcess.launchPath = "/usr/bin/unzip"
                unzipProcess.arguments = [
                    "-o", localURL.path, "-d", tempDir.path,
                ]
                unzipProcess.launch()
                unzipProcess.waitUntilExit()
                let newAppURL = tempDir.appendingPathComponent("Barik.app")
                let destinationURL = URL(
                    fileURLWithPath: "/Applications/Barik.app")
                let script = """
                    #!/bin/bash
                    sleep 2
                    rm -rf "\(destinationURL.path)"
                    mv "\(newAppURL.path)" "\(destinationURL.path)"
                    open "\(destinationURL.path)"
                    rm -- "$0"
                    """
                let scriptURL = tempDir.appendingPathComponent("update.sh")
                try script.write(
                    to: scriptURL, atomically: true, encoding: .utf8)
                try fileManager.setAttributes(
                    [.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)
                let process = Process()
                process.launchPath = scriptURL.path
                process.launch()
                DispatchQueue.main.async {
                    NSApplication.shared.terminate(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    isUpdating = false
                }
            }
        }
        task.resume()
    }
}


struct UpdateBannerWidget_Previews: PreviewProvider {
    static var previews: some View {
        UpdateBannerWidget()
            .frame(width: 200, height: 100)
            .background(Color.black)
    }
}
