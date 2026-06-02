import SwiftUI
import SwiftData

struct AddEditHabitView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]

    let habit: Habit?

    @State private var name: String = ""
    @State private var icon: String = "⭐"
    @State private var colorHex: String = "#4FC14F"
    @State private var targetPerWeek: Int = 0
    @State private var customReminderEnabled: Bool = false
    @State private var customReminderTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()

    @AppStorage("notificationsEnabled") private var notificationsEnabled = false

    var isEditing: Bool { habit != nil }

    private let frequencyOptions: [(label: String, value: Int)] = [
        ("Every day", 0),
        ("2× / week", 2),
        ("3× / week", 3),
        ("4× / week", 4),
        ("5× / week", 5),
        ("6× / week", 6),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Go to the gym", text: $name)
                        .font(.system(size: 16))
                }

                Section("Icon") {
                    IconPickerView(selected: $icon)
                        .padding(.vertical, 4)
                }

                Section("Color") {
                    ColorPickerView(selectedHex: $colorHex)
                        .padding(.vertical, 8)
                }

                Section("Frequency") {
                    Picker("How often?", selection: $targetPerWeek) {
                        ForEach(frequencyOptions, id: \.value) { opt in
                            Text(opt.label).tag(opt.value)
                        }
                    }
                    .pickerStyle(.menu)
                    if targetPerWeek > 0 {
                        Label("Streak counts consecutive weeks meeting this target", systemImage: "info.circle")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }

                Section("Custom Reminder") {
                    Toggle("Personal reminder time", isOn: $customReminderEnabled)
                    if customReminderEnabled {
                        DatePicker("Time", selection: $customReminderTime, displayedComponents: .hourAndMinute)
                        if !notificationsEnabled {
                            Label("Enable notifications in Settings to receive reminders", systemImage: "bell.slash")
                                .font(.caption).foregroundStyle(.orange)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(isEditing ? "Edit Habit" : "New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let h = habit {
                    name                  = h.name
                    icon                  = h.icon
                    colorHex              = h.colorHex
                    targetPerWeek         = h.targetPerWeek
                    customReminderEnabled = h.customReminderEnabled
                    customReminderTime    = h.customReminderTime
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let h = habit {
            h.name                  = trimmed
            h.icon                  = icon
            h.colorHex              = colorHex
            h.targetPerWeek         = targetPerWeek
            h.customReminderEnabled = customReminderEnabled
            h.customReminderTime    = customReminderTime
            if customReminderEnabled && notificationsEnabled {
                NotificationManager.shared.scheduleHabitReminder(habit: h)
            } else {
                NotificationManager.shared.cancelHabitReminder(habit: h)
            }
        } else {
            let h = Habit(name: trimmed, icon: icon, colorHex: colorHex, sortOrder: habits.count)
            h.targetPerWeek         = targetPerWeek
            h.customReminderEnabled = customReminderEnabled
            h.customReminderTime    = customReminderTime
            context.insert(h)
            if customReminderEnabled && notificationsEnabled {
                NotificationManager.shared.scheduleHabitReminder(habit: h)
            }
        }
        try? context.save()
        dismiss()
    }
}
