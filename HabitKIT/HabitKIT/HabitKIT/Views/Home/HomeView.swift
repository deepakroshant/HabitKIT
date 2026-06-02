import SwiftUI
import SwiftData
import Combine

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @State private var selectedDay: Date = Date().startOfDay
    @State private var showAddSheet = false
    @State private var habitToEdit: Habit? = nil
    @State private var habitToPause: Habit? = nil
    @State private var entryToNote: HabitEntry? = nil
    @State private var now = Date()
    @State private var confettiTrigger = 0
    @State private var showHeatmaps = false

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private func entry(for habit: Habit) -> HabitEntry? {
        habit.entries.first { $0.date == selectedDay }
    }

    private var activeHabits: [Habit] { habits.filter { !$0.isPaused } }
    private var pending: [Habit] { activeHabits.filter { entry(for: $0) == nil } }
    private var done: [Habit]    { activeHabits.filter { entry(for: $0) != nil } }
    private var paused: [Habit]  { habits.filter { $0.isPaused } }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    dateHeader

                    if !habits.isEmpty {
                        Picker("View", selection: $showHeatmaps) {
                            Text("Today").tag(false)
                            Text("Heatmaps").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 6)

                        if !showHeatmaps {
                            DayStripView(selectedDay: $selectedDay)
                        }
                    }
                    Divider().opacity(habits.isEmpty ? 0 : 0.15)

                    if habits.isEmpty {
                        emptyState
                    } else if showHeatmaps {
                        heatmapList
                    } else {
                        taskList
                    }
                }
                .navigationBarHidden(true)
                .sheet(isPresented: $showAddSheet) { AddEditHabitView(habit: nil) }
                .sheet(item: $habitToEdit) { AddEditHabitView(habit: $0) }
                .sheet(item: $habitToPause) { PauseHabitSheet(habit: $0) }
                .sheet(item: $entryToNote) { AddNoteSheet(entry: $0) }
                .onChange(of: habits.count) {
                    rescheduleNotifications()
                }
                .onReceive(timer) { now = $0 }

                ConfettiView(trigger: $confettiTrigger)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Date Header

    private var dateHeader: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedDay, format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(.system(size: 26, weight: .bold))
                if selectedDay == Date().startOfDay {
                    Text(now, format: .dateTime.hour().minute())
                        .font(.system(size: 14)).foregroundStyle(.secondary)
                } else {
                    Text("Logging past day")
                        .font(.system(size: 14)).foregroundStyle(.orange)
                }
            }
            Spacer()
            Button { showAddSheet = true } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28)).foregroundStyle(.green)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 10)
    }

    // MARK: - Heatmap List

    private var heatmapList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(activeHabits) { habit in
                    NavigationLink(destination: HabitDetailView(habit: habit)) {
                        HabitRowView(habit: habit) { date in toggleEntry(habit: habit, date: date) }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.bottom, 60)
        }
    }

    // MARK: - Task List

    private var taskList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Pending
                if !pending.isEmpty {
                    sectionLabel(pending.count == activeHabits.count
                        ? "\(pending.count) habits today"
                        : "\(pending.count) remaining")

                    VStack(spacing: 10) {
                        ForEach(pending) { habit in
                            PendingHabitRow(habit: habit) { logNow(habit: habit) }
                                .contextMenu {
                                    Button("Edit") { habitToEdit = habit }
                                    Button("Pause") { habitToPause = habit }
                                    Divider()
                                    Button("Move Up")   { moveHabit(habit, by: -1) }
                                    Button("Move Down") { moveHabit(habit, by: +1) }
                                    Divider()
                                    Button("Delete", role: .destructive) { delete(habit) }
                                }
                                .background(
                                    NavigationLink("", destination: HabitDetailView(habit: habit)).opacity(0)
                                )
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // Done
                if !done.isEmpty {
                    sectionLabel("Done · \(done.count)")
                        .padding(.top, pending.isEmpty ? 0 : 20)

                    VStack(spacing: 10) {
                        ForEach(done) { habit in
                            DoneHabitRow(
                                habit: habit,
                                completedAt: entry(for: habit)?.completedAt,
                                note: entry(for: habit)?.note ?? "",
                                onUndo: { undo(habit: habit) },
                                onAddNote: { entryToNote = entry(for: habit) }
                            )
                            .background(
                                NavigationLink("", destination: HabitDetailView(habit: habit)).opacity(0)
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // All-done celebration
                if pending.isEmpty && !activeHabits.isEmpty {
                    VStack(spacing: 8) {
                        Text("🎉").font(.system(size: 36))
                        Text("All done for \(selectedDay == Date().startOfDay ? "today" : "this day")!")
                            .font(.headline).fontWeight(.bold)
                        Text("Keep the streak going tomorrow.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 32)
                }

                // Paused habits section
                if !paused.isEmpty {
                    sectionLabel("Paused · \(paused.count)")
                        .padding(.top, 28)

                    VStack(spacing: 10) {
                        ForEach(paused) { habit in
                            PausedHabitRow(habit: habit) {
                                habit.isPaused    = false
                                habit.pauseReason = ""
                                habit.pausedAt    = nil
                                if hapticsEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
                                try? context.save()
                                rescheduleNotifications()
                            }
                            .contextMenu {
                                Button("Edit")   { habitToEdit = habit }
                                Button("Delete", role: .destructive) { delete(habit) }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 60)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("✦").font(.system(size: 48))
            Text("No habits yet").font(.title2).fontWeight(.bold)
            Text("Tap + to add your first habit")
                .font(.subheadline).foregroundStyle(.secondary)
            Button("Add Habit") { showAddSheet = true }
                .buttonStyle(.borderedProminent).tint(.green)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private func logNow(habit: Habit) {
        let now = Date()
        let e = HabitEntry(date: selectedDay == Date().startOfDay ? now : selectedDay, habit: habit)
        if selectedDay != Date().startOfDay { e.completedAt = selectedDay }
        context.insert(e)
        habit.entries.append(e)
        if hapticsEnabled { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
        try? context.save()
        confettiTrigger += 1
        rescheduleNotifications()
    }

    private func undo(habit: Habit) {
        if let existing = habit.entries.first(where: { $0.date == selectedDay }) {
            context.delete(existing)
            habit.entries.removeAll { $0.date == selectedDay }
            if hapticsEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
            try? context.save()
            rescheduleNotifications()
        }
    }

    private func toggleEntry(habit: Habit, date: Date) {
        let day = date.startOfDay
        if let existing = habit.entries.first(where: { $0.date == day }) {
            context.delete(existing)
            habit.entries.removeAll { $0.date == day }
        } else {
            let e = HabitEntry(date: date, habit: habit)
            context.insert(e)
            habit.entries.append(e)
        }
        if hapticsEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        try? context.save()
    }

    private func moveHabit(_ habit: Habit, by delta: Int) {
        let sorted = habits.sorted { $0.sortOrder < $1.sortOrder }
        guard let idx = sorted.firstIndex(where: { $0.id == habit.id }) else { return }
        let swapIdx = idx + delta
        guard swapIdx >= 0, swapIdx < sorted.count else { return }
        let neighbor = sorted[swapIdx]
        let tmp = habit.sortOrder
        habit.sortOrder = neighbor.sortOrder
        neighbor.sortOrder = tmp
        if hapticsEnabled { UIImpactFeedbackGenerator(style: .rigid).impactOccurred() }
        try? context.save()
    }

    private func delete(_ habit: Habit) {
        NotificationManager.shared.cancelHabitReminder(habit: habit)
        context.delete(habit)
        try? context.save()
    }

    private func rescheduleNotifications() {
        guard notificationsEnabled else { return }
        NotificationManager.shared.scheduleDailyReminders(habits: activeHabits, pendingToday: pending.count)
    }
}

// MARK: - Pending Habit Row

struct PendingHabitRow: View {
    let habit: Habit
    let onDidIt: () -> Void

    private var accentColor: Color { Color(hex: habit.colorHex) ?? .green }
    private var stats: HabitStats { HabitStats.calculate(for: habit) }
    @State private var pressed = false
    @State private var tapped  = false

    var body: some View {
        HStack(spacing: 14) {
            Text(habit.icon)
                .font(.system(size: 22))
                .frame(width: 48, height: 48)
                .background(accentColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 13))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(habit.name).font(.system(size: 16, weight: .semibold))
                    if habit.targetPerWeek > 0 {
                        Text("\(habit.targetPerWeek)×/wk")
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(accentColor.opacity(0.18))
                            .clipShape(Capsule())
                            .foregroundStyle(accentColor)
                    }
                }
                if stats.currentStreak > 0 {
                    Text("🔥 \(stats.currentStreak) \(stats.streakUnit) streak")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                } else {
                    Text("Start your streak!")
                        .font(.system(size: 12)).foregroundStyle(Color.white.opacity(0.3))
                }
            }

            Spacer()

            Button(action: {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { tapped = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { onDidIt() }
            }) {
                Text("Did It!")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(accentColor)
                    .clipShape(Capsule())
                    .scaleEffect(tapped ? 1.18 : (pressed ? 0.94 : 1.0))
            }
            .buttonStyle(.plain)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in pressed = true }
                    .onEnded   { _ in pressed = false }
            )
            .animation(.easeInOut(duration: 0.1), value: pressed)
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Done Habit Row

struct DoneHabitRow: View {
    let habit: Habit
    let completedAt: Date?
    let note: String
    let onUndo: () -> Void
    let onAddNote: () -> Void

    private var accentColor: Color { Color(hex: habit.colorHex) ?? .green }

    private var timeLabel: String {
        guard let t = completedAt else { return "" }
        return t.formatted(.dateTime.hour().minute())
    }

    var body: some View {
        HStack(spacing: 14) {
            Text(habit.icon)
                .font(.system(size: 22))
                .frame(width: 48, height: 48)
                .background(accentColor.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 13))
                .opacity(0.7)

            VStack(alignment: .leading, spacing: 3) {
                Text(habit.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary.opacity(0.7))
                Text("✓ Done at \(timeLabel)")
                    .font(.system(size: 12)).foregroundStyle(accentColor.opacity(0.8))
                if !note.isEmpty {
                    Text(note)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: onAddNote) {
                    Image(systemName: note.isEmpty ? "note.text.badge.plus" : "pencil")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.07))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Button(action: onUndo) {
                    Text("Undo")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Color.white.opacity(0.07))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemBackground).opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(accentColor.opacity(0.25), lineWidth: 1))
    }
}

// MARK: - Paused Habit Row

struct PausedHabitRow: View {
    let habit: Habit
    let onResume: () -> Void

    private var accentColor: Color { Color(hex: habit.colorHex) ?? .green }

    var body: some View {
        HStack(spacing: 14) {
            Text(habit.icon)
                .font(.system(size: 22))
                .frame(width: 48, height: 48)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 13))
                .opacity(0.5)

            VStack(alignment: .leading, spacing: 3) {
                Text(habit.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary.opacity(0.5))
                if !habit.pauseReason.isEmpty {
                    Text(habit.pauseReason)
                        .font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(1)
                } else if let pausedAt = habit.pausedAt {
                    Text("Paused \(pausedAt.formatted(.relative(presentation: .named)))")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(action: onResume) {
                Text("Resume")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemBackground).opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.orange.opacity(0.2), lineWidth: 1))
    }
}
