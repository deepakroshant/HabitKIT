import Foundation
import SwiftData

@Model
final class Habit {
    // CloudKit requires all non-optional stored properties to have default values
    var id: UUID = UUID()
    var name: String = ""
    var subtitle: String = ""
    var icon: String = "⭐"
    var colorHex: String = "#4FC14F"
    var createdAt: Date = Date()
    var sortOrder: Int = 0
    // Pause / archive
    var isPaused: Bool = false
    var pauseReason: String = ""
    var pausedAt: Date? = nil
    // Frequency (0 = daily, 2-6 = N times/week)
    var targetPerWeek: Int = 0
    // Custom per-habit reminder
    var customReminderEnabled: Bool = false
    var customReminderTime: Date = Date()
    @Relationship(deleteRule: .cascade) var entries: [HabitEntry] = []

    init(name: String, icon: String = "⭐", colorHex: String = "#4FC14F", sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.createdAt = Date()
        self.sortOrder = sortOrder
        self.isPaused = false
        self.pauseReason = ""
        self.pausedAt = nil
        self.targetPerWeek = 0
        self.customReminderEnabled = false
        self.customReminderTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    }
}
