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
    let duration: Double?  // Duration in seconds

    /// Initializes a song model from a given output string.
    /// - Parameters:
    ///   - application: The name of the music application.
    ///   - output: The output string returned by AppleScript.
    init?(application: String, from output: String) {
        let components = output.components(separatedBy: "|")
        guard components.count == 6,
            let state = PlaybackState(rawValue: components[0])
        else {
            return nil
        }
        // Replace commas with dots for correct decimal conversion.
        let positionString = components[4].replacingOccurrences(
            of: ",", with: ".")
        let durationString = components[5].replacingOccurrences(
            of: ",", with: ".")
        guard let position = Double(positionString),
            let duration = Double(durationString)
        else {
            return nil
        }

        self.appName = application
        self.state = state
        self.title = components[1]
        self.artist = components[2]
        self.albumArtURL = URL(string: components[3])
        self.position = position
        if application == MusicApp.spotify.rawValue {
            self.duration = duration / 1000
        } else {
            self.duration = duration
        }
    }
}

// MARK: - Supported Music Applications

/// Supported music applications with corresponding AppleScript commands.
enum MusicApp: String, CaseIterable {
    case spotify = "Spotify"
    case music = "Music"

    /// AppleScript to fetch the now playing song.
    var nowPlayingScript: String {
        if self == .music {
            return """
                if application "Music" is running then
                    tell application "Music"
                        if player state is playing or player state is paused then
                            set currentTrack to current track
                            try
                                set artworkURL to (get URL of artwork 1 of currentTrack) as text
                            on error
                                set artworkURL to ""
                            end try
                            set stateText to ""
                            if player state is playing then
                                set stateText to "playing"
                            else if player state is paused then
                                set stateText to "paused"
                            end if
                            return stateText & "|" & (name of currentTrack) & "|" & (artist of currentTrack) & "|" & artworkURL & "|" & (player position as text) & "|" & ((duration of currentTrack) as text)
                        else
                            return "stopped"
                        end if
                    end tell
                else
                    return "stopped"
                end if
                """
        } else {
            return """
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
            output != "stopped"
        else {
            return nil
        }
        return NowPlayingSong(application: app.rawValue, from: output)
    }

    /// Checks if the specified music application is currently running.
    static func isAppRunning(_ app: MusicApp) -> Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.localizedName == app.rawValue
        }
    }

    /// Executes the provided AppleScript and returns the trimmed result.
    @discardableResult
    static func runAppleScript(_ script: String) -> String? {
        guard let appleScript = NSAppleScript(source: script) else {
            return nil
        }
        var error: NSDictionary?
        let outputDescriptor = appleScript.executeAndReturnError(&error)
        if let error = error {
            print("AppleScript Error: \(error)")
            return nil
        }
        return outputDescriptor.stringValue?.trimmingCharacters(
            in: .whitespacesAndNewlines)
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
final class NowPlayingManager: ObservableObject, ConditionallyActivatableWidget {
    static let shared = NowPlayingManager()

    @Published private(set) var nowPlaying: NowPlayingSong?
    private var cancellable: AnyCancellable?
    private var currentInterval: TimeInterval = 5.0
    let widgetId = "default.nowplaying"
    
    private var isActive = false

    private init() {
        setupNotifications()
        // For now, always activate to ensure widgets work
        activate()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupNotifications() {
        // Listen for performance mode changes
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PerformanceModeChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let intervals = notification.object as? [String: TimeInterval],
               let newInterval = intervals["nowplaying"] {
                self?.updateTimerInterval(newInterval)
            }
        }
    }
    
    func activate() {
        guard !isActive else { 
            return 
        }
        
        isActive = true
        
        // Get current performance mode interval
        let performanceManager = PerformanceModeManager.shared
        let intervals = performanceManager.getTimerIntervals(for: performanceManager.currentMode)
        currentInterval = intervals["nowplaying"] ?? 5.0
        
        startTimer()
    }
    
    func deactivate() {
        guard isActive else { return }
        isActive = false
        stopTimer()
        
        // Clear the now playing info when deactivated
        DispatchQueue.main.async {
            self.nowPlaying = nil
        }
    }
    
    private func updateTimerInterval(_ newInterval: TimeInterval) {
        guard isActive else { return }
        currentInterval = newInterval
        
        // Restart timer with new interval
        stopTimer()
        startTimer()
    }
    
    private func startTimer() {
        cancellable = Timer.publish(every: currentInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateNowPlaying()
            }
    }
    
    private func stopTimer() {
        cancellable?.cancel()
        cancellable = nil
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
