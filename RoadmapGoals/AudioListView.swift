import SwiftUI

struct AudioListView: View {
    @EnvironmentObject var audioStore: AudioStore
    @State private var showingFilePicker = false
    @State private var showingScheduleView = false
    @State private var selectedAudioFile: AudioFile?
    @State private var isImporting = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Audio Player (if something is playing)
                if audioStore.currentAudioFile != nil {
                    AudioPlayerView()
                        .environmentObject(audioStore)
                        .padding(.horizontal)
                }
                
                if audioStore.audioFiles.isEmpty {
                    EmptyAudioView(showingFilePicker: $showingFilePicker)
                } else {
                    List {
                        // Current Playing Section
                        if let currentFile = audioStore.currentAudioFile {
                            Section(header: Text("Now Playing")) {
                                AudioFileRow(
                                    audioFile: currentFile,
                                    audioStore: audioStore,
                                    isCurrentlyPlaying: true,
                                    onSchedule: { audioFile in
                                        selectedAudioFile = audioFile
                                        showingScheduleView = true
                                    }
                                )
                            }
                        }
                        
                        // Scheduled Audio Section
                        if !audioStore.scheduledAudioFiles.isEmpty {
                            Section(header: Text("Scheduled")) {
                                ForEach(audioStore.scheduledAudioFiles) { audioFile in
                                    AudioFileRow(
                                        audioFile: audioFile,
                                        audioStore: audioStore,
                                        isCurrentlyPlaying: false,
                                        onSchedule: { audioFile in
                                            selectedAudioFile = audioFile
                                            showingScheduleView = true
                                        }
                                    )
                                }
                            }
                        }
                        
                        // Available Audio Section
                        Section(header: Text("Available")) {
                            ForEach(audioStore.readyToPlayAudioFiles) { audioFile in
                                AudioFileRow(
                                    audioFile: audioFile,
                                    audioStore: audioStore,
                                    isCurrentlyPlaying: false,
                                    onSchedule: { audioFile in
                                        selectedAudioFile = audioFile
                                        showingScheduleView = true
                                    }
                                )
                            }
                            .onDelete(perform: deleteAudioFiles)
                        }
                        
                        // Storage Info Section
                        Section(header: Text("Storage")) {
                            HStack {
                                Image(systemName: "internaldrive")
                                    .foregroundColor(.blue)
                                Text("Total Storage Used")
                                Spacer()
                                Text(audioStore.formattedTotalStorage)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Image(systemName: "doc.audio")
                                    .foregroundColor(.green)
                                Text("Audio Files")
                                Spacer()
                                Text("\(audioStore.audioFiles.count)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Audio")
            .navigationBarItems(
                trailing: Button(action: {
                    showingFilePicker = true
                }) {
                    if isImporting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "plus")
                    }
                }
                .disabled(isImporting)
            )
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            Task {
                await handleFileImport(result)
            }
        }
        .sheet(isPresented: $showingScheduleView) {
            if let audioFile = selectedAudioFile {
                ScheduleAudioView(audioFile: audioFile, audioStore: audioStore)
            } else {
                Text("Error: No audio file selected")
                    .padding()
            }
        }
        .onChange(of: showingScheduleView) { isPresented in
            if isPresented {
                if let audioFile = selectedAudioFile {
                    print("🎵 Presenting ScheduleAudioView for: \(audioFile.name)")
                } else {
                    print("❌ No audioFile selected for scheduling")
                }
            }
        }
    }
    
    private func deleteAudioFiles(offsets: IndexSet) {
        for index in offsets {
            let audioFile = audioStore.readyToPlayAudioFiles[index]
            audioStore.deleteAudioFile(audioFile)
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) async {
        print("🎵 handleFileImport called with result: \(result)")
        isImporting = true
        
        switch result {
        case .success(let urls):
            print("🎵 Success case: \(urls.count) URLs received")
            guard let url = urls.first else { 
                print("❌ No URLs in success result")
                isImporting = false
                return 
            }
            
            print("🎵 Processing URL: \(url)")
            
            // Start accessing the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                print("❌ Failed to access security-scoped resource for: \(url)")
                isImporting = false
                return
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
                print("🎵 Stopped accessing security-scoped resource")
                isImporting = false
            }
            
            print("🎵 Calling audioStore.importAudioFile...")
            if let audioFile = await audioStore.importAudioFile(from: url) {
                print("✅ Successfully imported audio file: \(audioFile.name)")
                print("✅ Audio file details: duration=\(audioFile.duration), size=\(audioFile.fileSize)")
            } else {
                print("❌ Failed to import audio file")
            }
            
        case .failure(let error):
            print("❌ File import failed: \(error)")
            isImporting = false
        }
    }
}

struct EmptyAudioView: View {
    @Binding var showingFilePicker: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Audio Files")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Import MP3 files to get started with audio playback and scheduling")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Import Audio File") {
                showingFilePicker = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}

struct AudioFileRow: View {
    let audioFile: AudioFile
    let audioStore: AudioStore
    let isCurrentlyPlaying: Bool
    let onSchedule: (AudioFile) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(audioFile.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    HStack {
                        Text(audioFile.formattedDuration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(audioFile.formattedFileSize)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if audioFile.isScheduled {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Scheduled")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Spacer()
                
                // Play/Pause Button
                Button(action: {
                    if audioFile.isPlaying {
                        audioStore.pausePlayback()
                    } else if audioStore.currentAudioFile?.id == audioFile.id {
                        audioStore.resumePlayback()
                    } else {
                        audioStore.playAudio(audioFile)
                    }
                }) {
                    Image(systemName: audioFile.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .disabled(!audioFile.isReadyToPlay)
            }
            
            // Schedule Info
            if audioFile.isScheduled, let scheduledTime = audioFile.scheduledTime {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.orange)
                        .font(.caption)
                    
                    Text("Scheduled for \(scheduledTime, style: .time)")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    if let device = audioFile.targetDevice {
                        Text("on \(device.displayName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if let timeUntil = audioFile.formattedTimeUntilPlay {
                        Text("in \(timeUntil)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Action Buttons
            HStack {
                Button("Schedule") {
                    onSchedule(audioFile)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                if audioFile.isScheduled {
                    Button("Cancel") {
                        audioStore.cancelScheduledAudio(audioFile)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .foregroundColor(.red)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AudioListView()
        .environmentObject(AudioStore())
}
