import Combine
import Foundation
import CoreAudio
import IOKit
import IOKit.graphics

/// Central manager for audio and visual system controls.
class AudioVisualManager: ObservableObject {
    @Published var volumeLevel: Float = 0.0
    @Published var isMuted: Bool = false
    
    private var timer: Timer?
    private var audioObjectPropertyAddress: AudioObjectPropertyAddress
    
    init() {
        audioObjectPropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    private func startMonitoring() {
        // Update every 10 seconds for optimal energy efficiency
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.updateStatus()
        }
        updateStatus()
    }
    
    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    /// Updates all audio and visual status properties
    private func updateStatus() {
        self.updateVolumeStatus()
    }
    
    /// Updates volume level and mute status
    private func updateVolumeStatus() {
        // Run audio API calls on background queue to avoid blocking
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            var outputDeviceID: AudioDeviceID = kAudioObjectUnknown
            var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
            
            var propertyAddress = AudioObjectPropertyAddress(
                mSelector: kAudioHardwarePropertyDefaultOutputDevice,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            
            let result = AudioObjectGetPropertyData(
                AudioObjectID(kAudioObjectSystemObject),
                &propertyAddress,
                0,
                nil,
                &propertySize,
                &outputDeviceID
            )
            
            guard result == noErr && outputDeviceID != kAudioObjectUnknown else { 
                DispatchQueue.main.async {
                    self.volumeLevel = 0.0
                    self.isMuted = false
                }
                return 
            }
            
            // Get volume level - using master volume property
            var volume: Float32 = 0.0
            propertySize = UInt32(MemoryLayout<Float32>.size)
            propertyAddress.mSelector = kAudioDevicePropertyVolumeScalar
            propertyAddress.mScope = kAudioObjectPropertyScopeOutput
            propertyAddress.mElement = kAudioObjectPropertyElementMain
            
            let volumeResult = AudioObjectGetPropertyData(
                outputDeviceID,
                &propertyAddress,
                0,
                nil,
                &propertySize,
                &volume
            )
            
            // Get mute status
            var muteValue: UInt32 = 0
            propertySize = UInt32(MemoryLayout<UInt32>.size)
            propertyAddress.mSelector = kAudioDevicePropertyMute
            propertyAddress.mScope = kAudioObjectPropertyScopeOutput
            propertyAddress.mElement = kAudioObjectPropertyElementMain
            
            let muteResult = AudioObjectGetPropertyData(
                outputDeviceID,
                &propertyAddress,
                0,
                nil,
                &propertySize,
                &muteValue
            )
            
            // Update UI on main queue
            DispatchQueue.main.async {
                if volumeResult == noErr {
                    self.volumeLevel = max(0.0, min(1.0, volume))
                } else {
                    // Fallback: keep current volume or set to reasonable default
                    if self.volumeLevel == 0.0 {
                        self.volumeLevel = 0.5
                    }
                }
                
                if muteResult == noErr {
                    self.isMuted = muteValue != 0
                } else {
                    // If we can't determine mute status, assume not muted
                    self.isMuted = false
                }
            }
        }
    }
    

    
    // MARK: - Control Methods
    
    /// Sets the system volume level
    func setVolume(level: Float) {
        let clampedLevel = max(0.0, min(1.0, level))
        
        var outputDeviceID: AudioDeviceID = kAudioObjectUnknown
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let result = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &outputDeviceID
        )
        
        guard result == noErr else { return }
        
        var volume = Float32(clampedLevel)
        propertySize = UInt32(MemoryLayout<Float32>.size)
        propertyAddress.mSelector = kAudioDevicePropertyVolumeScalar
        propertyAddress.mScope = kAudioObjectPropertyScopeOutput
        propertyAddress.mElement = kAudioObjectPropertyElementMain
        
        AudioObjectSetPropertyData(
            outputDeviceID,
            &propertyAddress,
            0,
            nil,
            propertySize,
            &volume
        )
        
        DispatchQueue.main.async {
            self.volumeLevel = clampedLevel
        }
    }
    
    /// Toggles the mute status
    func toggleMute() {
        var outputDeviceID: AudioDeviceID = kAudioObjectUnknown
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let result = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &outputDeviceID
        )
        
        guard result == noErr else { return }
        
        let newMuteValue: UInt32 = isMuted ? 0 : 1
        var muteValue = newMuteValue
        propertySize = UInt32(MemoryLayout<UInt32>.size)
        propertyAddress.mSelector = kAudioDevicePropertyMute
        
        AudioObjectSetPropertyData(
            outputDeviceID,
            &propertyAddress,
            0,
            nil,
            propertySize,
            &muteValue
        )
        
        DispatchQueue.main.async {
            self.isMuted = newMuteValue != 0
        }
    }
    

} 