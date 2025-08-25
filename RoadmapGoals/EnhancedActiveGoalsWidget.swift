import WidgetKit
import SwiftUI

struct EnhancedActiveGoalsWidget: Widget {
    let kind: String = "EnhancedActiveGoalsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EnhancedActiveGoalsTimelineProvider()) { entry in
            EnhancedActiveGoalsWidgetView(entry: entry)
        }
        .configurationDisplayName("Enhanced Active Goals")
        .description("Shows your current active roadmap goals with progress and deadlines")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct EnhancedActiveGoalsWidgetView: View {
    let entry: EnhancedActiveGoalsTimelineEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("Active Goals")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(entry.activeGoals.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
            }
            
            if entry.activeGoals.isEmpty {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.green)
                    Text("All caught up!")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                    Text("No active goals")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Goals list
                LazyVStack(spacing: 6) {
                    ForEach(entry.activeGoals.prefix(entry.maxGoalsToShow), id: \.id) { goal in
                        EnhancedGoalWidgetRow(goal: goal, family: entry.family)
                    }
                }
                
                // More goals indicator
                if entry.activeGoals.count > entry.maxGoalsToShow {
                    HStack {
                        Text("+\(entry.activeGoals.count - entry.maxGoalsToShow) more")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct EnhancedGoalWidgetRow: View {
    let goal: Goal
    let family: WidgetFamily
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                // Priority indicator
                Circle()
                    .fill(Color(goal.priority.color))
                    .frame(width: 6, height: 6)
                
                // Goal name
                Text(goal.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Spacer()
                
                // Days remaining
                if family != .systemSmall {
                    Text("\(daysRemaining) days")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress bar
            if goal.isInProgress && family != .systemSmall {
                HStack(spacing: 4) {
                    ProgressView(value: goal.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color(goal.priority.color)))
                        .scaleEffect(y: 0.8)
                    
                    Text("\(Int(goal.progress * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 25, alignment: .trailing)
                }
            }
            
            // Overdue indicator
            if goal.isOverdue {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundColor(.red)
                    Text("Overdue")
                        .font(.caption2)
                        .foregroundColor(.red)
                        .fontWeight(.medium)
                    Spacer()
                }
            }
        }
        .padding(.vertical, 2)
    }
    
    private var daysRemaining: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: goal.endDate)
        return max(0, components.day ?? 0)
    }
}

struct EnhancedActiveGoalsTimelineEntry: TimelineEntry {
    let date: Date
    let activeGoals: [Goal]
    let maxGoalsToShow: Int
    let family: WidgetFamily
    
    init(date: Date, activeGoals: [Goal], family: WidgetFamily) {
        self.date = date
        self.activeGoals = activeGoals
        self.family = family
        
        switch family {
        case .systemSmall:
            self.maxGoalsToShow = 2
        case .systemMedium:
            self.maxGoalsToShow = 4
        case .systemLarge:
            self.maxGoalsToShow = 6
        default:
            self.maxGoalsToShow = 3
        }
    }
}

struct EnhancedActiveGoalsTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> EnhancedActiveGoalsTimelineEntry {
        EnhancedActiveGoalsTimelineEntry(
            date: Date(),
            activeGoals: [
                Goal(name: "Learn SwiftUI", durationInDays: 30, startDate: Date().addingTimeInterval(-86400 * 10)),
                Goal(name: "Build Widget", durationInDays: 7, startDate: Date().addingTimeInterval(-86400 * 2))
            ],
            family: context.family
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (EnhancedActiveGoalsTimelineEntry) -> ()) {
        let entry = EnhancedActiveGoalsTimelineEntry(
            date: Date(),
            activeGoals: loadActiveGoals(),
            family: context.family
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let entry = EnhancedActiveGoalsTimelineEntry(
            date: currentDate,
            activeGoals: loadActiveGoals(),
            family: context.family
        )
        
        // Update every 30 minutes for more responsive widget
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate) ?? currentDate
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadActiveGoals() -> [Goal] {
        guard let data = UserDefaults.standard.data(forKey: "SavedGoals"),
              let goals = try? JSONDecoder().decode([Goal].self, from: data) else {
            return []
        }
        
        // Sort by priority (high first), then by deadline (earliest first)
        return goals.filter { !$0.isCompleted }
            .sorted { goal1, goal2 in
                if goal1.priority.rawValue != goal2.priority.rawValue {
                    return goal1.priority.rawValue > goal2.priority.rawValue
                }
                return goal1.endDate < goal2.endDate
            }
    }
}
