import SwiftUI
import SwiftData
import UserNotifications

// MARK: - App Delegate (foreground notification display + delegate)
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    /// Show banner + play sound even while the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 willPresent notification: UNNotification,
                                 withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

// MARK: - App Entry Point
@main
struct HabitKITApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let container: ModelContainer = Self.makeContainer()

    static func makeContainer() -> ModelContainer {
        let schema = Schema([Habit.self, HabitEntry.self])
        if let c = try? ModelContainer(for: schema) { return c }
        // Schema changed — wipe store and start fresh
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        if let contents = try? FileManager.default.contentsOfDirectory(at: support, includingPropertiesForKeys: nil) {
            for url in contents where url.lastPathComponent.contains(".store") {
                try? FileManager.default.removeItem(at: url)
            }
        }
        return try! ModelContainer(for: schema)
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(container)
    }
}
