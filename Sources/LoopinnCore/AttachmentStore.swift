import Foundation

public final class AttachmentStore {
    private let directory: URL

    public init(directory: URL) throws {
        self.directory = directory.appendingPathComponent("attachments", isDirectory: true)
        try FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
    }

    public func copy(_ source: URL) throws -> TaskAttachment {
        let accessed = source.startAccessingSecurityScopedResource()
        defer { if accessed { source.stopAccessingSecurityScopedResource() } }
        let id = UUID()
        let suffix = source.pathExtension.isEmpty ? "" : ".\(source.pathExtension)"
        let storedName = id.uuidString + suffix
        let destination = directory.appendingPathComponent(storedName)
        let sourceSize = try source.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard sourceSize <= 100 * 1024 * 1024 else { throw DatabaseError.failed("Attachments must be 100 MB or smaller") }
        try FileManager.default.copyItem(at: source, to: destination)
        do {
            let values = try destination.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
            guard values.isRegularFile == true else { throw DatabaseError.failed("Only regular files can be attached") }
            guard (values.fileSize ?? 0) <= 100 * 1024 * 1024 else { throw DatabaseError.failed("Attachments must be 100 MB or smaller") }
            return TaskAttachment(id: id, originalName: source.lastPathComponent, storedName: storedName, byteCount: Int64(values.fileSize ?? 0))
        } catch {
            try? FileManager.default.removeItem(at: destination)
            throw error
        }
    }

    public func fileURL(for attachment: TaskAttachment) -> URL {
        directory.appendingPathComponent(attachment.storedName)
    }

    public func remove(_ attachment: TaskAttachment) throws {
        let url = fileURL(for: attachment)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    public func prune(keeping attachments: [TaskAttachment]) throws {
        let names = Set(attachments.filter { $0.linkURLString == nil }.map(\.storedName))
        for file in try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) {
            if !names.contains(file.lastPathComponent) {
                try FileManager.default.removeItem(at: file)
            }
        }
    }
}
