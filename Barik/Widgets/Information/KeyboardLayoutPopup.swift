import SwiftUI

struct KeyboardLayoutPopup: View {
    @StateObject private var keyboardLayoutManager = KeyboardLayoutManager()
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "keyboard")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Keyboard Layout")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Current: \(keyboardLayoutManager.currentInputSource)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .foregroundStyle(.white)
            
            // Available input sources
            if !keyboardLayoutManager.availableInputSources.isEmpty {
                VStack(spacing: 8) {
                    ForEach(keyboardLayoutManager.availableInputSources, id: \.self) { source in
                        Button(action: {
                            keyboardLayoutManager.switchToInputSource(name: source)
                        }) {
                            HStack {
                                Text(source)
                                    .foregroundStyle(.white)
                                
                                Spacer()
                                
                                if source.contains(keyboardLayoutManager.currentInputSource) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.green)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Divider()
                    .background(.white.opacity(0.3))
                
                // Quick switch button
                Button("Switch to Next Layout") {
                    keyboardLayoutManager.switchToNextInputSource()
                }
                .buttonStyle(ActionButtonStyle())
            } else {
                Text("No additional layouts available")
                    .foregroundStyle(.secondary)
                    .italic()
            }
        }
        .padding(20)
        .frame(width: 250)
        .background(.ultraThinMaterial.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.blue.opacity(configuration.isPressed ? 0.7 : 1.0))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
} 