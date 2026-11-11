import Foundation
import XCTest
@testable import LoopinnCore

final class UtilityTimersTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_700_000_000)

    func testStopwatchPauseResumeLapsAndRestore() throws {
        var stopwatch = StopwatchSession()
        stopwatch.start(at: start)
        stopwatch.addLap(at: start.addingTimeInterval(12))
        stopwatch.addLap(at: start.addingTimeInterval(30))
        stopwatch.pause(at: start.addingTimeInterval(40))
        XCTAssertEqual(stopwatch.elapsed(at: start.addingTimeInterval(100)), 40)
        XCTAssertEqual(stopwatch.laps.map(\.split), [12, 18])
        stopwatch.start(at: start.addingTimeInterval(100))
        let restored = try JSONDecoder().decode(StopwatchSession.self, from: JSONEncoder().encode(stopwatch))
        XCTAssertEqual(restored.elapsed(at: start.addingTimeInterval(110)), 50)
        XCTAssertEqual(restored.laps.map(\.elapsed), [12, 30])
    }

    func testStopwatchNeverShowsNegativeTimeAfterClockMovesBack() {
        var stopwatch = StopwatchSession()
        stopwatch.start(at: start)
        XCTAssertEqual(stopwatch.elapsed(at: start.addingTimeInterval(-60)), 0)
        stopwatch.pause(at: start.addingTimeInterval(-60))
        XCTAssertEqual(stopwatch.elapsed(), 0)
    }

    func testCountdownCompletionIsOneTimeAfterSleepAndRestore() throws {
        var countdown = CountdownSession()
        countdown.setDuration(minutes: 2)
        countdown.start(at: start)
        let restored = try JSONDecoder().decode(CountdownSession.self, from: JSONEncoder().encode(countdown))
        countdown = restored
        XCTAssertEqual(countdown.remaining(at: start.addingTimeInterval(30)), 90)
        XCTAssertTrue(countdown.reconcile(at: start.addingTimeInterval(180)))
        XCTAssertEqual(countdown.status, .completed)
        XCTAssertEqual(countdown.remaining(at: start.addingTimeInterval(180)), 0)
        XCTAssertFalse(countdown.reconcile(at: start.addingTimeInterval(181)))
    }

    func testCountdownPauseResumeAndResetPreserveDuration() {
        var countdown = CountdownSession()
        countdown.setDuration(minutes: 3)
        countdown.start(at: start)
        countdown.pause(at: start.addingTimeInterval(30))
        XCTAssertEqual(countdown.remaining(at: start.addingTimeInterval(600)), 150)
        countdown.start(at: start.addingTimeInterval(600))
        XCTAssertEqual(countdown.remaining(at: start.addingTimeInterval(610)), 140)
        countdown.reset()
        XCTAssertEqual(countdown.status, .idle)
        XCTAssertEqual(countdown.remaining(), 180)
    }

    func testStoreKeepsRunningTimersAcrossRelaunch() throws {
        let suite = "LoopinnTimerTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var timers = UtilityTimers()
        timers.stopwatch.start(at: start)
        timers.countdown.start(at: start)
        try UtilityTimersStore(defaults: defaults).save(timers)
        let restored = try UtilityTimersStore(defaults: defaults).load()
        XCTAssertEqual(restored.stopwatch.elapsed(at: start.addingTimeInterval(10)), 10)
        XCTAssertEqual(restored.countdown.remaining(at: start.addingTimeInterval(10)), 590)
    }
}
