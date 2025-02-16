import SwiftUI
import Foundation

struct SpotifyView: View {
    @State private var songTitle: String = ""
    @State private var artistSubtitle: String = ""
    @State private var albumArtURL: String = ""
    @State private var showMusicIcon: Bool = true

    // Fires every second.
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        Button(action: openSpotify) {
            HStack {
                if showMusicIcon {
                    Image(systemName: "music.note")
                        .frame(width: 10, height: 10)
                        .shadow(color: .iconShadow, radius: 2)
                } else {
                    HStack(spacing: 8) {
                        // Display the album art.
                        AsyncImage(url: URL(string: albumArtURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .shadow(color: .shadow, radius: 2)
                        } placeholder: {
                            Color.gray
                        }
                        .frame(width: 30, height: 30)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(songTitle)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(artistSubtitle)
                                .opacity(0.8)
                                .font(.footnote)
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(height: 39)
            .background(Color.noActive)
            .background(.ultraThinMaterial)
            .preferredColorScheme(.dark)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: .shadow, radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .onReceive(timer) { _ in
            fetchSpotifySong()
        }
    }
    
    /// Queries Spotify via AppleScript.
    private func fetchSpotifySong() {
        // The AppleScript now returns album art URL as the fourth component.
        let script = """
        if application "Spotify" is running then
            tell application "Spotify"
                if player state is playing then
                    return "playing|" & (name of current track) & "|" & (artist of current track) & "|" & (artwork url of current track)
                else if player state is paused then
                    return "paused|" & (name of current track) & "|" & (artist of current track) & "|" & (artwork url of current track)
                else
                    return "stopped"
                end if
            end tell
        else
            return "stopped"
        end if
        """
        
        guard let output = runAppleScript(script) else { return }
        
        DispatchQueue.main.async {
            let components = output.components(separatedBy: "|")
            if components.count == 4 {
                let state = components[0]
                let track = components[1]
                let artist = components[2]
                let artURL = components[3]
                showMusicIcon = false
                songTitle = track
                artistSubtitle = (state == "paused") ? "by " + artist + " (paused)" : "by " + artist
                albumArtURL = artURL
            } else {
                // For "stopped" (or any unexpected format), show the music icon.
                showMusicIcon = true
                songTitle = ""
                artistSubtitle = ""
                albumArtURL = ""
            }
        }
    }
    
    /// Runs the provided AppleScript and returns its string output.
    private func runAppleScript(_ script: String) -> String? {
        var error: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else { return nil }
        let outputDescriptor = appleScript.executeAndReturnError(&error)
        if let error = error {
            print("AppleScript Error: \(error)")
            return nil
        }
        return outputDescriptor.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Opens Spotify. On macOS, it uses NSWorkspace; on iOS, it opens the Spotify URL scheme.
    private func openSpotify() {
        #if os(macOS)
        NSWorkspace.shared.launchApplication("Spotify")
        #elseif os(iOS)
        if let url = URL(string: "spotify:") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        #endif
    }
}

struct SpotifyView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            SpotifyView()
        }
        .frame(width: 500, height: 100)
    }
}
