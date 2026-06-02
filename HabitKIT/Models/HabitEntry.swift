import Foundation
import SwiftData

@Model
final class HabitEntry {
    var date: Date
    @Relationship var habit: Habit?

    init(date: Date, habit: Habit) {
        self.date = Calendar.current.startOfDay(for: date)
        self.habit = habit
    }
}
