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
}
