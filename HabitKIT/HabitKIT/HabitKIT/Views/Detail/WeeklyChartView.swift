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
