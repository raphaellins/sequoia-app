import Foundation

struct Goal: Identifiable, Codable {
    var id = UUID()
    var name: String
    var durationInDays: Int
    var startDate: Date
    var isCompleted: Bool = false
    var priority: Priority = .medium
    var description: String = ""
    
    enum Priority: String, CaseIterable, Codable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        
        var color: String {
            switch self {
            case .low: return "green"
            case .medium: return "orange"
            case .high: return "red"
            }
        }
    }
    
    var endDate: Date {
        Calendar.current.date(byAdding: .day, value: durationInDays, to: startDate) ?? startDate
    }
    
    var progress: Double {
        let totalDays = Double(durationInDays)
        let elapsedDays = Double(Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0)
        return min(max(elapsedDays / totalDays, 0), 1)
    }
    
    var isOverdue: Bool {
        Date() > endDate && !isCompleted
    }
    
    var isInProgress: Bool {
        let now = Date()
        return now >= startDate && now <= endDate && !isCompleted
    }
}
