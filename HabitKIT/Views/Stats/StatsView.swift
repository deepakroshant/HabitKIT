import SwiftUI
import SwiftData

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
                        HStack(spacing: 12) {
                            SummaryCard(value: "\(totalCompletions)", label: "Total\nCompletions")
                            SummaryCard(value: "\(perfectDays)", label: "Perfect\nDays")
                            SummaryCard(value: "\(habits.count)", label: "Habits\nTracked")
                        }

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

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Completion This Month")
                                .font(.footnote).fontWeight(.semibold).foregroundStyle(.secondary)
                            VStack(spacing: 0) {
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
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 14)
                                    if habit.id != habits.last?.id {
                                        Divider().padding(.leading, 14)
                                    }
                                }
                            }
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
