import Foundation
import HomeKit
import SwiftUI

class HomeKitManager: NSObject, ObservableObject {
    @Published var homeManager: HMHomeManager
    @Published var availableSpeakers: [HMAccessory] = []
    @Published var isAuthorized = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    override init() {
        self.homeManager = HMHomeManager()
        super.init()
        self.homeManager.delegate = self
        checkAuthorization()
    }
    
    func checkAuthorization() {
        let status = homeManager.authorizationStatus
        print("🏠 HomeKit authorization status: \(status.rawValue)")
        
        // Check if we're in simulator first
        #if targetEnvironment(simulator)
        print("🏠 Running in simulator - HomeKit is not available")
        DispatchQueue.main.async {
            self.isAuthorized = false
            self.errorMessage = "HomeKit is not available in the iOS Simulator. Please test on a physical device to use HomePod features."
        }
        return
        #endif
        
        // For HomeKit, we need to check if we can actually access homes
        // The authorization status might not be immediately accurate
        let canAccessHomes = !homeManager.homes.isEmpty || status == .authorized
        
        DispatchQueue.main.async {
            self.isAuthorized = canAccessHomes
        }
        
        if canAccessHomes {
            // Already authorized, load devices
            discoverSpeakers()
        } else {
            print("🏠 HomeKit not authorized, status: \(status.rawValue)")
            
            // Provide specific error messages based on authorization status
            DispatchQueue.main.async {
                switch status {
                case .restricted:
                    self.errorMessage = "HomeKit access is restricted. Please check your device settings and ensure HomeKit is enabled."
                default:
                    self.errorMessage = "HomeKit access unavailable. Please check your device settings."
                }
            }
        }
    }
    
    func requestAuthorization() {
        print("🏠 Requesting HomeKit authorization...")
        isLoading = true
        errorMessage = nil
        
        // Check if we're in simulator first
        #if targetEnvironment(simulator)
        DispatchQueue.main.async {
            self.isLoading = false
            self.errorMessage = "HomeKit is not available in the iOS Simulator. Please test on a physical device."
        }
        return
        #endif
        
        // First, try to access homes to trigger authorization if needed
        let homes = homeManager.homes
        print("🏠 Current homes count: \(homes.count)")
        
        // If we have homes, we're already authorized
        if !homes.isEmpty {
            DispatchQueue.main.async {
                self.isLoading = false
                self.checkAuthorization()
            }
            return
        }
        
        // If no homes, try to create one to trigger the permission dialog
        homeManager.addHome(withName: "RoadmapGoals Home") { [weak self] home, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    print("🏠 Error creating home: \(error.localizedDescription)")
                    
                    // Check for specific error codes
                    let nsError = error as NSError
                    if nsError.code == 4097 {
                        self?.errorMessage = "HomeKit service unavailable (Error 4097). This usually means:\n\n1. HomeKit is disabled in Settings\n2. Device needs to be restarted\n3. HomeKit service is not running\n\nPlease try:\n• Settings > Privacy & Security > HomeKit (enable if disabled)\n• Restart your iPhone\n• Check if Home app works"
                    } else if error.localizedDescription.contains("connection") || 
                       error.localizedDescription.contains("service") {
                        self?.errorMessage = "HomeKit service unavailable. Please ensure HomeKit is enabled in Settings and try again."
                    } else if error.localizedDescription.contains("authorized") || 
                       error.localizedDescription.contains("permission") {
                        self?.errorMessage = "HomeKit access denied. Please enable HomeKit access in Settings > Privacy & Security > HomeKit."
                    } else {
                        self?.errorMessage = "Failed to create home: \(error.localizedDescription)"
                    }
                } else {
                    print("🏠 Home created successfully")
                    self?.checkAuthorization()
                }
            }
        }
    }
    
    func loadHomes() {
        isLoading = true
        errorMessage = nil
        
        // Access homes to trigger authorization if needed
        let homes = homeManager.homes
        
        if homes.isEmpty {
            // Create a default home if none exists
            homeManager.addHome(withName: "My Home") { [weak self] home, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.errorMessage = "Failed to create home: \(error.localizedDescription)"
                    } else {
                        self?.discoverSpeakers()
                    }
                }
            }
        } else {
            discoverSpeakers()
        }
    }
    
    func discoverSpeakers() {
        isLoading = true
        availableSpeakers.removeAll()
        
        for home in homeManager.homes {
            for accessory in home.accessories {
                // Look for HomePod and other audio accessories
                if isAudioAccessory(accessory) {
                    availableSpeakers.append(accessory)
                }
            }
        }
        
        DispatchQueue.main.async {
            self.isLoading = false
            print("🏠 Found \(self.availableSpeakers.count) audio accessories")
        }
    }
    
    private func isAudioAccessory(_ accessory: HMAccessory) -> Bool {
        // Check if accessory is a HomePod or other audio device
        let name = accessory.name.lowercased()
        let model = accessory.model?.lowercased() ?? ""
        
        return name.contains("homepod") || 
               name.contains("speaker") || 
               model.contains("homepod") ||
               accessory.services.contains { service in
                   service.serviceType == HMServiceTypeSpeaker
               }
    }
    
    func playAudioOnSpeaker(_ speaker: HMAccessory, audioURL: URL) {
        // Find the speaker service
        guard let speakerService = speaker.services.first(where: { 
            $0.serviceType == HMServiceTypeSpeaker 
        }) else {
            print("❌ No speaker service found for \(speaker.name)")
            return
        }
        
        // This is a simplified implementation
        // In a real app, you would need to implement the actual audio streaming
        // to the HomePod using AirPlay or HomeKit audio services
        
        print("🎵 Attempting to play audio on \(speaker.name)")
        print("🎵 Audio URL: \(audioURL)")
        
        // For now, we'll just log the attempt
        // Real implementation would require:
        // 1. AirPlay integration
        // 2. HomeKit audio service commands
        // 3. Background audio session management
    }
    
    func refreshSpeakers() {
        discoverSpeakers()
    }
    
    func forceRefreshAuthorization() {
        print("🏠 Force refreshing HomeKit authorization...")
        isLoading = true
        errorMessage = nil
        
        // Force a fresh check by accessing homes
        let _ = homeManager.homes
        
        // Wait a moment for any async operations to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.checkAuthorization()
            self.isLoading = false
        }
    }
}

