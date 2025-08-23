import Foundation
import SwiftUI

class GoalStore: ObservableObject {
    @Published var goals: [Goal] = []
    
    private let saveKey = "SavedGoals"
    private let backupKey = "SavedGoalsBackup"
    
    init() {
        print("🚀 GoalStore.init: Starting initialization")
        loadGoals()
        print("🚀 GoalStore.init: Initialization complete. Goals count: \(goals.count)")
    }
    
    func addGoal(_ goal: Goal) {
        print("➕ GoalStore.addGoal: Adding goal '\(goal.name)'")
        goals.append(goal)
        print("➕ GoalStore.addGoal: Goals count after adding: \(goals.count)")
        saveGoals()
    }
    
    func deleteGoal(_ goal: Goal) {
        goals.removeAll { $0.id == goal.id }
        saveGoals()
    }
    
    func updateGoal(_ goal: Goal) {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index] = goal
            saveGoals()
        }
    }
    
    func toggleGoalCompletion(_ goal: Goal) {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index].isCompleted.toggle()
            saveGoals()
        }
    }
    
    private func saveGoals() {
        print("💾 GoalStore.saveGoals: Saving \(goals.count) goals")
        
        // Create backup before saving
        createBackup()
        
        // Save current data
        do {
            let encoder = JSONEncoder()
            let encoded = try encoder.encode(goals)
            UserDefaults.standard.set(encoded, forKey: saveKey)
            UserDefaults.standard.synchronize() // Force immediate save
            print("✅ GoalStore.saveGoals: Successfully saved \(encoded.count) bytes")
        } catch {
            print("❌ GoalStore.saveGoals: Failed to encode goals: \(error)")
        }
    }
    
    private func loadGoals() {
        // Try to load from main storage first
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Goal].self, from: data) {
            goals = decoded
            print("✅ Successfully loaded \(goals.count) goals from main storage")
            return
        }
        
        // If main storage fails, try backup
        if let backupData = UserDefaults.standard.data(forKey: backupKey),
           let decoded = try? JSONDecoder().decode([Goal].self, from: backupData) {
            goals = decoded
            print("⚠️ Loaded \(goals.count) goals from backup storage")
            // Restore backup to main storage
            if let encoded = try? JSONEncoder().encode(goals) {
                UserDefaults.standard.set(encoded, forKey: saveKey)
            }
            return
        }
        
        // If both fail, start with empty goals
        print("ℹ️ No saved goals found, starting with empty list")
        goals = []
    }
    
    private func createBackup() {
        if let encoded = try? JSONEncoder().encode(goals) {
            UserDefaults.standard.set(encoded, forKey: backupKey)
        }
    }
    
    // MARK: - Data Recovery Methods
    
    func exportGoals() -> String? {
        print("🔍 GoalStore.exportGoals: Starting export of \(goals.count) goals")
        
        guard !goals.isEmpty else {
            print("❌ GoalStore.exportGoals: No goals to export")
            return nil
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let encoded = try encoder.encode(goals)
            let jsonString = String(data: encoded, encoding: .utf8)
            
            print("✅ GoalStore.exportGoals: Successfully encoded \(encoded.count) bytes")
            print("🔍 JSON Preview: \(String(jsonString?.prefix(200) ?? "nil"))")
            
            return jsonString
        } catch {
            print("❌ GoalStore.exportGoals: Encoding failed with error: \(error)")
            return nil
        }
    }
    
    func importGoals(from jsonString: String) -> Bool {
        guard let data = jsonString.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([Goal].self, from: data) else {
            return false
        }
        
        goals = decoded
        saveGoals()
        return true
    }
    
    func clearAllData() {
        goals = []
        UserDefaults.standard.removeObject(forKey: saveKey)
        UserDefaults.standard.removeObject(forKey: backupKey)
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - Data Validation
    
    func validateData() -> Bool {
        // Check if goals have valid data
        for goal in goals {
            if goal.name.isEmpty || goal.durationInDays <= 0 {
                return false
            }
        }
        return true
    }
    
    // MARK: - Debug/Test Functions
    
    func addTestGoals() {
        print("🧪 GoalStore.addTestGoals: Adding test goals")
        
        let testGoals = [
            Goal(name: "Test Goal 1", durationInDays: 7, startDate: Date()),
            Goal(name: "Test Goal 2", durationInDays: 14, startDate: Date().addingTimeInterval(86400)),
            Goal(name: "Test Goal 3", durationInDays: 30, startDate: Date().addingTimeInterval(172800))
        ]
        
        for goal in testGoals {
            addGoal(goal)
        }
        
        print("🧪 GoalStore.addTestGoals: Added \(testGoals.count) test goals. Total goals: \(goals.count)")
    }
    
    var activeGoals: [Goal] {
        goals.filter { !$0.isCompleted }
    }
    
    var completedGoals: [Goal] {
        goals.filter { $0.isCompleted }
    }
    
    var overdueGoals: [Goal] {
        goals.filter { $0.isOverdue }
    }
}
