import SwiftUI
import AVFoundation

struct AudioPlayerView: View {
    @EnvironmentObject var audioStore: AudioStore
    @State private var isDragging = false
    
    var body: some View {
        if let currentFile = audioStore.currentAudioFile {
            VStack(spacing: 12) {
                // Audio File Info
                HStack {
                    Image(systemName: "music.note")
                        .foregroundColor(.blue)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentFile.name)
                            .font(.headline)
                            .lineLimit(1)
                        
                        Text("\(formatTime(audioStore.currentTime)) / \(formatTime(audioStore.duration))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        audioStore.stopPlayback()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                
                // Progress Slider
                VStack(spacing: 4) {
                    Slider(
                        value: Binding(
                            get: { audioStore.currentTime },
                            set: { newValue in
                                if !isDragging {
                                    audioStore.seekToTime(newValue)
                                }
                            }
                        ),
                        in: 0...max(audioStore.duration, 1),
                        onEditingChanged: { editing in
                            isDragging = editing
                            if !editing {
                                audioStore.seekToTime(audioStore.currentTime)
                            }
                        }
                    )
                    .accentColor(.blue)
                    
                    HStack {
                        Text(formatTime(audioStore.currentTime))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(formatTime(audioStore.duration))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Control Buttons
                HStack(spacing: 20) {
                    Button(action: {
                        // Skip backward 15 seconds
                        let newTime = max(0, audioStore.currentTime - 15)
                        audioStore.seekToTime(newTime)
                    }) {
                        Image(systemName: "gobackward.15")
                            .font(.title2)
                    }
                    .disabled(!audioStore.isPlaying)
                    
                    Button(action: {
                        if audioStore.isPlaying {
                            audioStore.pausePlayback()
                        } else {
                            audioStore.resumePlayback()
                        }
                    }) {
                        Image(systemName: audioStore.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        // Skip forward 15 seconds
                        let newTime = min(audioStore.duration, audioStore.currentTime + 15)
                        audioStore.seekToTime(newTime)
                    }) {
                        Image(systemName: "goforward.15")
                            .font(.title2)
                    }
                    .disabled(!audioStore.isPlaying)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    let audioStore = AudioStore()
    let sampleAudioFile = AudioFile(
        name: "Sample Audio File",
        fileName: "sample.mp3",
        duration: 180,
        fileSize: 1024000
    )
    
    audioStore.currentAudioFile = sampleAudioFile
    audioStore.isPlaying = true
    
    return AudioPlayerView()
        .environmentObject(audioStore)
        .padding()
}
