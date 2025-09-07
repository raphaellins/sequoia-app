import Foundation
import SwiftUI
import AVFoundation
import AVKit
import HomeKit
import UserNotifications
import BackgroundTasks

class AudioStore: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var audioFiles: [AudioFile] = []
    @Published var isPlaying: Bool = false
    @Published var currentAudioFile: AudioFile?
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    
    private let saveKey = "SavedAudioFiles"
    private let backupKey = "SavedAudioFilesBackup"
    private var audioPlayer: AVAudioPlayer?
    private var playbackTimer: Timer?
    private var homeKitManager: HomeKitManager?
    private var schedulingTimer: Timer?
    private var volumeFadeTimer: Timer?
    
    override init() {
        super.init()
        print("🎵 AudioStore.init: Starting initialization")
        setupAudioSession()
        loadAudioFiles()
        setupHomeKit()
        setupScheduling()
        requestNotificationPermission()
        print("🎵 AudioStore.init: Initialization complete. Audio files count: \(audioFiles.count)")
    }
    
    private func setupHomeKit() {
        homeKitManager = HomeKitManager()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Configure for background playback
            try audioSession.setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetooth])
            
            // Activate the audio session
            try audioSession.setActive(true)
            
            print("🔊 AudioStore.setupAudioSession: Audio session configured for background playback")
        } catch {
            print("❌ AudioStore.setupAudioSession: Failed to configure audio session: \(error)")
        }
    }
    
    deinit {
        schedulingTimer?.invalidate()
        playbackTimer?.invalidate()
        volumeFadeTimer?.invalidate()
    }
    
    // MARK: - File Management
    
    func addAudioFile(_ audioFile: AudioFile) {
        print("➕ AudioStore.addAudioFile: Adding audio file '\(audioFile.name)'")
        audioFiles.append(audioFile)
        print("➕ AudioStore.addAudioFile: Audio files count after adding: \(audioFiles.count)")
        saveAudioFiles()
    }
    
    func deleteAudioFile(_ audioFile: AudioFile) {
        // Stop playback if this file is currently playing
        if currentAudioFile?.id == audioFile.id {
            stopPlayback()
        }
        
        // Remove the physical file
        if let fileURL = audioFile.fileURL {
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        audioFiles.removeAll { $0.id == audioFile.id }
        saveAudioFiles()
    }
    
    func updateAudioFile(_ audioFile: AudioFile) {
        if let index = audioFiles.firstIndex(where: { $0.id == audioFile.id }) {
            audioFiles[index] = audioFile
            saveAudioFiles()
        }
    }
    
    // MARK: - File Upload
    
    func importAudioFile(from url: URL) async -> AudioFile? {
        print("🎵 AudioStore.importAudioFile: Starting import from \(url)")
        
        do {
            // Get file attributes
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = fileAttributes[.size] as? Int64 ?? 0
            print("🎵 File size: \(fileSize) bytes")
            
            // Create documents directory if it doesn't exist
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioDirectory = documentsPath.appendingPathComponent("AudioFiles")
            print("🎵 Audio directory: \(audioDirectory)")
            
            if !FileManager.default.fileExists(atPath: audioDirectory.path) {
                try FileManager.default.createDirectory(at: audioDirectory, withIntermediateDirectories: true)
                print("🎵 Created audio directory")
            }
            
            // Generate unique filename
            let fileName = "\(UUID().uuidString).mp3"
            let destinationURL = audioDirectory.appendingPathComponent(fileName)
            print("🎵 Destination URL: \(destinationURL)")
            
            // Copy file to documents directory
            try FileManager.default.copyItem(at: url, to: destinationURL)
            print("🎵 File copied successfully")
            
            // Get audio duration - handle potential audio format issues
            var duration: TimeInterval = 0
            
            // Try AVAudioPlayer first
            do {
                let audioPlayer = try AVAudioPlayer(contentsOf: destinationURL)
                duration = audioPlayer.duration
                print("🎵 Audio duration (AVAudioPlayer): \(duration) seconds")
            } catch {
                print("⚠️ AVAudioPlayer failed, trying AVAsset: \(error)")
                
                // Fallback to AVAsset
                do {
                    let asset = AVAsset(url: destinationURL)
                    let durationValue = try await asset.load(.duration)
                    duration = CMTimeGetSeconds(durationValue)
                    print("🎵 Audio duration (AVAsset): \(duration) seconds")
                } catch {
                    print("⚠️ AVAsset also failed, using duration 0: \(error)")
                    // Continue with duration = 0, the file will still be imported
                }
            }
            
            // Create AudioFile object
            let audioFile = AudioFile(
                name: url.deletingPathExtension().lastPathComponent,
                fileName: fileName,
                fileURL: destinationURL,
                duration: duration,
                fileSize: fileSize
            )
            
            print("🎵 Created AudioFile: \(audioFile.name)")
            addAudioFile(audioFile)
            print("🎵 Added audio file to store")
            return audioFile
            
        } catch {
            print("❌ AudioStore.importAudioFile: Failed to import audio file: \(error)")
            return nil
        }
    }
    
    // MARK: - Playback Control
    
    func playAudio(_ audioFile: AudioFile) {
        guard let fileURL = audioFile.fileURL else {
            print("❌ AudioStore.playAudio: No file URL for audio file")
            return
        }
        
        // Stop current playback
        stopPlayback()
        
        // Check if this is a HomeKit device
        if let targetDevice = audioFile.targetDevice, targetDevice.isHomeKitDevice {
            playAudioOnHomeKitDevice(audioFile, fileURL: fileURL)
        } else {
            playAudioLocally(audioFile, fileURL: fileURL)
        }
    }
    
    private func playAudioLocally(_ audioFile: AudioFile, fileURL: URL) {
        do {
            // Ensure audio session is active for background playback
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(true)
            
            // Create new player
            audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            
            // Set initial volume based on fade-in setting
            if audioFile.volumeFadeIn {
                audioPlayer?.volume = 0.1 // Start at low volume
            } else {
                audioPlayer?.volume = 1.0 // Start at full volume
            }
            
            // Start playback
            if audioPlayer?.play() == true {
                currentAudioFile = audioFile
                isPlaying = true
                duration = audioPlayer?.duration ?? 0
                currentTime = 0
                
                // Update the audio file in the store
                if let index = audioFiles.firstIndex(where: { $0.id == audioFile.id }) {
                    audioFiles[index].isPlaying = true
                }
                
                // Start progress timer
                startProgressTimer()
                
                // Start volume fade-in if enabled
                if audioFile.volumeFadeIn {
                    startVolumeFadeIn(duration: audioFile.fadeInDuration)
                }
                
                print("▶️ AudioStore.playAudioLocally: Started playing '\(audioFile.name)' with fade-in: \(audioFile.volumeFadeIn)")
            } else {
                print("❌ AudioStore.playAudioLocally: Failed to start playback")
            }
            
        } catch {
            print("❌ AudioStore.playAudioLocally: Error creating audio player: \(error)")
        }
    }
    
    private func startVolumeFadeIn(duration: TimeInterval) {
        volumeFadeTimer?.invalidate()
        
        let startVolume: Float = 0.1
        let endVolume: Float = 1.0
        let fadeSteps = 50 // Number of steps for smooth fade
        let stepDuration = duration / Double(fadeSteps)
        let volumeStep = (endVolume - startVolume) / Float(fadeSteps)
        
        var currentStep = 0
        
        volumeFadeTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
            guard let self = self, let player = self.audioPlayer else {
                timer.invalidate()
                return
            }
            
            currentStep += 1
            let newVolume = startVolume + (volumeStep * Float(currentStep))
            
            if newVolume >= endVolume {
                player.volume = endVolume
                timer.invalidate()
                print("🔊 Volume fade-in completed")
            } else {
                player.volume = newVolume
            }
        }
    }
    
    private func playAudioOnHomeKitDevice(_ audioFile: AudioFile, fileURL: URL) {
        guard let homeKitManager = homeKitManager,
              let homeKitInfo = audioFile.targetDevice?.homeKitInfo else {
            print("❌ AudioStore.playAudioOnHomeKitDevice: No HomeKit info available")
            return
        }
        
        // Find the HomeKit accessory
        let speaker = homeKitManager.availableSpeakers.first { accessory in
            accessory.uniqueIdentifier.uuidString == homeKitInfo.id
        }
        
        guard let homeKitSpeaker = speaker else {
            print("❌ AudioStore.playAudioOnHomeKitDevice: HomeKit speaker not found")
            return
        }
        
        // Update current file and playing state
        currentAudioFile = audioFile
        isPlaying = true
        
        // Update the audio file in the store
        if let index = audioFiles.firstIndex(where: { $0.id == audioFile.id }) {
            audioFiles[index].isPlaying = true
        }
        
        // Attempt to play on HomeKit device
        homeKitManager.playAudioOnSpeaker(homeKitSpeaker, audioURL: fileURL)
        
        print("🎵 AudioStore.playAudioOnHomeKitDevice: Attempting to play '\(audioFile.name)' on '\(homeKitSpeaker.name)'")
    }
    
    func pausePlayback() {
        audioPlayer?.pause()
        isPlaying = false
        
        if let currentFile = currentAudioFile,
           let index = audioFiles.firstIndex(where: { $0.id == currentFile.id }) {
            audioFiles[index].isPlaying = false
        }
        
        print("⏸️ AudioStore.pausePlayback: Playback paused")
    }
    
    func resumePlayback() {
        if audioPlayer?.play() == true {
            isPlaying = true
            
            if let currentFile = currentAudioFile,
               let index = audioFiles.firstIndex(where: { $0.id == currentFile.id }) {
                audioFiles[index].isPlaying = true
            }
            
            print("▶️ AudioStore.resumePlayback: Playback resumed")
        }
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        
        if let currentFile = currentAudioFile,
           let index = audioFiles.firstIndex(where: { $0.id == currentFile.id }) {
            audioFiles[index].isPlaying = false
        }
        
        currentAudioFile = nil
        playbackTimer?.invalidate()
        playbackTimer = nil
        
        print("⏹️ AudioStore.stopPlayback: Playback stopped")
    }
    
    func seekToTime(_ time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
    }
    
    private func startProgressTimer() {
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            self.currentTime = player.currentTime
        }
    }
    
    // MARK: - Scheduling
    
    func scheduleAudio(_ audioFile: AudioFile, for date: Date, on device: AudioFile.AudioDevice, recurring: RecurringType = .none, volumeFadeIn: Bool = true, fadeInDuration: TimeInterval = 5.0) {
        var updatedFile = audioFile
        updatedFile.scheduledTime = date
        updatedFile.targetDevice = device
        updatedFile.isScheduled = true
        updatedFile.recurringType = recurring
        updatedFile.volumeFadeIn = volumeFadeIn
        updatedFile.fadeInDuration = fadeInDuration
        
        updateAudioFile(updatedFile)
        
        // Schedule local notification
        scheduleNotification(for: updatedFile, at: date)
        
        // Update scheduled files list
        updateScheduledFilesList()
        
        print("⏰ AudioStore.scheduleAudio: Scheduled '\(audioFile.name)' for \(date) on \(device.displayName) (recurring: \(recurring.displayName), fade-in: \(volumeFadeIn))")
    }
    
    func cancelScheduledAudio(_ audioFile: AudioFile) {
        var updatedFile = audioFile
        updatedFile.scheduledTime = nil
        updatedFile.targetDevice = nil
        updatedFile.isScheduled = false
        
        updateAudioFile(updatedFile)
        
        // Cancel notification
        cancelNotification(for: audioFile)
        
        // Update scheduled files list
        updateScheduledFilesList()
        
        print("❌ AudioStore.cancelScheduledAudio: Cancelled schedule for '\(audioFile.name)'")
    }
    
    private func setupScheduling() {
        // Register background task
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.example.RoadmapGoals.audio-scheduling", using: nil) { task in
            self.handleBackgroundAudioScheduling(task: task as! BGAppRefreshTask)
        }
        
        // Start a timer that checks for scheduled audio every 30 seconds
        schedulingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.checkScheduledAudio()
        }
        
        // Also check immediately
        checkScheduledAudio()
    }
    
    private func handleBackgroundAudioScheduling(task: BGAppRefreshTask) {
        // Schedule the next background task
        scheduleBackgroundTask()
        
        // Check for scheduled audio
        checkScheduledAudio()
        
        // Mark task as completed
        task.setTaskCompleted(success: true)
    }
    
    private func scheduleBackgroundTask() {
        let request = BGAppRefreshTaskRequest(identifier: "com.example.RoadmapGoals.audio-scheduling")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("🔄 Background task scheduled for audio scheduling")
        } catch {
            print("❌ Failed to schedule background task: \(error)")
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("🔔 Notification permission granted")
            } else {
                print("🔔 Notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    private func scheduleNotification(for audioFile: AudioFile, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Audio Scheduled"
        content.body = "'\(audioFile.name)' is about to play"
        content.sound = .default
        
        // Add user info to help with background playback
        content.userInfo = [
            "audioFileId": audioFile.id.uuidString,
            "audioFileName": audioFile.name,
            "deviceType": audioFile.targetDevice?.displayName ?? "iPhone"
        ]
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "audio_\(audioFile.id)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification: \(error)")
            } else {
                print("🔔 Scheduled notification for '\(audioFile.name)' at \(date)")
            }
        }
    }
    
    private func cancelNotification(for audioFile: AudioFile) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["audio_\(audioFile.id)"])
    }
    
    private func updateScheduledFilesList() {
        // No need to update since scheduledAudioFiles is a computed property
        // This method is kept for compatibility but does nothing
    }
    
    private func checkScheduledAudio() {
        let now = Date()
        let calendar = Calendar.current
        
        for audioFile in scheduledAudioFiles {
            guard let scheduledTime = audioFile.scheduledTime else { continue }
            
            // Check if it's time to play (within 1 minute of scheduled time)
            let timeDifference = scheduledTime.timeIntervalSince(now)
            
            if timeDifference <= 60 && timeDifference >= -60 { // Within 1 minute window
                print("🎵 Time to play scheduled audio: '\(audioFile.name)' (recurring: \(audioFile.recurringType.displayName))")
                playScheduledAudio(audioFile)
                
                // Handle recurring schedules
                if audioFile.recurringType != .none {
                    scheduleNextRecurring(audioFile)
                }
            }
        }
    }
    
    private func scheduleNextRecurring(_ audioFile: AudioFile) {
        let calendar = Calendar.current
        guard let currentScheduledTime = audioFile.scheduledTime else { return }
        
        var nextScheduledTime: Date?
        
        switch audioFile.recurringType {
        case .daily:
            nextScheduledTime = calendar.date(byAdding: .day, value: 1, to: currentScheduledTime)
        case .weekdays:
            // Find next weekday (Monday-Friday)
            var nextDate = calendar.date(byAdding: .day, value: 1, to: currentScheduledTime) ?? currentScheduledTime
            while calendar.component(.weekday, from: nextDate) == 1 || calendar.component(.weekday, from: nextDate) == 7 {
                // Skip weekends (Sunday = 1, Saturday = 7)
                nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate) ?? nextDate
            }
            nextScheduledTime = nextDate
        case .none:
            return
        }
        
        guard let nextTime = nextScheduledTime else { return }
        
        // Update the audio file with the next scheduled time
        var updatedFile = audioFile
        updatedFile.scheduledTime = nextTime
        
        updateAudioFile(updatedFile)
        
        // Schedule notification for next occurrence
        scheduleNotification(for: updatedFile, at: nextTime)
        
        print("🔄 Scheduled next occurrence of '\(audioFile.name)' for \(nextTime)")
    }
    
    private func playScheduledAudio(_ audioFile: AudioFile) {
        // For non-recurring schedules, mark as no longer scheduled
        if audioFile.recurringType == .none {
            var updatedFile = audioFile
            updatedFile.isScheduled = false
            updatedFile.scheduledTime = nil
            updateAudioFile(updatedFile)
        }
        
        // Cancel the notification since we're playing
        cancelNotification(for: audioFile)
        
        // Play the audio
        if let fileURL = audioFile.fileURL {
            if let device = audioFile.targetDevice {
                if device.isHomeKitDevice {
                    playAudioOnHomeKitDevice(audioFile, fileURL: fileURL)
                } else if device.isAirPlayDevice {
                    playAudioOnAirPlayDevice(audioFile, device: device)
                } else {
                    playAudioLocally(audioFile, fileURL: fileURL)
                }
            } else {
                playAudioLocally(audioFile, fileURL: fileURL)
            }
        } else {
            print("❌ No file URL found for scheduled audio: \(audioFile.name)")
        }
        
        // Update scheduled files list
        updateScheduledFilesList()
    }
    
    private func playAudioOnAirPlayDevice(_ audioFile: AudioFile, device: AudioFile.AudioDevice) {
        // For now, fall back to local playback
        // In a real implementation, you would set up the audio session for AirPlay
        print("🎵 Playing on AirPlay device: \(device.displayName)")
        if let fileURL = audioFile.fileURL {
            playAudioLocally(audioFile, fileURL: fileURL)
        } else {
            print("❌ No file URL found for AirPlay audio: \(audioFile.name)")
        }
    }
    
    // MARK: - Data Persistence
    
    private func saveAudioFiles() {
        print("💾 AudioStore.saveAudioFiles: Saving \(audioFiles.count) audio files")
        
        // Create backup before saving
        createBackup()
        
        // Save current data
        do {
            let encoder = JSONEncoder()
            let encoded = try encoder.encode(audioFiles)
            UserDefaults.standard.set(encoded, forKey: saveKey)
            UserDefaults.standard.synchronize()
            print("✅ AudioStore.saveAudioFiles: Successfully saved \(encoded.count) bytes")
        } catch {
            print("❌ AudioStore.saveAudioFiles: Failed to encode audio files: \(error)")
        }
    }
    
    private func loadAudioFiles() {
        // Try to load from main storage first
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([AudioFile].self, from: data) {
            audioFiles = decoded
            print("✅ Successfully loaded \(audioFiles.count) audio files from main storage")
            updateScheduledFilesList()
            return
        }
        
        // If main storage fails, try backup
        if let backupData = UserDefaults.standard.data(forKey: backupKey),
           let decoded = try? JSONDecoder().decode([AudioFile].self, from: backupData) {
            audioFiles = decoded
            print("⚠️ Loaded \(audioFiles.count) audio files from backup storage")
            // Restore backup to main storage
            if let encoded = try? JSONEncoder().encode(audioFiles) {
                UserDefaults.standard.set(encoded, forKey: saveKey)
            }
            updateScheduledFilesList()
            return
        }
        
        // If both fail, start with empty audio files
        print("ℹ️ No saved audio files found, starting with empty list")
        audioFiles = []
        updateScheduledFilesList()
    }
    
    private func createBackup() {
        if let encoded = try? JSONEncoder().encode(audioFiles) {
            UserDefaults.standard.set(encoded, forKey: backupKey)
        }
    }
    
    // MARK: - Computed Properties
    
    var scheduledAudioFiles: [AudioFile] {
        audioFiles.filter { $0.isScheduled }
    }
    
    var readyToPlayAudioFiles: [AudioFile] {
        audioFiles.filter { $0.isReadyToPlay && !$0.isScheduled }
    }
    
    var totalStorageUsed: Int64 {
        audioFiles.reduce(0) { $0 + $1.fileSize }
    }
    
    var formattedTotalStorage: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalStorageUsed)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AudioStore {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let audioFileIdString = userInfo["audioFileId"] as? String,
           let audioFileId = UUID(uuidString: audioFileIdString),
           let audioFile = audioFiles.first(where: { $0.id == audioFileId }) {
            
            print("🔔 Notification received for audio file: \(audioFile.name)")
            
            // Trigger audio playback
            DispatchQueue.main.async {
                self.playScheduledAudio(audioFile)
            }
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.alert, .sound, .badge])
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioStore: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("🏁 AudioStore.audioPlayerDidFinishPlaying: Playback finished successfully: \(flag)")
        
        isPlaying = false
        currentTime = 0
        
        if let currentFile = currentAudioFile,
           let index = audioFiles.firstIndex(where: { $0.id == currentFile.id }) {
            audioFiles[index].isPlaying = false
        }
        
        currentAudioFile = nil
        audioPlayer = nil
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("❌ AudioStore.audioPlayerDecodeErrorDidOccur: Decode error: \(error?.localizedDescription ?? "Unknown error")")
        stopPlayback()
    }
}
