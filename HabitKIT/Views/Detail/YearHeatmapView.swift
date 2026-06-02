import SwiftUI

struct YearHeatmapView: View {
    let habit: Habit
    private let cellSize: CGFloat = 9
    private let spacing: CGFloat = 2.5

    private var entrySet: Set<Date> {
        Set(habit.entries.map { $0.date.startOfDay })
    }

    private var accentColor: Color {
        Color(hex: habit.colorHex) ?? .green
    }

    var body: some View {
        let today = Date().startOfDay
        let columns = weekColumns(weeks: 52)

        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: spacing) {
                    ForEach(columns, id: \.self) { monday in
                        VStack(spacing: spacing) {
                            ForEach(0..<7, id: \.self) { offset in
                                let date = monday.adding(days: offset)
                                let done = entrySet.contains(date.startOfDay)
                                let isFuture = date > today
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(isFuture ? .clear : (done ? accentColor : Color.white.opacity(0.07)))
                                    .frame(width: cellSize, height: cellSize)
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
