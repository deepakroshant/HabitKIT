import Foundation
import SwiftData
import Security

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

    // MARK: Auto-export → Keychain (survives app deletion) + Documents (Files app)

    func autoExport(habits: [Habit]) {
        guard !habits.isEmpty else { return }
        guard let data = try? makeBackupData(habits: habits) else { return }
        saveToKeychain(data)
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        try? data.write(to: docs.appendingPathComponent("habitkit-auto-backup.json"), options: .atomic)
    }

    // MARK: Auto-restore from Keychain — called on fresh install when habits list is empty

    func autoRestore(context: ModelContext) {
        guard let data = loadFromKeychain() else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let backup = try? decoder.decode(HabitBackup.self, from: data) else { return }
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
        try? context.save()
    }

    // MARK: Keychain helpers

    private let keychainKey = "habitkit-backup"

    private func saveToKeychain(_ data: Data) {
        let query: [String: Any] = [
            kSecClass as String:            kSecClassGenericPassword,
            kSecAttrAccount as String:      keychainKey,
            kSecAttrAccessible as String:   kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemDelete(query as CFDictionary)
        var item = query
        item[kSecValueData as String] = data
        SecItemAdd(item as CFDictionary, nil)
    }

    private func loadFromKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }

    // MARK: Export → returns a URL to a temp dated .json file ready to share

    func export(habits: [Habit]) throws -> URL {
        let data = try makeBackupData(habits: habits)
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let filename = "habitkit-backup-\(fmt.string(from: Date())).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return url
    }

    // MARK: Shared encoder

    private func makeBackupData(habits: [Habit]) throws -> Data {
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
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(HabitBackup(exportedAt: Date(), habits: dtos))
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
