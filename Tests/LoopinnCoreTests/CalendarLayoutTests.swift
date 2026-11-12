import Foundation
import XCTest
@testable import LoopinnCore

final class CalendarLayoutTests: XCTestCase {
    func testCrossMidnightBlockAppearsOnBothDays() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let first = calendar.date(from: DateComponents(year: 2026, month: 11, day: 10, hour: 23))!
        let second = first.addingTimeInterval(2 * 3600)
        let block = CalendarBlock(title: "Night shift", startAt: first, endAt: second)
        XCTAssertEqual(CalendarLayout.blocks(on: first, from: [block], calendar: calendar).count, 1)
        XCTAssertEqual(CalendarLayout.blocks(on: second, from: [block], calendar: calendar).count, 1)
    }

    func testMonthGridStartsOnConfiguredFirstWeekday() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        let date = calendar.date(from: DateComponents(year: 2026, month: 11, day: 10))!
        let days = CalendarLayout.gridDays(for: date, calendar: calendar)
        XCTAssertEqual(calendar.component(.weekday, from: days[0]), 2)
        XCTAssertEqual(days.count % 7, 0)
        XCTAssertTrue(days.contains { calendar.isDate($0, equalTo: date, toGranularity: .day) })
    }

    func testMonthGridFitsFiveAndSixWeeksAtDifferentWindowHeights() {
        for rows in [5, 6] {
            for height in [360.0, 520.0, 720.0] {
                let rowHeight = CalendarLayout.monthRowHeight(availableHeight: height, rowCount: rows)
                XCTAssertEqual(rowHeight * Double(rows) + 28, height, accuracy: 0.001)
                XCTAssertGreaterThanOrEqual(CalendarLayout.visibleMonthEventCount(cellHeight: rowHeight), 1)
            }
        }
        XCTAssertGreaterThan(CalendarLayout.visibleMonthEventCount(cellHeight: 140),
                             CalendarLayout.visibleMonthEventCount(cellHeight: 65))
    }
}
