import Foundation

struct HabitStats {
    let currentStreak: Int
    let bestStreak: Int
    let completionThisMonth: Double  // 0.0 – 1.0
    let totalCompletions: Int

    static func calculate(for habit: Habit, today: Date = Date()) -> HabitStats {
        let todayStart = today.startOfDay
        let entrySet = Set(habit.entries.compactMap { $0.date.startOfDay as Date? })

        // Current streak: count consecutive days ending today
        var current = 0
        var day = todayStart
        while entrySet.contains(day) {
            current += 1
            day = day.adding(days: -1)
        }

        // Best streak: scan all sorted entry dates
        let sorted = entrySet.sorted()
        var best = 0
        var run = 0
        var prev: Date? = nil
        for d in sorted {
            if let p = prev, d == p.adding(days: 1) {
                run += 1
            } else {
                run = 1
            }
            if run > best { best = run }
            prev = d
        }

        // Completion this month (days 1 through today)
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: todayStart)
        let startOfMonth = cal.date(from: comps)!
        let dayOfMonth = cal.component(.day, from: todayStart)
        var completedThisMonth = 0
        for offset in 0..<dayOfMonth {
            let d = startOfMonth.adding(days: offset)
            if entrySet.contains(d) { completedThisMonth += 1 }
        }
        let completion = dayOfMonth > 0 ? Double(completedThisMonth) / Double(dayOfMonth) : 0

        return HabitStats(
            currentStreak: current,
            bestStreak: max(best, current),
            completionThisMonth: completion,
            totalCompletions: entrySet.count
        )
    }
}
