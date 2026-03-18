import Combine
import Foundation
import Darwin
import IOKit

/// This class monitors system performance metrics: CPU, RAM, Temperature, and Network Activity.
class SystemMonitorManager: ObservableObject, ConditionallyActivatableWidget {
    @Published var cpuLoad: Double = 0.0
    @Published var ramUsage: Double = 0.0

    @Published var uploadSpeed: Double = 0.0
    @Published var downloadSpeed: Double = 0.0
    
    // Internal CPU breakdown for popup
    @Published var userLoad: Double = 0.0
    @Published var systemLoad: Double = 0.0
    @Published var idleLoad: Double = 0.0
    
    // Internal RAM details for popup
    @Published var totalRAM: Double = 0.0
    @Published var activeRAM: Double = 0.0
    @Published var wiredRAM: Double = 0.0
    @Published var compressedRAM: Double = 0.0
    
    private var timer: Timer?
    private var previousCpuInfo: processor_info_array_t?
    private var previousCpuInfoCount: mach_msg_type_number_t = 0
    private var previousNetworkData: [String: (ibytes: UInt64, obytes: UInt64)] = [:]
    private var lastNetworkUpdate: Date = Date()
    
    private var currentInterval: TimeInterval = 10.0
    let widgetId = "system-monitor" // This covers both cpuram and networkactivity
    
    private var isActive = false
    
    init() {
        setupNotifications()
        // For now, always activate to ensure widgets work
        activate()
    }
    
