import Foundation

final class AppUpdater: ObservableObject {
    // Published properties to notify the UI
    @Published var latestVersion: String?
    @Published var updateAvailable = false

    // Local path for the downloaded update directory
    private(set) var downloadedUpdatePath: String?
    // URL for the update asset obtained from GitHub release JSON
    private var updateAssetURL: URL?

    // Timer to schedule periodic update checks
    private var updateTimer: Timer?

    init() {
        fetchLatestRelease()
        // Check for updates every 30 minutes
        updateTimer = Timer.scheduledTimer(
            withTimeInterval: 1800, repeats: true
        ) { [weak self] _ in
            self?.fetchLatestRelease()
        }
    }

    deinit {
        updateTimer?.invalidate()
    }

    /// Returns a fallback download URL based on the version string.
    private func fallbackDownloadURL(for version: String) -> URL? {
        let versionWithoutPrefix =
            version.hasPrefix("v") ? String(version.dropFirst()) : version
        let urlString =
            "https://github.com/mocki-toki/barik/releases/download/\(version)/barik-v\(versionWithoutPrefix).zip"
        return URL(string: urlString)
    }

    /// Fetches the latest release information from GitHub and updates the state.
    func fetchLatestRelease() {
        guard
            let url = URL(
                string:
                    "https://api.github.com/repos/mocki-toki/barik/releases/latest"
            )
        else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            if let error = error {
                print("Error fetching release info: \(error)")
                return
            }
            guard let data = data,
                let json = try? JSONSerialization.jsonObject(with: data)
                    as? [String: Any],
                let tag = json["tag_name"] as? String
            else {
                return
            }

            // Attempt to extract the asset download URL if available
            if let assets = json["assets"] as? [[String: Any]] {
                for asset in assets {
                    if let name = asset["name"] as? String,
                        name.hasSuffix(".zip"),
                        let downloadURLString = asset["browser_download_url"]
                            as? String,
                        let assetURL = URL(string: downloadURLString)
                    {
                        self?.updateAssetURL = assetURL
                        break
                    }
                }
            }

            let currentVersion = VersionChecker.currentVersion ?? "0.0.0"
            let comparisonResult =
                self?.compareVersion(tag, currentVersion) ?? 0
            DispatchQueue.main.async {
                self?.latestVersion = tag
                self?.updateAvailable = comparisonResult > 0
            }
        }.resume()
    }

    /// Compares two version strings.
    /// - Returns: 1 if v1 > v2, -1 if v1 < v2, and 0 if equal.
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

    /// Downloads and unzips the update archive.
    /// - Parameters:
    ///   - version: The latest version string.
    ///   - completion: Returns the temporary directory URL containing the unzipped app.
    private func downloadAndUnzip(
        latest version: String, completion: @escaping (URL?) -> Void
    ) {
        let assetURL: URL
        if let url = updateAssetURL {
            assetURL = url
        } else if let fallbackURL = fallbackDownloadURL(for: version) {
            assetURL = fallbackURL
        } else {
            print("Invalid update URL")
            completion(nil)
            return
        }

        print("Downloading update from: \(assetURL.absoluteString)")
        let downloadTask = URLSession.shared.downloadTask(with: assetURL) {
            localURL, response, error in
            if let error = error {
                print("Update download error: \(error)")
                completion(nil)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200
            else {
                print("Download failed with HTTP error")
                completion(nil)
                return
            }
            guard let localURL = localURL else {
                print("No update file found")
                completion(nil)
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
                unzipProcess.executableURL = URL(
                    fileURLWithPath: "/usr/bin/unzip")
                unzipProcess.arguments = [
                    "-o", localURL.path, "-d", tempDir.path,
                ]
                try unzipProcess.run()
                unzipProcess.waitUntilExit()

                let newAppURL = tempDir.appendingPathComponent("Barik.app")
                if fileManager.fileExists(atPath: newAppURL.path) {
                    DispatchQueue.main.async {
                        completion(tempDir)
                    }
                } else {
                    print("Unzipping failed: Barik.app not found in archive")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            } catch {
                print("Error unzipping update: \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
        downloadTask.resume()
    }

    /// Downloads and installs the update immediately.
    /// - Parameters:
    ///   - version: The latest version string.
    ///   - completion: Called when the installation process has been triggered.
    func downloadAndInstall(
        latest version: String, completion: @escaping () -> Void
    ) {
        downloadAndUnzip(latest: version) { [weak self] tempDir in
            guard let tempDir = tempDir else {
                completion()
                return
            }
            self?.downloadedUpdatePath = tempDir.path
            self?.installUpdate(latest: version)
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    /// Installs the update by replacing the current application.
    /// - Parameter version: The latest version string.
    func installUpdate(latest version: String) {
        guard let downloadedPath = downloadedUpdatePath else {
            print("No downloaded update to install")
            return
        }
        let newAppURL = URL(fileURLWithPath: downloadedPath)
            .appendingPathComponent("Barik.app")
        let destinationURL = URL(fileURLWithPath: "/Applications/Barik.app")
        let script = """
            #!/bin/bash
            sleep 2
            rm -rf "\(destinationURL.path)"
            mv "\(newAppURL.path)" "\(destinationURL.path)"
            open "\(destinationURL.path)"
            rm -- "$0"
            """

        let fileManager = FileManager.default
        let updateTempDir = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        do {
            try fileManager.createDirectory(
                at: updateTempDir, withIntermediateDirectories: true,
                attributes: nil)
            let scriptURL = updateTempDir.appendingPathComponent("update.sh")
            try script.write(to: scriptURL, atomically: true, encoding: .utf8)
            try fileManager.setAttributes(
                [.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

            let process = Process()
            process.executableURL = scriptURL
            try process.run()
        } catch {
            print("Error installing update: \(error)")
        }
    }
}
