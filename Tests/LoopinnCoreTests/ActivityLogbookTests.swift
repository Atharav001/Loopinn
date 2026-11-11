import Foundation
import XCTest
@testable import LoopinnCore

final class ActivityLogbookTests: XCTestCase {
    func testHourlyPromptOccursOnceAndSkipsMissedHours() throws {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        var book = ActivityLogbook()
        let first = try XCTUnwrap(book.nextPrompt(at: now, calendar: calendar))
        XCTAssertEqual(first.duration, 3600)
        XCTAssertNil(book.nextPrompt(at: now.addingTimeInterval(10), calendar: calendar))
        let later = try XCTUnwrap(book.nextPrompt(at: now.addingTimeInterval(4 * 3600), calendar: calendar))
        XCTAssertEqual(later.start.timeIntervalSince(first.start), 4 * 3600)
    }

    func testEntriesPersistAndDuplicateIntervalIsRejected() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ActivityLogStore(directory: directory)
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let entry = try ActivityEntry(title: "Design review", startAt: start, endAt: start.addingTimeInterval(3600))
        var book = ActivityLogbook()
        try book.add(entry)
        XCTAssertThrowsError(try book.add(entry))
        try store.save(book)
        XCTAssertEqual(try store.load().entries, [entry])
        book.remove(entry.id)
        XCTAssertTrue(book.entries.isEmpty)
    }

    func testInvalidEntryCannotBeSaved() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        XCTAssertThrowsError(try ActivityEntry(title: " ", startAt: date, endAt: date.addingTimeInterval(60)))
        XCTAssertThrowsError(try ActivityEntry(title: "Work", startAt: date, endAt: date))
    }

    func testOvernightQuietHoursSuppressPrompt() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let night = calendar.date(from: DateComponents(year: 2026, month: 11, day: 11, hour: 23, minute: 1))!
        let morning = calendar.date(from: DateComponents(year: 2026, month: 11, day: 12, hour: 9, minute: 1))!
        var book = ActivityLogbook()
        book.quietHours = ActivityQuietHours(startHour: 22, endHour: 8)
        XCTAssertNil(book.nextPrompt(at: night, calendar: calendar))
        XCTAssertNotNil(book.nextPrompt(at: morning, calendar: calendar))
    }

    func testClassificationUsesLongestMatchingRuleAndLeavesUnknownUncategorized() {
        var book = ActivityLogbook()
        book.setRule(phrase: "read", category: "Personal")
        book.setRule(phrase: "read textbook", category: "Study")
        XCTAssertEqual(book.category(for: "Read textbook chapter"), "Study")
        XCTAssertEqual(book.category(for: "Read novel"), "Personal")
        XCTAssertEqual(book.category(for: "Walk outside"), "Uncategorized")
        book.removeRule("read textbook")
        XCTAssertEqual(book.category(for: "Read textbook chapter"), "Personal")
    }
}
