import Foundation
import SwiftData

// MARK: - Codable DTOs (plain structs, no SwiftData dependency)

struct HabitBackup: Codable {
    var version: Int = 1
    var exportedAt: Date
    var habits: [HabitDTO]

    struct HabitDTO: Codable {
        var id: UUID
        var name: String
        var icon: String
        var colorHex: String
        var createdAt: Date
        var sortOrder: Int
        var isPaused: Bool
        var pauseReason: String
        var pausedAt: Date?
        var targetPerWeek: Int
        var customReminderEnabled: Bool
        var customReminderTime: Date
        var entries: [EntryDTO]
    }

    struct EntryDTO: Codable {
        var date: Date
        var completedAt: Date
        var note: String
    }
}

// MARK: - BackupManager

final class BackupManager {
    static let shared = BackupManager()
    private init() {}

    // MARK: Export → returns a URL to a temp .json file ready to share

    func export(habits: [Habit]) throws -> URL {
        let dtos = habits.map { h in
            HabitBackup.HabitDTO(
                id: h.id,
                name: h.name,
                icon: h.icon,
                colorHex: h.colorHex,
                createdAt: h.createdAt,
                sortOrder: h.sortOrder,
                isPaused: h.isPaused,
                pauseReason: h.pauseReason,
                pausedAt: h.pausedAt,
                targetPerWeek: h.targetPerWeek,
                customReminderEnabled: h.customReminderEnabled,
                customReminderTime: h.customReminderTime,
                entries: h.entries.map { e in
                    HabitBackup.EntryDTO(date: e.date, completedAt: e.completedAt, note: e.note)
                }
            )
        }

        let backup = HabitBackup(exportedAt: Date(), habits: dtos)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(backup)

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let filename = "habitkit-backup-\(fmt.string(from: Date())).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return url
    }

    // MARK: Import — deletes existing data, recreates from backup file

    func restore(from url: URL, context: ModelContext, existingHabits: [Habit]) throws {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(HabitBackup.self, from: data)

        // Wipe existing
        for habit in existingHabits { context.delete(habit) }

        // Recreate in sort order
        for dto in backup.habits.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            let habit = Habit(name: dto.name, icon: dto.icon,
                              colorHex: dto.colorHex, sortOrder: dto.sortOrder)
            habit.id                    = dto.id
            habit.createdAt             = dto.createdAt
            habit.isPaused              = dto.isPaused
            habit.pauseReason           = dto.pauseReason
            habit.pausedAt              = dto.pausedAt
            habit.targetPerWeek         = dto.targetPerWeek
            habit.customReminderEnabled = dto.customReminderEnabled
            habit.customReminderTime    = dto.customReminderTime
            context.insert(habit)

            for e in dto.entries {
                let entry = HabitEntry(date: e.date, habit: habit, note: e.note)
                entry.completedAt = e.completedAt
                context.insert(entry)
            }
        }

        try context.save()
    }
}
