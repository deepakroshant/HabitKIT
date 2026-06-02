import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var habits: [Habit]
    @AppStorage("weekStartsMonday") private var weekStartsMonday = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @State private var showResetAlert = false
    @State private var notifDenied = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Reminders") {
                    Toggle("Daily reminders", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, enabled in
                            if enabled { requestAndSchedule() }
                            else { NotificationManager.shared.cancelAll() }
                        }
                    if notificationsEnabled {
                        Label("8:00 AM — morning nudge", systemImage: "sunrise.fill")
                            .font(.subheadline).foregroundStyle(.secondary)
                        Label("8:00 PM — evening check-in", systemImage: "moon.fill")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    if notifDenied {
                        Text("Notifications are blocked. Go to Settings → HabitKIT → Notifications to enable.")
                            .font(.caption).foregroundStyle(.orange)
                    }
                }

                Section("Preferences") {
                    Toggle("Week starts on Monday", isOn: $weekStartsMonday)
                    Toggle("Haptic feedback", isOn: $hapticsEnabled)
                }

                Section("Data") {
                    Button("Reset All Data", role: .destructive) { showResetAlert = true }
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0").foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Habits tracked")
                        Spacer()
                        Text("\(habits.count)").foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Reset All Data?", isPresented: $showResetAlert) {
                Button("Delete Everything", role: .destructive) { resetAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all habits and entries. This cannot be undone.")
            }
        }
        .preferredColorScheme(.dark)
    }

    private func requestAndSchedule() {
        Task {
            let granted = await NotificationManager.shared.requestPermission()
            await MainActor.run {
                if granted {
                    NotificationManager.shared.scheduleDailyReminders(habits: habits)
                    notifDenied = false
                } else {
                    notificationsEnabled = false
                    notifDenied = true
                }
            }
        }
    }

    private func resetAll() {
        for habit in habits { context.delete(habit) }
        try? context.save()
    }
}