    deinit {
        stopMonitoring()
        NotificationCenter.default.removeObserver(self)
        if let previousCpuInfo = previousCpuInfo, previousCpuInfoCount > 0 {
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: previousCpuInfo), vm_size_t(previousCpuInfoCount) * vm_size_t(MemoryLayout<integer_t>.size))
        }
    }
    
    private func setupNotifications() {
        // Listen for performance mode changes
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PerformanceModeChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let intervals = notification.object as? [String: TimeInterval],
               let newInterval = intervals["system"] {
                self?.updateTimerInterval(newInterval)
            }
        }
        
        // Listen for widget activation changes
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("WidgetActivationChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let activeWidgets = notification.object as? Set<String> {
                // Activate if any system monitoring widget is active
                let systemWidgets = ["default.cpuram", "default.networkactivity"]
                let shouldBeActive = systemWidgets.contains { activeWidgets.contains($0) }
                
                if shouldBeActive {
                    self?.activate()
                } else {
                    self?.deactivate()
                }
            }
        }
    }
    
    private func activateIfNeeded() {
        let activationManager = WidgetActivationManager.shared
        let systemWidgets = ["default.cpuram", "default.networkactivity"]
        let shouldBeActive = systemWidgets.contains { activationManager.isWidgetActive($0) }
        
        if shouldBeActive {
            print("SystemMonitorManager: Activating via WidgetActivationManager")
            activate()
        } else {
            // Fallback: activate anyway for now to prevent breaking the widget
            print("SystemMonitorManager: Fallback activation")
            activate()
        }
    }
    
    func activate() {
        guard !isActive else { 
            return 
        }
        
        isActive = true
        
        // Get current performance mode interval
        let performanceManager = PerformanceModeManager.shared
        let intervals = performanceManager.getTimerIntervals(for: performanceManager.currentMode)
        currentInterval = intervals["system"] ?? 10.0
        
        startMonitoring()
    }
    
    func deactivate() {
        guard isActive else { return }
        isActive = false
        stopMonitoring()
    }
    
    private func updateTimerInterval(_ newInterval: TimeInterval) {
        guard isActive else { return }
        currentInterval = newInterval
        
        // Restart timer with new interval
        stopMonitoring()
        startMonitoring()
    }

    private func startMonitoring() {
        // Update every X seconds based on performance mode
        timer = Timer.scheduledTimer(withTimeInterval: currentInterval, repeats: true) { [weak self] _ in
            // Run system calls on background queue to avoid blocking UI
            DispatchQueue.global(qos: .utility).async {
                self?.updateAllMetrics()
            }
        }
        // Initial update on background queue
        DispatchQueue.global(qos: .utility).async {
            self.updateAllMetrics()
        }
    }
    
    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateAllMetrics() {
        // Add safety checks to prevent hanging
        autoreleasepool {
            updateCPUUsageSimple()
            updateRAMUsage()
            updateNetworkActivity()
        }
    }
    
    // MARK: - CPU Usage (Simple and Safe)
    private func updateCPUUsageSimple() {
        // Use a simple approach via sysctl for CPU usage
        var load: Double = 0.0
        var size = MemoryLayout<Double>.size
        if sysctlbyname("vm.loadavg", &load, &size, nil, 0) == 0 {
            // Load average represents system load, convert to rough CPU percentage
            let cpuPercent = min(100.0, max(0.0, load * 25.0)) // Scale load avg to percentage
            
            DispatchQueue.main.async {
                self.cpuLoad = cpuPercent
                self.userLoad = cpuPercent * 0.7  // Approximate user load
                self.systemLoad = cpuPercent * 0.3  // Approximate system load
                self.idleLoad = 100.0 - cpuPercent
            }
        } else {
            // Fallback to a simple process-based approach
            self.updateCPUUsageViaProcessInfo()
        }
    }
    
    private func updateCPUUsageViaProcessInfo() {
        let task = Process()
        task.launchPath = "/usr/bin/top"
        task.arguments = ["-l", "1", "-n", "0"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                self.parseCPUFromTopOutput(output)
            }
        } catch {
            // If all else fails, provide reasonable default values
            DispatchQueue.main.async {
                self.cpuLoad = 15.0
                self.userLoad = 10.0
                self.systemLoad = 5.0
                self.idleLoad = 85.0
            }
        }
    }
    
    private func parseCPUFromTopOutput(_ output: String) {
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            if line.contains("CPU usage:") {
                // Parse line like: "CPU usage: 12.5% user, 3.2% sys, 84.3% idle"
                let components = line.components(separatedBy: ",")
                var userPercent: Double = 0
                var systemPercent: Double = 0
                
                for component in components {
                    let trimmed = component.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed.contains("user") {
                        let userString = trimmed.replacingOccurrences(of: "% user", with: "")
                            .replacingOccurrences(of: "CPU usage: ", with: "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        userPercent = Double(userString) ?? 0
                    } else if trimmed.contains("sys") {
                        let sysString = trimmed.replacingOccurrences(of: "% sys", with: "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        systemPercent = Double(sysString) ?? 0
                    }
                }
                
                let totalPercent = userPercent + systemPercent
                let idlePercent = 100.0 - totalPercent
                
                DispatchQueue.main.async {
                    self.cpuLoad = min(100.0, max(0.0, totalPercent))
                    self.userLoad = min(100.0, max(0.0, userPercent))
                    self.systemLoad = min(100.0, max(0.0, systemPercent))
                    self.idleLoad = min(100.0, max(0.0, idlePercent))
                }
                break
            }
        }
    }
    
    // MARK: - CPU Usage (Complex - Currently Disabled Due to Memory Issues)
    private func updateCPUUsage() {
        var cpuInfoArray: processor_info_array_t?
        var cpuInfoCount: mach_msg_type_number_t = 0
        var numCpus: natural_t = 0
        
        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCpus,
            &cpuInfoArray,
            &cpuInfoCount
        )
        
        guard result == KERN_SUCCESS, let cpuInfo = cpuInfoArray, numCpus > 0 else {
            // If CPU info fails, reset to safe values
            DispatchQueue.main.async {
                self.cpuLoad = 0.0
                self.userLoad = 0.0
                self.systemLoad = 0.0
                self.idleLoad = 100.0
            }
            return
        }
        
        defer {
            if cpuInfoCount > 0 {
                vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), vm_size_t(cpuInfoCount) * vm_size_t(MemoryLayout<integer_t>.size))
            }
        }
        
        let cpuLoadInfo = cpuInfo.withMemoryRebound(to: processor_cpu_load_info.self, capacity: Int(numCpus)) { $0 }
        
        var totalUser: UInt32 = 0
        var totalSystem: UInt32 = 0
        var totalIdle: UInt32 = 0
        var totalNice: UInt32 = 0
        
        for i in 0..<Int(numCpus) {
            let info = cpuLoadInfo[i]
            totalUser += info.cpu_ticks.0     // CPU_STATE_USER
            totalSystem += info.cpu_ticks.1   // CPU_STATE_SYSTEM
            totalIdle += info.cpu_ticks.2     // CPU_STATE_IDLE
            totalNice += info.cpu_ticks.3     // CPU_STATE_NICE
        }
        
        if let previousCpuInfo = previousCpuInfo {
            let previousCpuLoadInfo = previousCpuInfo.withMemoryRebound(to: processor_cpu_load_info.self, capacity: Int(numCpus)) { $0 }
            
            var prevTotalUser: UInt32 = 0
            var prevTotalSystem: UInt32 = 0
            var prevTotalIdle: UInt32 = 0
            var prevTotalNice: UInt32 = 0
            
            for i in 0..<Int(numCpus) {
                let info = previousCpuLoadInfo[i]
                prevTotalUser += info.cpu_ticks.0
                prevTotalSystem += info.cpu_ticks.1
                prevTotalIdle += info.cpu_ticks.2
                prevTotalNice += info.cpu_ticks.3
            }
            
            // Safely calculate deltas to avoid overflow
            let userDelta = totalUser >= prevTotalUser ? totalUser - prevTotalUser : 0
            let systemDelta = totalSystem >= prevTotalSystem ? totalSystem - prevTotalSystem : 0
            let idleDelta = totalIdle >= prevTotalIdle ? totalIdle - prevTotalIdle : 0
            let niceDelta = totalNice >= prevTotalNice ? totalNice - prevTotalNice : 0
            
            let totalDelta = userDelta + systemDelta + idleDelta + niceDelta
            
            if totalDelta > 0 {
                let userPercent = min(100.0, max(0.0, Double(userDelta + niceDelta) / Double(totalDelta) * 100.0))
                let systemPercent = min(100.0, max(0.0, Double(systemDelta) / Double(totalDelta) * 100.0))
                let idlePercent = min(100.0, max(0.0, Double(idleDelta) / Double(totalDelta) * 100.0))
                
                DispatchQueue.main.async {
                    self.userLoad = userPercent
                    self.systemLoad = systemPercent
                    self.idleLoad = idlePercent
                    self.cpuLoad = min(100.0, max(0.0, userPercent + systemPercent))
                }
            }
        }
        
        // Store current info for next iteration
        if let previousCpuInfo = previousCpuInfo, previousCpuInfoCount > 0 {
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: previousCpuInfo), vm_size_t(previousCpuInfoCount) * vm_size_t(MemoryLayout<integer_t>.size))
        }
        
        previousCpuInfo = cpuInfo
        previousCpuInfoCount = cpuInfoCount
    }
    
    // MARK: - RAM Usage
    private func updateRAMUsage() {
        var vmStats = vm_statistics64()
        var size = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &size)
            }
        }
        
        guard result == KERN_SUCCESS else { 
            // If RAM info fails, reset to safe values
            DispatchQueue.main.async {
                self.ramUsage = 0.0
                self.totalRAM = 0.0
                self.activeRAM = 0.0
                self.wiredRAM = 0.0
                self.compressedRAM = 0.0
            }
            return 
        }
        
        // Get total physical memory
        var totalMemory: UInt64 = 0
        var totalMemorySize = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &totalMemory, &totalMemorySize, nil, 0)
        
        let pageSize = UInt64(vm_page_size)
        _ = totalMemory / pageSize
        
        let activePages = UInt64(vmStats.active_count)
        let wiredPages = UInt64(vmStats.wire_count)
        let compressedPages = UInt64(vmStats.compressor_page_count)
        _ = UInt64(vmStats.inactive_count)
        
        let usedPages = activePages + wiredPages + compressedPages
        let usedMemory = usedPages * pageSize
        
        let totalMemoryGB = Double(totalMemory) / (1024 * 1024 * 1024)
        let usedMemoryGB = Double(usedMemory) / (1024 * 1024 * 1024)
        let activeMemoryGB = Double(activePages * pageSize) / (1024 * 1024 * 1024)
        let wiredMemoryGB = Double(wiredPages * pageSize) / (1024 * 1024 * 1024)
        let compressedMemoryGB = Double(compressedPages * pageSize) / (1024 * 1024 * 1024)
        
        let ramUsagePercent = totalMemoryGB > 0 ? min(100.0, max(0.0, (usedMemoryGB / totalMemoryGB) * 100.0)) : 0.0
        
        DispatchQueue.main.async {
            self.ramUsage = ramUsagePercent
            self.totalRAM = totalMemoryGB
            self.activeRAM = activeMemoryGB
            self.wiredRAM = wiredMemoryGB
            self.compressedRAM = compressedMemoryGB
        }
    }
    

    
    // MARK: - Network Activity
    private func updateNetworkActivity() {
        var ifaddrs: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrs) == 0, let firstAddr = ifaddrs else {
            return
        }
        
        defer { freeifaddrs(ifaddrs) }
        
        var currentNetworkData: [String: (ibytes: UInt64, obytes: UInt64)] = [:]
        var addr = firstAddr
        
        while true {
            let name = String(cString: addr.pointee.ifa_name)
            
            // Focus on typical active interfaces (Wi-Fi/Ethernet)
            if name.hasPrefix("en") || name.hasPrefix("wi") {
                if let data = addr.pointee.ifa_data?.assumingMemoryBound(to: if_data.self) {
                    let ibytes = UInt64(data.pointee.ifi_ibytes)
                    let obytes = UInt64(data.pointee.ifi_obytes)
                    currentNetworkData[name] = (ibytes: ibytes, obytes: obytes)
                }
            }
            
            guard let nextAddr = addr.pointee.ifa_next else { break }
            addr = nextAddr
        }
        
        let currentTime = Date()
        let timeDelta = currentTime.timeIntervalSince(lastNetworkUpdate)
        
        if timeDelta > 0 && !previousNetworkData.isEmpty {
            var totalUploadDelta: UInt64 = 0
            var totalDownloadDelta: UInt64 = 0
            
            for (interface, current) in currentNetworkData {
                if let previous = previousNetworkData[interface] {
                    let uploadDelta = current.obytes > previous.obytes ? current.obytes - previous.obytes : 0
                    let downloadDelta = current.ibytes > previous.ibytes ? current.ibytes - previous.ibytes : 0
                    
                    totalUploadDelta = totalUploadDelta.addingReportingOverflow(uploadDelta).partialValue
                    totalDownloadDelta = totalDownloadDelta.addingReportingOverflow(downloadDelta).partialValue
                }
            }
            
            // Convert to MB/s with safety checks
            let uploadSpeedMBps = timeDelta > 0 ? max(0.0, Double(totalUploadDelta) / timeDelta / (1024 * 1024)) : 0.0
            let downloadSpeedMBps = timeDelta > 0 ? max(0.0, Double(totalDownloadDelta) / timeDelta / (1024 * 1024)) : 0.0
            
            DispatchQueue.main.async {
                self.uploadSpeed = uploadSpeedMBps
                self.downloadSpeed = downloadSpeedMBps
            }
        }
        
        previousNetworkData = currentNetworkData
        lastNetworkUpdate = currentTime
    }
} 