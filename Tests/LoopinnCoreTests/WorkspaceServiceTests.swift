import Foundation
import XCTest
@testable import LoopinnCore

final class WorkspaceServiceTests: XCTestCase {
    func testCaptureRejectsBlankAndKeepsSeparateLines() throws {
        var workspace = Workspace()
        let listID = workspace.lists[0].id
        let service = WorkspaceService()
        XCTAssertThrowsError(try service.captureTasks("  \n ", listID: listID, in: &workspace))
        XCTAssertTrue(workspace.tasks.isEmpty)
        try service.captureTasks("First\n\n Second ", listID: listID, in: &workspace)
        XCTAssertEqual(workspace.tasks.map(\.title), ["First", "Second"])
    }

    func testIndependentBlockCanMoveAndResizeWithoutTask() throws {
        var workspace = Workspace()
        let service = WorkspaceService()
        let start = Date(timeIntervalSince1970: 123_456)
        try service.createBlock(title: "Reading", startAt: start, endAt: start.addingTimeInterval(1800), in: &workspace)
        let id = try XCTUnwrap(workspace.blocks.first?.id)
        try service.updateBlock(id, title: "Writing", startAt: start.addingTimeInterval(900), endAt: start.addingTimeInterval(2700), in: &workspace)
        XCTAssertEqual(workspace.blocks.first?.title, "Writing")
        XCTAssertTrue(workspace.tasks.isEmpty)
    }

    func testPublishedLinkCanBeRemovedWithoutDeletingLocalBlock() throws {
        var workspace = Workspace()
        let service = WorkspaceService()
        let start = Date(timeIntervalSince1970: 123_456)
        try service.createBlock(title: "Reading", startAt: start, endAt: start.addingTimeInterval(1800), in: &workspace)
        let id = try XCTUnwrap(workspace.blocks.first?.id)
        let link = ExternalCalendarLink(provider: "google", calendarID: "primary", eventID: "event")
        try service.recordPublishedEvent(link, for: id, in: &workspace)
        XCTAssertEqual(workspace.blocks[0].externalLinks, [link])
        try service.removePublishedEvent(link, from: id, in: &workspace)
        XCTAssertEqual(workspace.blocks.count, 1)
        XCTAssertTrue(workspace.blocks[0].externalLinks?.isEmpty == true)
    }
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

    func testTaskAndListReorderingPreserveOwnership() throws {
        let service = WorkspaceService()
        var workspace = Workspace()
        let inboxID = try XCTUnwrap(workspace.lists.first?.id)
        try service.addList(named: "Work", to: &workspace)
        let workID = try XCTUnwrap(workspace.lists.last?.id)
        try service.addTask(to: &workspace, title: "First", listID: inboxID)
        try service.addTask(to: &workspace, title: "Work item", listID: workID)
        try service.addTask(to: &workspace, title: "Second", listID: inboxID)
        let secondID = try XCTUnwrap(workspace.tasks.last?.id)
        try service.moveTask(secondID, by: -1, in: &workspace)
        XCTAssertEqual(workspace.tasks.filter { $0.listID == inboxID }.map(\.title), ["Second", "First"])
        XCTAssertEqual(workspace.tasks.filter { $0.listID == workID }.map(\.title), ["Work item"])
        try service.moveList(workID, by: -1, in: &workspace)
        XCTAssertEqual(workspace.lists.first?.id, workID)
    }
}
