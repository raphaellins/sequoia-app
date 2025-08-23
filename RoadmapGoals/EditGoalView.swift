import SwiftUI

struct EditGoalView: View {
    @EnvironmentObject var goalStore: GoalStore
    @Environment(\.dismiss) var dismiss
    
    let goal: Goal
    @State private var goalName: String
    @State private var durationInDays: Int
    @State private var startDate: Date
    @State private var priority: Goal.Priority
    @State private var description: String
    @State private var isCompleted: Bool
    
    init(goal: Goal) {
        self.goal = goal
        _goalName = State(initialValue: goal.name)
        _durationInDays = State(initialValue: goal.durationInDays)
        _startDate = State(initialValue: goal.startDate)
        _priority = State(initialValue: goal.priority)
        _description = State(initialValue: goal.description)
        _isCompleted = State(initialValue: goal.isCompleted)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Edit Goal: \(goal.name)")
                    .font(.title)
                    .padding()
                    .onAppear {
                        print("📝 EditGoalView.onAppear: Editing goal '\(goal.name)'")
                        print("📝 EditGoalView: goalName='\(goalName)', duration=\(durationInDays)")
                    }
                
                Form {
                    Section(header: Text("Goal Details")) {
                        TextField("Goal Name", text: $goalName)
                        
                        Stepper("Duration: \(durationInDays) days", value: $durationInDays, in: 1...365)
                        
                        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        
                        Picker("Priority", selection: $priority) {
                            ForEach(Goal.Priority.allCases, id: \.self) { priority in
                                Text(priority.rawValue).tag(priority)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    Section(header: Text("Description (Optional)")) {
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                    }
                    
                    Section(header: Text("Status")) {
                        Toggle("Mark as Completed", isOn: $isCompleted)
                            .tint(.green)
                    }
                    
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Preview")
                                .font(.headline)
                            
                            if !goalName.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(goalName)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .strikethrough(isCompleted)
                                    
                                    Text("Duration: \(durationInDays) days")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text("Start: \(startDate, style: .date)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text("End: \(Calendar.current.date(byAdding: .day, value: durationInDays, to: startDate) ?? startDate, style: .date)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    HStack {
                                        Text("Priority:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text(priority.rawValue)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color(priority.color).opacity(0.2))
                                            .foregroundColor(Color(priority.color))
                                            .cornerRadius(4)
                                    }
                                    
                                    if isCompleted {
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                            Text("Completed")
                                                .font(.caption)
                                                .foregroundColor(.green)
                                                .fontWeight(.semibold)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            } else {
                                Text("Enter a goal name to see preview")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveGoal()
                    }
                    .disabled(goalName.isEmpty)
                }
            }
        }
    }
    
    private func saveGoal() {
        let updatedGoal = Goal(
            id: goal.id,
            name: goalName,
            durationInDays: durationInDays,
            startDate: startDate,
            isCompleted: isCompleted,
            priority: priority,
            description: description
        )
        
        goalStore.updateGoal(updatedGoal)
        dismiss()
    }
}

#Preview {
    EditGoalView(goal: Goal(
        name: "Sample Goal",
        durationInDays: 7,
        startDate: Date(),
        priority: .medium,
        description: "Sample description"
    ))
    .environmentObject(GoalStore())
}
