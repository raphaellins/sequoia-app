import SwiftUI

struct AddGoalView: View {
    @EnvironmentObject var goalStore: GoalStore
    @Environment(\.dismiss) var dismiss
    
    @State private var goalName = ""
    @State private var durationInDays = 7
    @State private var startDate = Date()
    @State private var priority = Goal.Priority.medium
    @State private var description = ""
    
    var body: some View {
        NavigationView {
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
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preview")
                            .font(.headline)
                        
                        if !goalName.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(goalName)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
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
            .navigationTitle("Add Goal")
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
        let newGoal = Goal(
            name: goalName,
            durationInDays: durationInDays,
            startDate: startDate,
            priority: priority,
            description: description
        )
        
        goalStore.addGoal(newGoal)
        dismiss()
    }
}

#Preview {
    AddGoalView()
        .environmentObject(GoalStore())
}
