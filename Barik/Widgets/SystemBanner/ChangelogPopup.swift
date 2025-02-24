import MarkdownUI
import SwiftUI

struct ChangelogPopup: View {
    @State private var changelogText: String = "Loading..."

    private var bundleVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            ?? "0.0.0"
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("v\(bundleVersion) Changelog")
                .padding(15)
                .font(.system(size: 14))
                .fontWeight(.medium)
            Rectangle().fill(.white).opacity(0.2).frame(height: 0.5)
            ScrollView {
                Markdown(changelogText)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 20)
                    .padding(.trailing, 15)
                    .markdownTheme(.barik)
                    .foregroundStyle(.white)
            }.offset(x: 15)
                .markdownImageProvider(WebImageProvider())
        }
        .scrollIndicators(.hidden)
        .frame(width: 500)
        .frame(maxHeight: 600)
        .task {
            await loadChangelog()
        }
    }

    // Asynchronously loads the changelog from the remote URL
    private func loadChangelog() async {
        guard
            let url = URL(
                string:
                    "https://raw.githubusercontent.com/mocki-toki/barik/main/CHANGELOG.md"
            )
        else {
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let fullChangelog = String(data: data, encoding: .utf8) else {
                updateChangelogText("Failed to load CHANGELOG.")
                return
            }

            let extractedSection = extractSection(
                forVersion: bundleVersion, from: fullChangelog)
            let displayText =
                extractedSection.isEmpty
                ? "Changelog for v\(bundleVersion) not found"
                : extractedSection

            updateChangelogText(displayText)
        } catch {
            updateChangelogText("Failed to load CHANGELOG.")
        }
    }

    // Updates the changelog text on the main thread
    private func updateChangelogText(_ text: String) {
        DispatchQueue.main.async {
            self.changelogText = text
        }
    }

    // Extracts the section corresponding to the specified version from the changelog
    private func extractSection(
        forVersion version: String, from changelog: String
    ) -> String {
        let lines = changelog.components(separatedBy: .newlines)

        guard
            let versionIndex = lines.firstIndex(where: {
                $0.contains("## \(version)")
            })
        else {
            return ""
        }

        var sectionLines: [String] = []
        for i in versionIndex..<lines.count {
            let line = lines[i]

            if i == versionIndex, line.hasPrefix("## ") {
                continue
            }

            // End the section when a new version header is encountered
            if i != versionIndex && line.hasPrefix("## ") {
                break
            }

            // Replace "<br>" with a markdown header if encountered
            if line == "<br>" {
                sectionLines.append("### ")
            } else {
                sectionLines.append(line)
            }
        }

        return sectionLines.joined(separator: "\n")
    }
}

// MARK: - Preview

struct ChangelogPopup_Previews: PreviewProvider {
    static var previews: some View {
        ChangelogPopup()
            .background(Color.black)
            .previewLayout(.sizeThatFits)
    }
}
