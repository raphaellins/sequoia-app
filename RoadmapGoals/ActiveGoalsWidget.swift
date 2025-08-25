import WidgetKit
import SwiftUI

struct ActiveGoalsWidget: Widget {
    let kind: String = "ActiveGoalsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ActiveGoalsTimelineProvider()) { entry in
            ActiveGoalsWidgetView(entry: entry)
        }
        .configurationDisplayName("Active Goals")
        .description("Shows your current active roadmap goals")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct ActiveGoalsWidgetView: View {
    let entry: ActiveGoalsTimelineEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.blue)
                Text("Active Goals")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if entry.activeGoals.isEmpty {
                VStack {
                    Image(systemName: "checkmark.circle")
                        .font(.title2)
                        .foregroundColor(.green)
                    Text("All caught up!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ForEach(entry.activeGoals.prefix(entry.maxGoalsToShow), id: \.id) { goal in
                    GoalWidgetRow(goal: goal)
                }
                
                if entry.activeGoals.count > entry.maxGoalsToShow {
                    Text("+\(entry.activeGoals.count - entry.maxGoalsToShow) more")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct GoalWidgetRow: View {
    let goal: Goal
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(goal.priority.color))
                .frame(width: 8, height: 8)
            
            Text(goal.name)
                .font(.caption)
                .lineLimit(1)
            
            Spacer()
            
            if goal.isInProgress {
                ProgressView(value: goal.progress)
                    .frame(width: 30)
                    .scaleEffect(0.8)
            }
        }
    }
}

struct ActiveGoalsTimelineEntry: TimelineEntry {
    let date: Date
    let activeGoals: [Goal]
    let maxGoalsToShow: Int
    
    init(date: Date, activeGoals: [Goal], family: WidgetFamily) {
        self.date = date
        self.activeGoals = activeGoals
        
        switch family {
        case .systemSmall:
            self.maxGoalsToShow = 2
        case .systemMedium:
            self.maxGoalsToShow = 4
        case .systemLarge:
            self.maxGoalsToShow = 8
        default:
            self.maxGoalsToShow = 3
        }
    }
}

struct ActiveGoalsTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ActiveGoalsTimelineEntry {
        ActiveGoalsTimelineEntry(
            date: Date(),
            activeGoals: [
                Goal(name: "Sample Goal 1", durationInDays: 7, startDate: Date()),
                Goal(name: "Sample Goal 2", durationInDays: 14, startDate: Date())
            ],
            family: context.family
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ActiveGoalsTimelineEntry) -> ()) {
        let entry = ActiveGoalsTimelineEntry(
            date: Date(),
            activeGoals: loadActiveGoals(),
            family: context.family
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let entry = ActiveGoalsTimelineEntry(
            date: currentDate,
            activeGoals: loadActiveGoals(),
            family: context.family
        )
        
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate) ?? currentDate
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadActiveGoals() -> [Goal] {
        guard let data = UserDefaults.standard.data(forKey: "SavedGoals"),
              let goals = try? JSONDecoder().decode([Goal].self, from: data) else {
            return []
        }
        
        return goals.filter { !$0.isCompleted }.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
}
