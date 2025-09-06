# Roadmap Goals - iOS App

A comprehensive SwiftUI iOS app for managing and visualizing goals in a roadmap format, similar to Jira and GitHub roadmaps.

## Features

### 🎯 Goal Management
- **Create Goals**: Set name, duration, start date, priority, and description
- **Track Progress**: Visual progress indicators for ongoing goals
- **Priority Levels**: Low, Medium, and High priority with color coding
- **Status Tracking**: Mark goals as completed or incomplete
- **Overdue Detection**: Automatic detection and highlighting of overdue goals

### 📊 Roadmap Visualization
- **Timeline View**: Visual timeline similar to Jira/GitHub roadmaps
- **Multiple Timeframes**: Week, Month, and Quarter views
- **Interactive Navigation**: Navigate through different time periods
- **Today Indicator**: Red line showing current date on timeline
- **Goal Positioning**: Goals positioned accurately on timeline based on start/end dates

### 📱 User Interface
- **Tab Navigation**: Separate tabs for Goals list and Roadmap view
- **Filtering**: Filter goals by All, Active, Completed, or Overdue
- **Swipe Actions**: Quick actions for completing and deleting goals
- **Modern Design**: Clean, intuitive interface following iOS design guidelines
- **Responsive Layout**: Works on both iPhone and iPad

### 💾 Data Persistence
- **Local Storage**: Goals saved using UserDefaults
- **Automatic Sync**: Changes automatically saved to device
- **Data Integrity**: Proper encoding/decoding with Codable

## Technical Stack

- **SwiftUI**: Modern declarative UI framework
- **iOS 17.0+**: Latest iOS features and APIs
- **Xcode 15.0+**: Latest development tools
- **Swift 5.0**: Latest Swift language features
- **MVVM Architecture**: Clean separation of concerns

## Project Structure

```
RoadmapGoals/
├── RoadmapGoalsApp.swift      # Main app entry point
├── ContentView.swift          # Main tab navigation
├── Goal.swift                 # Data model for goals
├── GoalStore.swift            # Data management and persistence
├── GoalListView.swift         # Goals list with filtering
├── AddGoalView.swift          # Form for adding new goals
├── RoadmapView.swift          # Timeline visualization
└── Assets.xcassets/           # App icons and colors
```

## Getting Started

### Prerequisites
- macOS with Xcode 15.0 or later
- iOS 17.0+ device or simulator

### Installation
1. Clone or download this project
2. Open `RoadmapGoals.xcodeproj` in Xcode
3. Select your target device or simulator
4. Build and run the project (⌘+R)

### Usage

#### Adding Goals
1. Tap the "Goals" tab
2. Tap the "+" button in the top right
3. Fill in the goal details:
   - **Name**: Required field
   - **Duration**: Number of days (1-365)
   - **Start Date**: When the goal begins
   - **Priority**: Low, Medium, or High
   - **Description**: Optional details
4. Tap "Save"

#### Managing Goals
- **View Goals**: See all goals in the Goals tab
- **Filter Goals**: Use the segmented control to filter by status
- **Complete Goals**: Swipe left on a goal and tap "Mark Complete"
- **Delete Goals**: Swipe left on a goal and tap "Delete"

#### Roadmap View
1. Tap the "Roadmap" tab
2. Use the timeframe picker to switch between Week/Month/Quarter views
3. Navigate through time using the arrow buttons
4. Tap "Today" to return to current date
5. Goals appear as colored bars on the timeline

## Key Features Explained

### Goal Model
The `Goal` struct includes:
- Unique identifier
- Name and description
- Duration in days
- Start and calculated end dates
- Priority level with color coding
- Completion status
- Progress calculation
- Overdue detection

### Data Management
The `GoalStore` class provides:
- Observable object for SwiftUI integration
- CRUD operations for goals
- Automatic persistence using UserDefaults
- Filtered views for different goal states

### Timeline Visualization
The roadmap view features:
- Dynamic timeline positioning
- Goal bars sized proportionally to duration
- Color coding based on priority and status
- Today indicator line
- Smooth navigation between time periods

## Customization

### Colors
- Priority colors can be modified in `Goal.Priority.color`
- Timeline colors are customizable in `GoalTimelineCard`
- Accent color can be changed in the app's asset catalog

### Timeframes
- Additional timeframes can be added to `RoadmapView.Timeframe`
- Default timeframe can be changed in `selectedTimeframe`

### Goal Properties
- Additional goal properties can be added to the `Goal` struct
- Remember to update the Codable implementation for persistence

## Best Practices Used

- **MVVM Architecture**: Clean separation of data and UI
- **SwiftUI Best Practices**: Proper use of @StateObject, @EnvironmentObject
- **Data Persistence**: Efficient local storage with UserDefaults
- **Error Handling**: Graceful handling of edge cases
- **Performance**: Lazy loading and efficient data filtering
- **Accessibility**: Proper semantic markup and navigation

## Future Enhancements

Potential features for future versions:
- Cloud synchronization
- Goal categories/tags
- Team collaboration
- Notifications and reminders
- Export/import functionality
- Advanced analytics and reporting
- Dark mode optimization
- Audio playback and scheduling

## License

This project is created for educational and personal use. Feel free to modify and extend it according to your needs.

## Support

For questions or issues, please refer to the code comments or create an issue in the project repository.
