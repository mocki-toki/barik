import SwiftUI

struct SystemMonitorPopup: View {
    @StateObject private var systemMonitor = SystemMonitorManager()
    @State private var cpuHistory: [Double] = Array(repeating: 0, count: 30)
    @State private var ramHistory: [Double] = Array(repeating: 0, count: 30)
    @State private var networkUpHistory: [Double] = Array(repeating: 0, count: 30)
    @State private var networkDownHistory: [Double] = Array(repeating: 0, count: 30)
    
    private let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "cpu")
                        .font(.title2)
                        .foregroundStyle(.white)
                    Text("System Monitor")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    Spacer()
                    Text(Date(), style: .time)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                
                // CPU Section with Chart
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("CPU Usage")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Spacer()
                        Text("\(Int(systemMonitor.cpuLoad))%")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(cpuColor)
                    }
                    
                    // CPU Chart
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.black.opacity(0.3))
                            .frame(height: 60)
                        
                        CPUChart(data: cpuHistory, color: cpuColor)
                            .frame(height: 50)
                            .padding(.horizontal, 8)
                    }
                    
                    // CPU Breakdown
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("User")
                                .font(.caption2)
                                .foregroundStyle(.gray)
                            Text("\(Int(systemMonitor.userLoad))%")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("System")
                                .font(.caption2)
                                .foregroundStyle(.gray)
                            Text("\(Int(systemMonitor.systemLoad))%")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Idle")
                                .font(.caption2)
                                .foregroundStyle(.gray)
                            Text("\(Int(systemMonitor.idleLoad))%")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                        }
                        
                        Spacer()
                    }
                }
            
            Divider()
                .background(.gray.opacity(0.3))
            
                // RAM Section with Chart
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Memory Usage")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(Int(systemMonitor.ramUsage))%")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(ramColor)
                            Text("\(String(format: "%.1f", usedRAM)) GB")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                    }
                    
                    // RAM Chart
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.black.opacity(0.3))
                            .frame(height: 60)
                        
                        RAMChart(data: ramHistory, color: ramColor)
                            .frame(height: 50)
                            .padding(.horizontal, 8)
                    }
                    
                    // Memory breakdown with visual bars
                    VStack(spacing: 6) {
                        MemoryBar(label: "Active", value: systemMonitor.activeRAM, total: systemMonitor.totalRAM, color: .blue)
                        MemoryBar(label: "Wired", value: systemMonitor.wiredRAM, total: systemMonitor.totalRAM, color: .orange)
                        MemoryBar(label: "Compressed", value: systemMonitor.compressedRAM, total: systemMonitor.totalRAM, color: .purple)
                    }
                }
                
                Divider()
                    .background(.gray.opacity(0.3))
                
                // Network Section with Charts
                VStack(alignment: .leading, spacing: 12) {
                    Text("Network Activity")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    HStack(spacing: 16) {
                        // Upload
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "arrow.up.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Upload")
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                Spacer()
                            }
                            
                            Text(formatSpeed(systemMonitor.uploadSpeed))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.green)
                            
                            NetworkMiniChart(data: networkUpHistory, color: .green)
                                .frame(height: 20)
                        }
                        
                        // Download  
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "arrow.down.circle.fill")
                                    .foregroundStyle(.blue)
                                Text("Download")
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                Spacer()
                            }
                            
                            Text(formatSpeed(systemMonitor.downloadSpeed))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.blue)
                            
                            NetworkMiniChart(data: networkDownHistory, color: .blue)
                                .frame(height: 20)
                        }
                    }
                }
                
                
            }
        }
        .padding(16)
        .background(.black.opacity(0.9))
        .cornerRadius(12)
        .frame(width: 320)
        .onReceive(timer) { _ in
            updateHistory()
        }
    }
    
    private var usedRAM: Double {
        systemMonitor.activeRAM + systemMonitor.wiredRAM + systemMonitor.compressedRAM
    }
    
    private var cpuColor: Color {
        let cpu = Int(systemMonitor.cpuLoad)
        if cpu >= 90 {
            return .red
        } else if cpu >= 70 {
            return .yellow
        } else {
            return .green
        }
    }
    
    private var ramColor: Color {
        let ram = Int(systemMonitor.ramUsage)
        if ram >= 90 {
            return .red
        } else if ram >= 70 {
            return .yellow
        } else {
            return .green
        }
    }
    
    private func formatSpeed(_ speed: Double) -> String {
        if speed >= 1.0 {
            return String(format: "%.2f MB/s", speed)
        } else if speed >= 0.001 {
            return String(format: "%.0f KB/s", speed * 1024)
        } else {
            return "0 B/s"
        }
    }
    
    private func updateHistory() {
        // Update CPU history
        cpuHistory.removeFirst()
        cpuHistory.append(systemMonitor.cpuLoad)
        
        // Update RAM history
        ramHistory.removeFirst()
        ramHistory.append(systemMonitor.ramUsage)
        
        // Update Network history
        networkUpHistory.removeFirst()
        networkUpHistory.append(systemMonitor.uploadSpeed)
        
        networkDownHistory.removeFirst()
        networkDownHistory.append(systemMonitor.downloadSpeed)
    }
}

