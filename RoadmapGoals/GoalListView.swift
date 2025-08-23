import SwiftUI

struct GoalListView: View {
    @EnvironmentObject var goalStore: GoalStore
    @State private var showingAddGoal = false
    @State private var showingSettings = false
    @State private var selectedFilter: GoalFilter = .all
    @State private var goalToEdit: Goal?
    
    enum GoalFilter {
        case all, active, completed, overdue
        
        var title: String {
            switch self {
            case .all: return "All"
            case .active: return "Active"
            case .completed: return "Completed"
            case .overdue: return "Overdue"
            }
        }
    }
    
    var filteredGoals: [Goal] {
        switch selectedFilter {
        case .all:
            return goalStore.goals
        case .active:
            return goalStore.activeGoals
        case .completed:
            return goalStore.completedGoals
        case .overdue:
            return goalStore.overdueGoals
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Filter Picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach([GoalFilter.all, .active, .completed, .overdue], id: \.self) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if filteredGoals.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "target")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No goals yet")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Tap the + button to add your first goal")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredGoals) { goal in
                            GoalRowView(goal: goal)
                                .onTapGesture {
                                    print("📱 GoalListView: Tapped goal '\(goal.name)'")
                                    goalToEdit = goal
                                    print("📱 GoalListView: Set goalToEdit to '\(goalToEdit?.name ?? "nil")'")
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        goalStore.deleteGoal(goal)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        goalStore.toggleGoalCompletion(goal)
                                    } label: {
                                        Label(goal.isCompleted ? "Mark Incomplete" : "Mark Complete", 
                                              systemImage: goal.isCompleted ? "xmark.circle" : "checkmark.circle")
                                    }
                                    .tint(goal.isCompleted ? .orange : .green)
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    Button {
                                        goalToEdit = goal
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                }
            }
            .navigationTitle("Goals")
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
                        showingAddGoal = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddGoal) {
                AddGoalView()
                    .environmentObject(goalStore)
            }
            .sheet(item: $goalToEdit) { goal in
                EditGoalView(goal: goal)
                    .environmentObject(goalStore)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(goalStore)
            }
        }
    }
}

struct GoalRowView: View {
    let goal: Goal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(goal.name)
                        .font(.headline)
                        .strikethrough(goal.isCompleted)
                    
                    Text("\(goal.durationInDays) days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(goal.priority.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(goal.priority.color).opacity(0.2))
                        .foregroundColor(Color(goal.priority.color))
                        .cornerRadius(8)
                    
                    if goal.isInProgress {
                        ProgressView(value: goal.progress)
                            .frame(width: 60)
                    }
                }
                
                // Edit indicator
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .opacity(0.6)
            }
            
            HStack {
                Text("Start: \(goal.startDate, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("End: \(goal.endDate, style: .date)")
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
        .padding(.vertical, 4)
    }
}

#Preview {
    GoalListView()
        .environmentObject(GoalStore())
}
