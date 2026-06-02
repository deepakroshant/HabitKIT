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

                HStack(spacing: 12) {
                    StatCard(value: "\(stats.currentStreak)", label: "Current\nStreak", color: accentColor)
                    StatCard(value: "\(stats.bestStreak)", label: "Best\nStreak", color: accentColor)
                    StatCard(value: "\(Int(stats.completionThisMonth * 100))%", label: "This\nMonth", color: accentColor)
                    StatCard(value: "\(stats.totalCompletions)", label: "Total\nDone", color: accentColor)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Past 12 Months")
                        .font(.footnote).fontWeight(.semibold).foregroundStyle(.secondary)
                    YearHeatmapView(habit: habit)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Last 8 Weeks")
                        .font(.footnote).fontWeight(.semibold).foregroundStyle(.secondary)
                    WeeklyChartView(habit: habit)
                }
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
