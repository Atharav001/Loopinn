import Foundation

public enum BackupError: LocalizedError {
    case unsupportedVersion
    case invalidWorkspace
    case unsafeAttachmentName
    case missingAttachment(String)
    case attachmentConflict(String)
    case destinationExists

    public var errorDescription: String? {
        switch self {
        case .unsupportedVersion: "This backup was created by an unsupported version of Loopinn."
        case .invalidWorkspace: "This backup contains invalid task or schedule links."
        case .unsafeAttachmentName: "This backup contains an unsafe attachment name."
        case .missingAttachment(let name): "The backup is missing attachment \(name)."
        case .attachmentConflict(let name): "An existing attachment conflicts with backup file \(name)."
        case .destinationExists: "A backup already exists at that location. Choose a new name."
        }
    }
}

public struct WorkspaceSnapshot: Codable, Sendable {
    public let version: Int
    public let workspace: Workspace
    public let settings: AppSettings

    public init(workspace: Workspace, settings: AppSettings) {
        version = 1
        self.workspace = workspace
        self.settings = settings
    }
}

public enum WorkspaceBackup {
    public static func create(workspace: Workspace, settings: AppSettings, attachmentsDirectory: URL, at destination: URL) throws {
        try validate(workspace)
        let files = try attachmentNames(in: workspace)
        let manager = FileManager.default
        guard !manager.fileExists(atPath: destination.path) else { throw BackupError.destinationExists }
        let staging = destination.deletingLastPathComponent().appendingPathComponent(".loopinn-backup-\(UUID().uuidString)", isDirectory: true)
        try manager.createDirectory(at: staging, withIntermediateDirectories: false)
        defer { try? manager.removeItem(at: staging) }
        let attachmentTarget = staging.appendingPathComponent("attachments", isDirectory: true)
        try manager.createDirectory(at: attachmentTarget, withIntermediateDirectories: false)
        for name in files {
            let source = attachmentsDirectory.appendingPathComponent(name)
            guard manager.fileExists(atPath: source.path) else { throw BackupError.missingAttachment(name) }
            try manager.copyItem(at: source, to: attachmentTarget.appendingPathComponent(name))
        }
        let snapshot = WorkspaceSnapshot(workspace: workspace, settings: settings)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(snapshot).write(to: staging.appendingPathComponent("workspace.json"), options: .atomic)
        try manager.moveItem(at: staging, to: destination)
    }

    public static func inspect(at source: URL) throws -> WorkspaceSnapshot {
        let data = try Data(contentsOf: source.appendingPathComponent("workspace.json"))
        let snapshot = try JSONDecoder().decode(WorkspaceSnapshot.self, from: data)
        guard snapshot.version == 1, snapshot.settings.version == 1, snapshot.workspace.schemaVersion == 1 else {
            throw BackupError.unsupportedVersion
        }
        try validate(snapshot.workspace)
        let directory = source.appendingPathComponent("attachments", isDirectory: true)
        for name in try attachmentNames(in: snapshot.workspace) {
            let file = directory.appendingPathComponent(name)
            guard FileManager.default.fileExists(atPath: file.path) else { throw BackupError.missingAttachment(name) }
            let values = try file.resourceValues(forKeys: [.isRegularFileKey])
            guard values.isRegularFile == true else { throw BackupError.missingAttachment(name) }
        }
        return snapshot
    }

    /// Copies files before the caller commits the workspace. Existing files are never overwritten.
    public static func installAttachments(from source: URL, workspace: Workspace, into destination: URL) throws {
        let manager = FileManager.default
        try manager.createDirectory(at: destination, withIntermediateDirectories: true)
        for name in try attachmentNames(in: workspace) {
            let target = destination.appendingPathComponent(name)
            let backupFile = source.appendingPathComponent("attachments").appendingPathComponent(name)
            if manager.fileExists(atPath: target.path) {
                guard try Data(contentsOf: target) == Data(contentsOf: backupFile) else {
                    throw BackupError.attachmentConflict(name)
                }
                continue
            }
            try manager.copyItem(at: backupFile, to: target)
        }
    }

    private static func attachmentNames(in workspace: Workspace) throws -> Set<String> {
        let names = workspace.tasks.flatMap { $0.attachments ?? [] }.filter { $0.linkURLString == nil }.map(\.storedName)
        for name in names where name.isEmpty || name == "." || name == ".." || name != (name as NSString).lastPathComponent || name.contains("/") || name.contains("\\") {
            throw BackupError.unsafeAttachmentName
        }
        return Set(names)
    }

    private static func validate(_ workspace: Workspace) throws {
        let listIDs = Set(workspace.lists.map(\.id))
        let taskIDs = Set(workspace.tasks.map(\.id))
        guard !workspace.lists.isEmpty,
              listIDs.count == workspace.lists.count,
              taskIDs.count == workspace.tasks.count,
              workspace.tasks.allSatisfy({ listIDs.contains($0.listID) }),
              workspace.blocks.allSatisfy({ ($0.taskID == nil || taskIDs.contains($0.taskID!)) && $0.startAt < $0.endAt }),
              Set(workspace.blocks.compactMap(\.taskID)).count == workspace.blocks.compactMap(\.taskID).count else {
            throw BackupError.invalidWorkspace
        }
    }
}
