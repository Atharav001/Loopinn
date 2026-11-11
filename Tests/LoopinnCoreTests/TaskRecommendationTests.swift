import Foundation
import XCTest
@testable import LoopinnCore

final class TaskRecommendationTests: XCTestCase {
    func testOverdueTaskPrecedesStarredTaskAndExplainsChoice() throws {
        var workspace = Workspace()
        let listID = workspace.lists[0].id
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        var starred = LoopTask(listID: listID, title: "Starred")
        starred.isStarred = true
        var overdue = LoopTask(listID: listID, title: "Overdue")
        overdue.dueAt = now.addingTimeInterval(-60)
        workspace.tasks = [starred, overdue]
        let choice = try XCTUnwrap(TaskRecommendations.next(in: workspace, now: now))
        XCTAssertEqual(choice.taskID, overdue.id)
        XCTAssertEqual(choice.reason, "Due now or overdue")
    }

    func testShorterEffortBreaksTiesDeterministically() throws {
        var workspace = Workspace()
        let listID = workspace.lists[0].id
        let created = Date(timeIntervalSince1970: 1_700_000_000)
        var long = LoopTask(listID: listID, title: "Long", createdAt: created)
        long.estimateMinutes = 60
        var short = LoopTask(listID: listID, title: "Short", createdAt: created)
        short.estimateMinutes = 10
        workspace.tasks = [long, short]
        let choice = try XCTUnwrap(TaskRecommendations.next(in: workspace, now: created))
        XCTAssertEqual(choice.taskID, short.id)
        XCTAssertEqual(choice.reason, "Quick win (10 min)")
    }
}
