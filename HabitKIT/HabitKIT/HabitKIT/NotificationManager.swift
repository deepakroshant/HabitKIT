import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    // MARK: - Daily reminders (8 AM + 8 PM)

    func scheduleDailyReminders(habits: [Habit], pendingToday: Int? = nil) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["habitkit-morning", "habitkit-evening"])
        guard !habits.isEmpty else { return }

        let names = habits.prefix(3).map { $0.icon + " " + $0.name }.joined(separator: ", ")
        let extra = habits.count > 3 ? " +\(habits.count - 3) more" : ""

        let morningContent = UNMutableNotificationContent()
        morningContent.title = "Rise and shine! ☀️"
        morningContent.body  = "Today's habits: \(names)\(extra)"
        morningContent.sound = .default
        var morning = DateComponents(); morning.hour = 8; morning.minute = 0
        center.add(UNNotificationRequest(
            identifier: "habitkit-morning",
            content: morningContent,
            trigger: UNCalendarNotificationTrigger(dateMatching: morning, repeats: true)
        ))

        let pending = pendingToday ?? habits.count
        let eveningContent = UNMutableNotificationContent()
        eveningContent.sound = .default
        if pending == 0 {
            eveningContent.title = "Crushed it today! 🎉"
            eveningContent.body  = "All \(habits.count) habits done. Keep the streak alive tomorrow!"
        } else if pending == habits.count {
            eveningContent.title = "Evening check-in 🌙"
            eveningContent.body  = "None of today's \(habits.count) habits logged yet — still time!"
        } else {
            let done = habits.count - pending
            eveningContent.title = "Almost there! 🌙"
            eveningContent.body  = "\(done)/\(habits.count) habits done — \(pending) left for today."
        }
        var evening = DateComponents(); evening.hour = 20; evening.minute = 0
        center.add(UNNotificationRequest(
            identifier: "habitkit-evening",
            content: eveningContent,
            trigger: UNCalendarNotificationTrigger(dateMatching: evening, repeats: true)
        ))
    }

    // MARK: - Per-habit custom reminders

    func scheduleHabitReminder(habit: Habit) {
        guard habit.customReminderEnabled else {
            cancelHabitReminder(habit: habit)
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "\(habit.icon) Time for \(habit.name)!"
        content.body  = "Log it in HabitKIT to keep your streak going."
        content.sound = .default

        var comps = Calendar.current.dateComponents([.hour, .minute], from: habit.customReminderTime)
        comps.second = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(
            identifier: "habitkit-habit-\(habit.id.uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    func cancelHabitReminder(habit: Habit) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["habitkit-habit-\(habit.id.uuidString)"])
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
