import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var createdAt: Date
    var sortOrder: Int
    @Relationship(deleteRule: .cascade) var entries: [HabitEntry] = []

    init(name: String, icon: String = "⭐", colorHex: String = "#4FC14F", sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.createdAt = Date()
        self.sortOrder = sortOrder
    }
}
