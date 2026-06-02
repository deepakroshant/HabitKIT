import SwiftUI

struct HeatmapGridView: View {
    let habit: Habit
    var weeks: Int = 18
    let onToggle: (Date) -> Void

    private let cellSize: CGFloat = 11
    private let spacing: CGFloat = 3

    private var entrySet: Set<Date> {
        Set(habit.entries.map { $0.date.startOfDay })
    }

    private var accentColor: Color {
        Color(hex: habit.colorHex) ?? .green
    }

    var body: some View {
        let today = Date().startOfDay
        let columns = weekColumns(weeks: weeks)

        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: spacing) {
                    ForEach(columns, id: \.self) { monday in
                        VStack(spacing: spacing) {
                            ForEach(0..<7, id: \.self) { offset in
                                let date = monday.adding(days: offset)
                                DotView(
                                    date: date,
                                    today: today,
                                    isDone: entrySet.contains(date),
                                    color: accentColor,
                                    cellSize: cellSize
                                )
                                .onTapGesture {
                                    if date <= today { onToggle(date) }
                                }
                            }
                        }
                        .id(monday)
                    }
                }
                .padding(.horizontal, 2)
            }
            .onAppear {
                if let last = columns.last {
                    proxy.scrollTo(last, anchor: .trailing)
                }
            }
        }
        .frame(height: cellSize * 7 + spacing * 6)
    }
}

private struct DotView: View {
    let date: Date
    let today: Date
    let isDone: Bool
    let color: Color
    let cellSize: CGFloat
    @State private var pressed = false

    var body: some View {
        let isFuture = date > today
        let isToday = date == today

        RoundedRectangle(cornerRadius: 3)
            .fill(cellFill(isFuture: isFuture))
            .frame(width: cellSize, height: cellSize)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(isToday && !isDone ? color.opacity(0.6) : .clear, lineWidth: 1.5)
            )
            .opacity(isFuture ? 0 : 1)
            .scaleEffect(pressed ? 0.75 : 1.0)
            .animation(.spring(duration: 0.15), value: isDone)
            .animation(.easeInOut(duration: 0.1), value: pressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in if !isFuture { pressed = true } }
                    .onEnded { _ in pressed = false }
            )
    }

    private func cellFill(isFuture: Bool) -> Color {
        if isFuture { return .clear }
        return isDone ? color : Color.white.opacity(0.07)
    }
}
