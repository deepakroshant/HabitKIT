import Foundation

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self)!
    }

    func adding(weeks: Int) -> Date {
        Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: self)!
    }
}

/// Returns the Monday of the week containing `date`.
func mondayOfWeek(containing date: Date) -> Date {
    let cal = Calendar.current
    let weekday = cal.component(.weekday, from: date)
    // weekday: 1=Sun, 2=Mon, ... 7=Sat
    let daysToMonday = (weekday + 5) % 7
    return cal.startOfDay(for: date).adding(days: -daysToMonday)
}

/// Returns an array of Monday dates for the last `weeks` weeks,
/// ending with the Monday of the current week.
func weekColumns(weeks: Int, today: Date = Date()) -> [Date] {
    let thisMonday = mondayOfWeek(containing: today)
    return (0..<weeks).reversed().map { thisMonday.adding(weeks: -$0) }
}
