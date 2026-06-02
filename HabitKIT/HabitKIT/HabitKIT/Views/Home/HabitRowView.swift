import SwiftUI

// HabitRowView is kept for the heatmap context (used in HabitDetailView if needed).
// The main home screen now uses QuickLogCard defined in HomeView.swift.
struct HabitRowView: View {
    let habit: Habit
    let onToggle: (Date) -> Void

    private var accentColor: Color { Color(hex: habit.colorHex) ?? .green }

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
                Spacer()
                let streak = HabitStats.calculate(for: habit).currentStreak
                if streak > 0 {
                    Text("🔥 \(streak)").font(.system(size: 13, weight: .bold))
                }
            }
            HeatmapGridView(habit: habit, weeks: 18, onToggle: onToggle)
            Text("Tap any dot to log a past day")
                .font(.system(size: 10)).foregroundStyle(Color.white.opacity(0.25))
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
