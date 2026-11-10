import Foundation
import XCTest
import SQLite3
@testable import LoopinnCore

final class WorkspaceDatabaseTests: XCTestCase {
    func testRoundTripPreservesTaskOrderAndLinkedBlock() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let database = try WorkspaceDatabase(directory: directory)
        var workspace = try database.load()
        let service = WorkspaceService()
        let listID = try XCTUnwrap(workspace.lists.first?.id)
        try service.addTask(to: &workspace, title: "First", listID: listID)
        try service.addTask(to: &workspace, title: "Second", listID: listID)
        let taskID = try XCTUnwrap(workspace.tasks.last?.id)
        let start = Date(timeIntervalSince1970: 123_456)
        try service.schedule(taskID: taskID, startAt: start, endAt: start.addingTimeInterval(3600), in: &workspace)
        try service.moveTask(taskID, by: -1, in: &workspace)
        try database.save(workspace)
        let reopened = try WorkspaceDatabase(directory: directory).load()
        XCTAssertEqual(reopened.tasks.map(\.title), ["Second", "First"])
        XCTAssertEqual(reopened.blocks.count, 1)
        XCTAssertEqual(reopened.blocks.first?.taskID, taskID)
    }

    func testImportsLegacyJSONWithoutRemovingIt() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var legacy = Workspace()
        try WorkspaceService().addTask(to: &legacy, title: "Existing work", listID: XCTUnwrap(legacy.lists.first?.id))
        let legacyURL = directory.appendingPathComponent("workspace.json")
        try JSONEncoder().encode(legacy).write(to: legacyURL)
        let database = try WorkspaceDatabase(directory: directory)
        XCTAssertEqual(try database.load().tasks.first?.title, "Existing work")
        XCTAssertTrue(FileManager.default.fileExists(atPath: legacyURL.path))
    }

    func testIndependentBlockPersistsAndDoesNotCreateTask() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let database = try WorkspaceDatabase(directory: directory)
        var workspace = try database.load()
        let start = Date(timeIntervalSince1970: 123_456)
        try WorkspaceService().createBlock(title: "Reading", startAt: start, endAt: start.addingTimeInterval(1800), in: &workspace)
        try database.save(workspace)
        let reopened = try WorkspaceDatabase(directory: directory).load()
        XCTAssertTrue(reopened.tasks.isEmpty)
        XCTAssertEqual(reopened.blocks.first?.title, "Reading")
        XCTAssertNil(reopened.blocks.first?.taskID)
    }

    func testVersionOneMigratesWithBackupAndKeepsTasks() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        do {
            let database = try WorkspaceDatabase(directory: directory)
            var workspace = try database.load()
            let listID = workspace.lists[0].id
            try WorkspaceService().addTask(to: &workspace, title: "Keep me", listID: listID)
            try database.save(workspace)
        }
        var raw: OpaquePointer?
        XCTAssertEqual(sqlite3_open(directory.appendingPathComponent("loopinn.sqlite3").path, &raw), SQLITE_OK)
        XCTAssertEqual(sqlite3_exec(raw, "DROP TABLE independent_blocks; PRAGMA user_version = 1", nil, nil, nil), SQLITE_OK)
        sqlite3_close(raw)
        let migrated = try WorkspaceDatabase(directory: directory)
        XCTAssertEqual(try migrated.load().tasks.first?.title, "Keep me")
        XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: directory.path).contains { $0.hasPrefix("loopinn-before-v2-") })
    }
}
