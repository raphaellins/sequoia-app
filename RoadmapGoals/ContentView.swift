import SwiftUI

struct ContentView: View {
    @StateObject private var goalStore = GoalStore()
    
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
                    Image(systemName: "chart.timeline.xaxis")
                    Text("Roadmap")
                }
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
}
