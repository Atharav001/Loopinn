import Foundation
import XCTest
@testable import LoopinnCore

final class FocusReminderTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_700_000_000)

    func testMissedIntervalsCollapseToOneDeliveryAfterSleep() {
        var reminder = FocusReminder()
        reminder.setEnabled(true, at: start)
        XCTAssertFalse(reminder.reconcile(at: start.addingTimeInterval(60)))
        XCTAssertTrue(reminder.reconcile(at: start.addingTimeInterval(3 * 60 * 60)))
        XCTAssertFalse(reminder.reconcile(at: start.addingTimeInterval(3 * 60 * 60 + 1)))
        XCTAssertEqual(reminder.nextFireAt, start.addingTimeInterval(3 * 60 * 60 + 30 * 60))
    }

    func testDisableIntervalChangeAndSnoozeDoNotDuplicate() {
        var reminder = FocusReminder()
        reminder.setEnabled(true, at: start)
        reminder.setInterval(minutes: 15, at: start.addingTimeInterval(60))
        XCTAssertFalse(reminder.reconcile(at: start.addingTimeInterval(15 * 60)))
        reminder.snooze(minutes: 10, at: start.addingTimeInterval(15 * 60))
        XCTAssertFalse(reminder.reconcile(at: start.addingTimeInterval(20 * 60)))
        XCTAssertTrue(reminder.reconcile(at: start.addingTimeInterval(25 * 60)))
        reminder.setEnabled(false, at: start.addingTimeInterval(26 * 60))
        XCTAssertNil(reminder.nextFireAt)
        XCTAssertFalse(reminder.reconcile(at: start.addingTimeInterval(24 * 60 * 60)))
    }

    func testRelaunchKeepsNextDeadline() throws {
        let suite = "LoopinnReminderTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var reminder = FocusReminder()
        reminder.setEnabled(true, at: start)
        XCTAssertTrue(reminder.reconcile(at: start.addingTimeInterval(30 * 60)))
        try FocusReminderStore(defaults: defaults).save(reminder)
        var restored = try FocusReminderStore(defaults: defaults).load()
        XCTAssertFalse(restored.reconcile(at: start.addingTimeInterval(30 * 60 + 1)))
        XCTAssertTrue(restored.reconcile(at: start.addingTimeInterval(60 * 60)))
    }
}