// MARK: - HMHomeManagerDelegate

extension HomeKitManager: HMHomeManagerDelegate {
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        print("🏠 HomeManager did update homes")
        DispatchQueue.main.async {
            self.checkAuthorization()
            if self.isAuthorized {
                self.discoverSpeakers()
            }
        }
    }
    
    func homeManager(_ manager: HMHomeManager, didAdd home: HMHome) {
        print("🏠 Home added: \(home.name)")
        DispatchQueue.main.async {
            self.checkAuthorization()
            if self.isAuthorized {
                self.discoverSpeakers()
            }
        }
    }
    
    func homeManager(_ manager: HMHomeManager, didRemove home: HMHome) {
        print("🏠 Home removed: \(home.name)")
        DispatchQueue.main.async {
            self.checkAuthorization()
            if self.isAuthorized {
                self.discoverSpeakers()
            }
        }
    }
}

// MARK: - HomeKit Speaker Model

struct HomeKitSpeaker: Identifiable, Hashable {
    let id: String
    let name: String
    let model: String
    let isReachable: Bool
    let accessory: HMAccessory
    
    init(from accessory: HMAccessory) {
        self.id = accessory.uniqueIdentifier.uuidString
        self.name = accessory.name
        self.model = accessory.model ?? "Unknown"
        self.isReachable = accessory.isReachable
        self.accessory = accessory
    }
    
    var displayName: String {
        return name
    }
    
    var icon: String {
        let name = self.name.lowercased()
        if name.contains("homepod") {
            return "homepod"
        } else if name.contains("mini") {
            return "homepod.mini"
        } else {
            return "speaker.wave.2"
        }
    }
    
    var statusText: String {
        return isReachable ? "Available" : "Unavailable"
    }
    
    var statusColor: String {
        return isReachable ? "green" : "red"
    }
}
