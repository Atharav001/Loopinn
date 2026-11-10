import Foundation
import XCTest
@testable import LoopinnCore

final class PomodoroSessionTests: XCTestCase {
    func testPauseResumeAndRelaunchDeadline() throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        var session = PomodoroSession()
        session.start(at: now)
        session.pause(at: now.addingTimeInterval(60))
        XCTAssertEqual(session.remaining(), 24 * 60)
        session.start(at: now.addingTimeInterval(300))
        let restored = try JSONDecoder().decode(PomodoroSession.self, from: JSONEncoder().encode(session))
        XCTAssertEqual(restored.remaining(at: now.addingTimeInterval(360)), 23 * 60)
    }

    func testSleepRecoveryTransitionsToBreak() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        var session = PomodoroSession()
        session.start(at: now)
        session.reconcile(at: now.addingTimeInterval(25 * 60 + 30))
        XCTAssertEqual(session.phase, .breakTime)
        XCTAssertEqual(session.completedCycles, 1)
        XCTAssertEqual(session.remaining(at: now.addingTimeInterval(25 * 60 + 30)), 4 * 60 + 30)
    }
}
