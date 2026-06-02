import SwiftUI
import SwiftData

@main
struct HabitKITApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [Habit.self, HabitEntry.self])
    }
}
