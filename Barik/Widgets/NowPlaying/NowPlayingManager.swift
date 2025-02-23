import AppKit
import Combine
import Foundation

// MARK: - Playback State

/// Represents the current playback state.
enum PlaybackState: String {
    case playing, paused, stopped
}

// MARK: - Now Playing Song Model

/// A model representing the currently playing song.
struct NowPlayingSong: Equatable, Identifiable {
    var id: String { title + artist }
    let appName: String
    let state: PlaybackState
    let title: String
    let artist: String
    let albumArtURL: URL?
    let position: Double?
    let duration: Double? // Duration in seconds

    /// Initializes a song model from a given output string.
    /// - Parameters:
    ///   - application: The name of the music application.
    ///   - output: The output string returned by AppleScript.
    init?(application: String, from output: String) {
        let components = output.components(separatedBy: "|")
        guard components.count == 6,
              let state = PlaybackState(rawValue: components[0]) else {
            return nil
        }
        // Replace commas with dots for correct decimal conversion.
        let positionString = components[4].replacingOccurrences(of: ",", with: ".")
        let durationString = components[5].replacingOccurrences(of: ",", with: ".")
        guard let position = Double(positionString),
              let durationMilliseconds = Double(durationString) else {
            return nil
        }
        
        self.appName = application
        self.state = state
        self.title = components[1]
        self.artist = components[2]
        self.albumArtURL = URL(string: components[3])
        self.position = position
        self.duration = durationMilliseconds / 1000
    }
}

// MARK: - Supported Music Applications

/// Supported music applications with corresponding AppleScript commands.
enum MusicApp: String, CaseIterable {
    case spotify = "Spotify"
    case music = "Music"
    
    /// AppleScript to fetch the now playing song.
    var nowPlayingScript: String {
        """
        if application "\(rawValue)" is running then
            tell application "\(rawValue)"
                if player state is playing then
                    set currentTrack to current track
                    return "playing|" & (name of currentTrack) & "|" & (artist of currentTrack) & "|" & (artwork url of currentTrack) & "|" & player position & "|" & (duration of currentTrack)
                else if player state is paused then
                    set currentTrack to current track
                    return "paused|" & (name of currentTrack) & "|" & (artist of currentTrack) & "|" & (artwork url of currentTrack) & "|" & player position & "|" & (duration of currentTrack)
                else
                    return "stopped"
                end if
            end tell
        else
            return "stopped"
        end if
        """
    }
    
    var previousTrackCommand: String {
        "tell application \"\(rawValue)\" to previous track"
    }
    
    var togglePlayPauseCommand: String {
        "tell application \"\(rawValue)\" to playpause"
    }
    
    var nextTrackCommand: String {
        "tell application \"\(rawValue)\" to next track"
    }
}

// MARK: - Now Playing Provider

/// Provides functionality to fetch the now playing song and execute playback commands.
final class NowPlayingProvider {
    
    /// Returns the current playing song from any supported music application.
    static func fetchNowPlaying() -> NowPlayingSong? {
        for app in MusicApp.allCases {
            if let song = fetchNowPlaying(from: app) {
                return song
            }
        }
        return nil
    }
    
    /// Returns the now playing song for a specific music application.
    private static func fetchNowPlaying(from app: MusicApp) -> NowPlayingSong? {
        guard let output = runAppleScript(app.nowPlayingScript),
              output != "stopped" else {
            return nil
        }
        return NowPlayingSong(application: app.rawValue, from: output)
    }
    
    /// Checks if the specified music application is currently running.
    static func isAppRunning(_ app: MusicApp) -> Bool {
        NSWorkspace.shared.runningApplications.contains { $0.localizedName == app.rawValue }
    }
    
    /// Executes the provided AppleScript and returns the trimmed result.
    @discardableResult
    static func runAppleScript(_ script: String) -> String? {
        guard let appleScript = NSAppleScript(source: script) else { return nil }
        var error: NSDictionary?
        let outputDescriptor = appleScript.executeAndReturnError(&error)
        if let error = error {
            print("AppleScript Error: \(error)")
            return nil
        }
        return outputDescriptor.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Returns the first running music application.
    static func activeMusicApp() -> MusicApp? {
        MusicApp.allCases.first { isAppRunning($0) }
    }
    
    /// Executes a playback command for the active music application.
    static func executeCommand(_ command: (MusicApp) -> String) {
        guard let activeApp = activeMusicApp() else { return }
        _ = runAppleScript(command(activeApp))
    }
}

// MARK: - Now Playing Manager

/// An observable manager that periodically updates the now playing song.
final class NowPlayingManager: ObservableObject {
    static let shared = NowPlayingManager()
    
    @Published private(set) var nowPlaying: NowPlayingSong?
    private var cancellable: AnyCancellable?
    
    private init() {
        cancellable = Timer.publish(every: 0.3, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateNowPlaying()
            }
    }
    
    /// Updates the now playing song asynchronously.
    private func updateNowPlaying() {
        DispatchQueue.global(qos: .background).async {
            let song = NowPlayingProvider.fetchNowPlaying()
            DispatchQueue.main.async { [weak self] in
                self?.nowPlaying = song
            }
        }
    }
    
    /// Skips to the previous track.
    func previousTrack() {
        NowPlayingProvider.executeCommand { $0.previousTrackCommand }
    }
    
    /// Toggles between play and pause.
    func togglePlayPause() {
        NowPlayingProvider.executeCommand { $0.togglePlayPauseCommand }
    }
    
    /// Skips to the next track.
    func nextTrack() {
        NowPlayingProvider.executeCommand { $0.nextTrackCommand }
    }
}
