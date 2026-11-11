import Foundation
import XCTest
@testable import LoopinnCore

final class ActivityTimeParserTests: XCTestCase {
    func testExplicitNoonAndMidnightRanges() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let day = Date(timeIntervalSince1970: 1_700_000_000)
        let draft = try XCTUnwrap(ActivityTimeParser.parse("11am to noon Design review", on: day, calendar: calendar))
        XCTAssertEqual(draft.title, "Design review")
        XCTAssertEqual(draft.endAt.timeIntervalSince(draft.startAt), 3600)
        XCTAssertNotNil(ActivityTimeParser.parse("midnight - 1:30am Reading", on: day, calendar: calendar))
    }

    func testAmbiguousAndInvalidRangesUseManualFallback() {
        let day = Date(timeIntervalSince1970: 1_700_000_000)
        XCTAssertNil(ActivityTimeParser.parse("11 to 12 Work", on: day))
        XCTAssertNil(ActivityTimeParser.parse("11pm to 1am Work", on: day))
        XCTAssertNil(ActivityTimeParser.parse("13am to 2pm Work", on: day))
    }
}
