import SwiftUI
import SwiftData

struct HabitRowView: View {
    let habit: Habit
    let onToggle: (Date) -> Void

    private var stats: HabitStats { HabitStats.calculate(for: habit) }
    private var accentColor: Color { Color(hex: habit.colorHex) ?? .green }
    private var doneToday: Bool {
        habit.entries.contains { $0.date == Date().startOfDay }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top row: icon + name + streak + big check button
            HStack(spacing: 10) {
                Text(habit.icon)
                    .font(.system(size: 16))
                    .frame(width: 32, height: 32)
                    .background(accentColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    if stats.currentStreak > 0 {
                        Text("🔥 \(stats.currentStreak) day streak")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Big "mark today" button
                Button(action: { onToggle(Date()) }) {
                    ZStack {
                        Circle()
                            .fill(doneToday ? accentColor : Color.white.opacity(0.08))
                            .frame(width: 38, height: 38)
                        Image(systemName: doneToday ? "checkmark" : "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(doneToday ? .black : accentColor)
                    }
                }
                .buttonStyle(.plain)
                .animation(.spring(duration: 0.2), value: doneToday)
            }

            // Heatmap grid (tap any past dot to backfill)
            HeatmapGridView(habit: habit, weeks: 18, onToggle: onToggle)

            Text("Tap any dot to log a past day")
                .font(.system(size: 10))
                .foregroundStyle(Color.white.opacity(0.25))
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
