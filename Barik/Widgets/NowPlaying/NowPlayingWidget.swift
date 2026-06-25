import SwiftUI

// MARK: - Now Playing Widget

struct NowPlayingWidget: View {
    @EnvironmentObject var configProvider: ConfigProvider
    @ObservedObject var playingManager = NowPlayingManager.shared

    @State private var widgetFrame: CGRect = .zero
    @State private var animatedWidth: CGFloat = 0
    @State private var lastSong: NowPlayingSong?
    private let maxWidgetWidth: CGFloat = 500
    private let iconWidth: CGFloat = 12

    var body: some View {
        ZStack(alignment: .trailing) {
            if let song = playingManager.nowPlaying {
                // Visible content with fixed animated width.
                VisibleNowPlayingContent(song: song, width: animatedWidth)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        MenuBarPopup.show(rect: widgetFrame, id: "nowplaying") {
                            NowPlayingPopup(configProvider: configProvider)
                        }
                    }

                // Hidden view for measuring the intrinsic width.
                // Placed in an overlay on a zero-size view so it doesn't
                // affect ZStack layout, while .fixedSize() lets it measure
                // its natural unconstrained width.
                Color.clear
                    .frame(width: 0, height: 0)
                    .overlay(
                        MeasurableNowPlayingContent(song: song) { measuredWidth in
                            let clampedWidth = min(measuredWidth, maxWidgetWidth)
                            if animatedWidth == 0 {
                                animatedWidth = clampedWidth
                            } else if animatedWidth != clampedWidth {
                                withAnimation(.smooth) {
                                    animatedWidth = clampedWidth
                                }
                            }
                        }
                        .hidden()
                        .fixedSize()
                    )
            } else if let lastSong = lastSong {
                // Show last song content during collapse animation
                VisibleNowPlayingContent(song: lastSong, width: animatedWidth)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        MenuBarPopup.show(rect: widgetFrame, id: "nowplaying") {
                            NowPlayingPopup(configProvider: configProvider)
                        }
                    }
            } else {
                // Show music icon when no song is playing
                Image(systemName: "music.note")
                    .font(.system(size: 12))
                    .foregroundColor(.foreground)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        MenuBarPopup.show(rect: widgetFrame, id: "nowplaying") {
                            NowPlayingPopup(configProvider: configProvider)
                        }
                    }
            }
        }
        .onChange(of: playingManager.nowPlaying) { oldValue, newValue in
            if oldValue != nil && newValue == nil {
                // Song stopped - save last song and animate collapse
                lastSong = oldValue
                withAnimation(.smooth(duration: 0.3)) {
                    animatedWidth = iconWidth
                }
                // Clear lastSong shortly after animation starts for smoother transition
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    lastSong = nil
                }
            } else if newValue != nil {
                // New song started - clear last song immediately
                lastSong = nil
            }
        }
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        widgetFrame = geometry.frame(in: .global)
                    }
                    .onChange(of: geometry.frame(in: .global)) { _, newFrame in
                        widgetFrame = newFrame
                    }
            }
        )
    }
}

// MARK: - Now Playing Content

/// A view that composes the album art and song text into a capsule-shaped content view.
struct NowPlayingContent: View {
    let song: NowPlayingSong
    @ObservedObject var configManager = ConfigManager.shared
    var foregroundHeight: CGFloat { configManager.config.experimental.foreground.resolveHeight() }
    
    var body: some View {
        HStack(spacing: 8) {
            AlbumArtView(song: song)
            if song.state != .paused {
                SongTextView(song: song)
            }
        }
        .padding(.horizontal, 0)
        .foregroundColor(.foreground)
    }
}

// MARK: - Measurable Now Playing Content

/// A wrapper view that measures the intrinsic width of the now playing content.
struct MeasurableNowPlayingContent: View {
    let song: NowPlayingSong
    let onSizeChange: (CGFloat) -> Void

    var body: some View {
        NowPlayingContent(song: song)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            onSizeChange(geometry.size.width)
                        }
                        .onChange(of: geometry.size.width) { _, newWidth in
                            onSizeChange(newWidth)
                        }
                }
            )
    }
}

// MARK: - Visible Now Playing Content

/// A view that displays now playing content with a fixed, animated width and transition.
struct VisibleNowPlayingContent: View {
    let song: NowPlayingSong
    let width: CGFloat

    var body: some View {
        NowPlayingContent(song: song)
            .frame(width: width, height: 30)
            .animation(.smooth(duration: 0.1), value: song)
            .transition(.blurReplace)
    }
}

// MARK: - Album Art View

/// A view that displays the album art with a fade animation and a pause indicator if needed.
struct AlbumArtView: View {
    let song: NowPlayingSong

    var body: some View {
        ZStack {
            FadeAnimatedCachedImage(
                url: song.albumArtURL,
                targetSize: CGSize(width: 20, height: 20)
            )
            .frame(width: 20, height: 20)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .scaleEffect(song.state == .paused ? 0.9 : 1)
            .brightness(song.state == .paused ? -0.3 : 0)

        }
        .animation(.smooth(duration: 0.1), value: song.state == .paused)
    }
}

// MARK: - Song Text View

/// A view that displays the song title and artist.
struct SongTextView: View {
    let song: NowPlayingSong
    @ObservedObject var configManager = ConfigManager.shared
    var foregroundHeight: CGFloat { configManager.config.experimental.foreground.resolveHeight() }

    var body: some View {

        VStack(alignment: .leading, spacing: -1) {
            if foregroundHeight >= 30 {
                Text(song.title)
                    .font(.system(size: 11))
                    .fontWeight(.medium)
                    .padding(.trailing, 2)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(song.artist)
                    .opacity(0.8)
                    .font(.system(size: 10))
                    .padding(.trailing, 2)
                    .lineLimit(1)
                    .truncationMode(.tail)
            } else {
                Text(song.artist + " — " + song.title)
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        // Disable animations for text changes.
        .transaction { transaction in
            transaction.animation = nil
        }
    }
}

// MARK: - Preview

struct NowPlayingWidget_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            NowPlayingWidget()
        }
        .frame(width: 500, height: 100)
    }
}
