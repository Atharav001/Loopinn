import Foundation

public struct WidgetTask: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let title: String
    public init(id: UUID, title: String) { self.id = id; self.title = title }
}

public struct WidgetSnapshot: Codable, Equatable, Sendable {
    public let tasks: [WidgetTask]
    public let updatedAt: Date
    public init(workspace: Workspace, updatedAt: Date = .now) {
        tasks = Array(workspace.tasks.filter { $0.completedAt == nil }.prefix(8).map { WidgetTask(id: $0.id, title: $0.title) })
        self.updatedAt = updatedAt
    }
}

public enum WidgetSnapshotStore {
    public static let suite = "group.com.atharav.loopinn"
    private static let key = "loopinn.widget.tasks.v1"
    public enum SnapshotError: Error { case appGroupUnavailable }

    public static func save(_ snapshot: WidgetSnapshot, defaults: UserDefaults? = UserDefaults(suiteName: suite)) throws {
        guard let defaults else { throw SnapshotError.appGroupUnavailable }
        defaults.set(try JSONEncoder().encode(snapshot), forKey: key)
    }

    public static func load(defaults: UserDefaults? = UserDefaults(suiteName: suite)) -> WidgetSnapshot? {
        guard let data = defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }
}
