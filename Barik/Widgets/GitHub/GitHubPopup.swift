import AppKit
import SwiftUI

struct GitHubNotificationsPopup: View {
    @ObservedObject var viewModel: GitHubNotificationsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("GitHub Notifications")
                .font(.system(size: 14))
                .fontWeight(.medium)

            if let error = viewModel.errorMessage {
                Text("Error: \(error)")
                    .foregroundStyle(.red)
                    .font(.system(size: 12))
            }

            if viewModel.notifications.isEmpty {
                Text("No new notifications")
                    .foregroundStyle(.white.opacity(0.7))
                    .font(.system(size: 12))
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(viewModel.notifications) { notification in
                            Button {
                                open(notification)
                            } label: {
                                notificationRow(notification)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 320)
            }
        }
        .padding(20)
        .frame(width: 420)
        .background(Color.black)
    }

    private func notificationRow(_ notification: GitHubNotification) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: iconName(for: notification.subject.type))
                .foregroundColor(iconColor(for: notification.subject.type))
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 3) {
                Text(notification.repository.fullName)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                Text(notification.subject.title)
                    .font(.system(size: 12))
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(8)
        .background(Color.white.opacity(0.06))
        .cornerRadius(8)
    }

    private func iconName(for type: String) -> String {
        switch type {
        case "Issue":
            return "exclamationmark.circle"
        case "PullRequest":
            return "arrow.triangle.pull"
        case "Discussion":
            return "bubble.left.and.bubble.right"
        case "Commit":
            return "chevron.left.slash.chevron.right"
        case "Release":
            return "tag"
        default:
            return "bell"
        }
    }

    private func iconColor(for type: String) -> Color {
        switch type {
        case "Issue":
            return .green
        case "PullRequest":
            return .blue
        case "Discussion":
            return .white
        case "Commit":
            return .white
        case "Release":
            return .yellow
        default:
            return .gray
        }
    }

    private func open(_ notification: GitHubNotification) {
        guard let url = notification.webUrl else { return }
        NSWorkspace.shared.open(url)
    }
}

struct GitHubNotificationsPopup_Previews: PreviewProvider {
    static var previews: some View {
        GitHubNotificationsPopup(viewModel: GitHubNotificationsViewModel())
            .previewLayout(.sizeThatFits)
    }
}
