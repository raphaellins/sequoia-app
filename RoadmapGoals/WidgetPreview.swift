import SwiftUI
import WidgetKit

struct WidgetPreview: View {
    var body: some View {
        Group {
            // Small Widget Preview
            ActiveGoalsWidgetView(entry: ActiveGoalsTimelineEntry(
                date: Date(),
                activeGoals: [
                    Goal(name: "Learn SwiftUI", durationInDays: 30, startDate: Date().addingTimeInterval(-86400 * 10)),
                    Goal(name: "Build Widget", durationInDays: 7, startDate: Date().addingTimeInterval(-86400 * 2))
                ],
                family: .systemSmall
            ))
            .frame(width: 158, height: 158)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(radius: 5)
            
            // Medium Widget Preview
            ActiveGoalsWidgetView(entry: ActiveGoalsTimelineEntry(
                date: Date(),
                activeGoals: [
                    Goal(name: "Learn SwiftUI", durationInDays: 30, startDate: Date().addingTimeInterval(-86400 * 10)),
                    Goal(name: "Build Widget", durationInDays: 7, startDate: Date().addingTimeInterval(-86400 * 2)),
                    Goal(name: "App Store Review", durationInDays: 14, startDate: Date()),
                    Goal(name: "User Testing", durationInDays: 5, startDate: Date().addingTimeInterval(86400 * 3))
                ],
                family: .systemMedium
            ))
            .frame(width: 329, height: 155)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(radius: 5)
            
            // Large Widget Preview
            ActiveGoalsWidgetView(entry: ActiveGoalsTimelineEntry(
                date: Date(),
                activeGoals: [
                    Goal(name: "Learn SwiftUI", durationInDays: 30, startDate: Date().addingTimeInterval(-86400 * 10)),
                    Goal(name: "Build Widget", durationInDays: 7, startDate: Date().addingTimeInterval(-86400 * 2)),
                    Goal(name: "App Store Review", durationInDays: 14, startDate: Date()),
                    Goal(name: "User Testing", durationInDays: 5, startDate: Date().addingTimeInterval(86400 * 3)),
                    Goal(name: "Marketing Campaign", durationInDays: 21, startDate: Date().addingTimeInterval(86400 * 7)),
                    Goal(name: "Bug Fixes", durationInDays: 3, startDate: Date().addingTimeInterval(86400 * 5))
                ],
                family: .systemLarge
            ))
            .frame(width: 329, height: 345)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(radius: 5)
        }
        .padding()
    }
}

#Preview {
    WidgetPreview()
}
