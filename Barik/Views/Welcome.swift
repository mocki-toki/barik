//
//  Welcome.swift
//  Barik
//
//  Created by ash on 2/28/25.
//

import SwiftUI

struct WelcomeView: View {
    private var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "Unknown"
    }
    
    var body: some View {
        VStack {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
            
            Text("Welcome to")
            
            HStack(spacing: 4) {
                Text("Barik")
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }
            .font(.largeTitle)
        }
        .frame(width: 450, height: 450)
        .background(
            VisualEffectView(material: .sidebar, blendingMode: .behindWindow).ignoresSafeArea()
        )
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }
    
    func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}

#Preview {
    WelcomeView()
}
