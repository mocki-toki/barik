import Foundation

class AppUpdater: ObservableObject {
    @Published var latestVersion: String? = nil
    @Published var updateAvailable = false

    init() {
        checkForUpdate()
        Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { _ in
            self.checkForUpdate()
        }
    }

    func checkForUpdate() {
        guard
            let url = URL(
                string:
                    "https://api.github.com/repos/mocki-toki/barik/releases/latest"
            )
        else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                let json = try? JSONSerialization.jsonObject(with: data)
                    as? [String: Any],
                let tag = json["tag_name"] as? String
            else { return }
            let currentVersion =
                Bundle.main.infoDictionary?["CFBundleShortVersionString"]
                as? String ?? "0.0.0"
            if self.compareVersion(tag, currentVersion) > 0 {
                DispatchQueue.main.async {
                    self.latestVersion = tag
                    self.updateAvailable = true
                }
            } else {
                DispatchQueue.main.async {
                    self.latestVersion = tag
                    self.updateAvailable = false
                }
            }
        }.resume()
    }

    func compareVersion(_ v1: String, _ v2: String) -> Int {
        let version1 = v1.replacingOccurrences(of: "v", with: "")
        let version2 = v2.replacingOccurrences(of: "v", with: "")
        let parts1 = version1.split(separator: ".").compactMap { Int($0) }
        let parts2 = version2.split(separator: ".").compactMap { Int($0) }
        let maxCount = max(parts1.count, parts2.count)
        for i in 0..<maxCount {
            let num1 = i < parts1.count ? parts1[i] : 0
            let num2 = i < parts2.count ? parts2[i] : 0
            if num1 > num2 { return 1 }
            if num1 < num2 { return -1 }
        }
        return 0
    }
}
