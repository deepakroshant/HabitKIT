# HabitKit iOS Clone — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a pixel-accurate SwiftUI clone of HabitKit — a free, locally-stored iOS habit tracker with heatmap grids, streaks, and stats.

**Architecture:** SwiftData models (Habit + HabitEntry) power all persistence. Pure Swift logic in HabitStats computes streaks/completion. SwiftUI views are composable and driven by `@Query` / `@Bindable` macros. No networking, no accounts.

**Tech Stack:** Swift 5.9+, SwiftUI, SwiftData, Swift Charts — all free, all local, iOS 17+, Xcode 15+

---

## File Map

```
HabitKIT/
  HabitKITApp.swift               # @main + ModelContainer
  Models/
    Habit.swift                   # @Model — name, icon, color, entries
    HabitEntry.swift              # @Model — date, habit relationship
  Helpers/
    DateHelpers.swift             # startOfDay, daysBack, dateRange, weekColumns
    ColorHelpers.swift            # Color(hex:), preset palette
    HabitStats.swift              # currentStreak, bestStreak, completion%
  Views/
    Home/
      HomeView.swift              # @Query habits list, nav, + button
      HabitRowView.swift          # single habit row: icon/name/streak/heatmap
      HeatmapGridView.swift       # scrollable N-week dot grid
    AddEdit/
      AddEditHabitView.swift      # sheet: name + icon + color + save
      IconPickerView.swift        # emoji grid picker
      ColorPickerView.swift       # 12-color swatch picker
    Detail/
      HabitDetailView.swift       # nav to year heatmap + stats cards
      YearHeatmapView.swift       # 52-week full-year grid
      WeeklyChartView.swift       # Swift Charts bar chart last 8 weeks
    Stats/
      StatsView.swift             # aggregate stats across all habits
    Settings/
      SettingsView.swift          # theme, week start, haptics, reset

HabitKITTests/
  HabitStatsTests.swift           # streak + completion unit tests
  DateHelpersTests.swift          # date utility unit tests
```

---

## Task 1: Xcode Project Setup

**Files:**
- Create: `HabitKIT.xcodeproj` (via Xcode GUI)
- Modify: `HabitKITApp.swift`

- [ ] **Step 1: Create Xcode project**

  Open Xcode → File → New → Project → iOS → App
  - Product Name: `HabitKIT`
  - Team: None (or personal team)
  - Organization Identifier: `com.local.habitkit`
  - Interface: `SwiftUI`
  - Language: `Swift`
  - Storage: **SwiftData** ✓ (check this box)
  - Tests: ✓ (check Include Tests)

  Save to `/Users/deepak/HabitKIT/`

- [ ] **Step 2: Delete Xcode's generated boilerplate**

  Xcode generates `Item.swift` (a sample SwiftData model). Delete it:
  - Right-click `Item.swift` in Project Navigator → Delete → Move to Trash

- [ ] **Step 3: Create folder groups in Xcode**

  In Project Navigator, right-click `HabitKIT` group → New Group (without folder) for each:
  `Models`, `Helpers`, `Views/Home`, `Views/AddEdit`, `Views/Detail`, `Views/Stats`, `Views/Settings`

- [ ] **Step 4: Replace HabitKITApp.swift**

  Replace the entire file contents with:

  ```swift
  import SwiftUI
  import SwiftData

  @main
  struct HabitKITApp: App {
      var body: some Scene {
          WindowGroup {
              HomeView()
          }
          .modelContainer(for: [Habit.self, HabitEntry.self])
      }
  }
  ```

