import SwiftUI

enum PerformanceMode: String, CaseIterable {
    case batterySaver = "battery-saver"
    case balanced = "balanced"
    case maxPerformance = "max-performance"
    
    var displayName: String {
        switch self {
        case .batterySaver: return "Battery Saver"
        case .balanced: return "Balanced"
        case .maxPerformance: return "Max Performance"
        }
    }
    
    var icon: String {
        switch self {
        case .batterySaver: return "battery.25"
        case .balanced: return "speedometer"
        case .maxPerformance: return "bolt.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .batterySaver: return .yellow
        case .balanced: return .orange
        case .maxPerformance: return .red
        }
    }
}

class PerformanceModeManager: ObservableObject {
    static let shared = PerformanceModeManager()
    
    @Published var currentMode: PerformanceMode = .batterySaver
    
    private init() {
        loadCurrentMode()
    }
    
    private func loadCurrentMode() {
        if let modeString = UserDefaults.standard.string(forKey: "performance_mode"),
           let mode = PerformanceMode(rawValue: modeString) {
            currentMode = mode
        } else {
            currentMode = .batterySaver
        }
    }
    
    func setMode(_ mode: PerformanceMode) {
        currentMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: "performance_mode")
        
        // Apply the performance mode settings
        applyPerformanceMode(mode)
    }
    
    private func applyPerformanceMode(_ mode: PerformanceMode) {
        // Get the timer intervals for each mode
        let intervals = getTimerIntervals(for: mode)
        
        // Notify all managers to update their timers
        NotificationCenter.default.post(
            name: NSNotification.Name("PerformanceModeChanged"), 
            object: intervals
        )
    }
    
    func getTimerIntervals(for mode: PerformanceMode) -> [String: TimeInterval] {
        switch mode {
        case .batterySaver:
            return [
                "spaces": 5.0,
                "nowplaying": 5.0,
                "audio": 10.0,
                "system": 10.0,
                "battery": 30.0,
                "keyboard": 10.0,
                "time": 5.0,
                "systemPopup": 3.0,
                "calendar": 5.0,
                "network": 5.0
            ]
        case .balanced:
            return [
                "spaces": 2.0,
                "nowplaying": 3.0,
                "audio": 5.0,
                "system": 5.0,
                "battery": 10.0,
                "keyboard": 5.0,
                "time": 2.0,
                "systemPopup": 2.0,
                "calendar": 5.0,
                "network": 5.0
            ]
        case .maxPerformance:
            return [
                "spaces": 0.1,
                "nowplaying": 0.3,
                "audio": 0.5,
                "system": 1.0,
                "battery": 1.0,
                "keyboard": 2.0,
                "time": 1.0,
                "systemPopup": 1.0,
                "calendar": 5.0,
                "network": 5.0
            ]
        }
    }
}

struct PerformanceModeWidget: View {
    @EnvironmentObject var configProvider: ConfigProvider
    @StateObject private var performanceManager = PerformanceModeManager.shared
    
    @State private var rect: CGRect = .zero
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: performanceManager.currentMode.icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(performanceManager.currentMode.color)
                .animation(.easeInOut(duration: 0.3), value: performanceManager.currentMode)
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
            MenuBarPopup.show(rect: rect, id: "performance") { PerformanceModePopup() }
        }
        .help("Performance Mode: \(performanceManager.currentMode.displayName)")
    }
}

struct PerformanceModePopup: View {
    @StateObject private var performanceManager = PerformanceModeManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "speedometer")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Performance Mode")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Current: \(performanceManager.currentMode.displayName)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Spacer()
            }
            
            // Mode selection
            VStack(spacing: 12) {
                ForEach(PerformanceMode.allCases, id: \.self) { mode in
                    Button(action: {
                        performanceManager.setMode(mode)
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(mode.color)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mode.displayName)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.white)
                                
                                Text(getModeDescription(mode))
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            if performanceManager.currentMode == mode {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(performanceManager.currentMode == mode ? 
                                     .white.opacity(0.1) : .white.opacity(0.05))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Info text
            Text("Changes update intervals for widgets to optimize energy consumption")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding(25)
        .frame(width: 320)
        .foregroundStyle(.white)
    }
    
    private func getModeDescription(_ mode: PerformanceMode) -> String {
        switch mode {
        case .batterySaver:
            return "Longest intervals, best for battery life"
        case .balanced:
            return "Moderate intervals, good balance"
        case .maxPerformance:
            return "Shortest intervals, most responsive"
        }
    }
}

struct PerformanceModeWidget_Previews: PreviewProvider {
    static var previews: some View {
        PerformanceModeWidget()
            .background(.black)
            .environmentObject(ConfigProvider(config: [:]))
            .previewLayout(.sizeThatFits)
    }
} 
