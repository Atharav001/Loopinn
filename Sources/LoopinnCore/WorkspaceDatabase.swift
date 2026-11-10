import Foundation
import SQLite3

public enum DatabaseError: LocalizedError {
    case failed(String)

    public var errorDescription: String? {
        switch self { case .failed(let message): "Database error: \(message)" }
    }
}

public final class WorkspaceDatabase {
    private var handle: OpaquePointer?
    public let databaseURL: URL
    private let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    public init(directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        databaseURL = directory.appendingPathComponent("loopinn.sqlite3")
        let existed = FileManager.default.fileExists(atPath: databaseURL.path)
        guard sqlite3_open_v2(databaseURL.path, &handle, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK else {
            throw DatabaseError.failed("Could not open local database")
        }
        do {
            try execute("PRAGMA foreign_keys = ON")
            try execute("PRAGMA journal_mode = WAL")
            sqlite3_busy_timeout(handle, 5_000)
            let version = Int(sqlite3_user_version())
            if version < 1 {
                if existed {
                    let backupURL = directory.appendingPathComponent("loopinn-before-migration.sqlite3")
                    try FileManager.default.copyItem(at: databaseURL, to: backupURL)
                }
                try execute("BEGIN IMMEDIATE")
                do {
                    try execute("CREATE TABLE lists (id TEXT PRIMARY KEY, sort_order INTEGER NOT NULL, payload BLOB NOT NULL)")
                    try execute("CREATE TABLE tasks (id TEXT PRIMARY KEY, list_id TEXT NOT NULL REFERENCES lists(id), sort_order INTEGER NOT NULL, payload BLOB NOT NULL)")
                    try execute("CREATE TABLE blocks (id TEXT PRIMARY KEY, task_id TEXT NOT NULL UNIQUE REFERENCES tasks(id), start_at REAL NOT NULL, payload BLOB NOT NULL)")
                    try execute("PRAGMA user_version = 1")
                    try execute("COMMIT")
                } catch {
                    try? execute("ROLLBACK")
                    throw error
                }
            }
            if version < 2 {
                if existed && version == 1 {
                    try backupDatabase(to: directory.appendingPathComponent("loopinn-before-v2-\(UUID().uuidString).sqlite3"))
                }
                try execute("BEGIN IMMEDIATE")
                do {
                    try execute("CREATE TABLE independent_blocks (id TEXT PRIMARY KEY, start_at REAL NOT NULL, payload BLOB NOT NULL)")
                    try execute("PRAGMA user_version = 2")
                    try execute("COMMIT")
                } catch {
                    try? execute("ROLLBACK")
                    throw error
                }
            }
            if try rowCount("lists") == 0 {
                let legacyURL = directory.appendingPathComponent("workspace.json")
                if FileManager.default.fileExists(atPath: legacyURL.path) {
                    let legacy = try JSONDecoder().decode(Workspace.self, from: Data(contentsOf: legacyURL))
                    try save(legacy)
                } else {
                    try save(Workspace())
                }
            }
        } catch {
            sqlite3_close(handle)
            handle = nil
            throw error
        }
    }

    deinit { sqlite3_close(handle) }

    public func load() throws -> Workspace {
        var workspace = Workspace()
        workspace.lists = try fetch("SELECT payload FROM lists ORDER BY sort_order", as: TaskList.self)
        workspace.tasks = try fetch("SELECT payload FROM tasks ORDER BY sort_order", as: LoopTask.self)
        workspace.blocks = try fetch("SELECT payload FROM blocks ORDER BY start_at", as: CalendarBlock.self)
        workspace.blocks += try fetch("SELECT payload FROM independent_blocks ORDER BY start_at", as: CalendarBlock.self)
        workspace.blocks.sort { $0.startAt < $1.startAt }
        return workspace
    }

    public func save(_ workspace: Workspace) throws {
        try execute("BEGIN IMMEDIATE")
        do {
            try execute("DELETE FROM blocks")
            try execute("DELETE FROM independent_blocks")
            try execute("DELETE FROM tasks")
            try execute("DELETE FROM lists")
            for (position, list) in workspace.lists.enumerated() {
                try insert("INSERT INTO lists (id, sort_order, payload) VALUES (?, ?, ?)", id: list.id, foreignID: nil, position: position, payload: list)
            }
            for (position, task) in workspace.tasks.enumerated() {
                try insert("INSERT INTO tasks (id, list_id, sort_order, payload) VALUES (?, ?, ?, ?)", id: task.id, foreignID: task.listID, position: position, payload: task)
            }
            for block in workspace.blocks {
                if let taskID = block.taskID {
                    try insert("INSERT INTO blocks (id, task_id, start_at, payload) VALUES (?, ?, ?, ?)", id: block.id, foreignID: taskID, position: Int(block.startAt.timeIntervalSince1970), payload: block)
                } else {
                    try insertIndependentBlock(block)
                }
            }
            try execute("COMMIT")
        } catch {
            try? execute("ROLLBACK")
            throw error
        }
    }

    private func sqlite3_user_version() -> Int32 {
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        guard sqlite3_prepare_v2(handle, "PRAGMA user_version", -1, &statement, nil) == SQLITE_OK else { return -1 }
        return sqlite3_step(statement) == SQLITE_ROW ? sqlite3_column_int(statement, 0) : -1
    }

    private func backupDatabase(to url: URL) throws {
        var backupHandle: OpaquePointer?
        guard sqlite3_open_v2(url.path, &backupHandle, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nil) == SQLITE_OK else {
            sqlite3_close(backupHandle)
            throw DatabaseError.failed("Could not create migration backup")
        }
        defer { sqlite3_close(backupHandle) }
        guard let operation = sqlite3_backup_init(backupHandle, "main", handle, "main") else { throw failure() }
        let result = sqlite3_backup_step(operation, -1)
        let finish = sqlite3_backup_finish(operation)
        guard result == SQLITE_DONE, finish == SQLITE_OK else { throw DatabaseError.failed("Could not finish migration backup") }
    }

    private func rowCount(_ table: String) throws -> Int32 {
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        guard sqlite3_prepare_v2(handle, "SELECT COUNT(*) FROM \(table)", -1, &statement, nil) == SQLITE_OK else { throw failure() }
        guard sqlite3_step(statement) == SQLITE_ROW else { throw failure() }
        return sqlite3_column_int(statement, 0)
    }

    private func fetch<T: Decodable>(_ sql: String, as type: T.Type) throws -> [T] {
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK else { throw failure() }
        var values: [T] = []
        while true {
            let result = sqlite3_step(statement)
            if result == SQLITE_DONE { return values }
            guard result == SQLITE_ROW, let bytes = sqlite3_column_blob(statement, 0) else { throw failure() }
            let data = Data(bytes: bytes, count: Int(sqlite3_column_bytes(statement, 0)))
            values.append(try JSONDecoder().decode(T.self, from: data))
        }
    }

    private func insert<T: Encodable>(_ sql: String, id: UUID, foreignID: UUID?, position: Int, payload: T) throws {
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK else { throw failure() }
        guard sqlite3_bind_text(statement, 1, id.uuidString, -1, transient) == SQLITE_OK else { throw failure() }
        if let foreignID {
            guard sqlite3_bind_text(statement, 2, foreignID.uuidString, -1, transient) == SQLITE_OK else { throw failure() }
            if sql.contains("blocks") { sqlite3_bind_double(statement, 3, Double(position)) }
            else { sqlite3_bind_int(statement, 3, Int32(position)) }
        } else {
            sqlite3_bind_int(statement, 2, Int32(position))
        }
        let data = try JSONEncoder().encode(payload)
        let payloadIndex: Int32 = foreignID == nil ? 3 : 4
        let bindResult = data.withUnsafeBytes { bytes in
            sqlite3_bind_blob(statement, payloadIndex, bytes.baseAddress, Int32(bytes.count), transient)
        }
        guard bindResult == SQLITE_OK, sqlite3_step(statement) == SQLITE_DONE else { throw failure() }
    }

    private func insertIndependentBlock(_ block: CalendarBlock) throws {
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        let sql = "INSERT INTO independent_blocks (id, start_at, payload) VALUES (?, ?, ?)"
        guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK else { throw failure() }
        guard sqlite3_bind_text(statement, 1, block.id.uuidString, -1, transient) == SQLITE_OK else { throw failure() }
        sqlite3_bind_double(statement, 2, block.startAt.timeIntervalSince1970)
        let data = try JSONEncoder().encode(block)
        let result = data.withUnsafeBytes { sqlite3_bind_blob(statement, 3, $0.baseAddress, Int32($0.count), transient) }
        guard result == SQLITE_OK, sqlite3_step(statement) == SQLITE_DONE else { throw failure() }
    }

    private func execute(_ sql: String) throws {
        var errorPointer: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(handle, sql, nil, nil, &errorPointer)
        defer { sqlite3_free(errorPointer) }
        guard result == SQLITE_OK else { throw DatabaseError.failed(errorPointer.map { String(cString: $0) } ?? "SQLite error \(result)") }
    }

    private func failure() -> DatabaseError {
        DatabaseError.failed(handle.map { String(cString: sqlite3_errmsg($0)) } ?? "Unknown SQLite error")
    }
}
