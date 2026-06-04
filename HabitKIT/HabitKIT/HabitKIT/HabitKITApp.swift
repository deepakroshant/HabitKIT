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

        // Try CloudKit-backed container first (syncs data across reinstalls via iCloud)
        let cloudConfig = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .automatic
        )
        if let c = try? ModelContainer(for: schema, configurations: cloudConfig) {
            return c
        }

        // CloudKit unavailable (no iCloud account, simulator, etc.) — fall back to local store
        if let c = try? ModelContainer(for: schema) { return c }

        // Schema changed — wipe local store and start fresh
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
