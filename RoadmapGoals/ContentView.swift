import SwiftUI

struct ContentView: View {
    @StateObject private var goalStore = GoalStore()
    @StateObject private var audioStore = AudioStore()
    
    var body: some View {
        TabView {
            GoalListView()
                .environmentObject(goalStore)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Goals")
                }
            
            RoadmapView()
                .environmentObject(goalStore)
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Roadmap")
                }
            
            AudioListView()
                .environmentObject(audioStore)
                .tabItem {
                    Image(systemName: "music.note")
                    Text("Audio")
                }
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
}
