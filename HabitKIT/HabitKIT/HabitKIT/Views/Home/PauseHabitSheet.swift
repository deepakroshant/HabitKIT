import SwiftUI

struct PauseHabitSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var habit: Habit
    @State private var reason: String = ""
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        Text(habit.icon)
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .background((Color(hex: habit.colorHex) ?? .green).opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(habit.name).font(.headline)
                            Text("Pausing this habit").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Reason (optional)") {
                    TextField("e.g. Traveling this week, recovering from injury…",
                              text: $reason, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Text("Your streak and history are fully preserved. The habit won't appear in your daily list until you resume it.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Pause Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Pause") {
                        habit.isPaused    = true
                        habit.pauseReason = reason
                        habit.pausedAt    = Date()
                        if hapticsEnabled { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
                        dismiss()
                    }
                    .foregroundStyle(.orange)
                    .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
