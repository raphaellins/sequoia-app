import WidgetKit
import SwiftUI

@main
struct RoadmapGoalsWidgetBundle: WidgetBundle {
    var body: some Widget {
        ActiveGoalsWidget()
        EnhancedActiveGoalsWidget()
        ConfigurableActiveGoalsWidget()
    }
}
