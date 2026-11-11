import Foundation

public struct ShelfFile: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let bookmark: Data
    public let addedAt: Date
    public init(id: UUID = UUID(), name: String, bookmark: Data, addedAt: Date = .now) {
        self.id = id; self.name = name; self.bookmark = bookmark; self.addedAt = addedAt
    }
}

public struct ClipboardItem: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let text: String
    public let addedAt: Date
    public var isPinned: Bool
    public init(id: UUID = UUID(), text: String, addedAt: Date = .now, isPinned: Bool = false) {
        self.id = id; self.text = text; self.addedAt = addedAt; self.isPinned = isPinned
    }
}

public struct UtilityShelf: Codable, Equatable, Sendable {
    public var files: [ShelfFile] = []
    public var clips: [ClipboardItem] = []
    public init() {}

    public mutating func capture(_ text: String) {
        let trimmed = String(text.prefix(10_000)).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, clips.first?.text != trimmed else { return }
        clips.insert(ClipboardItem(text: trimmed), at: 0)
        clips = clips.filter(\.isPinned) + Array(clips.filter { !$0.isPinned }.prefix(50))
    }

    public mutating func removeClip(_ id: UUID) { clips.removeAll { $0.id == id } }
    public mutating func togglePin(_ id: UUID) {
        guard let index = clips.firstIndex(where: { $0.id == id }) else { return }
        clips[index].isPinned.toggle()
    }
}

public final class UtilityShelfStore {
    private let url: URL
    public init(directory: URL) { url = directory.appendingPathComponent("utility-shelf.json") }
    public func load() throws -> UtilityShelf {
        guard FileManager.default.fileExists(atPath: url.path) else { return UtilityShelf() }
        return try JSONDecoder().decode(UtilityShelf.self, from: Data(contentsOf: url))
    }
    public func save(_ shelf: UtilityShelf) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(shelf).write(to: url, options: .atomic)
    }
}
