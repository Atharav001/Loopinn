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
    public var attachments: [TaskAttachment]?
    public var dueAt: Date?
    public var startAt: Date?
    public var endAt: Date?
    public var completedAt: Date?
    public var createdAt: Date
    public var firstStep: String?
    public var estimateMinutes: Int?
    public var colorTag: String?

    public init(id: UUID = UUID(), listID: UUID, title: String, notes: String = "", dueAt: Date? = nil, startAt: Date? = nil, endAt: Date? = nil, completedAt: Date? = nil, createdAt: Date = .now) {
        self.id = id
        self.listID = listID
        self.title = title
        self.notes = notes
        self.priority = nil
        self.isStarred = false
        self.attachments = []
        self.dueAt = dueAt
        self.startAt = startAt
        self.endAt = endAt
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.firstStep = nil
        self.estimateMinutes = nil
        self.colorTag = nil
    }
}

public struct TaskAttachment: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let originalName: String
    public let storedName: String
    public let byteCount: Int64
    public let linkURLString: String?

    public init(id: UUID, originalName: String, storedName: String, byteCount: Int64, linkURLString: String? = nil) {
        self.id = id
        self.originalName = originalName
        self.storedName = storedName
        self.byteCount = byteCount
        self.linkURLString = linkURLString
    }
}

public struct CalendarBlock: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var taskID: UUID?
    public var title: String?
    public var externalLinks: [ExternalCalendarLink]?
    public var startAt: Date
    public var endAt: Date

    public init(id: UUID = UUID(), taskID: UUID? = nil, title: String? = nil, startAt: Date, endAt: Date) {
        self.id = id
        self.taskID = taskID
        self.title = title
        self.externalLinks = []
        self.startAt = startAt
        self.endAt = endAt
    }
}

public struct ExternalCalendarLink: Codable, Equatable, Sendable {
    public let provider: String
    public let calendarID: String
    public let eventID: String
    public init(provider: String, calendarID: String, eventID: String) {
        self.provider = provider
        self.calendarID = calendarID
        self.eventID = eventID
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
    case invalidMove
    case missingAttachment
    case missingBlock

    public var errorDescription: String? {
        switch self {
        case .emptyTitle: "Enter a task title."
        case .missingList: "The selected list no longer exists."
        case .missingTask: "The task no longer exists."
        case .incompleteInterval: "Set both a start and end time to schedule a task."
        case .invalidInterval: "The end time must be after the start time."
        case .emptyListName: "Enter a list name."
        case .lastList: "Keep at least one list."
        case .invalidMove: "This item cannot move further."
        case .missingAttachment: "The attachment no longer exists."
        case .missingBlock: "The time block no longer exists."
        }
    }
}
