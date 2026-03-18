import SwiftUI

struct NetworkActivityWidget: View {
    @EnvironmentObject var configProvider: ConfigProvider
    var config: ConfigData { configProvider.config }
    
    @StateObject private var systemMonitor = SystemMonitorManager()
    
    @State private var rect: CGRect = CGRect()
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "network")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.foregroundOutside.opacity(0.8))
            
            VStack(alignment: .leading, spacing: 2) {
                // Upload Section
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.green)
                    
                    Text(formatSpeed(systemMonitor.uploadSpeed))
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.foregroundOutside)
                        .frame(width: 50, alignment: .leading)
                }
                
                // Download Section  
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.blue)
                    
                    Text(formatSpeed(systemMonitor.downloadSpeed))
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.foregroundOutside)
                        .frame(width: 50, alignment: .leading)
                }
            }
            
            // Activity indicator
            VStack(spacing: 1) {
                Circle()
                    .fill(systemMonitor.uploadSpeed > 0.01 ? .green : .gray.opacity(0.3))
                    .frame(width: 3, height: 3)
                    .animation(.easeInOut(duration: 0.5), value: systemMonitor.uploadSpeed > 0.01)
                
                Circle()
                    .fill(systemMonitor.downloadSpeed > 0.01 ? .blue : .gray.opacity(0.3))
                    .frame(width: 3, height: 3)
                    .animation(.easeInOut(duration: 0.5), value: systemMonitor.downloadSpeed > 0.01)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
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
            MenuBarPopup.show(rect: rect, id: "systemmonitor") { 
                SystemMonitorPopup() 
            }
        }
    }
    
    private func formatSpeed(_ speed: Double) -> String {
        if speed >= 1.0 {
            return String(format: "%.1f MB/s", speed)
        } else if speed >= 0.001 {
            return String(format: "%.0f KB/s", speed * 1024)
        } else {
            return "0 B/s"
        }
    }
}

struct NetworkActivityWidget_Previews: PreviewProvider {
    static var previews: some View {
        NetworkActivityWidget()
            .background(.black)
            .environmentObject(ConfigProvider(config: [:]))
            .previewLayout(.sizeThatFits)
    }
} 