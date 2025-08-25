# Widget Setup Guide

This guide will help you add the Active Goals widget to your iOS app.

## Step 1: Add Widget Extension Target

1. In Xcode, go to **File** → **New** → **Target**
2. Select **Widget Extension** under iOS
3. Name it "RoadmapGoalsWidget"
4. Make sure "Include Configuration Intent" is **unchecked**
5. Click **Finish**

## Step 2: Configure Widget Files

1. Replace the generated widget files with the ones provided:
   - Replace `WidgetBundle.swift` with our version
   - Replace the main widget file with `ActiveGoalsWidget.swift`
   - Add `WidgetPreview.swift` for testing

## Step 3: Configure App Groups (Optional but Recommended)

For better data sharing between the main app and widget:

1. Select your main app target
2. Go to **Signing & Capabilities**
3. Click **+ Capability** and add **App Groups**
4. Create a group: `group.com.yourapp.roadmapgoals`
5. Repeat for the widget target

## Step 4: Update Bundle Identifiers

Make sure your widget target has a bundle identifier that matches your main app:
- Main app: `com.yourapp.roadmapgoals`
- Widget: `com.yourapp.roadmapgoals.widget`

## Step 5: Build and Test

1. Build the project (⌘+B)
2. Run the app on a device or simulator
3. Add the widget to your home screen:
   - Long press on home screen
   - Tap the "+" button
   - Search for "RoadmapGoalsWidget"
   - Add the widget

## Widget Features

The app includes three different widget types:

### 1. Active Goals Widget (Basic)
- **Small**: Up to 2 active goals
- **Medium**: Up to 4 active goals  
- **Large**: Up to 8 active goals

### 2. Enhanced Active Goals Widget
- Same sizes as basic widget
- Shows progress bars and days remaining
- Better visual design with gradients
- Sorts by priority and deadline

### 3. Configurable Active Goals Widget
- Same sizes as other widgets
- User-configurable options:
  - Show/hide progress bars
  - Show/hide days remaining
  - Sort by: Priority, Deadline, or Name
- Most flexible option

Each goal shows:
- Priority indicator (colored dot)
- Goal name
- Progress bar (if in progress and enabled)
- Days remaining (if enabled)
- Overdue indicator (if applicable)

The widgets automatically update when:
- Goals are added/removed
- Goals are marked complete/incomplete
- Every 30 minutes (background refresh)

## Troubleshooting

If the widget doesn't show data:
1. Make sure you have active (non-completed) goals in the app
2. Check that the widget has permission to access data
3. Try removing and re-adding the widget
4. Restart the device if needed

## Customization

You can customize the widget by modifying:
- `ActiveGoalsWidgetView.swift` - Visual appearance
- `ActiveGoalsTimelineProvider.swift` - Data loading and refresh frequency
- `GoalWidgetRow.swift` - Individual goal row appearance
