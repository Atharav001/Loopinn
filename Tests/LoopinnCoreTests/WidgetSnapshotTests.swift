import Foundation
import XCTest
@testable import LoopinnCore

final class WidgetSnapshotTests: XCTestCase {
    func testSnapshotExcludesCompletedTasksAndRestores() throws {
        var workspace = Workspace()
        let listID = workspace.lists[0].id
        let open = LoopTask(listID: listID, title: "Open")
        let done = LoopTask(listID: listID, title: "Done", completedAt: .now)
        workspace.tasks = [open, done]
        let snapshot = WidgetSnapshot(workspace: workspace)
        XCTAssertEqual(snapshot.tasks.map(\.title), ["Open"])
        let suite = "LoopinnWidgetTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        try WidgetSnapshotStore.save(snapshot, defaults: defaults)
        XCTAssertEqual(WidgetSnapshotStore.load(defaults: defaults), snapshot)
    }
}
