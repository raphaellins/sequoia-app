import Foundation
import AVFoundation
import MediaPlayer
import SwiftUI

class AirPlayManager: NSObject, ObservableObject {
    @Published var availableDevices: [AirPlayDevice] = []
    @Published var isScanning = false
    @Published var errorMessage: String?
    
    private var audioSession: AVAudioSession
    private var routeChangeObserver: NSObjectProtocol?
    
    override init() {
        self.audioSession = AVAudioSession.sharedInstance()
        super.init()
        setupAudioSession()
        startScanning()
    }
    
    deinit {
        if let observer = routeChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("❌ Failed to setup audio session: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Failed to setup audio session: \(error.localizedDescription)"
            }
        }
    }
    
    func startScanning() {
        print("🎵 Starting AirPlay device scanning...")
        isScanning = true
        errorMessage = nil
        
        // Get available AirPlay routes
        updateAvailableDevices()
        
        // Listen for route changes
        routeChangeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateAvailableDevices()
        }
        
        // Also listen for media player route changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: .MPVolumeViewWirelessRouteActiveDidChange,
            object: nil
        )
    }
    
    @objc private func handleRouteChange() {
        updateAvailableDevices()
    }
    
    private func updateAvailableDevices() {
        var devices: [AirPlayDevice] = []
        
        // Get current audio route
        let currentRoute = audioSession.currentRoute
        
        // Add built-in device
        devices.append(AirPlayDevice(
            id: "built-in",
            name: "iPhone Speaker",
            type: .builtIn,
            isConnected: currentRoute.outputs.contains { $0.portType == .builtInSpeaker }
        ))
        
        // Add AirPlay devices
        for output in currentRoute.outputs {
            if output.portType == .airPlay {
                devices.append(AirPlayDevice(
                    id: output.uid,
                    name: output.portName,
                    type: .airPlay,
                    isConnected: true
                ))
            }
        }
        
        // Add Bluetooth devices
        for output in currentRoute.outputs {
            if output.portType == .bluetoothA2DP || output.portType == .bluetoothHFP {
                devices.append(AirPlayDevice(
                    id: output.uid,
                    name: output.portName,
                    type: .bluetooth,
                    isConnected: true
                ))
            }
        }
        
        // Add available AirPlay destinations (if any)
        // Note: iOS doesn't provide a direct way to discover AirPlay devices
        // We'll rely on the system's AirPlay picker and route changes
        
        DispatchQueue.main.async {
            self.availableDevices = devices
            self.isScanning = false
            print("🎵 Found \(devices.count) audio devices")
        }
    }
    
    func selectDevice(_ device: AirPlayDevice) {
        print("🎵 Selecting device: \(device.name)")
        
        switch device.type {
        case .builtIn:
            // Switch to built-in speaker
            do {
                try audioSession.overrideOutputAudioPort(.speaker)
                updateAvailableDevices()
            } catch {
                print("❌ Failed to switch to built-in speaker: \(error)")
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to switch to built-in speaker: \(error.localizedDescription)"
                }
            }
            
        case .airPlay, .bluetooth:
            // For AirPlay and Bluetooth, we need to use the system picker
            // This will be handled by the UI with MPVolumeView
            break
        }
    }
    
    func playAudioOnDevice(_ device: AirPlayDevice, audioURL: URL) {
        print("🎵 Attempting to play audio on \(device.name)")
        print("🎵 Audio URL: \(audioURL)")
        
        // This is a simplified implementation
        // In a real app, you would:
        // 1. Set up the audio session for the selected route
        // 2. Use AVAudioPlayer or AVPlayer to play the audio
        // 3. The system will automatically route to the selected device
        
        // For now, we'll just log the attempt
        // The actual audio playback will be handled by AudioStore
    }
    
    func refreshDevices() {
        updateAvailableDevices()
    }
}

// MARK: - AirPlay Device Model

struct AirPlayDevice: Identifiable, Hashable {
    let id: String
    let name: String
    let type: AirPlayDeviceType
    let isConnected: Bool
    
    var displayName: String {
        return name
    }
    
    var icon: String {
        switch type {
        case .builtIn:
            return "speaker.wave.2"
        case .airPlay:
            return "airplayvideo"
        case .bluetooth:
            return "bluetooth"
        }
    }
    
    var statusText: String {
        return isConnected ? "Connected" : "Available"
    }
    
    var statusColor: String {
        return isConnected ? "green" : "blue"
    }
}

enum AirPlayDeviceType: String, CaseIterable {
    case builtIn = "built-in"
    case airPlay = "airplay"
    case bluetooth = "bluetooth"
    
    var displayName: String {
        switch self {
        case .builtIn:
            return "Built-in Speaker"
        case .airPlay:
            return "AirPlay"
        case .bluetooth:
            return "Bluetooth"
        }
    }
}
