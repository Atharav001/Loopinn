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

    func testDeepWorkSharesTimerAndCompletesWithoutBreak() throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let taskID = UUID()
        var session = PomodoroSession()
        session.startDeepWork(minutes: 90, taskID: taskID, at: now)
        XCTAssertEqual(session.mode, .deepWork)
        XCTAssertEqual(session.linkedTaskID, taskID)
        session.pause(at: now.addingTimeInterval(60))
        session.start(at: now.addingTimeInterval(120))
        let restored = try JSONDecoder().decode(PomodoroSession.self, from: JSONEncoder().encode(session))
        XCTAssertEqual(restored.linkedTaskID, taskID)
        session.reconcile(at: now.addingTimeInterval(92 * 60))
        XCTAssertEqual(session.status, .completed)
        XCTAssertEqual(session.phase, .focus)
        XCTAssertEqual(session.completedCycles, 0)
        XCTAssertEqual(session.remaining(), 0)
    }

    func testExistingPomodoroDataDecodesWithDefaultMode() throws {
        let legacy = """
        {"phase":"focus","status":"paused","focusMinutes":25,"breakMinutes":5,
         "completedCycles":2,"deadline":null,"pausedRemaining":120}
        """.data(using: .utf8)!
        let session = try JSONDecoder().decode(PomodoroSession.self, from: legacy)
        XCTAssertEqual(session.mode, .pomodoro)
        XCTAssertEqual(session.completedCycles, 2)
        XCTAssertEqual(session.remaining(), 120)
    }

    func testCompletedFocusRecordsActiveDurationAcrossPause() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        var session = PomodoroSession()
        session.start(at: start)
        session.pause(at: start.addingTimeInterval(10 * 60))
        session.start(at: start.addingTimeInterval(20 * 60))
        session.reconcile(at: start.addingTimeInterval(35 * 60))
        XCTAssertEqual(session.focusHistory.count, 1)
        XCTAssertEqual(session.focusHistory[0].activeSeconds, 25 * 60)
        let insights = FocusInsights(records: session.focusHistory, during: DateInterval(start: start, end: start.addingTimeInterval(40 * 60)))
        XCTAssertEqual(insights.focusedSeconds, 25 * 60)
        session.reset()
        XCTAssertEqual(session.focusHistory.count, 1)
    }

    func testLongBreakAndManualAdvanceConfiguration() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        var session = PomodoroSession()
        session.configure(focus: 1, shortBreak: 1, longBreak: 4, longBreakEvery: 2, autoAdvance: true)
        session.start(at: start)
        session.reconcile(at: start.addingTimeInterval(3 * 60))
        XCTAssertEqual(session.phase, .breakTime)
        XCTAssertEqual(session.completedCycles, 2)
        XCTAssertEqual(session.remaining(at: start.addingTimeInterval(3 * 60)), 4 * 60)

        var manual = PomodoroSession()
        manual.configure(focus: 1, shortBreak: 1, longBreak: 4, longBreakEvery: 2, autoAdvance: false)
        manual.start(at: start)
        manual.reconcile(at: start.addingTimeInterval(60))
        XCTAssertEqual(manual.status, .idle)
        XCTAssertEqual(manual.phase, .breakTime)
        manual.start(at: start.addingTimeInterval(120))
        XCTAssertEqual(manual.remaining(at: start.addingTimeInterval(120)), 60)
    }
}
