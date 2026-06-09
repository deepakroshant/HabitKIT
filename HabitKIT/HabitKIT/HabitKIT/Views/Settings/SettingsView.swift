import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var habits: [Habit]
    @AppStorage("weekStartsMonday") private var weekStartsMonday = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @State private var showResetAlert = false
    @State private var notifDenied = false
    @State private var testSent = false
    // Backup
    @State private var exportURL: URL?
    @State private var showExportShare = false
    @State private var showImportPicker = false
    @State private var showImportSuccess = false
    @State private var importError: String?

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

                        Button(testSent ? "Test sent! Lock your screen ✓" : "Send test notification (5 sec)") {
                            sendTestNotification()
                        }
                        .foregroundStyle(testSent ? .green : .blue)
                        .disabled(testSent)
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

                Section("Backup & Restore") {
                    Button {
                        do {
                            exportURL = try BackupManager.shared.export(habits: habits)
                            showExportShare = true
                        } catch {
                            importError = error.localizedDescription
                        }
                    } label: {
                        Label("Export Backup", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        showImportPicker = true
                    } label: {
                        Label("Import Backup", systemImage: "square.and.arrow.down")
                    }
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
            .alert("Backup Restored ✅", isPresented: $showImportSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("All your habits and history have been restored from the backup.")
            }
            .alert("Import Failed", isPresented: Binding(
                get: { importError != nil },
                set: { if !$0 { importError = nil } }
            )) {
                Button("OK", role: .cancel) { importError = nil }
            } message: {
                Text(importError ?? "Unknown error")
            }
            .sheet(isPresented: $showExportShare) {
                if let url = exportURL {
                    ShareSheet(url: url)
                }
            }
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: [.json]
            ) { result in
                switch result {
                case .success(let url):
                    do {
                        try BackupManager.shared.restore(from: url, context: context,
                                                         existingHabits: habits)
                        showImportSuccess = true
                    } catch {
                        importError = error.localizedDescription
                    }
                case .failure(let error):
                    importError = error.localizedDescription
                }
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

    private func sendTestNotification() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            let pending = habits.filter { habit in
                habit.entries.first { Calendar.current.isDateInToday($0.completedAt) } == nil
            }.count

            let content = UNMutableNotificationContent()
            if pending == 0 {
                content.title = "Crushed it today! 🎉"
                content.body  = "All \(habits.count) habits done. Keep the streak alive tomorrow!"
            } else {
                let done = habits.count - pending
                content.title = done == 0 ? "Evening check-in 🌙" : "Almost there! 🌙"
                content.body  = done == 0
                    ? "None of today's \(habits.count) habits logged yet — still time!"
                    : "\(done)/\(habits.count) habits done — \(pending) left for today."
            }
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let request = UNNotificationRequest(identifier: "habitkit-test", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }

        DispatchQueue.main.async { testSent = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) { testSent = false }
    }

    private func resetAll() {
        for habit in habits { context.delete(habit) }
        try? context.save()
    }
}

// MARK: - Share Sheet wrapper

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
