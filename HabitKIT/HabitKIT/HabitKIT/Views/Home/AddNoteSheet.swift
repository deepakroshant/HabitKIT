import SwiftUI
import SwiftData

struct AddNoteSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var entry: HabitEntry
    @State private var noteText: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Note") {
                    TextField("How did it go? Any details to remember…",
                              text: $noteText, axis: .vertical)
                        .lineLimit(3...10)
                }
                if !entry.note.isEmpty {
                    Section {
                        Text("Logged at \(entry.completedAt.formatted(.dateTime.hour().minute()))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(entry.note.isEmpty ? "Add Note" : "Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { noteText = entry.note }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        entry.note = noteText
                        try? context.save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(noteText == entry.note)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
