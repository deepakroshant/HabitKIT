import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Query private var habits: [Habit]

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Today", systemImage: "checkmark.circle.fill")
                }
            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(.green)
        .preferredColorScheme(.dark)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                BackupManager.shared.autoExport(habits: habits)
            }
        }
    }
}
