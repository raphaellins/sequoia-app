import WidgetKit
import SwiftUI

struct WidgetConfigurationIntent: AppIntent {
    static var title: LocalizedStringResource = "Widget Configuration"
    
    @Parameter(title: "Show Progress Bars")
    var showProgressBars: Bool = true
    
    @Parameter(title: "Show Days Remaining")
    var showDaysRemaining: Bool = true
    
    @Parameter(title: "Sort By")
    var sortBy: SortOption = .priority
    
    enum SortOption: String, CaseIterable, AppEnum {
        case priority = "Priority"
        case deadline = "Deadline"
        case name = "Name"
        
        static var typeDisplayRepresentation: TypeDisplayRepresentation = "Sort Option"
        static var caseDisplayRepresentations: [SortOption : DisplayRepresentation] = [
            .priority: "Priority",
            .deadline: "Deadline", 
            .name: "Name"
        ]
    }
}

struct ConfigurableActiveGoalsWidget: Widget {
    let kind: String = "ConfigurableActiveGoalsWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: WidgetConfigurationIntent.self,
            provider: ConfigurableActiveGoalsTimelineProvider()
        ) { entry in
            ConfigurableActiveGoalsWidgetView(entry: entry)
        }
        .configurationDisplayName("Configurable Active Goals")
        .description("Customizable widget showing your active roadmap goals")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct ConfigurableActiveGoalsWidgetView: View {
    let entry: ConfigurableActiveGoalsTimelineEntry
    
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
                LazyVStack(spacing: 6) {
                    ForEach(entry.activeGoals.prefix(entry.maxGoalsToShow), id: \.id) { goal in
                        ConfigurableGoalWidgetRow(
                            goal: goal,
                            family: entry.family,
                            showProgressBars: entry.config.showProgressBars,
                            showDaysRemaining: entry.config.showDaysRemaining
                        )
                    }
                }
                
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

struct ConfigurableGoalWidgetRow: View {
    let goal: Goal
    let family: WidgetFamily
    let showProgressBars: Bool
    let showDaysRemaining: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(goal.priority.color))
                    .frame(width: 6, height: 6)
                
                Text(goal.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Spacer()
                
                if showDaysRemaining && family != .systemSmall {
                    Text("\(daysRemaining) days")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if showProgressBars && goal.isInProgress && family != .systemSmall {
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

struct ConfigurableActiveGoalsTimelineEntry: TimelineEntry {
    let date: Date
    let activeGoals: [Goal]
    let maxGoalsToShow: Int
    let family: WidgetFamily
    let config: WidgetConfigurationIntent
    
    init(date: Date, activeGoals: [Goal], family: WidgetFamily, config: WidgetConfigurationIntent) {
        self.date = date
        self.activeGoals = activeGoals
        self.family = family
        self.config = config
        
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

struct ConfigurableActiveGoalsTimelineProvider: AppIntentTimelineProvider<WidgetConfigurationIntent> {
    func placeholder(in context: Context) -> ConfigurableActiveGoalsTimelineEntry {
        ConfigurableActiveGoalsTimelineEntry(
            date: Date(),
            activeGoals: [
                Goal(name: "Sample Goal 1", durationInDays: 7, startDate: Date()),
                Goal(name: "Sample Goal 2", durationInDays: 14, startDate: Date())
            ],
            family: context.family,
            config: WidgetConfigurationIntent()
        )
    }

    func snapshot(for configuration: WidgetConfigurationIntent, in context: Context) async -> ConfigurableActiveGoalsTimelineEntry {
        ConfigurableActiveGoalsTimelineEntry(
            date: Date(),
            activeGoals: loadActiveGoals(sortedBy: configuration.sortBy),
            family: context.family,
            config: configuration
        )
    }

    func timeline(for configuration: WidgetConfigurationIntent, in context: Context) async -> Timeline<ConfigurableActiveGoalsTimelineEntry> {
        let currentDate = Date()
        let entry = ConfigurableActiveGoalsTimelineEntry(
            date: currentDate,
            activeGoals: loadActiveGoals(sortedBy: configuration.sortBy),
            family: context.family,
            config: configuration
        )
        
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate) ?? currentDate
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    private func loadActiveGoals(sortedBy sortOption: WidgetConfigurationIntent.SortOption) -> [Goal] {
        guard let data = UserDefaults.standard.data(forKey: "SavedGoals"),
              let goals = try? JSONDecoder().decode([Goal].self, from: data) else {
            return []
        }
        
        let activeGoals = goals.filter { !$0.isCompleted }
        
        switch sortOption {
        case .priority:
            return activeGoals.sorted { goal1, goal2 in
                if goal1.priority.rawValue != goal2.priority.rawValue {
                    return goal1.priority.rawValue > goal2.priority.rawValue
                }
                return goal1.endDate < goal2.endDate
            }
        case .deadline:
            return activeGoals.sorted { $0.endDate < $1.endDate }
        case .name:
            return activeGoals.sorted { $0.name < $1.name }
        }
    }
}