- [ ] **Step 5: Build to verify project compiles**

  Press `Cmd+B`. Expected: Build Succeeded (will fail on missing HomeView — that's OK, fix by adding a placeholder):

  Create `Views/Home/HomeView.swift` temporarily:
  ```swift
  import SwiftUI
  struct HomeView: View {
      var body: some View { Text("HabitKIT") }
  }
  ```

  Press `Cmd+B` again. Expected: **Build Succeeded**

- [ ] **Step 6: Commit**

  ```bash
  cd /Users/deepak/HabitKIT
  git init
  git add .
  git commit -m "feat: initial Xcode project setup"
  ```

---

## Task 2: SwiftData Models

**Files:**
- Create: `HabitKIT/Models/Habit.swift`
- Create: `HabitKIT/Models/HabitEntry.swift`

- [ ] **Step 1: Create Habit.swift**

  In Xcode, right-click the `Models` group → New File → Swift File → name it `Habit.swift`

  ```swift
  import Foundation
  import SwiftData

  @Model
  final class Habit {
      var id: UUID
      var name: String
      var icon: String
      var colorHex: String
      var createdAt: Date
      var sortOrder: Int
      @Relationship(deleteRule: .cascade) var entries: [HabitEntry] = []

      init(name: String, icon: String = "⭐", colorHex: String = "#4FC14F", sortOrder: Int = 0) {
          self.id = UUID()
          self.name = name
          self.icon = icon
          self.colorHex = colorHex
          self.createdAt = Date()
          self.sortOrder = sortOrder
      }
  }
  ```

- [ ] **Step 2: Create HabitEntry.swift**

  ```swift
  import Foundation
  import SwiftData

  @Model
  final class HabitEntry {
      var date: Date
      @Relationship var habit: Habit?

      init(date: Date, habit: Habit) {
          self.date = Calendar.current.startOfDay(for: date)
          self.habit = habit
      }
  }
  ```

- [ ] **Step 3: Build to verify models compile**

  Press `Cmd+B`. Expected: **Build Succeeded**

- [ ] **Step 4: Commit**

  ```bash
  git add HabitKIT/Models/
  git commit -m "feat: add SwiftData models Habit and HabitEntry"
  ```

---

## Task 3: Date and Color Helpers

**Files:**
- Create: `HabitKIT/Helpers/DateHelpers.swift`
- Create: `HabitKIT/Helpers/ColorHelpers.swift`

- [ ] **Step 1: Create DateHelpers.swift**

  ```swift
  import Foundation

  extension Date {
      var startOfDay: Date {
          Calendar.current.startOfDay(for: self)
      }

      func adding(days: Int) -> Date {
          Calendar.current.date(byAdding: .day, value: days, to: self)!
      }

      func adding(weeks: Int) -> Date {
          Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: self)!
      }
  }

  /// Returns the Monday of the week containing `date`.
  func mondayOfWeek(containing date: Date) -> Date {
      let cal = Calendar.current
      let weekday = cal.component(.weekday, from: date)
      // weekday: 1=Sun, 2=Mon, ... 7=Sat
      let daysToMonday = (weekday + 5) % 7
      return cal.startOfDay(for: date).adding(days: -daysToMonday)
  }

  /// Returns an array of Monday dates for the last `weeks` weeks,
  /// ending with the Monday of the current week.
  func weekColumns(weeks: Int, today: Date = Date()) -> [Date] {
      let thisMonday = mondayOfWeek(containing: today)
      return (0..<weeks).reversed().map { thisMonday.adding(weeks: -$0) }
  }
  ```

- [ ] **Step 2: Create ColorHelpers.swift**

  ```swift
  import SwiftUI

  extension Color {
      init?(hex: String) {
          let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
          var int: UInt64 = 0
          guard Scanner(string: hex).scanHexInt64(&int) else { return nil }
          let r, g, b: UInt64
          switch hex.count {
          case 6:
              (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
          default:
              return nil
          }
          self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255)
      }

      func toHex() -> String {
          let ui = UIColor(self)
          var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
          ui.getRed(&r, green: &g, blue: &b, alpha: nil)
          return String(format: "#%02X%02X%02X", Int(r*255), Int(g*255), Int(b*255))
      }
  }

  /// The 12 preset habit colors matching HabitKit's palette.
  let habitColors: [Color] = [
      Color(hex: "#4FC14F")!, // green
      Color(hex: "#5B8DEE")!, // blue
      Color(hex: "#C46EFF")!, // purple
      Color(hex: "#FF6B6B")!, // red
      Color(hex: "#FFB347")!, // orange
      Color(hex: "#FFE066")!, // yellow
      Color(hex: "#5BC8EF")!, // teal
      Color(hex: "#FF80AB")!, // pink
      Color(hex: "#A8E063")!, // lime
      Color(hex: "#FF8C42")!, // deep orange
      Color(hex: "#B0BEC5")!, // grey
      Color(hex: "#80DEEA")!, // cyan
  ]
  ```

- [ ] **Step 3: Build to verify**

  Press `Cmd+B`. Expected: **Build Succeeded**

- [ ] **Step 4: Commit**

  ```bash
  git add HabitKIT/Helpers/
  git commit -m "feat: add DateHelpers and ColorHelpers utilities"
  ```

---

## Task 4: HabitStats — Streak and Completion Logic

**Files:**
- Create: `HabitKIT/Helpers/HabitStats.swift`

- [ ] **Step 1: Create HabitStats.swift**

  ```swift
  import Foundation

  struct HabitStats {
      let currentStreak: Int
      let bestStreak: Int
      let completionThisMonth: Double  // 0.0 – 1.0
      let totalCompletions: Int

      static func calculate(for habit: Habit, today: Date = Date()) -> HabitStats {
          let todayStart = today.startOfDay
          let entrySet = Set(habit.entries.compactMap { $0.date.startOfDay as Date? })

          // Current streak: count consecutive days ending today
          var current = 0
          var day = todayStart
          while entrySet.contains(day) {
              current += 1
              day = day.adding(days: -1)
          }

          // Best streak: scan all sorted entry dates
          let sorted = entrySet.sorted()
          var best = 0
          var run = 0
          var prev: Date? = nil
          for d in sorted {
              if let p = prev, d == p.adding(days: 1) {
                  run += 1
              } else {
                  run = 1
              }
              if run > best { best = run }
              prev = d
          }

          // Completion this month (days 1 through today)
          let cal = Calendar.current
          let comps = cal.dateComponents([.year, .month], from: todayStart)
          let startOfMonth = cal.date(from: comps)!
          let dayOfMonth = cal.component(.day, from: todayStart)
          var completedThisMonth = 0
          for offset in 0..<dayOfMonth {
              let d = startOfMonth.adding(days: offset)
              if entrySet.contains(d) { completedThisMonth += 1 }
          }
          let completion = dayOfMonth > 0 ? Double(completedThisMonth) / Double(dayOfMonth) : 0

          return HabitStats(
              currentStreak: current,
              bestStreak: max(best, current),
              completionThisMonth: completion,
              totalCompletions: entrySet.count
          )
      }
  }
  ```

- [ ] **Step 2: Build to verify**

  Press `Cmd+B`. Expected: **Build Succeeded**

- [ ] **Step 3: Commit**

  ```bash
  git add HabitKIT/Helpers/HabitStats.swift
  git commit -m "feat: add HabitStats streak and completion calculation"
  ```

---

## Task 5: Unit Tests for HabitStats and DateHelpers

**Files:**
- Create: `HabitKITTests/HabitStatsTests.swift`
- Create: `HabitKITTests/DateHelpersTests.swift`

- [ ] **Step 1: Write DateHelpersTests.swift**

  In Xcode, open the `HabitKITTests` group → New File → Swift File → `DateHelpersTests.swift`

  ```swift
  import XCTest
  @testable import HabitKIT

  final class DateHelpersTests: XCTestCase {
      func test_startOfDay_zeroesTime() {
          let date = Date(timeIntervalSince1970: 1_700_000_000) // some time mid-day
          let sod = date.startOfDay
          let comps = Calendar.current.dateComponents([.hour, .minute, .second], from: sod)
          XCTAssertEqual(comps.hour, 0)
          XCTAssertEqual(comps.minute, 0)
          XCTAssertEqual(comps.second, 0)
      }

      func test_adding_days_positive() {
          let base = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 1))!
          let result = base.adding(days: 5)
          let comps = Calendar.current.dateComponents([.day, .month], from: result)
          XCTAssertEqual(comps.day, 6)
          XCTAssertEqual(comps.month, 1)
      }

      func test_mondayOfWeek_onWednesday() {
          // 2024-01-03 is a Wednesday
          let wed = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 3))!
          let monday = mondayOfWeek(containing: wed)
          let comps = Calendar.current.dateComponents([.year, .month, .day], from: monday)
          XCTAssertEqual(comps.year, 2024)
          XCTAssertEqual(comps.month, 1)
          XCTAssertEqual(comps.day, 1) // 2024-01-01 is Monday
      }

      func test_weekColumns_count() {
          let today = Date()
          let cols = weekColumns(weeks: 18, today: today)
          XCTAssertEqual(cols.count, 18)
      }

      func test_weekColumns_lastIsThisMonday() {
          let today = Date()
          let cols = weekColumns(weeks: 18, today: today)
          let thisMonday = mondayOfWeek(containing: today)
          XCTAssertEqual(cols.last!, thisMonday)
      }
  }
  ```

- [ ] **Step 2: Run DateHelpersTests**

  Press `Cmd+U` or click the diamond next to the class. Expected: All 5 tests **PASS**

- [ ] **Step 3: Write HabitStatsTests.swift**

  Because `HabitStats.calculate` takes a `Habit` (SwiftData model), we need a ModelContainer in tests.

  ```swift
  import XCTest
  import SwiftData
  @testable import HabitKIT

  @MainActor
  final class HabitStatsTests: XCTestCase {
      var container: ModelContainer!

      override func setUp() {
          super.setUp()
          let config = ModelConfiguration(isStoredInMemoryOnly: true)
          container = try! ModelContainer(for: Habit.self, HabitEntry.self, configurations: config)
      }

      override func tearDown() {
          container = nil
          super.tearDown()
      }

      private func makeHabit(name: String = "Test") -> Habit {
          let h = Habit(name: name)
          container.mainContext.insert(h)
          return h
      }

      private func addEntry(to habit: Habit, daysAgo: Int, today: Date = Date()) {
          let date = today.startOfDay.adding(days: -daysAgo)
          let entry = HabitEntry(date: date, habit: habit)
          container.mainContext.insert(entry)
          habit.entries.append(entry)
      }

      func test_currentStreak_consecutive() {
          let habit = makeHabit()
          let today = Date()
          addEntry(to: habit, daysAgo: 0, today: today)
          addEntry(to: habit, daysAgo: 1, today: today)
          addEntry(to: habit, daysAgo: 2, today: today)
          let stats = HabitStats.calculate(for: habit, today: today)
          XCTAssertEqual(stats.currentStreak, 3)
      }

      func test_currentStreak_gap_resets() {
          let habit = makeHabit()
          let today = Date()
          addEntry(to: habit, daysAgo: 0, today: today)
          // gap: daysAgo 1 missing
          addEntry(to: habit, daysAgo: 2, today: today)
          let stats = HabitStats.calculate(for: habit, today: today)
          XCTAssertEqual(stats.currentStreak, 1)
      }

      func test_currentStreak_noEntries_isZero() {
          let habit = makeHabit()
          let stats = HabitStats.calculate(for: habit, today: Date())
          XCTAssertEqual(stats.currentStreak, 0)
      }

      func test_bestStreak_nonConsecutive() {
          let habit = makeHabit()
          let today = Date()
          // 3-day streak ending 10 days ago
          addEntry(to: habit, daysAgo: 10, today: today)
          addEntry(to: habit, daysAgo: 11, today: today)
          addEntry(to: habit, daysAgo: 12, today: today)
          // 1-day streak today
          addEntry(to: habit, daysAgo: 0, today: today)
          let stats = HabitStats.calculate(for: habit, today: today)
          XCTAssertEqual(stats.bestStreak, 3)
      }

      func test_totalCompletions() {
          let habit = makeHabit()
          let today = Date()
          addEntry(to: habit, daysAgo: 0, today: today)
          addEntry(to: habit, daysAgo: 3, today: today)
          addEntry(to: habit, daysAgo: 7, today: today)
          let stats = HabitStats.calculate(for: habit, today: today)
          XCTAssertEqual(stats.totalCompletions, 3)
      }

      func test_completionThisMonth_perfect() {
          let habit = makeHabit()
          // Use 2024-01-05 as "today" (day 5 of month)
          let today = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 5))!
          for d in 0..<5 {
              addEntry(to: habit, daysAgo: d, today: today)
          }
          let stats = HabitStats.calculate(for: habit, today: today)
          XCTAssertEqual(stats.completionThisMonth, 1.0, accuracy: 0.01)
      }
  }
  ```

- [ ] **Step 4: Run HabitStatsTests**

  Press `Cmd+U`. Expected: All 6 tests **PASS**

- [ ] **Step 5: Commit**

  ```bash
  git add HabitKITTests/
  git commit -m "test: add unit tests for HabitStats and DateHelpers"
  ```

---

## Task 6: HeatmapGridView (Core Visual Component)

**Files:**
- Create: `HabitKIT/Views/Home/HeatmapGridView.swift`

- [ ] **Step 1: Create HeatmapGridView.swift**

  ```swift
  import SwiftUI

  struct HeatmapGridView: View {
      let habit: Habit
      var weeks: Int = 18
      let onToggle: (Date) -> Void

      private let cellSize: CGFloat = 11
      private let spacing: CGFloat = 3

      private var entrySet: Set<Date> {
          Set(habit.entries.map { $0.date.startOfDay })
      }

      private var accentColor: Color {
          Color(hex: habit.colorHex) ?? .green
      }

      var body: some View {
          let today = Date().startOfDay
          let columns = weekColumns(weeks: weeks)

          ScrollViewReader { proxy in
              ScrollView(.horizontal, showsIndicators: false) {
                  HStack(spacing: spacing) {
                      ForEach(columns, id: \.self) { monday in
                          VStack(spacing: spacing) {
                              ForEach(0..<7, id: \.self) { offset in
                                  let date = monday.adding(days: offset)
                                  DotView(
                                      date: date,
                                      today: today,
                                      isDone: entrySet.contains(date),
                                      color: accentColor,
                                      cellSize: cellSize
                                  )
                                  .onTapGesture {
                                      if date <= today { onToggle(date) }
                                  }
                              }
                          }
                          .id(monday)
                      }
                  }
                  .padding(.horizontal, 2)
              }
              .onAppear {
                  if let last = columns.last {
                      proxy.scrollTo(last, anchor: .trailing)
                  }
              }
          }
          .frame(height: cellSize * 7 + spacing * 6)
      }
  }

  private struct DotView: View {
      let date: Date
      let today: Date
      let isDone: Bool
      let color: Color
      let cellSize: CGFloat

      var body: some View {
          let isFuture = date > today
          let isToday = date == today

          RoundedRectangle(cornerRadius: 3)
              .fill(cellFill(isFuture: isFuture))
              .frame(width: cellSize, height: cellSize)
              .overlay(
                  RoundedRectangle(cornerRadius: 3)
                      .stroke(isToday && !isDone ? color.opacity(0.6) : .clear, lineWidth: 1.5)
              )
              .opacity(isFuture ? 0 : 1)
              .animation(.easeInOut(duration: 0.15), value: isDone)
      }

      private func cellFill(isFuture: Bool) -> Color {
          if isFuture { return .clear }
          return isDone ? color : Color.white.opacity(0.07)
      }
  }

  #Preview {
      let config = ModelConfiguration(isStoredInMemoryOnly: true)
      let container = try! ModelContainer(for: Habit.self, HabitEntry.self, configurations: config)
      let habit = Habit(name: "Exercise", icon: "🏃", colorHex: "#4FC14F")
      container.mainContext.insert(habit)
      // Add some sample entries
      for i in [0,1,2,4,5,7,8,9,10,14,15,16,20] {
          let entry = HabitEntry(date: Date().adding(days: -i), habit: habit)
          container.mainContext.insert(entry)
          habit.entries.append(entry)
      }
      return HeatmapGridView(habit: habit, weeks: 18) { _ in }
          .padding()
          .background(Color.black)
          .modelContainer(container)
  }
  ```

- [ ] **Step 2: Verify preview in Xcode**

  Click the Preview canvas button (or `Cmd+Option+P`). You should see a scrollable dot grid with green dots on a black background.

- [ ] **Step 3: Build**

  Press `Cmd+B`. Expected: **Build Succeeded**

- [ ] **Step 4: Commit**

  ```bash
  git add HabitKIT/Views/Home/HeatmapGridView.swift
  git commit -m "feat: add HeatmapGridView core visual component"
  ```

---

## Task 7: HabitRowView

**Files:**
- Create: `HabitKIT/Views/Home/HabitRowView.swift`

- [ ] **Step 1: Create HabitRowView.swift**

  ```swift
  import SwiftUI
  import SwiftData

  struct HabitRowView: View {
      let habit: Habit
      let onToggle: (Date) -> Void

      private var stats: HabitStats {
          HabitStats.calculate(for: habit)
      }

      private var accentColor: Color {
          Color(hex: habit.colorHex) ?? .green
      }

      var body: some View {
          VStack(alignment: .leading, spacing: 8) {
              HStack(spacing: 10) {
                  // Icon bubble
                  Text(habit.icon)
                      .font(.system(size: 16))
                      .frame(width: 32, height: 32)
                      .background(accentColor.opacity(0.15))
                      .clipShape(RoundedRectangle(cornerRadius: 8))

                  // Name
                  Text(habit.name)
                      .font(.system(size: 15, weight: .semibold))
                      .foregroundStyle(.primary)

                  Spacer()

                  // Streak badge
                  if stats.currentStreak > 0 {
                      HStack(spacing: 3) {
                          Text("🔥")
                              .font(.system(size: 12))
                          Text("\(stats.currentStreak)")
                              .font(.system(size: 13, weight: .bold))
                              .foregroundStyle(.primary)
                      }
                  }
              }

              HeatmapGridView(habit: habit, weeks: 18, onToggle: onToggle)
          }
          .padding(12)
          .background(Color(UIColor.secondarySystemBackground))
          .clipShape(RoundedRectangle(cornerRadius: 14))
      }
  }

  #Preview {
      let config = ModelConfiguration(isStoredInMemoryOnly: true)
      let container = try! ModelContainer(for: Habit.self, HabitEntry.self, configurations: config)
      let habit = Habit(name: "Practice Guitar", icon: "🎸", colorHex: "#C46EFF")
      container.mainContext.insert(habit)
      for i in [0,1,3,4,5,8,9,10,15,16] {
          let e = HabitEntry(date: Date().adding(days: -i), habit: habit)
          container.mainContext.insert(e)
          habit.entries.append(e)
      }
      return HabitRowView(habit: habit) { _ in }
          .padding()
          .background(Color(UIColor.systemBackground))
          .modelContainer(container)
          .preferredColorScheme(.dark)
  }
  ```

- [ ] **Step 2: Verify preview renders correctly**

  You should see an icon bubble, habit name, fire streak badge, and the heatmap grid.

- [ ] **Step 3: Build**

  Press `Cmd+B`. Expected: **Build Succeeded**

- [ ] **Step 4: Commit**

  ```bash
  git add HabitKIT/Views/Home/HabitRowView.swift
  git commit -m "feat: add HabitRowView with icon, streak badge, and heatmap"
  ```

---

## Task 8: HomeView with Toggle Logic

**Files:**
- Modify: `HabitKIT/Views/Home/HomeView.swift`

- [ ] **Step 1: Replace HomeView.swift with full implementation**

  ```swift
  import SwiftUI
  import SwiftData

  struct HomeView: View {
      @Environment(\.modelContext) private var context
      @Query(sort: \Habit.sortOrder) private var habits: [Habit]
      @State private var showAddSheet = false
      @State private var habitToEdit: Habit? = nil

      var body: some View {
          NavigationStack {
              Group {
                  if habits.isEmpty {
                      emptyState
                  } else {
                      habitList
                  }
              }
              .navigationTitle("Habits")
              .navigationBarTitleDisplayMode(.large)
              .toolbar {
                  ToolbarItem(placement: .topBarTrailing) {
                      Button {
                          showAddSheet = true
                      } label: {
                          Image(systemName: "plus.circle.fill")
                              .font(.system(size: 22))
                              .foregroundStyle(.green)
                      }
                  }
              }
              .sheet(isPresented: $showAddSheet) {
                  AddEditHabitView(habit: nil)
              }
              .sheet(item: $habitToEdit) { habit in
                  AddEditHabitView(habit: habit)
              }
          }
          .preferredColorScheme(.dark)
      }

      private var habitList: some View {
          ScrollView {
              LazyVStack(spacing: 10) {
                  ForEach(habits) { habit in
                      NavigationLink(destination: HabitDetailView(habit: habit)) {
                          HabitRowView(habit: habit) { date in
                              toggle(habit: habit, on: date)
                          }
                      }
                      .buttonStyle(.plain)
                      .contextMenu {
                          Button("Edit") { habitToEdit = habit }
                          Button("Delete", role: .destructive) { delete(habit) }
                      }
                  }
              }
              .padding(.horizontal, 16)
              .padding(.top, 8)
              .padding(.bottom, 40)
          }
      }

      private var emptyState: some View {
          VStack(spacing: 16) {
              Text("✦")
                  .font(.system(size: 48))
              Text("No habits yet")
                  .font(.title2).fontWeight(.bold)
              Text("Tap + to add your first habit")
                  .font(.subheadline).foregroundStyle(.secondary)
              Button("Add Habit") { showAddSheet = true }
                  .buttonStyle(.borderedProminent)
                  .tint(.green)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }

      private func toggle(habit: Habit, on date: Date) {
          let day = date.startOfDay
          if let existing = habit.entries.first(where: { $0.date == day }) {
              context.delete(existing)
              habit.entries.removeAll { $0.date == day }
          } else {
              let entry = HabitEntry(date: day, habit: habit)
              context.insert(entry)
              habit.entries.append(entry)
          }
          UIImpactFeedbackGenerator(style: .light).impactOccurred()
          try? context.save()
      }

      private func delete(_ habit: Habit) {
          context.delete(habit)
          try? context.save()
      }
  }

  #Preview {
      HomeView()
          .modelContainer(for: [Habit.self, HabitEntry.self], inMemory: true)
  }
  ```

- [ ] **Step 2: Build and run in Simulator**

  `Cmd+R` → pick iPhone 15 or any iOS 17 simulator.
  You should see the empty state "No habits yet" with an Add Habit button.

- [ ] **Step 3: Tap + and verify sheet opens** (AddEditHabitView not built yet — it will crash. That's fine, just verify navigation compiles)

- [ ] **Step 4: Commit**

  ```bash
  git add HabitKIT/Views/Home/HomeView.swift
  git commit -m "feat: add HomeView with habit list, toggle logic, and empty state"
  ```

---

## Task 9: AddEditHabitView (Icon + Color Picker)

**Files:**
- Create: `HabitKIT/Views/AddEdit/AddEditHabitView.swift`
- Create: `HabitKIT/Views/AddEdit/IconPickerView.swift`
- Create: `HabitKIT/Views/AddEdit/ColorPickerView.swift`

- [ ] **Step 1: Create IconPickerView.swift**

  ```swift
  import SwiftUI

  let habitIcons: [String] = [
      "🏃","🏋️","🧘","🚴","🏊","⚽","🎸","🎹","🎨","📚",
      "✍️","💊","💧","🥗","☕","🛌","🧹","💰","🌿","🧠",
      "❤️","🎯","🏆","⭐","🔥","💡","🌅","🎵","📝","🧪"
  ]

  struct IconPickerView: View {
      @Binding var selected: String
      let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

      var body: some View {
          LazyVGrid(columns: columns, spacing: 8) {
              ForEach(habitIcons, id: \.self) { icon in
                  Button(action: { selected = icon }) {
                      Text(icon)
                          .font(.system(size: 24))
                          .frame(width: 44, height: 44)
                          .background(selected == icon ? Color.white.opacity(0.15) : Color.clear)
                          .clipShape(RoundedRectangle(cornerRadius: 10))
                          .overlay(
                              RoundedRectangle(cornerRadius: 10)
                                  .stroke(selected == icon ? Color.white.opacity(0.5) : .clear, lineWidth: 1.5)
                          )
                  }
              }
          }
      }
  }
  ```

- [ ] **Step 2: Create ColorPickerView.swift**

  ```swift
  import SwiftUI

  struct ColorPickerView: View {
      @Binding var selectedHex: String

      var body: some View {
          HStack(spacing: 10) {
              ForEach(habitColors, id: \.self) { color in
                  let hex = color.toHex()
                  Button(action: { selectedHex = hex }) {
                      Circle()
                          .fill(color)
                          .frame(width: 30, height: 30)
                          .overlay(
                              Circle().stroke(Color.white, lineWidth: selectedHex == hex ? 2.5 : 0)
                          )
                          .scaleEffect(selectedHex == hex ? 1.15 : 1.0)
                          .animation(.spring(duration: 0.2), value: selectedHex)
                  }
              }
          }
      }
  }
  ```

- [ ] **Step 3: Create AddEditHabitView.swift**

  ```swift
  import SwiftUI
  import SwiftData

  struct AddEditHabitView: View {
      @Environment(\.modelContext) private var context
      @Environment(\.dismiss) private var dismiss
      @Query(sort: \Habit.sortOrder) private var habits: [Habit]

      let habit: Habit?  // nil = adding new habit

      @State private var name: String = ""
      @State private var icon: String = "⭐"
      @State private var colorHex: String = "#4FC14F"

      var isEditing: Bool { habit != nil }

      var body: some View {
          NavigationStack {
              Form {
                  Section("Name") {
                      TextField("e.g. Go to the gym", text: $name)
                          .font(.system(size: 16))
                  }

                  Section("Icon") {
                      IconPickerView(selected: $icon)
                          .padding(.vertical, 4)
                  }

                  Section("Color") {
                      ColorPickerView(selectedHex: $colorHex)
                          .padding(.vertical, 8)
                  }
              }
              .scrollContentBackground(.hidden)
              .background(Color(UIColor.systemGroupedBackground))
              .navigationTitle(isEditing ? "Edit Habit" : "New Habit")
              .navigationBarTitleDisplayMode(.inline)
              .toolbar {
                  ToolbarItem(placement: .cancellationAction) {
                      Button("Cancel") { dismiss() }
                  }
                  ToolbarItem(placement: .confirmationAction) {
                      Button("Save") { save() }
                          .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                          .fontWeight(.semibold)
                  }
              }
              .onAppear {
                  if let h = habit {
                      name = h.name
                      icon = h.icon
                      colorHex = h.colorHex
                  }
              }
          }
          .preferredColorScheme(.dark)
      }

      private func save() {
          let trimmed = name.trimmingCharacters(in: .whitespaces)
          if let h = habit {
              h.name = trimmed
              h.icon = icon
              h.colorHex = colorHex
          } else {
              let h = Habit(name: trimmed, icon: icon, colorHex: colorHex, sortOrder: habits.count)
              context.insert(h)
          }
          try? context.save()
          dismiss()
      }
  }

  #Preview {
      AddEditHabitView(habit: nil)
          .modelContainer(for: [Habit.self, HabitEntry.self], inMemory: true)
  }
  ```

- [ ] **Step 4: Run in Simulator**

  `Cmd+R` → tap `+` → AddEditHabitView sheet appears. Type a name, pick an icon and color, tap Save. Habit appears in the list. Tap dots on the heatmap to toggle.

- [ ] **Step 5: Commit**

  ```bash
  git add HabitKIT/Views/AddEdit/
  git commit -m "feat: add AddEditHabitView with icon and color pickers"
  ```

---

## Task 10: HabitDetailView + YearHeatmapView

**Files:**
- Create: `HabitKIT/Views/Detail/HabitDetailView.swift`
- Create: `HabitKIT/Views/Detail/YearHeatmapView.swift`

- [ ] **Step 1: Create YearHeatmapView.swift**

  ```swift
  import SwiftUI

  struct YearHeatmapView: View {
      let habit: Habit
      private let cellSize: CGFloat = 9
      private let spacing: CGFloat = 2.5

      private var entrySet: Set<Date> {
          Set(habit.entries.map { $0.date.startOfDay })
      }

      private var accentColor: Color {
          Color(hex: habit.colorHex) ?? .green
      }

      var body: some View {
          let today = Date().startOfDay
          let columns = weekColumns(weeks: 52)

          ScrollViewReader { proxy in
              ScrollView(.horizontal, showsIndicators: false) {
                  HStack(spacing: spacing) {
                      ForEach(columns, id: \.self) { monday in
                          VStack(spacing: spacing) {
                              ForEach(0..<7, id: \.self) { offset in
                                  let date = monday.adding(days: offset)
                                  let done = entrySet.contains(date.startOfDay)
                                  let isFuture = date > today
                                  RoundedRectangle(cornerRadius: 2)
                                      .fill(isFuture ? .clear : (done ? accentColor : Color.white.opacity(0.07)))
                                      .frame(width: cellSize, height: cellSize)
                              }
                          }
                          .id(monday)
                      }
                  }
                  .padding(.horizontal, 2)
              }
              .onAppear {
                  if let last = columns.last {
                      proxy.scrollTo(last, anchor: .trailing)
                  }
              }
          }
          .frame(height: cellSize * 7 + spacing * 6)
      }
  }
  ```

- [ ] **Step 2: Create HabitDetailView.swift**

  ```swift
  import SwiftUI
  import SwiftData

  struct HabitDetailView: View {
      @Environment(\.modelContext) private var context
      @Bindable var habit: Habit
      @State private var showEdit = false

      private var stats: HabitStats {
          HabitStats.calculate(for: habit)
      }

      private var accentColor: Color {
          Color(hex: habit.colorHex) ?? .green
      }

      var body: some View {
          ScrollView {
              VStack(alignment: .leading, spacing: 24) {
                  // Header
                  HStack(spacing: 12) {
                      Text(habit.icon)
                          .font(.system(size: 36))
                          .frame(width: 60, height: 60)
                          .background(accentColor.opacity(0.15))
                          .clipShape(RoundedRectangle(cornerRadius: 16))
                      Text(habit.name)
                          .font(.title).fontWeight(.bold)
                  }
                  .padding(.top, 8)

                  // Stats cards
                  HStack(spacing: 12) {
                      StatCard(value: "\(stats.currentStreak)", label: "Current Streak", color: accentColor)
                      StatCard(value: "\(stats.bestStreak)", label: "Best Streak", color: accentColor)
                      StatCard(value: "\(Int(stats.completionThisMonth * 100))%", label: "This Month", color: accentColor)
                  }

                  // Year heatmap
                  VStack(alignment: .leading, spacing: 8) {
                      Text("Past 12 Months")
                          .font(.footnote).fontWeight(.semibold).foregroundStyle(.secondary)
                      YearHeatmapView(habit: habit)
                  }

                  // Weekly chart
                  VStack(alignment: .leading, spacing: 8) {
                      Text("Last 8 Weeks")
                          .font(.footnote).fontWeight(.semibold).foregroundStyle(.secondary)
                      WeeklyChartView(habit: habit)
                  }

                  // Total completions
                  HStack {
                      Text("Total completions")
                          .font(.subheadline).foregroundStyle(.secondary)
                      Spacer()
                      Text("\(stats.totalCompletions)")
                          .font(.subheadline).fontWeight(.bold)
                  }
                  .padding(.horizontal, 4)
              }
              .padding(.horizontal, 20)
              .padding(.bottom, 40)
          }
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
              ToolbarItem(placement: .topBarTrailing) {
                  Button("Edit") { showEdit = true }
              }
          }
          .sheet(isPresented: $showEdit) {
              AddEditHabitView(habit: habit)
          }
          .preferredColorScheme(.dark)
      }
  }

  private struct StatCard: View {
      let value: String
      let label: String
      let color: Color

      var body: some View {
          VStack(spacing: 4) {
              Text(value)
                  .font(.title2).fontWeight(.bold)
                  .foregroundStyle(color)
              Text(label)
                  .font(.caption2)
                  .foregroundStyle(.secondary)
                  .multilineTextAlignment(.center)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 14)
          .background(Color(UIColor.secondarySystemBackground))
          .clipShape(RoundedRectangle(cornerRadius: 12))
      }
  }
  ```

- [ ] **Step 3: Run in Simulator**

  Add a habit, tap dots to mark some days, then tap the habit row to navigate to HabitDetailView. Verify stats cards and year heatmap show.

- [ ] **Step 4: Commit**

  ```bash
  git add HabitKIT/Views/Detail/
  git commit -m "feat: add HabitDetailView with year heatmap and stats cards"
  ```

---

## Task 11: WeeklyChartView (Swift Charts)

**Files:**
- Create: `HabitKIT/Views/Detail/WeeklyChartView.swift`

- [ ] **Step 1: Create WeeklyChartView.swift**

  ```swift
  import SwiftUI
  import Charts

  struct WeeklyChartView: View {
      let habit: Habit

      private var accentColor: Color {
          Color(hex: habit.colorHex) ?? .green
      }

      private struct WeekBar: Identifiable {
          let id = UUID()
          let label: String
          let count: Int
      }

      private var data: [WeekBar] {
          let today = Date().startOfDay
          let entrySet = Set(habit.entries.map { $0.date.startOfDay })
          let cols = weekColumns(weeks: 8)
          let df = DateFormatter()
          df.dateFormat = "MMM d"
          return cols.map { monday in
              var count = 0
              for d in 0..<7 {
                  let day = monday.adding(days: d)
                  if day <= today && entrySet.contains(day) { count += 1 }
              }
              return WeekBar(label: df.string(from: monday), count: count)
          }
      }

      var body: some View {
          Chart(data) { bar in
              BarMark(
                  x: .value("Week", bar.label),
                  y: .value("Days", bar.count)
              )
              .foregroundStyle(accentColor)
              .cornerRadius(4)
          }
          .chartYScale(domain: 0...7)
          .chartXAxis {
              AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                  AxisValueLabel()
                      .font(.caption2)
                      .foregroundStyle(Color.secondary)
              }
          }
          .chartYAxis {
              AxisMarks(values: [0, 3, 7]) { _ in
                  AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                  AxisValueLabel()
                      .font(.caption2)
                      .foregroundStyle(Color.secondary)
              }
          }
          .frame(height: 120)
      }
  }
  ```

- [ ] **Step 2: Build and verify chart renders**

  Press `Cmd+B`. Navigate to a habit detail in Simulator — the bar chart should appear at the bottom.

- [ ] **Step 3: Commit**

  ```bash
  git add HabitKIT/Views/Detail/WeeklyChartView.swift
  git commit -m "feat: add WeeklyChartView bar chart using Swift Charts"
  ```

---

## Task 12: StatsView

**Files:**
- Create: `HabitKIT/Views/Stats/StatsView.swift`
- Modify: `HabitKIT/Views/Home/HomeView.swift` — add TabView wrapping

- [ ] **Step 1: Create StatsView.swift**

  ```swift
  import SwiftUI
  import SwiftData
  import Charts

  struct StatsView: View {
      @Query private var habits: [Habit]

      private var allStats: [(Habit, HabitStats)] {
          habits.map { ($0, HabitStats.calculate(for: $0)) }
      }

      private var bestHabit: Habit? {
          allStats.max(by: { $0.1.currentStreak < $1.1.currentStreak })?.0
      }

      private var totalCompletions: Int {
          allStats.reduce(0) { $0 + $1.1.totalCompletions }
      }

      private var perfectDays: Int {
          guard !habits.isEmpty else { return 0 }
          let allEntrySets = habits.map { Set($0.entries.map { $0.date.startOfDay }) }
          let today = Date().startOfDay
          var count = 0
          var day = today.adding(days: -364)
          while day <= today {
              if allEntrySets.allSatisfy({ $0.contains(day) }) { count += 1 }
              day = day.adding(days: 1)
          }
          return count
      }

      var body: some View {
          NavigationStack {
              ScrollView {
                  if habits.isEmpty {
                      VStack(spacing: 12) {
                          Text("No data yet")
                              .font(.title3).fontWeight(.semibold)
                          Text("Add habits and start tracking to see your stats here.")
                              .font(.subheadline).foregroundStyle(.secondary)
                              .multilineTextAlignment(.center)
                      }
                      .padding(.top, 80)
                      .padding(.horizontal, 40)
                  } else {
                      VStack(spacing: 16) {
                          // Summary cards
                          HStack(spacing: 12) {
                              SummaryCard(value: "\(totalCompletions)", label: "Total\nCompletions")
                              SummaryCard(value: "\(perfectDays)", label: "Perfect\nDays")
                              SummaryCard(value: "\(habits.count)", label: "Habits\nTracked")
                          }

                          // Best habit
                          if let best = bestHabit {
                              let s = HabitStats.calculate(for: best)
                              VStack(alignment: .leading, spacing: 8) {
                                  Text("Best Streak")
                                      .font(.footnote).fontWeight(.semibold).foregroundStyle(.secondary)
                                  HStack {
                                      Text(best.icon).font(.title2)
                                      Text(best.name).fontWeight(.semibold)
                                      Spacer()
                                      Text("🔥 \(s.currentStreak) days")
                                          .fontWeight(.bold)
                                          .foregroundStyle(Color(hex: best.colorHex) ?? .green)
                                  }
                                  .padding(14)
                                  .background(Color(UIColor.secondarySystemBackground))
                                  .clipShape(RoundedRectangle(cornerRadius: 12))
                              }
                          }

                          // Per-habit completion this month
                          VStack(alignment: .leading, spacing: 8) {
                              Text("Completion This Month")
                                  .font(.footnote).fontWeight(.semibold).foregroundStyle(.secondary)
                              ForEach(habits) { habit in
                                  let s = HabitStats.calculate(for: habit)
                                  let color = Color(hex: habit.colorHex) ?? .green
                                  HStack(spacing: 10) {
                                      Text(habit.icon)
                                      Text(habit.name).font(.subheadline)
                                      Spacer()
                                      GeometryReader { geo in
                                          ZStack(alignment: .leading) {
                                              RoundedRectangle(cornerRadius: 4)
                                                  .fill(Color.white.opacity(0.07))
                                              RoundedRectangle(cornerRadius: 4)
                                                  .fill(color)
                                                  .frame(width: geo.size.width * s.completionThisMonth)
                                          }
                                      }
                                      .frame(width: 80, height: 8)
                                      Text("\(Int(s.completionThisMonth * 100))%")
                                          .font(.caption).fontWeight(.bold)
                                          .foregroundStyle(color)
                                          .frame(width: 36, alignment: .trailing)
                                  }
                                  .padding(.vertical, 4)
                              }
                              .padding(14)
                              .background(Color(UIColor.secondarySystemBackground))
                              .clipShape(RoundedRectangle(cornerRadius: 12))
                          }
                      }
                      .padding(.horizontal, 16)
                      .padding(.top, 8)
                      .padding(.bottom, 40)
                  }
              }
              .navigationTitle("Stats")
              .navigationBarTitleDisplayMode(.large)
          }
          .preferredColorScheme(.dark)
      }
  }

  private struct SummaryCard: View {
      let value: String
      let label: String
      var body: some View {
          VStack(spacing: 4) {
              Text(value).font(.title).fontWeight(.bold)
              Text(label).font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 16)
          .background(Color(UIColor.secondarySystemBackground))
          .clipShape(RoundedRectangle(cornerRadius: 12))
      }
  }
  ```

- [ ] **Step 2: Wrap HomeView in TabView**

  Modify `HabitKITApp.swift`:

  ```swift
  import SwiftUI
  import SwiftData

  @main
  struct HabitKITApp: App {
      var body: some Scene {
          WindowGroup {
              MainTabView()
          }
          .modelContainer(for: [Habit.self, HabitEntry.self])
      }
  }
  ```

  Create `HabitKIT/Views/MainTabView.swift`:

  ```swift
  import SwiftUI

  struct MainTabView: View {
      var body: some View {
          TabView {
              HomeView()
                  .tabItem {
                      Label("Today", systemImage: "square.grid.2x2")
                  }
              StatsView()
                  .tabItem {
                      Label("Stats", systemImage: "chart.bar")
                  }
              SettingsView()
                  .tabItem {
                      Label("Settings", systemImage: "gearshape")
                  }
          }
          .tint(.green)
          .preferredColorScheme(.dark)
      }
  }
  ```

- [ ] **Step 3: Run in Simulator**

  `Cmd+R` — tab bar should appear with Today / Stats / Settings. Navigate to Stats tab.

- [ ] **Step 4: Commit**

  ```bash
  git add HabitKIT/Views/Stats/ HabitKIT/Views/MainTabView.swift HabitKIT/HabitKITApp.swift
  git commit -m "feat: add StatsView and MainTabView with tab navigation"
  ```

---

## Task 13: SettingsView

**Files:**
- Create: `HabitKIT/Views/Settings/SettingsView.swift`

- [ ] **Step 1: Create SettingsView.swift**

  ```swift
  import SwiftUI
  import SwiftData

  struct SettingsView: View {
      @Environment(\.modelContext) private var context
      @Query private var habits: [Habit]
      @AppStorage("weekStartsMonday") private var weekStartsMonday = true
      @AppStorage("hapticsEnabled") private var hapticsEnabled = true
      @State private var showResetAlert = false

      var body: some View {
          NavigationStack {
              Form {
                  Section("Preferences") {
                      Toggle("Week starts on Monday", isOn: $weekStartsMonday)
                      Toggle("Haptic feedback", isOn: $hapticsEnabled)
                  }

                  Section("Data") {
                      Button("Reset All Data", role: .destructive) {
                          showResetAlert = true
                      }
                  }

                  Section {
                      HStack {
                          Text("Version")
                          Spacer()
                          Text("1.0.0").foregroundStyle(.secondary)
                      }
                      HStack {
                          Text("Habits tracked")
                          Spacer()
                          Text("\(habits.count)").foregroundStyle(.secondary)
                      }
                  }
              }
              .navigationTitle("Settings")
              .navigationBarTitleDisplayMode(.large)
              .alert("Reset All Data?", isPresented: $showResetAlert) {
                  Button("Delete Everything", role: .destructive) { resetAll() }
                  Button("Cancel", role: .cancel) {}
              } message: {
                  Text("This will permanently delete all habits and entries. This cannot be undone.")
              }
          }
          .preferredColorScheme(.dark)
      }

      private func resetAll() {
          for habit in habits {
              context.delete(habit)
          }
          try? context.save()
      }
  }

  #Preview {
      SettingsView()
          .modelContainer(for: [Habit.self, HabitEntry.self], inMemory: true)
  }
  ```

- [ ] **Step 2: Run in Simulator**

  Navigate to Settings tab. Verify toggles work, Reset shows confirmation alert.

- [ ] **Step 3: Commit**

  ```bash
  git add HabitKIT/Views/Settings/SettingsView.swift
  git commit -m "feat: add SettingsView with preferences and reset"
  ```

---

## Task 14: Polish — Haptics, Animations, Dark Mode

**Files:**
- Modify: `HabitKIT/Views/Home/HomeView.swift`
- Modify: `HabitKIT/Views/Home/HabitRowView.swift`

- [ ] **Step 1: Hook hapticsEnabled into toggle in HomeView**

  In `HomeView.toggle()`, replace the hardcoded haptic call:

  ```swift
  @AppStorage("hapticsEnabled") private var hapticsEnabled = true

  private func toggle(habit: Habit, on date: Date) {
      let day = date.startOfDay
      if let existing = habit.entries.first(where: { $0.date == day }) {
          context.delete(existing)
          habit.entries.removeAll { $0.date == day }
      } else {
          let entry = HabitEntry(date: day, habit: habit)
          context.insert(entry)
          habit.entries.append(entry)
          if hapticsEnabled {
              UIImpactFeedbackGenerator(style: .light).impactOccurred()
          }
      }
      try? context.save()
  }
  ```

- [ ] **Step 2: Add scale animation to dot tap in HeatmapGridView**

  In `DotView`, add a `@State` pressed effect:

  ```swift
  private struct DotView: View {
      let date: Date
      let today: Date
      let isDone: Bool
      let color: Color
      let cellSize: CGFloat
      @State private var pressed = false

      var body: some View {
          let isFuture = date > today
          let isToday = date == today

          RoundedRectangle(cornerRadius: 3)
              .fill(cellFill(isFuture: isFuture))
              .frame(width: cellSize, height: cellSize)
              .overlay(
                  RoundedRectangle(cornerRadius: 3)
                      .stroke(isToday && !isDone ? color.opacity(0.6) : .clear, lineWidth: 1.5)
              )
              .opacity(isFuture ? 0 : 1)
              .scaleEffect(pressed ? 0.75 : 1.0)
              .animation(.spring(duration: 0.15), value: isDone)
              .animation(.easeInOut(duration: 0.1), value: pressed)
              .simultaneousGesture(
                  DragGesture(minimumDistance: 0)
                      .onChanged { _ in if !isFuture { pressed = true } }
                      .onEnded { _ in pressed = false }
              )
      }

      private func cellFill(isFuture: Bool) -> Color {
          if isFuture { return .clear }
          return isDone ? color : Color.white.opacity(0.07)
      }
  }
  ```

- [ ] **Step 3: Run full Simulator test**

  1. Add 3 habits (gym 🏋️, guitar 🎸, supplements 💊)
  2. Tap multiple dots — verify haptics fire and animation plays
  3. Navigate to detail — verify year heatmap, stats, chart
  4. Navigate to Stats tab — verify total completions and bars
  5. Navigate to Settings — toggle haptics off, verify no haptic on next dot tap
  6. Test Reset — confirm all habits deleted, empty state shown

- [ ] **Step 4: Final commit**

  ```bash
  git add -A
  git commit -m "feat: polish haptics, dot tap animation, settings wired up — v1 complete"
  ```

---

## Done ✓

The app is complete when:
- [ ] All 5 screens render correctly in dark mode
- [ ] Adding a habit persists across app restarts (SwiftData)
- [ ] Tapping dots toggles completion with haptic feedback
- [ ] Streaks update correctly (unit tests pass)
- [ ] Navigating Home → Detail → back works cleanly
- [ ] Stats tab shows real aggregate data
- [ ] Settings reset deletes all data
