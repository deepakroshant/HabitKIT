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
        let activeSets = habits.filter { !$0.isPaused }.map { Set($0.entries.map { $0.date.startOfDay }) }
        guard !activeSets.isEmpty else { return 0 }
        let today = Date().startOfDay
        var count = 0
        var day = today.adding(days: -364)
        while day <= today {
            if activeSets.allSatisfy({ $0.contains(day) }) { count += 1 }
            day = day.adding(days: 1)
        }
        return count
    }

    private struct DayCount: Identifiable {
        let id = UUID()
        let day: String
        let count: Int
    }

    private var bestDayData: [DayCount] {
        let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        var counts = [Int](repeating: 0, count: 7)
        let cal = Calendar.current
        for habit in habits {
            for entry in habit.entries {
                let weekday = cal.component(.weekday, from: entry.date)
                let idx = (weekday + 5) % 7  // 0 = Mon … 6 = Sun
                counts[idx] += 1
            }
        }
        return dayNames.enumerated().map { DayCount(day: $1, count: counts[$0]) }
    }

    private var bestDay: String {
        bestDayData.max(by: { $0.count < $1.count })?.day ?? "—"
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
                            SummaryCard(value: "\(habits.filter { !$0.isPaused }.count)", label: "Active\nHabits")
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
                                    Text("🔥 \(s.currentStreak) \(s.streakUnit)")
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color(hex: best.colorHex) ?? .green)
                                }
                                .padding(14)
                                .background(Color(UIColor.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }

                        // Best day of week chart
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Most Active Day")
                                    .font(.footnote).fontWeight(.semibold).foregroundStyle(.secondary)
                                Spacer()
                                Text(bestDay)
                                    .font(.footnote).fontWeight(.bold).foregroundStyle(.green)
                            }
                            Chart(bestDayData) { item in
                                BarMark(
                                    x: .value("Day", item.day),
                                    y: .value("Count", item.count)
                                )
                                .foregroundStyle(item.day == bestDay
                                    ? Color.green.gradient
                                    : Color.white.opacity(0.2).gradient)
                                .cornerRadius(4)
                            }
                            .chartYAxis(.hidden)
                            .frame(height: 100)
                            .padding(14)
                            .background(Color(UIColor.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Completion this month per habit
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Completion This Month")
                                .font(.footnote).fontWeight(.semibold).foregroundStyle(.secondary)
                            VStack(spacing: 0) {
                                ForEach(habits.filter { !$0.isPaused }) { habit in
                                    let s = HabitStats.calculate(for: habit)
                                    let color = Color(hex: habit.colorHex) ?? .green
                                    let label = habit.targetPerWeek > 0
                                        ? "\(habit.targetPerWeek)×/wk"
                                        : "daily"
                                    HStack(spacing: 10) {
                                        Text(habit.icon)
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(habit.name).font(.subheadline)
                                            Text(label).font(.caption2).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        GeometryReader { geo in
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.07))
                                                RoundedRectangle(cornerRadius: 4).fill(color)
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
                                    if habit.id != habits.filter({ !$0.isPaused }).last?.id {
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
