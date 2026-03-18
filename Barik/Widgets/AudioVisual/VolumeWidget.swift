import SwiftUI

struct VolumeWidget: View {
    @EnvironmentObject var configProvider: ConfigProvider
    var config: ConfigData { configProvider.config }
    var showPercentage: Bool { config["show-percentage"]?.boolValue ?? false }
    
    @StateObject private var audioVisualManager = AudioVisualManager()
    @State private var rect: CGRect = .zero
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: volumeIcon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(volumeColor)
                .animation(.easeInOut(duration: 0.3), value: audioVisualManager.isMuted)
            
            if showPercentage {
                Text("\(Int(audioVisualManager.volumeLevel * 100))%")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.foregroundOutside)
                    .transition(.blurReplace)
            }
        }
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        rect = geometry.frame(in: .global)
                    }
                    .onChange(of: geometry.frame(in: .global)) { oldState, newState in
                        rect = newState
                    }
            }
        )
        .experimentalConfiguration(cornerRadius: 15)
        .frame(maxHeight: .infinity)
        .background(.black.opacity(0.001))
        .onTapGesture {
            MenuBarPopup.show(rect: rect, id: "volume") { VolumePopup() }
        }
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
        return audioVisualManager.isMuted ? .red.opacity(0.8) : .icon
    }
}

struct VolumeWidget_Previews: PreviewProvider {
    static var previews: some View {
        VolumeWidget()
            .background(.black)
            .environmentObject(ConfigProvider(config: [:]))
            .previewLayout(.sizeThatFits)
    }
} 