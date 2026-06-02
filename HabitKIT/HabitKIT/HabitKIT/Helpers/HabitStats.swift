import Foundation

struct HabitStats {
    let currentStreak: Int
    let bestStreak: Int
    let streakUnit: String        // "days" or "weeks"
    let completionThisMonth: Double   // 0.0 – 1.0
    let completionThisWeek: Double    // 0.0 – 1.0 (vs weekly target)
    let totalCompletions: Int

    static func calculate(for habit: Habit, today: Date = Date()) -> HabitStats {
        let todayStart = today.startOfDay
        let entryDates = Set(habit.entries.map { $0.date.startOfDay })

        if habit.targetPerWeek > 0 {
            return calculateWeekly(habit: habit, entryDates: entryDates, today: todayStart)
        } else {
            return calculateDaily(habit: habit, entryDates: entryDates, today: todayStart)
        }
    }

    // MARK: - Daily habits

    private static func calculateDaily(habit: Habit, entryDates: Set<Date>, today: Date) -> HabitStats {
        var current = 0
        var day = today
        while entryDates.contains(day) {
            current += 1
            day = day.adding(days: -1)
        }

        let sorted = entryDates.sorted()
        var best = 0, run = 0
        var prev: Date? = nil
        for d in sorted {
            if let p = prev, d == p.adding(days: 1) { run += 1 } else { run = 1 }
            if run > best { best = run }
            prev = d
        }

        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: today)
        let startOfMonth = cal.date(from: comps)!
        let dayOfMonth = cal.component(.day, from: today)
        var completedThisMonth = 0
        for offset in 0..<dayOfMonth {
            if entryDates.contains(startOfMonth.adding(days: offset)) { completedThisMonth += 1 }
        }
        let monthCompletion = dayOfMonth > 0 ? Double(completedThisMonth) / Double(dayOfMonth) : 0

        return HabitStats(
            currentStreak: current,
            bestStreak: max(best, current),
            streakUnit: "days",
            completionThisMonth: monthCompletion,
            completionThisWeek: entryDates.contains(today) ? 1.0 : 0.0,
            totalCompletions: entryDates.count
        )
    }

    // MARK: - Weekly habits (N times/week target)

    private static func calculateWeekly(habit: Habit, entryDates: Set<Date>, today: Date) -> HabitStats {
        let cal = Calendar.current
        let target = habit.targetPerWeek

        func weekStart(_ date: Date) -> Date {
            var comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            comps.weekday = 2  // Monday
            return cal.date(from: comps) ?? date
        }

        func completionsInWeek(_ monday: Date) -> Int {
            (0..<7).filter { entryDates.contains(monday.adding(days: $0)) }.count
        }

        // Current streak: consecutive weeks meeting target, ending this week
        var currentWeek = weekStart(today)
        var current = 0
        while completionsInWeek(currentWeek) >= target {
            current += 1
            currentWeek = currentWeek.adding(days: -7)
        }

        // Best streak: scan past 52 weeks
        var best = 0, run = 0
        let anchor = weekStart(today.adding(days: -364))
        var w = anchor
        while w <= weekStart(today) {
            if completionsInWeek(w) >= target { run += 1 } else { run = 0 }
            if run > best { best = run }
            w = w.adding(days: 7)
        }

        // This week progress
        let thisWeekCount = completionsInWeek(weekStart(today))
        let weekProgress = min(1.0, Double(thisWeekCount) / Double(target))

        // This month (by week)
        let comps = cal.dateComponents([.year, .month], from: today)
        let startOfMonth = cal.date(from: comps)!
        let dayOfMonth = cal.component(.day, from: today)
        var completedThisMonth = 0
        for offset in 0..<dayOfMonth {
            if entryDates.contains(startOfMonth.adding(days: offset)) { completedThisMonth += 1 }
        }
        let expectedThisMonth = dayOfMonth * target / 7
        let monthCompletion = expectedThisMonth > 0 ? min(1.0, Double(completedThisMonth) / Double(expectedThisMonth)) : 0

        return HabitStats(
            currentStreak: current,
            bestStreak: max(best, current),
            streakUnit: "weeks",
            completionThisMonth: monthCompletion,
            completionThisWeek: weekProgress,
            totalCompletions: entryDates.count
        )
    }
}
