import SwiftUI

struct DayStripView: View {
    @Binding var selectedDay: Date

    private let days: [Date] = {
        let today = Date().startOfDay
        return (0..<14).reversed().map { today.adding(days: -$0) }
    }()

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(days, id: \.self) { day in
                        DayChip(day: day, isSelected: day == selectedDay)
                            .onTapGesture { selectedDay = day }
                            .id(day)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .onAppear {
                proxy.scrollTo(Date().startOfDay, anchor: .trailing)
            }
        }
    }
}

private struct DayChip: View {
    let day: Date
    let isSelected: Bool

    private var isToday: Bool { day == Date().startOfDay }

    private var dayLetter: String {
        day.formatted(.dateTime.weekday(.narrow))
    }

    private var dayNumber: String {
        day.formatted(.dateTime.day())
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(dayLetter)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isSelected ? .black : .secondary)
            Text(dayNumber)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(isSelected ? .black : .primary)
        }
        .frame(width: 40, height: 54)
        .background(isSelected ? Color.green : Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isToday && !isSelected ? Color.green.opacity(0.4) : .clear, lineWidth: 1.5)
        )
    }
}
