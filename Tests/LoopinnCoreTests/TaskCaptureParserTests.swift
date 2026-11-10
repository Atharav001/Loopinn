import Foundation
import XCTest
@testable import LoopinnCore

final class TaskCaptureParserTests: XCTestCase {
    func testRecognizedMetadataAndUnknownTokenFallback() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 11, day: 10, hour: 12))!
        let inbox = TaskList(name: "Inbox")
        let work = TaskList(name: "Work")
        let task = try TaskCaptureParser.parse("Write report !high @tomorrow #Work !urgent", defaultListID: inbox.id, lists: [inbox, work], now: now, calendar: calendar)
        XCTAssertEqual(task.title, "Write report !urgent")
        XCTAssertEqual(task.priority, 3)
        XCTAssertEqual(task.listID, work.id)
        XCTAssertEqual(calendar.component(.day, from: try XCTUnwrap(task.dueAt)), 11)
    }

    func testMetadataOnlyInputDoesNotCreateTask() throws {
        let inbox = TaskList(name: "Inbox")
        XCTAssertThrowsError(try TaskCaptureParser.parse("!high @today", defaultListID: inbox.id, lists: [inbox]))
    }
}
