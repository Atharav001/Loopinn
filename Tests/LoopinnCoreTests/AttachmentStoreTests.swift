import Foundation
import XCTest
@testable import LoopinnCore

final class AttachmentStoreTests: XCTestCase {
    func testCopiedFileReopensAndUnreferencedFileIsRemoved() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let source = directory.appendingPathComponent("notes.txt")
        try Data("hello".utf8).write(to: source)
        let store = try AttachmentStore(directory: directory)
        let attachment = try store.copy(source)
        XCTAssertEqual(attachment.originalName, "notes.txt")
        XCTAssertEqual(try Data(contentsOf: store.fileURL(for: attachment)), Data("hello".utf8))
        try store.prune(keeping: [attachment])
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.fileURL(for: attachment).path))
        try store.prune(keeping: [])
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.fileURL(for: attachment).path))
    }
}
