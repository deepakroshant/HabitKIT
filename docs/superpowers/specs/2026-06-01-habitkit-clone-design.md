# HabitKit iOS Clone — Design Spec

**Date:** 2026-06-01  
**Platform:** iOS (SwiftUI + SwiftData)  
**Goal:** Free, locally-run iOS habit tracker that is a pixel-accurate clone of HabitKit

---

## Overview

A native iOS app for tracking daily habits (gym, instrument practice, supplements, etc.) with a GitHub-style heatmap grid per habit, streak tracking, and detailed stats. All data stored locally via SwiftData — no account, no subscription, no cost.

---

## Screens

### 1. Home Screen
- List of all habits, each showing:
  - Emoji icon + habit name
  - Horizontally scrollable heatmap dot-grid (18 weeks visible, scrolls back in time)
  - Current streak badge (🔥 N)
  - Tap any dot to toggle completion for that day
- `+` button (top right) to add a new habit
- Long-press a habit row → Edit / Delete actions
- Empty state when no habits exist

### 2. Add / Edit Habit Sheet
- Text field: habit name
- Emoji icon picker (grid of common emojis)
- Color picker (12 preset colors matching HabitKit palette)
- Frequency selector: Every day / Specific days of week
- Save and Cancel buttons

### 3. Habit Detail View
- Full-year heatmap (52 weeks × 7 days)
- Stats cards: Current Streak, Best Streak, Completion % (this month), Total Completions
- Weekly bar chart (last 8 weeks)
- Edit button in nav bar

### 4. Stats Overview Tab
- Best habit (highest current streak)
- Total completions across all habits
- Perfect days (days where every habit was completed)
- Monthly completion line chart

### 5. Settings Screen
- Appearance: Dark / Light / System
- Week start: Monday / Sunday
- Haptic feedback: On / Off
- Reset all data (with confirmation alert)

---

## Architecture

### Tech Stack
- **SwiftUI** — all UI, iOS 17+
- **SwiftData** — local persistence, no server required
- **UIImpactFeedbackGenerator** — haptic on habit completion
- **Charts (Swift Charts)** — bar/line charts in detail and stats views
- **Xcode** — free, runs on simulator with no Apple Developer account

### File Structure
```
HabitKIT/
  App/
    HabitKITApp.swift        # @main, ModelContainer setup
  Models/
    Habit.swift              # @Model
    HabitEntry.swift         # @Model
  Views/
    Home/
      HomeView.swift
      HabitRowView.swift
      HeatmapGridView.swift
    AddEdit/
      AddEditHabitView.swift
      IconPickerView.swift
      ColorPickerView.swift
    Detail/
      HabitDetailView.swift
      YearHeatmapView.swift
      WeeklyChartView.swift
    Stats/
      StatsView.swift
    Settings/
      SettingsView.swift
  Helpers/
    DateHelpers.swift
    ColorHelpers.swift
```

### Data Model

```swift
@Model
class Habit {
    var id: UUID
    var name: String
    var icon: String        // emoji character
    var colorHex: String    // e.g. "#4FC14F"
    var createdAt: Date
    var sortOrder: Int
    @Relationship(deleteRule: .cascade) var entries: [HabitEntry]
}

@Model
class HabitEntry {
    var date: Date          // normalized to midnight (start of day)
    var habit: Habit
}
```

---

## Key Interactions

- **Tap dot on heatmap** → toggle HabitEntry for that date, haptic feedback
- **Today's dot** → highlighted with color border
- **Long-press habit row** → context menu: Edit, Delete
- **Swipe left on habit row** → Delete shortcut
- **All past dates editable** — can backfill missed days

---

## Build Order

1. Xcode project setup + SwiftData models
2. HomeView + HabitRowView (static data)
3. HeatmapGridView (the core visual component)
4. Tap-to-toggle logic wired to SwiftData
5. AddEditHabitView sheet (create/edit habits)
6. HabitDetailView + YearHeatmapView
7. StatsView + WeeklyChartView
8. SettingsView
9. Polish: animations, haptics, empty states, dark mode

---

## Out of Scope (v1)
- Notifications / reminders
- iCloud sync
- Widgets
- Apple Watch companion
- Data export
