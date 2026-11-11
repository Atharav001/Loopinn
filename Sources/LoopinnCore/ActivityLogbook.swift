import Foundation

public struct ActivityEntry: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var startAt: Date
    public var endAt: Date
    public var category: String

    public init(id: UUID = UUID(), title: String, startAt: Date, endAt: Date, category: String = "Uncategorized") throws {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, endAt > startAt else { throw ActivityLogError.invalidEntry }
        self.id = id
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.startAt = startAt
        self.endAt = endAt
        self.category = category
    }
}

public enum ActivityLogError: LocalizedError {
    case invalidEntry, duplicateInterval
    public var errorDescription: String? {
        switch self {
        case .invalidEntry: "Enter an activity and a valid start and end time."
        case .duplicateInterval: "This hour has already been logged. Edit its existing entry instead."
        }
    }
}

public struct ActivityLogbook: Codable, Equatable, Sendable {
    public var entries: [ActivityEntry] = []
    public var lastPromptedHour: Date?

    public init() {}

    public mutating func add(_ entry: ActivityEntry) throws {
        guard !entries.contains(where: { $0.startAt == entry.startAt && $0.endAt == entry.endAt }) else { throw ActivityLogError.duplicateInterval }
        entries.append(entry)
        entries.sort { $0.startAt < $1.startAt }
    }

    public mutating func update(_ entry: ActivityEntry) throws {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { throw ActivityLogError.invalidEntry }
        guard !entries.contains(where: { $0.id != entry.id && $0.startAt == entry.startAt && $0.endAt == entry.endAt }) else { throw ActivityLogError.duplicateInterval }
        entries[index] = entry
        entries.sort { $0.startAt < $1.startAt }
    }

    public mutating func remove(_ id: UUID) { entries.removeAll { $0.id == id } }

    public mutating func nextPrompt(at now: Date = .now, calendar: Calendar = .current) -> DateInterval? {
        guard let hourStart = calendar.dateInterval(of: .hour, for: now)?.start,
              let previous = calendar.date(byAdding: .hour, value: -1, to: hourStart) else { return nil }
        if let lastPromptedHour, lastPromptedHour >= previous { return nil }
        lastPromptedHour = previous
        return DateInterval(start: previous, end: hourStart)
    }
}

public final class ActivityLogStore {
    private let url: URL
    public init(directory: URL) { url = directory.appendingPathComponent("activity-logbook.json") }
    public func load() throws -> ActivityLogbook {
        guard FileManager.default.fileExists(atPath: url.path) else { return ActivityLogbook() }
        return try JSONDecoder().decode(ActivityLogbook.self, from: Data(contentsOf: url))
    }
    public func save(_ book: ActivityLogbook) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(book).write(to: url, options: .atomic)
    }
}
