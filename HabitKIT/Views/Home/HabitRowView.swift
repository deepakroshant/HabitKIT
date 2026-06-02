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
                Text(habit.icon)
                    .font(.system(size: 16))
                    .frame(width: 32, height: 32)
                    .background(accentColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(habit.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)

                Spacer()

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
