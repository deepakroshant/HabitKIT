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

    func scheduleDailyReminders(habits: [Habit]) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["habitkit-morning", "habitkit-evening"])

        guard !habits.isEmpty else { return }

        let names = habits.prefix(3).map { $0.icon + " " + $0.name }.joined(separator: ", ")
        let total = habits.count

        // 8 AM — morning nudge
        let morningContent = UNMutableNotificationContent()
        morningContent.title = "Good morning! 🌅"
        morningContent.body = total == 1
            ? "Don't forget: \(names)"
            : "Today's habits: \(names)\(total > 3 ? " + \(total - 3) more" : "")"
        morningContent.sound = .default

        var morning = DateComponents()
        morning.hour = 8
        morning.minute = 0
        let morningTrigger = UNCalendarNotificationTrigger(dateMatching: morning, repeats: true)
        center.add(UNNotificationRequest(identifier: "habitkit-morning", content: morningContent, trigger: morningTrigger))

        // 8 PM — evening check-in
        let eveningContent = UNMutableNotificationContent()
        eveningContent.title = "Evening check-in 🌙"
        eveningContent.body = "Open HabitKIT to log today's habits before midnight."
        eveningContent.sound = .default

        var evening = DateComponents()
        evening.hour = 20
        evening.minute = 0
        let eveningTrigger = UNCalendarNotificationTrigger(dateMatching: evening, repeats: true)
        center.add(UNNotificationRequest(identifier: "habitkit-evening", content: eveningContent, trigger: eveningTrigger))
    }

    func cancelAll() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["habitkit-morning", "habitkit-evening"])
    }
}
