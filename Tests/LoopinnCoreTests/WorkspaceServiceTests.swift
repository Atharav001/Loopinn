import Foundation
import XCTest
@testable import LoopinnCore

final class WorkspaceServiceTests: XCTestCase {
    func testScheduleUpdatesOneBlockAndRemovalKeepsTask() throws {
        let service = WorkspaceService()
        var workspace = Workspace()
        let listID = try XCTUnwrap(workspace.lists.first?.id)
        try service.addTask(to: &workspace, title: "Plan work", listID: listID)
        let taskID = try XCTUnwrap(workspace.tasks.first?.id)
        let start = Date(timeIntervalSince1970: 100_000)
        let end = start.addingTimeInterval(3_600)

        XCTAssertThrowsError(try service.schedule(taskID: taskID, startAt: start, endAt: nil, in: &workspace))
        XCTAssertTrue(workspace.blocks.isEmpty)
        try service.schedule(taskID: taskID, startAt: start, endAt: end, in: &workspace)
        let blockID = try XCTUnwrap(workspace.blocks.first?.id)
        try service.schedule(taskID: taskID, startAt: end, endAt: end.addingTimeInterval(3_600), in: &workspace)
        XCTAssertEqual(workspace.blocks.count, 1)
        XCTAssertEqual(workspace.blocks.first?.id, blockID)
        try service.schedule(taskID: taskID, startAt: nil, endAt: nil, in: &workspace)
        XCTAssertTrue(workspace.blocks.isEmpty)
        XCTAssertEqual(workspace.tasks.count, 1)
    }

    func testDueDateAndListDeletionDoNotChangeSchedule() throws {
        let service = WorkspaceService()
        var workspace = Workspace()
        let inboxID = try XCTUnwrap(workspace.lists.first?.id)
        try service.addList(named: "Work", to: &workspace)
        let workID = try XCTUnwrap(workspace.lists.last?.id)
        try service.addTask(to: &workspace, title: "Review", listID: workID)
        let taskID = try XCTUnwrap(workspace.tasks.first?.id)
        try service.updateTask(taskID, title: "Review", notes: "", dueAt: .now, priority: 2, listID: workID, isStarred: true, in: &workspace)
        XCTAssertTrue(workspace.blocks.isEmpty)
        try service.deleteList(workID, movingTasksTo: inboxID, in: &workspace)
        XCTAssertEqual(workspace.tasks.first?.listID, inboxID)
        XCTAssertEqual(workspace.tasks.first?.dueAt != nil, true)
    }
}
