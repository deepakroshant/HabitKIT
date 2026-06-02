import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var habits: [Habit]
    @AppStorage("weekStartsMonday") private var weekStartsMonday = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @State private var showResetAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    Toggle("Week starts on Monday", isOn: $weekStartsMonday)
                    Toggle("Haptic feedback", isOn: $hapticsEnabled)
                }

                Section("Data") {
                    Button("Reset All Data", role: .destructive) {
                        showResetAlert = true
                    }
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

    private func resetAll() {
        for habit in habits {
            context.delete(habit)
        }
        try? context.save()
    }
}
