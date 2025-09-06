import SwiftUI
import MediaPlayer

struct AirPlayPickerView: View {
    @Binding var selectedDevice: AudioFile.AudioDevice
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Select AirPlay Device")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                Text("Choose where you want to play your audio")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // System AirPlay picker
                AirPlayVolumeView()
                    .frame(height: 50)
                    .padding(.horizontal)
                
                Spacer()
                
                // Instructions
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "airplayvideo")
                            .foregroundColor(.blue)
                        Text("Tap the AirPlay icon above to select a device")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "speaker.wave.2")
                            .foregroundColor(.green)
                        Text("Your HomePod and other AirPlay devices will appear")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("AirPlay")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Done") {
                    dismiss()
                }
            )
        }
    }
}

// Custom view that wraps MPVolumeView for AirPlay selection
struct AirPlayVolumeView: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        let volumeView = MPVolumeView()
        volumeView.showsVolumeSlider = false
        volumeView.showsRouteButton = true
        volumeView.backgroundColor = UIColor.clear
        return volumeView
    }
    
    func updateUIView(_ uiView: MPVolumeView, context: Context) {
        // No updates needed
    }
}

#Preview {
    AirPlayPickerView(selectedDevice: .constant(.phone))
}
