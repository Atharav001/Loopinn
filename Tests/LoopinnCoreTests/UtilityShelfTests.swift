import Foundation
import XCTest
@testable import LoopinnCore

final class UtilityShelfTests: XCTestCase {
    func testClipboardCaptureIsExplicitBoundedAndPinnedItemsRemain() throws {
        var shelf = UtilityShelf()
        shelf.capture("  hello  ")
        shelf.capture("hello")
        XCTAssertEqual(shelf.clips.count, 1)
        XCTAssertEqual(shelf.clips[0].text, "hello")
        shelf.togglePin(shelf.clips[0].id)
        for index in 0..<60 { shelf.capture("item \(index)") }
        XCTAssertEqual(shelf.clips.count, 51)
        XCTAssertTrue(shelf.clips.contains { $0.text == "hello" && $0.isPinned })
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try UtilityShelfStore(directory: directory).save(shelf)
        XCTAssertEqual(try UtilityShelfStore(directory: directory).load(), shelf)
    }
}
