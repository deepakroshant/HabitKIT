import XCTest
@testable import HabitKIT

final class DateHelpersTests: XCTestCase {
    func test_startOfDay_zeroesTime() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let sod = date.startOfDay
        let comps = Calendar.current.dateComponents([.hour, .minute, .second], from: sod)
        XCTAssertEqual(comps.hour, 0)
        XCTAssertEqual(comps.minute, 0)
        XCTAssertEqual(comps.second, 0)
    }

    func test_adding_days_positive() {
        let base = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let result = base.adding(days: 5)
        let comps = Calendar.current.dateComponents([.day, .month], from: result)
        XCTAssertEqual(comps.day, 6)
        XCTAssertEqual(comps.month, 1)
    }

    func test_mondayOfWeek_onWednesday() {
        // 2024-01-03 is a Wednesday
        let wed = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 3))!
        let monday = mondayOfWeek(containing: wed)
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: monday)
        XCTAssertEqual(comps.year, 2024)
        XCTAssertEqual(comps.month, 1)
        XCTAssertEqual(comps.day, 1) // 2024-01-01 is Monday
    }

    func test_weekColumns_count() {
        let cols = weekColumns(weeks: 18)
        XCTAssertEqual(cols.count, 18)
    }

    func test_weekColumns_lastIsThisMonday() {
        let today = Date()
        let cols = weekColumns(weeks: 18, today: today)
        let thisMonday = mondayOfWeek(containing: today)
        XCTAssertEqual(cols.last!, thisMonday)
    }
}
