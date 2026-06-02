import Foundation
import SwiftData

@Model
final class HabitEntry {
    var date: Date        // normalized to start of day — used for streak/heatmap logic
    var completedAt: Date // actual timestamp of when "Did It!" was tapped
    var note: String      // optional completion note
    @Relationship var habit: Habit?

    init(date: Date, habit: Habit, note: String = "") {
        self.date = Calendar.current.startOfDay(for: date)
        self.completedAt = date
        self.note = note
        self.habit = habit
    }
}
