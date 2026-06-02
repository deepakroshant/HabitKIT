# HabitKIT — Free iOS Habit Tracker

A pixel-faithful, free clone of the paid [HabitKit](https://apps.apple.com/app/habitkit/id1445651730) iOS app, built with **SwiftUI + SwiftData**. Runs entirely on-device — no account, no subscription, no server.

---

## Screenshots

> Add yours after running on device — heatmap, today list, stats tab

---

## Features

### 📋 Daily Task List
- Every habit appears as a to-do each morning
- Tap **Did It!** to log with a confetti burst animation
- Completed habits move to a **Done** section showing exact completion time
- **Undo** any entry instantly
- Scroll back up to 14 days via the **day strip** and log past days

### 🔥 Streak Tracking
- Live streak counter on every habit row
- Supports **daily** and **weekly target** modes (2×–6× per week)
- Weekly habits count consecutive weeks meeting the target
- Best streak tracked across all time

### 🗺️ Heatmap View
- Tap **Heatmaps** in the toggle at the top of the home screen
- Full scrollable dot-grid showing the last 18 weeks per habit
- Tap any dot to toggle a past day directly from the heatmap

### 📊 Stats Tab
- Total completions, perfect days, active habit count
- Best habit by current streak
- **Most Active Day** bar chart — see which day of the week you're most consistent
- Per-habit monthly completion percentage bar

### 🔍 Habit Detail
- Year heatmap (last 52 weeks)
- Last 8 weeks bar chart (Swift Charts)
- 4 stat cards: current streak, best streak, this month %, total completions
- Recent notes history
- **Export** the year heatmap as an image to share

### ✏️ Add / Edit Habits
- Emoji icon picker (30 icons)
- 12-colour palette picker
- **Frequency**: Every day / 2×–6× per week
- **Custom reminder time** per habit (personal notification at your chosen time)

### ⏸️ Pause & Resume
- Pause any habit with an optional reason (injury, travel, etc.)
- Streak and history fully preserved while paused
- Paused habits appear in a separate dimmed section
- One tap to Resume

### 📝 Notes on Completion
- Add a note to any completed habit entry (e.g. "ran 5 km")
- Notes preview inline on the Done row
- Full notes history in the habit detail view

### 🔔 Smart Notifications
- **8:00 AM** — lists all habits to complete today
- **8:00 PM** — dynamically updated: shows how many are left, or celebrates if all done
- **Custom per-habit reminders** at your chosen time
- Evening notification reschedules itself every time you log a habit
- Foreground banners work even while the app is open (for testing)
- Test button in Settings fires a preview notification in 5 seconds

### ⚙️ Settings
- Toggle haptic feedback
- Toggle all daily reminders
- Week starts on Monday / Sunday
- **Reset all data** with confirmation
- Test notification button

### 🛠️ Technical
- **SwiftUI** (iOS 17+)
- **SwiftData** for local persistence (no iCloud, no server)
- **Swift Charts** for bar charts
- `UNUserNotificationCenter` for local push notifications
- `UIImpactFeedbackGenerator` for haptics
- Auto-repair on SwiftData schema changes (no manual app deletion needed)
- Dark mode only

---

## Getting Started

### Requirements
- Xcode 15+
- iOS 17+ device or simulator

### Run locally
```bash
git clone https://github.com/deepakroshant/HabitKIT.git
cd HabitKIT
open HabitKIT/HabitKIT/HabitKIT.xcodeproj
```
Press `Cmd+R` in Xcode.

### Run on your iPhone
1. Connect via USB-C and trust the computer
2. Xcode → select your iPhone as the run destination
3. **Signing & Capabilities** → set your Apple ID as the Team
4. Change Bundle Identifier to something unique (e.g. `com.yourname.habitkit`)
5. `Cmd+R`

---

## Project Structure

```
HabitKIT/
├── Models/
│   ├── Habit.swift          # SwiftData model — name, icon, color, streak config
│   └── HabitEntry.swift     # SwiftData model — date, completedAt, note
├── Helpers/
│   ├── HabitStats.swift     # Streak + completion calculations (daily & weekly)
│   ├── DateHelpers.swift    # startOfDay, adding(days:), weekColumns
│   └── ColorHelpers.swift   # Color(hex:), toHex(), 12 preset colours
├── Views/
│   ├── Home/
│   │   ├── HomeView.swift        # Daily task list, confetti, day strip
│   │   ├── DayStripView.swift    # 14-day scrollable date picker
│   │   ├── HeatmapGridView.swift # N-week dot grid
│   │   ├── HabitRowView.swift    # Heatmap row (used in Heatmaps tab)
│   │   ├── ConfettiView.swift    # Particle burst animation
│   │   ├── PauseHabitSheet.swift # Pause with reason sheet
│   │   └── AddNoteSheet.swift    # Add/edit completion note
│   ├── AddEdit/
│   │   ├── AddEditHabitView.swift  # Create/edit form
│   │   ├── IconPickerView.swift    # Emoji grid
│   │   └── ColorPickerView.swift   # Colour swatches
│   ├── Detail/
│   │   ├── HabitDetailView.swift   # Full stats + heatmap + export
│   │   ├── YearHeatmapView.swift   # 52-week grid
│   │   └── WeeklyChartView.swift   # Swift Charts bar chart
│   ├── Stats/
│   │   └── StatsView.swift         # Overview stats + best-day chart
│   ├── Settings/
│   │   └── SettingsView.swift      # Prefs + notification test
│   └── MainTabView.swift
├── NotificationManager.swift   # Local notification scheduling
└── HabitKITApp.swift           # Entry point + SwiftData container
```

---

## Licence

MIT — free to use, modify, and distribute.
