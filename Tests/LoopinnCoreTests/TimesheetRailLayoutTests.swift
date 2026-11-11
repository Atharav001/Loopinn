import Foundation
import XCTest
@testable import LoopinnCore

final class TimesheetRailLayoutTests: XCTestCase {
    func testOverlapsUseSeparateLanesAndAdjacentEntriesReuseOne() {
        let origin = Date(timeIntervalSince1970: 1_700_000_000)
        let a = UUID(), b = UUID(), c = UUID(), d = UUID()
        let entries = [
            TimesheetRailEntry(id: a, start: origin, end: origin.addingTimeInterval(3600)),
            TimesheetRailEntry(id: b, start: origin.addingTimeInterval(900), end: origin.addingTimeInterval(2700)),
            TimesheetRailEntry(id: c, start: origin.addingTimeInterval(1800), end: origin.addingTimeInterval(4500)),
            TimesheetRailEntry(id: d, start: origin.addingTimeInterval(4500), end: origin.addingTimeInterval(5400))
        ]
        let placements = TimesheetRailLayout.place(entries, within: DateInterval(start: origin, duration: 7200))
        XCTAssertEqual(placements.count, 4)
        XCTAssertEqual(placements.first(where: { $0.id == a })?.laneCount, 3)
        XCTAssertEqual(placements.first(where: { $0.id == b })?.lane, 1)
        XCTAssertEqual(placements.first(where: { $0.id == c })?.lane, 2)
        XCTAssertEqual(placements.first(where: { $0.id == d })?.laneCount, 1)
    }

    func testCrossBoundaryEntriesAreClippedAndInvisibleOnesOmitted() {
        let origin = Date(timeIntervalSince1970: 1_700_000_000)
        let crossing = UUID()
        let placements = TimesheetRailLayout.place([
            TimesheetRailEntry(id: crossing, start: origin.addingTimeInterval(-600), end: origin.addingTimeInterval(600)),
            TimesheetRailEntry(id: UUID(), start: origin.addingTimeInterval(-1200), end: origin)
        ], within: DateInterval(start: origin, duration: 3600))
        XCTAssertEqual(placements.count, 1)
        XCTAssertEqual(placements[0].id, crossing)
        XCTAssertEqual(placements[0].start, origin)
        XCTAssertEqual(placements[0].end, origin.addingTimeInterval(600))
    }
}
