import SwiftUI

struct CPURAMWidget: View {
    @EnvironmentObject var configProvider: ConfigProvider
    var config: ConfigData { configProvider.config }
    
    // Configuration properties
    var showIcon: Bool { config["show-icon"]?.boolValue ?? false }
    var cpuWarningLevel: Int { config["cpu-warning-level"]?.intValue ?? 70 }
    var cpuCriticalLevel: Int { config["cpu-critical-level"]?.intValue ?? 90 }
    var ramWarningLevel: Int { config["ram-warning-level"]?.intValue ?? 70 }
    var ramCriticalLevel: Int { config["ram-critical-level"]?.intValue ?? 90 }
    
    @StateObject private var systemMonitor = SystemMonitorManager()
    
    @State private var rect: CGRect = CGRect()
    
    var body: some View {
        HStack(spacing: 6) {
            if showIcon {
                Image(systemName: "cpu")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.foregroundOutside)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                // CPU Section with mini progress bar
                HStack(spacing: 4) {
                    Text("CPU")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.foregroundOutside.opacity(0.8))
                    
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.foregroundOutside.opacity(0.2))
                            .frame(width: 30, height: 3)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(cpuTextColor)
                            .frame(width: max(2, 30 * systemMonitor.cpuLoad / 100), height: 3)
                            .animation(.easeInOut(duration: 0.3), value: systemMonitor.cpuLoad)
                    }
                    
                    Text("\(Int(systemMonitor.cpuLoad))%")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(cpuTextColor)
                        .frame(width: 24, alignment: .trailing)
                }
                
                // RAM Section with mini progress bar
                HStack(spacing: 4) {
                    Text("RAM")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.foregroundOutside.opacity(0.8))
                    
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.foregroundOutside.opacity(0.2))
                            .frame(width: 30, height: 3)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(ramTextColor)
                            .frame(width: max(2, 30 * systemMonitor.ramUsage / 100), height: 3)
                            .animation(.easeInOut(duration: 0.3), value: systemMonitor.ramUsage)
                    }
                    
                    Text("\(Int(systemMonitor.ramUsage))%")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(ramTextColor)
                        .frame(width: 24, alignment: .trailing)
                }
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
    
    private var cpuTextColor: Color {
        let cpu = Int(systemMonitor.cpuLoad)
        if cpu >= cpuCriticalLevel {
            return .red
        } else if cpu >= cpuWarningLevel {
            return .yellow
        } else {
            return .foregroundOutside
        }
    }
    
    private var ramTextColor: Color {
        let ram = Int(systemMonitor.ramUsage)
        if ram >= ramCriticalLevel {
            return .red
        } else if ram >= ramWarningLevel {
            return .yellow
        } else {
            return .foregroundOutside
        }
    }
}

struct CPURAMWidget_Previews: PreviewProvider {
    static var previews: some View {
        CPURAMWidget()
            .background(.black)
            .environmentObject(ConfigProvider(config: [:]))
            .previewLayout(.sizeThatFits)
    }
} 