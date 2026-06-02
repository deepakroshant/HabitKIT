import SwiftUI
import SwiftData

struct HabitDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var habit: Habit
    @State private var showEdit = false
    @State private var shareImage: UIImage? = nil
    @State private var showShareSheet = false

    private var stats: HabitStats { HabitStats.calculate(for: habit) }
    private var accentColor: Color { Color(hex: habit.colorHex) ?? .green }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack(spacing: 12) {
                    Text(habit.icon)
                        .font(.system(size: 36))
                        .frame(width: 60, height: 60)
                        .background(accentColor.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(habit.name).font(.title).fontWeight(.bold)
                        if habit.targetPerWeek > 0 {
                            Text("\(habit.targetPerWeek)× per week")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        if habit.isPaused {
                            Label("Paused", systemImage: "pause.circle.fill")
                                .font(.caption).foregroundStyle(.orange)
                        }
                    }
                }
                .padding(.top, 8)

                // Stats cards
                HStack(spacing: 12) {
                    StatCard(value: "\(stats.currentStreak)", label: "Current\nStreak", color: accentColor)
                    StatCard(value: "\(stats.bestStreak)", label: "Best\nStreak", color: accentColor)
                    StatCard(value: "\(Int(stats.completionThisMonth * 100))%", label: "This\nMonth", color: accentColor)
                    StatCard(value: "\(stats.totalCompletions)", label: "Total\nDone", color: accentColor)
                }

                // Year heatmap
                VStack(alignment: .leading, spacing: 8) {
                    Text("Past 12 Months")
                        .font(.footnote).fontWeight(.semibold).foregroundStyle(.secondary)
                    YearHeatmapView(habit: habit)
                }

                // Weekly chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("Last 8 Weeks")
                        .font(.footnote).fontWeight(.semibold).foregroundStyle(.secondary)
                    WeeklyChartView(habit: habit)
                }

                // Recent notes
                let notedEntries = habit.entries
                    .filter { !$0.note.isEmpty }
                    .sorted { $0.completedAt > $1.completedAt }
                    .prefix(5)
                if !notedEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Notes")
                            .font(.footnote).fontWeight(.semibold).foregroundStyle(.secondary)
                        VStack(spacing: 0) {
                            ForEach(Array(notedEntries), id: \.id) { entry in
                                HStack(alignment: .top, spacing: 10) {
                                    Text(entry.completedAt.formatted(.dateTime.month(.abbreviated).day()))
                                        .font(.caption).foregroundStyle(.secondary)
                                        .frame(width: 44, alignment: .leading)
                                    Text(entry.note)
                                        .font(.subheadline)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 14)
                                if entry.id != notedEntries.last?.id {
                                    Divider().padding(.leading, 14)
                                }
                            }
                        }
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        exportHeatmap()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Button("Edit") { showEdit = true }
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            AddEditHabitView(habit: habit)
        }
        .sheet(isPresented: $showShareSheet) {
            if let img = shareImage {
                ShareSheet(image: img)
            }
        }
        .preferredColorScheme(.dark)
    }

    @MainActor
    private func exportHeatmap() {
        let view = VStack(spacing: 12) {
            HStack(spacing: 10) {
                Text(habit.icon).font(.title2)
                Text(habit.name).font(.title2).bold().foregroundStyle(.white)
                Spacer()
                Text("🔥 \(HabitStats.calculate(for: habit).currentStreak) day streak")
                    .font(.subheadline).foregroundStyle(.green)
            }
            YearHeatmapView(habit: habit)
            Text("HabitKIT")
                .font(.caption).foregroundStyle(Color.white.opacity(0.3))
        }
        .padding(20)
        .background(Color(red: 0.067, green: 0.067, blue: 0.067))
        .frame(width: 360)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0
        if let img = renderer.uiImage {
            shareImage = img
            showShareSheet = true
        }
    }
}

private struct StatCard: View {
    let value: String
    let label: String
    let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.title2).fontWeight(.bold).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let image: UIImage
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [image], applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
