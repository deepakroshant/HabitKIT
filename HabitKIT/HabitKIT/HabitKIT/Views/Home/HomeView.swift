import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @State private var selectedDay: Date = Date().startOfDay
    @State private var showAddSheet = false
    @State private var habitToEdit: Habit? = nil

    private var doneCount: Int {
        habits.filter { h in h.entries.contains { $0.date == selectedDay } }.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Day picker strip
                DayStripView(selectedDay: $selectedDay)
                    .padding(.bottom, 4)

                if habits.isEmpty {
                    emptyState
                } else {
                    // Progress bar
                    VStack(spacing: 6) {
                        HStack {
                            Text(selectedDay == Date().startOfDay ? "Today" : selectedDay.formatted(.dateTime.weekday(.wide).month().day()))
                                .font(.subheadline).fontWeight(.semibold).foregroundStyle(.secondary)
                            Spacer()
                            Text("\(doneCount) / \(habits.count)")
                                .font(.subheadline).fontWeight(.bold)
                                .foregroundStyle(doneCount == habits.count ? .green : .secondary)
                        }
                        .padding(.horizontal, 16)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.white.opacity(0.07))
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.green)
                                    .frame(width: habits.isEmpty ? 0 : geo.size.width * CGFloat(doneCount) / CGFloat(habits.count))
                            }
                        }
                        .frame(height: 4)
                        .padding(.horizontal, 16)
                        .animation(.spring(duration: 0.3), value: doneCount)
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 8)

                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(habits) { habit in
                                QuickLogCard(
                                    habit: habit,
                                    day: selectedDay,
                                    onToggle: { toggle(habit: habit, on: selectedDay) },
                                    onDetail: { habitToEdit = nil }
                                )
                                .contextMenu {
                                    Button("Edit") { habitToEdit = habit }
                                    Button("Delete", role: .destructive) { delete(habit) }
                                }
                                // Navigate to detail on card tap (not toggle)
                                .background(
                                    NavigationLink("", destination: HabitDetailView(habit: habit))
                                        .opacity(0)
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Habits")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.green)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) { AddEditHabitView(habit: nil) }
            .sheet(item: $habitToEdit) { AddEditHabitView(habit: $0) }
            .onChange(of: habits.count) {
                if notificationsEnabled { NotificationManager.shared.scheduleDailyReminders(habits: habits) }
            }
        }
        .preferredColorScheme(.dark)
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

    private func toggle(habit: Habit, on date: Date) {
        let day = date.startOfDay
        if let existing = habit.entries.first(where: { $0.date == day }) {
            context.delete(existing)
            habit.entries.removeAll { $0.date == day }
        } else {
            let entry = HabitEntry(date: day, habit: habit)
            context.insert(entry)
            habit.entries.append(entry)
            if hapticsEnabled { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
        }
        try? context.save()
    }

    private func delete(_ habit: Habit) {
        context.delete(habit)
        try? context.save()
    }
}

// MARK: - Day Strip

struct DayStripView: View {
    @Binding var selectedDay: Date
    private let days: [Date] = (0..<14).reversed().map { Date().startOfDay.adding(days: -$0) }
    private let dayFmt: DateFormatter = { let f = DateFormatter(); f.dateFormat = "EEE"; return f }()
    private let numFmt: DateFormatter = { let f = DateFormatter(); f.dateFormat = "d"; return f }()

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(days, id: \.self) { day in
                        let isSelected = day == selectedDay
                        let isToday = day == Date().startOfDay
                        Button(action: { selectedDay = day }) {
                            VStack(spacing: 3) {
                                Text(dayFmt.string(from: day).uppercased())
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(isSelected ? .black : .secondary)
                                Text(numFmt.string(from: day))
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundStyle(isSelected ? .black : (isToday ? .green : .primary))
                            }
                            .frame(width: 44, height: 56)
                            .background(isSelected ? Color.green : Color.white.opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isToday && !isSelected ? Color.green.opacity(0.5) : .clear, lineWidth: 1.5)
                            )
                        }
                        .id(day)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .onAppear {
                proxy.scrollTo(Date().startOfDay, anchor: .trailing)
            }
        }
    }
}

// MARK: - Quick Log Card

struct QuickLogCard: View {
    let habit: Habit
    let day: Date
    let onToggle: () -> Void
    let onDetail: () -> Void

    private var isDone: Bool {
        habit.entries.contains { $0.date == day }
    }
    private var accentColor: Color { Color(hex: habit.colorHex) ?? .green }
    private var streak: Int { HabitStats.calculate(for: habit).currentStreak }

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            Text(habit.icon)
                .font(.system(size: 22))
                .frame(width: 48, height: 48)
                .background(accentColor.opacity(isDone ? 0.25 : 0.1))
                .clipShape(RoundedRectangle(cornerRadius: 13))

            // Name + streak
            VStack(alignment: .leading, spacing: 3) {
                Text(habit.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isDone ? .primary : .primary)
                if streak > 0 {
                    Text("🔥 \(streak) day streak")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                } else {
                    Text("Start your streak today")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.3))
                }
            }

            Spacer()

            // Big check button
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .fill(isDone ? accentColor : Color.white.opacity(0.08))
                        .frame(width: 48, height: 48)
                    Image(systemName: isDone ? "checkmark" : "circle")
                        .font(.system(size: isDone ? 20 : 22, weight: .bold))
                        .foregroundStyle(isDone ? .black : Color.white.opacity(0.3))
                }
            }
            .buttonStyle(.plain)
            .animation(.spring(duration: 0.25, bounce: 0.4), value: isDone)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isDone ? accentColor.opacity(0.3) : .clear, lineWidth: 1.5)
                )
        )
    }
}
