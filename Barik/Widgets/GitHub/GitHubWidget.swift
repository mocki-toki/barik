import Foundation
import SwiftUI

struct GitHubRepository: Decodable {
    let fullName: String
    let htmlUrl: String?

    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case htmlUrl = "html_url"
    }
}

struct GitHubSubject: Decodable {
    let title: String
    let type: String
    let url: String?
    let latestCommentUrl: String?

    enum CodingKeys: String, CodingKey {
        case title, type, url
        case latestCommentUrl = "latest_comment_url"
    }
}

struct GitHubNotification: Decodable, Identifiable {
    let id: String
    let unread: Bool
    let subject: GitHubSubject
    let repository: GitHubRepository

    enum CodingKeys: String, CodingKey {
        case id, unread, subject, repository
    }

    var webUrl: URL? {
        if let apiUrl = subject.url ?? subject.latestCommentUrl,
            let resolved = Self.resolveWebUrl(from: apiUrl, type: subject.type)
        {
            return resolved
        }
        if let repoUrl = repository.htmlUrl {
            return URL(string: repoUrl)
        }
        return URL(string: "https://github.com/notifications")
    }

    private static func resolveWebUrl(from apiUrl: String, type: String) -> URL? {
        if !apiUrl.hasPrefix("https://api.github.com/repos/") {
            return URL(string: apiUrl)
        }

        var web = apiUrl.replacingOccurrences(
            of: "https://api.github.com/repos/",
            with: "https://github.com/"
        )

        if type == "PullRequest" {
            web = web.replacingOccurrences(of: "/pulls/", with: "/pull/")
        } else if type == "Commit" {
            web = web.replacingOccurrences(of: "/commits/", with: "/commit/")
        }

        return URL(string: web)
    }
}

final class GitHubNotificationsViewModel: ObservableObject {
    @Published var notifications: [GitHubNotification] = []
    @Published var isAvailable: Bool = true
    @Published var errorMessage: String?

    private var timer: Timer?
    private let ghPath: String?

    init() {
        ghPath = ExecutableLocator.resolve(
            "gh",
            preferred: [
                "/opt/homebrew/bin/gh",
                "/usr/local/bin/gh",
                "/usr/bin/gh",
            ]
        )
    }

    func start(updateInterval: TimeInterval) {
        let interval = max(updateInterval, 1)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) {
            [weak self] _ in
            self?.refresh()
        }
        refresh()
    }

    deinit {
        timer?.invalidate()
    }

    private func refresh() {
        guard let path = ghPath else {
            isAvailable = false
            errorMessage = "gh not found"
            notifications = []
            return
        }

        DispatchQueue.global(qos: .utility).async {
            let result = CommandRunner.run(
                executable: path,
                arguments: ["api", "/notifications"]
            )

            guard let result = result, result.exitCode == 0 else {
                DispatchQueue.main.async {
                    self.isAvailable = true
                    self.errorMessage = "gh api failed"
                    self.notifications = []
                }
                return
            }

            guard let data = result.output.data(using: .utf8) else {
                DispatchQueue.main.async {
                    self.isAvailable = true
                    self.errorMessage = "bad gh output"
                    self.notifications = []
                }
                return
            }

            do {
                let decoded = try JSONDecoder().decode(
                    [GitHubNotification].self,
                    from: data
                )
                DispatchQueue.main.async {
                    self.isAvailable = true
                    self.errorMessage = nil
                    self.notifications = decoded
                }
            } catch {
                DispatchQueue.main.async {
                    self.isAvailable = true
                    self.errorMessage = "decode failed"
                    self.notifications = []
                }
            }
        }
    }
}

struct GitHubWidget: View {
    @EnvironmentObject var configProvider: ConfigProvider
    var config: ConfigData { configProvider.config }

    @StateObject private var viewModel = GitHubNotificationsViewModel()
    @State private var rect: CGRect = .zero

    private var updateFrequency: TimeInterval {
        config["update_freq"]?.doubleValue
            ?? config["update-freq"]?.doubleValue
            ?? 180
    }

    private var hasUnread: Bool {
        !viewModel.notifications.isEmpty
    }

    private var labelText: String {
        if !viewModel.isAvailable {
            return "N/A"
        }
        if viewModel.errorMessage != nil {
            return "Err"
        }
        return "\(viewModel.notifications.count)"
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: hasUnread ? "bell.badge.fill" : "bell")
                .foregroundColor(hasUnread ? .blue : .foregroundOutside)
            Text(labelText)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.foregroundOutside)
        }
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear { rect = geometry.frame(in: .global) }
                    .onChange(of: geometry.frame(in: .global)) { _, newValue in
                        rect = newValue
                    }
            }
        )
        .experimentalConfiguration(cornerRadius: 15)
        .frame(maxHeight: .infinity)
        .background(.black.opacity(0.001))
        .contentShape(Rectangle())
        .onTapGesture {
            MenuBarPopup.show(rect: rect, id: "github") {
                GitHubNotificationsPopup(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.start(updateInterval: updateFrequency)
        }
        .onChange(of: updateFrequency) { _, newValue in
            viewModel.start(updateInterval: newValue)
        }
    }
}

struct GitHubWidget_Previews: PreviewProvider {
    static var previews: some View {
        GitHubWidget()
            .frame(width: 140, height: 60)
            .background(Color.black)
            .environmentObject(ConfigProvider(config: [:]))
    }
}
