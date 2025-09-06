import SwiftUI

struct RoadmapView: View {
    @EnvironmentObject var goalStore: GoalStore
    @State private var selectedTimeframe: Timeframe = .month
    @State private var selectedDate = Date()
    @State private var showingSettings = false
    
    enum Timeframe: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            }
        }
    }
    
    var timelineStart: Date {
        Calendar.current.date(byAdding: .day, value: -selectedTimeframe.days/2, to: selectedDate) ?? selectedDate
    }
    
    var timelineEnd: Date {
        Calendar.current.date(byAdding: .day, value: selectedTimeframe.days/2, to: selectedDate) ?? selectedDate
    }
    
    var filteredGoals: [Goal] {
        goalStore.goals.filter { goal in
            let goalEnd = goal.endDate
            let goalStart = goal.startDate
            return (goalStart <= timelineEnd && goalEnd >= timelineStart)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header Controls
                VStack(spacing: 16) {
                    HStack {
                        Button {
                            selectedDate = Calendar.current.date(byAdding: .day, value: -selectedTimeframe.days, to: selectedDate) ?? selectedDate
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                        }
                        
                        Spacer()
                        
                        VStack {
                            Text(selectedDate, style: .date)
                                .font(.headline)
                            
                            Text("\(selectedTimeframe.rawValue) View")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            selectedDate = Calendar.current.date(byAdding: .day, value: selectedTimeframe.days, to: selectedDate) ?? selectedDate
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                        }
                    }
                    .padding(.horizontal)
                    
                    Picker("Timeframe", selection: $selectedTimeframe) {
                        ForEach(Timeframe.allCases, id: \.self) { timeframe in
                            Text(timeframe.rawValue).tag(timeframe)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                
                if filteredGoals.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No goals in this timeframe")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Add some goals or adjust the timeframe")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredGoals.sorted { $0.startDate < $1.startDate }) { goal in
                                GoalTimelineCard(goal: goal, timelineStart: timelineStart, timelineEnd: timelineEnd)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Roadmap")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        selectedDate = Date()
                    } label: {
                        Text("Today")
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(goalStore)
        }
    }
}

struct GoalTimelineCard: View {
    let goal: Goal
    let timelineStart: Date
    let timelineEnd: Date
    
    var goalPosition: Double {
        let totalDays = Calendar.current.dateComponents([.day], from: timelineStart, to: timelineEnd).day ?? 1
        let goalStartDays = Calendar.current.dateComponents([.day], from: timelineStart, to: goal.startDate).day ?? 0
        return Double(goalStartDays) / Double(totalDays)
    }
    
    var goalWidth: Double {
        let totalDays = Calendar.current.dateComponents([.day], from: timelineStart, to: timelineEnd).day ?? 1
        let goalDays = Calendar.current.dateComponents([.day], from: goal.startDate, to: goal.endDate).day ?? 1
        return min(Double(goalDays) / Double(totalDays), 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goal.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Text(goal.priority.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(goal.priority.color).opacity(0.2))
                    .foregroundColor(Color(goal.priority.color))
                    .cornerRadius(8)
            }
            
            // Timeline Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background timeline
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    // Goal bar
                    Rectangle()
                        .fill(goalColor)
                        .frame(width: max(geometry.size.width * goalWidth, 20), height: 8)
                        .cornerRadius(4)
                        .offset(x: geometry.size.width * goalPosition)
                    
                    // Today indicator
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 2, height: 12)
                        .offset(x: geometry.size.width * todayPosition)
                }
            }
            .frame(height: 12)
            
            HStack {
                Text("\(goal.startDate, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if goal.isInProgress {
                    ProgressView(value: goal.progress)
                        .frame(width: 60)
                }
                
                Spacer()
                
                Text("\(goal.endDate, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if goal.isOverdue {
                Text("Overdue!")
                    .font(.caption)
                    .foregroundColor(.red)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var goalColor: Color {
        if goal.isCompleted {
            return .green
        } else if goal.isOverdue {
            return .red
        } else {
            return Color(goal.priority.color)
        }
    }
    
    private var todayPosition: Double {
        let totalDays = Calendar.current.dateComponents([.day], from: timelineStart, to: timelineEnd).day ?? 1
        let todayDays = Calendar.current.dateComponents([.day], from: timelineStart, to: Date()).day ?? 0
        return Double(todayDays) / Double(totalDays)
    }
}

#Preview {
    RoadmapView()
        .environmentObject(GoalStore())
}
