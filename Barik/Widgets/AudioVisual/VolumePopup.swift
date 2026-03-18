import SwiftUI

struct VolumePopup: View {
    @StateObject private var audioVisualManager = AudioVisualManager()
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with icon and title
            HStack(spacing: 12) {
                Image(systemName: volumeIcon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(volumeColor)
                    .frame(width: 30, height: 30)
                    .animation(.easeInOut(duration: 0.3), value: audioVisualManager.isMuted)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Volume")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(volumeStatusText)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Spacer()
            }
            
            // Volume control section
            VStack(spacing: 12) {
                // Volume slider
                HStack(spacing: 12) {
                    Image(systemName: "speaker.wave.1")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                    
                    Slider(
                        value: Binding(
                            get: { audioVisualManager.volumeLevel },
                            set: { audioVisualManager.setVolume(level: $0) }
                        ),
                        in: 0...1
                    )
                    .accentColor(.white)
                    .disabled(audioVisualManager.isMuted)
                    
                    Image(systemName: "speaker.wave.3")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                }
                
                // Mute toggle button
                Button(action: {
                    audioVisualManager.toggleMute()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: audioVisualManager.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text(audioVisualManager.isMuted ? "Unmute" : "Mute")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(audioVisualManager.isMuted ? .red.opacity(0.3) : .white.opacity(0.2))
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .animation(.easeInOut(duration: 0.2), value: audioVisualManager.isMuted)
            }
        }
        .padding(25)
        .frame(width: 280)
        .foregroundStyle(.white)
    }
    
    private var volumeIcon: String {
        if audioVisualManager.isMuted {
            return "speaker.slash.fill"
        } else if audioVisualManager.volumeLevel < 0.33 {
            return "speaker.wave.1.fill"
        } else if audioVisualManager.volumeLevel < 0.66 {
            return "speaker.wave.2.fill"
        } else {
            return "speaker.wave.3.fill"
        }
    }
    
    private var volumeColor: Color {
        return audioVisualManager.isMuted ? .red.opacity(0.8) : .white
    }
    
    private var volumeStatusText: String {
        if audioVisualManager.isMuted {
            return "Muted"
        } else {
            return "\(Int(audioVisualManager.volumeLevel * 100))%"
        }
    }
}

struct VolumePopup_Previews: PreviewProvider {
    static var previews: some View {
        VolumePopup()
            .background(Color.black)
            .previewLayout(.sizeThatFits)
    }
} 