// MARK: - Chart Views

struct CPUChart: View {
    let data: [Double]
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard !data.isEmpty else { return }
                
                let width = geometry.size.width
                let height = geometry.size.height
                let stepX = width / CGFloat(data.count - 1)
                
                for (index, value) in data.enumerated() {
                    let x = CGFloat(index) * stepX
                    let y = height - (CGFloat(value) / 100.0) * height
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            
            // Add fill area
            Path { path in
                guard !data.isEmpty else { return }
                
                let width = geometry.size.width
                let height = geometry.size.height
                let stepX = width / CGFloat(data.count - 1)
                
                path.move(to: CGPoint(x: 0, y: height))
                
                for (index, value) in data.enumerated() {
                    let x = CGFloat(index) * stepX
                    let y = height - (CGFloat(value) / 100.0) * height
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                
                path.addLine(to: CGPoint(x: geometry.size.width, y: height))
                path.closeSubpath()
            }
            .fill(LinearGradient(colors: [color.opacity(0.3), color.opacity(0.1)], startPoint: .top, endPoint: .bottom))
        }
    }
}

struct RAMChart: View {
    let data: [Double]
    let color: Color
    
    var body: some View {
        CPUChart(data: data, color: color)
    }
}

struct NetworkMiniChart: View {
    let data: [Double]
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard !data.isEmpty else { return }
                
                let width = geometry.size.width
                let height = geometry.size.height
                let stepX = width / CGFloat(data.count - 1)
                let maxValue = data.max() ?? 1.0
                
                for (index, value) in data.enumerated() {
                    let x = CGFloat(index) * stepX
                    let normalizedValue = maxValue > 0 ? value / maxValue : 0
                    let y = height - CGFloat(normalizedValue) * height
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
        }
    }
}

struct MemoryBar: View {
    let label: String
    let value: Double
    let total: Double
    let color: Color
    
    private var percentage: Double {
        total > 0 ? (value / total) * 100 : 0
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.gray)
                .frame(width: 70, alignment: .leading)
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(.gray.opacity(0.2))
                    .frame(height: 6)
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                    .frame(width: max(2, percentage * 1.5), height: 6)
                    .animation(.easeInOut(duration: 0.3), value: percentage)
            }
            
            Text("\(String(format: "%.1f", value)) GB")
                .font(.caption2)
                .foregroundStyle(.white)
                .frame(width: 50, alignment: .trailing)
        }
    }
}



struct SystemMonitorPopup_Previews: PreviewProvider {
    static var previews: some View {
        SystemMonitorPopup()
            .previewLayout(.sizeThatFits)
    }
} 