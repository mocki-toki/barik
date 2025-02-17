import Combine
import Foundation

class LayoutManager: ObservableObject {
    @Published var layout: String = "bsp"
    
    private var timer: Timer?
    private let provider = YabaiSpacesProvider()
    
    init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateLayout()
        }
        updateLayout()
    }
    
    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
     func toggleLayout(){
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self,
                  let spaces = self.provider.getSpacesWithWindows(),
                  let currentSpace = spaces.first else {
                    DispatchQueue.main.async {
                    self?.layout = "Unknown"
                    }
                return
            }
            
            self.provider.toggleLayout(for: currentSpace)
            }
    }
    
    
    private func updateLayout() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self,
                  let spaces = self.provider.getSpacesWithWindows(),
                  let currentSpace = spaces.first else {
                DispatchQueue.main.async {
                    self?.layout = "Unknown"
                }
                return
            }
            
            let newLayout = self.provider.getSpaceLayout(for: currentSpace)
            if newLayout != self.layout {
                DispatchQueue.main.async {
                    self.layout = newLayout
                }
            }
        }
    }
}
