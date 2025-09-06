import SwiftUI
import HomeKit
import MediaPlayer

struct ScheduleAudioView: View {
    let audioFile: AudioFile
    let audioStore: AudioStore
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedDate = Date()
    @State private var selectedTime = Date()
    @State private var selectedDevice: AudioFile.AudioDevice = .phone
    @State private var showingConfirmation = false
    @State private var showingAirPlayPicker = false
    @State private var recurringType: RecurringType = .none
    @State private var volumeFadeIn: Bool = true
    @State private var fadeInDuration: Double = 5.0
    @StateObject private var homeKitManager = HomeKitManager()
    @StateObject private var airPlayManager = AirPlayManager()
    
    var body: some View {
        if audioFile.name.isEmpty {
            Text("Error: Invalid audio file")
                .foregroundColor(.red)
                .padding()
        } else {
            Form {
                Section(header: Text("Audio File")) {
                    HStack {
                        Image(systemName: "music.note")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text(audioFile.name)
                                .font(.headline)
                            Text("\(audioFile.formattedDuration) • \(audioFile.formattedFileSize)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Schedule Time")) {
                    DatePicker(
                        "Date",
                        selection: $selectedDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    
                    DatePicker(
                        "Time",
                        selection: $selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                }
                
                Section(header: Text("Playback Device")) {
                    // Local devices
                    deviceRow(device: .phone, title: "iPhone")
                    deviceRow(device: .airPods, title: "AirPods")
                    deviceRow(device: .bluetooth, title: "Bluetooth Speaker")
                    
                    // HomeKit devices
                    if homeKitManager.isAuthorized {
                        if homeKitManager.isLoading {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Loading HomeKit devices...")
                                    .foregroundColor(.secondary)
                            }
                        } else if homeKitManager.availableSpeakers.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.orange)
                                    Text("No HomeKit speakers found")
                                        .foregroundColor(.secondary)
                                }
                                Text("Make sure your HomePod or other HomeKit speakers are set up in the Home app and connected to the same network.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Button("Refresh") {
                                    homeKitManager.refreshSpeakers()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        } else {
                            ForEach(homeKitManager.availableSpeakers, id: \.uniqueIdentifier) { speaker in
                                let homeKitDevice = AudioFile.AudioDevice.homeKitSpeaker(
                                    AudioFile.AudioDevice.HomeKitSpeakerInfo(
                                        id: speaker.uniqueIdentifier.uuidString,
                                        name: speaker.name,
                                        model: speaker.model ?? "Unknown",
                                        isReachable: speaker.isReachable
                                    )
                                )
                                
                                deviceRow(device: homeKitDevice, title: speaker.name)
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                Text("HomeKit access required")
                                    .foregroundColor(.secondary)
                                Spacer()
                                if homeKitManager.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Button("Enable") {
                                        homeKitManager.requestAuthorization()
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                            Text("This app needs HomeKit access to discover and control your HomePod speakers.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Button("Refresh") {
                                    homeKitManager.forceRefreshAuthorization()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                
                                Spacer()
                                
                                Text("If you've already enabled HomeKit access, try refreshing.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // AirPlay devices
                    Section(header: Text("AirPlay Devices")) {
                        if airPlayManager.isScanning {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Scanning for AirPlay devices...")
                                    .foregroundColor(.secondary)
                            }
                        } else if airPlayManager.availableDevices.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.orange)
                                    Text("No AirPlay devices found")
                                        .foregroundColor(.secondary)
                                }
                                Text("Make sure your HomePod or other AirPlay devices are connected to the same network.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Button("Refresh") {
                                    airPlayManager.refreshDevices()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        } else {
                            ForEach(airPlayManager.availableDevices) { device in
                                let airPlayDevice = AudioFile.AudioDevice.airPlayDevice(
                                    AudioFile.AudioDevice.AirPlayDeviceInfo(
                                        id: device.id,
                                        name: device.name,
                                        type: device.type.rawValue,
                                        isConnected: device.isConnected
                                    )
                                )
                                deviceRow(device: airPlayDevice, title: device.displayName)
                            }
                        }
                        
                        // AirPlay picker button
                        Button(action: {
                            showingAirPlayPicker = true
                        }) {
                            HStack {
                                Image(systemName: "airplayvideo")
                                    .foregroundColor(.blue)
                                Text("Show AirPlay Picker")
                                    .foregroundColor(.blue)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Section(header: Text("Recurring Schedule")) {
                    Picker("Repeat", selection: $recurringType) {
                        ForEach(RecurringType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Volume Settings")) {
                    Toggle("Volume Fade-In", isOn: $volumeFadeIn)
                        .toggleStyle(SwitchToggleStyle())
                    
                    if volumeFadeIn {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Fade Duration")
                                Spacer()
                                Text("\(Int(fadeInDuration)) seconds")
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: $fadeInDuration, in: 1...15, step: 1)
                                .accentColor(.blue)
                        }
                    }
                }
                
                Section(header: Text("Schedule Summary")) {
                    VStack(alignment: .leading, spacing: 8) {
                        scheduleSummaryRow(label: "Will play:", value: audioFile.name)
                        scheduleSummaryRow(label: "At:", value: combinedDateTime.formatted(date: .abbreviated, time: .shortened))
                        scheduleSummaryRow(label: "On:", value: selectedDevice.displayName, icon: selectedDevice.icon)
                        scheduleSummaryRow(label: "Repeat:", value: recurringType.displayName, icon: recurringType.icon)
                        
                        if volumeFadeIn {
                            scheduleSummaryRow(label: "Volume:", value: "Fade-in (\(Int(fadeInDuration))s)")
                        }
                        
                        if let timeUntil = timeUntilPlay {
                            scheduleSummaryRow(label: "In:", value: timeUntil, isHighlighted: true)
                        }
                    }
                    .font(.body)
                    
                    // Save button
                    Button(action: {
                        showingConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                            Text("Schedule Audio")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(combinedDateTime <= Date() ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(combinedDateTime <= Date())
                }
            .navigationTitle("Schedule Audio")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button("Cancel") {
                dismiss()
            },
            trailing: Button("Schedule") {
                showingConfirmation = true
            }
            .disabled(combinedDateTime <= Date())
        )
            }
            .onAppear {
                print("🎵 ScheduleAudioView appeared for: \(audioFile.name)")
                setupInitialValues()
            }
            .alert("Confirm Schedule", isPresented: $showingConfirmation) {
            Button("Schedule") {
                scheduleAudio()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will schedule '\(audioFile.name)' to play at \(combinedDateTime.formatted(date: .abbreviated, time: .shortened)) on \(selectedDevice.displayName).")
        }
        .sheet(isPresented: $showingAirPlayPicker) {
            AirPlayPickerView(selectedDevice: $selectedDevice)
        }
        }
    }
    
    private var combinedDateTime: Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        
        return calendar.date(from: combinedComponents) ?? Date()
    }
    
    private var timeUntilPlay: String? {
        let timeInterval = combinedDateTime.timeIntervalSinceNow
        guard timeInterval > 0 else { return nil }
        
        let totalSeconds = Int(timeInterval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let days = hours / 24
        let remainingHours = hours % 24
        
        if days > 0 {
            return "\(days)d \(remainingHours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func setupInitialValues() {
        // Set default time to 1 hour from now
        let oneHourFromNow = Date().addingTimeInterval(3600)
        selectedDate = oneHourFromNow
        selectedTime = oneHourFromNow
        
        // If audio file is already scheduled, use those values
        if audioFile.isScheduled {
            if let scheduledTime = audioFile.scheduledTime {
                selectedDate = scheduledTime
                selectedTime = scheduledTime
            }
            if let device = audioFile.targetDevice {
                selectedDevice = device
            }
            recurringType = audioFile.recurringType
            volumeFadeIn = audioFile.volumeFadeIn
            fadeInDuration = audioFile.fadeInDuration
        }
    }
    
    private func scheduleAudio() {
        let scheduledDateTime = combinedDateTime
        
        // Validate the scheduled time
        guard scheduledDateTime > Date() else {
            print("❌ Cannot schedule audio in the past")
            return
        }
        
        audioStore.scheduleAudio(audioFile, for: scheduledDateTime, on: selectedDevice, recurring: recurringType, volumeFadeIn: volumeFadeIn, fadeInDuration: fadeInDuration)
        dismiss()
    }
    
    
    @ViewBuilder
    private func deviceRow(device: AudioFile.AudioDevice, title: String) -> some View {
        HStack {
            Image(systemName: device.icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                
                if device.isHomeKitDevice, let homeKitInfo = device.homeKitInfo {
                    Text(homeKitInfo.isReachable ? "Available" : "Unavailable")
                        .font(.caption)
                        .foregroundColor(homeKitInfo.isReachable ? .green : .red)
                } else if device.isAirPlayDevice, let airPlayInfo = device.airPlayInfo {
                    Text(airPlayInfo.isConnected ? "Connected" : "Available")
                        .font(.caption)
                        .foregroundColor(airPlayInfo.isConnected ? .green : .blue)
                }
            }
            
            Spacer()
            
            if isDeviceSelected(device) {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedDevice = device
        }
    }
    
    private func isDeviceSelected(_ device: AudioFile.AudioDevice) -> Bool {
        switch (selectedDevice, device) {
        case (.phone, .phone), (.airPods, .airPods), (.bluetooth, .bluetooth):
            return true
        case (.homeKitSpeaker(let selectedInfo), .homeKitSpeaker(let deviceInfo)):
            return selectedInfo.id == deviceInfo.id
        default:
            return false
        }
    }
    
    @ViewBuilder
    private func scheduleSummaryRow(label: String, value: String, icon: String? = nil, isHighlighted: Bool = false) -> some View {
        HStack {
            Text(label)
            Spacer()
            
            if let icon = icon {
                HStack {
                    Image(systemName: icon)
                    Text(value)
                }
                .fontWeight(.medium)
            } else {
                Text(value)
                    .fontWeight(.medium)
                    .foregroundColor(isHighlighted ? .orange : .primary)
            }
        }
    }
}

#Preview {
    let sampleAudioFile = AudioFile(
        name: "Sample Audio",
        fileName: "sample.mp3",
        duration: 180,
        fileSize: 1024000
    )
    
    return ScheduleAudioView(audioFile: sampleAudioFile, audioStore: AudioStore())
}

