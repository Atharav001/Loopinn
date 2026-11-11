import Foundation
import XCTest
@testable import LoopinnCore

final class ActivityAnalyticsTests: XCTestCase {
    func testClipsCrossingEntriesToSelectedPeriod() throws {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let interval = DateInterval(start: start, duration: 3600)
        let first = try ActivityEntry(title: "Reading", startAt: start.addingTimeInterval(-1800), endAt: start.addingTimeInterval(1800), category: "Learning")
        let second = try ActivityEntry(title: "Writing", startAt: start.addingTimeInterval(1800), endAt: start.addingTimeInterval(5400), category: "Work")
        let summary = ActivitySummary(entries: [first, second], during: interval)
        XCTAssertEqual(summary.trackedSeconds, 3600)
        XCTAssertEqual(summary.categorySeconds["Learning"], 1800)
        XCTAssertEqual(summary.categorySeconds["Work"], 1800)
        XCTAssertEqual(summary.entryCount, 2)
    }
}
