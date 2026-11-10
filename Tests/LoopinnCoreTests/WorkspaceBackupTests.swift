import Foundation
import XCTest
@testable import LoopinnCore

final class WorkspaceBackupTests: XCTestCase {
    func testBackupRestoresWorkspaceSettingsAndAttachment() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let attachments = root.appendingPathComponent("attachments", isDirectory: true)
        try FileManager.default.createDirectory(at: attachments, withIntermediateDirectories: true)
        let attachment = TaskAttachment(id: UUID(), originalName: "idea.txt", storedName: "idea.txt", byteCount: 5)
        try Data("hello".utf8).write(to: attachments.appendingPathComponent(attachment.storedName))
        var workspace = Workspace()
        var task = LoopTask(listID: workspace.lists[0].id, title: "Draft")
        task.attachments = [attachment]
        workspace.tasks.append(task)
        let backup = root.appendingPathComponent("copy.loopinnbackup", isDirectory: true)
        let settings = AppSettings(theme: .dark, accent: .teal)
        try WorkspaceBackup.create(workspace: workspace, settings: settings, attachmentsDirectory: attachments, at: backup)
        let snapshot = try WorkspaceBackup.inspect(at: backup)
        XCTAssertEqual(snapshot.workspace, workspace)
        XCTAssertEqual(snapshot.settings, settings)
        let restored = root.appendingPathComponent("restored", isDirectory: true)
        try WorkspaceBackup.installAttachments(from: backup, workspace: snapshot.workspace, into: restored)
        XCTAssertEqual(try Data(contentsOf: restored.appendingPathComponent("idea.txt")), Data("hello".utf8))
    }

    func testMissingAttachmentPreventsBackup() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        var workspace = Workspace()
        var task = LoopTask(listID: workspace.lists[0].id, title: "Draft")
        task.attachments = [TaskAttachment(id: UUID(), originalName: "gone.txt", storedName: "gone.txt", byteCount: 1)]
        workspace.tasks.append(task)
        let backup = root.appendingPathComponent("copy.loopinnbackup")
        XCTAssertThrowsError(try WorkspaceBackup.create(workspace: workspace, settings: AppSettings(), attachmentsDirectory: root, at: backup))
        XCTAssertFalse(FileManager.default.fileExists(atPath: backup.path))
    }

    func testUnsafeAttachmentPathIsRejected() throws {
        var workspace = Workspace()
        var task = LoopTask(listID: workspace.lists[0].id, title: "Draft")
        task.attachments = [TaskAttachment(id: UUID(), originalName: "bad", storedName: "../bad", byteCount: 1)]
        workspace.tasks.append(task)
        let root = FileManager.default.temporaryDirectory
        XCTAssertThrowsError(try WorkspaceBackup.create(workspace: workspace, settings: AppSettings(), attachmentsDirectory: root, at: root.appendingPathComponent(UUID().uuidString)))
    }

    func testRestoreRefusesConflictingExistingAttachment() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let source = root.appendingPathComponent("source", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        let attachment = TaskAttachment(id: UUID(), originalName: "idea.txt", storedName: "idea.txt", byteCount: 5)
        try Data("hello".utf8).write(to: source.appendingPathComponent("idea.txt"))
        var workspace = Workspace()
        var task = LoopTask(listID: workspace.lists[0].id, title: "Draft")
        task.attachments = [attachment]
        workspace.tasks.append(task)
        let backup = root.appendingPathComponent("copy.loopinnbackup")
        try WorkspaceBackup.create(workspace: workspace, settings: AppSettings(), attachmentsDirectory: source, at: backup)
        let destination = root.appendingPathComponent("destination", isDirectory: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        try Data("other".utf8).write(to: destination.appendingPathComponent("idea.txt"))
        XCTAssertThrowsError(try WorkspaceBackup.installAttachments(from: backup, workspace: workspace, into: destination))
        XCTAssertEqual(try Data(contentsOf: destination.appendingPathComponent("idea.txt")), Data("other".utf8))
    }
}
