import SwiftUI

struct KeyboardLayoutWidget: View {
    @EnvironmentObject var configProvider: ConfigProvider
    
    @StateObject private var keyboardLayoutManager = KeyboardLayoutManager()
    @State private var rect: CGRect = .zero
    
    var body: some View {
        HStack(spacing: 4) {
            Text(keyboardLayoutManager.currentInputSource)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(.primary)
                .frame(minWidth: 20)
        }
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        rect = geometry.frame(in: .global)
                    }
                    .onChange(of: geometry.frame(in: .global)) { _, newRect in
                        rect = newRect
                    }
            }
        )
        .onTapGesture {
            MenuBarPopup.show(rect: rect, id: "keyboardlayout") {
                KeyboardLayoutPopup()
                    .environmentObject(configProvider)
            }
        }
        .help("Current keyboard layout: \(keyboardLayoutManager.currentInputSource)")
    }
} 