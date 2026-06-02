import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @State private var showAddSheet = false
    @State private var habitToEdit: Habit? = nil

    var body: some View {
        NavigationStack {
            Group {
                if habits.isEmpty { emptyState } else { habitList }
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
            .sheet(isPresented: $showAddSheet) {
                AddEditHabitView(habit: nil)
            }
            .sheet(item: $habitToEdit) { habit in
                AddEditHabitView(habit: habit)
            }
            .onChange(of: habits.count) {
                if notificationsEnabled { NotificationManager.shared.scheduleDailyReminders(habits: habits) }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var habitList: some View {
        ScrollView {
            // Today's date header
            HStack {
                Text(Date(), style: .date)
                    .font(.subheadline).fontWeight(.semibold).foregroundStyle(.secondary)
                Spacer()
                let doneCount = habits.filter { h in
                    h.entries.contains { $0.date == Date().startOfDay }
                }.count
                Text("\(doneCount)/\(habits.count) today")
                    .font(.subheadline).fontWeight(.bold)
                    .foregroundStyle(doneCount == habits.count && habits.count > 0 ? .green : .secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

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
            .padding(.top, 6)
            .padding(.bottom, 40)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("✦").font(.system(size: 48))
            Text("No habits yet").font(.title2).fontWeight(.bold)
            Text("Tap + to add your first habit")
                .font(.subheadline).foregroundStyle(.secondary)
            Button("Add Habit") { showAddSheet = true }
                .buttonStyle(.borderedProminent).tint(.green)
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
            if hapticsEnabled {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
        try? context.save()
    }

    private func delete(_ habit: Habit) {
        context.delete(habit)
        try? context.save()
    }
}
