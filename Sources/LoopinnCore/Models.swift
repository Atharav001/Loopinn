import Foundation

public struct TaskList: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var order: Int

    public init(id: UUID = UUID(), name: String, order: Int = 0) {
        self.id = id
        self.name = name
        self.order = order
    }
}

public struct LoopTask: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var listID: UUID
    public var title: String
    public var notes: String
    public var priority: Int?
    public var isStarred: Bool?
    public var dueAt: Date?
    public var startAt: Date?
    public var endAt: Date?
    public var completedAt: Date?
    public var createdAt: Date

    public init(id: UUID = UUID(), listID: UUID, title: String, notes: String = "", dueAt: Date? = nil, startAt: Date? = nil, endAt: Date? = nil, completedAt: Date? = nil, createdAt: Date = .now) {
        self.id = id
        self.listID = listID
        self.title = title
        self.notes = notes
        self.priority = nil
        self.isStarred = false
        self.dueAt = dueAt
        self.startAt = startAt
        self.endAt = endAt
        self.completedAt = completedAt
        self.createdAt = createdAt
    }
}

public struct CalendarBlock: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var taskID: UUID
    public var startAt: Date
    public var endAt: Date

    public init(id: UUID = UUID(), taskID: UUID, startAt: Date, endAt: Date) {
        self.id = id
        self.taskID = taskID
        self.startAt = startAt
        self.endAt = endAt
    }
}

public struct Workspace: Codable, Equatable, Sendable {
    public var schemaVersion: Int = 1
    public var lists: [TaskList]
    public var tasks: [LoopTask]
    public var blocks: [CalendarBlock]

    public init() {
        lists = [TaskList(name: "Inbox")]
        tasks = []
        blocks = []
    }
}

public enum WorkspaceError: LocalizedError, Sendable {
    case emptyTitle
    case missingList
    case missingTask
    case incompleteInterval
    case invalidInterval
    case emptyListName
    case lastList

    public var errorDescription: String? {
        switch self {
        case .emptyTitle: "Enter a task title."
        case .missingList: "The selected list no longer exists."
        case .missingTask: "The task no longer exists."
        case .incompleteInterval: "Set both a start and end time to schedule a task."
        case .invalidInterval: "The end time must be after the start time."
        case .emptyListName: "Enter a list name."
        case .lastList: "Keep at least one list."
        }
    }
}
