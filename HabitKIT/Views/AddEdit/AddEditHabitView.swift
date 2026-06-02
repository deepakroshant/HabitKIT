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

    var isEditing: Bool { habit != nil }

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
                    name = h.name
                    icon = h.icon
                    colorHex = h.colorHex
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let h = habit {
            h.name = trimmed
            h.icon = icon
            h.colorHex = colorHex
        } else {
            let h = Habit(name: trimmed, icon: icon, colorHex: colorHex, sortOrder: habits.count)
            context.insert(h)
        }
        try? context.save()
        dismiss()
    }
}
