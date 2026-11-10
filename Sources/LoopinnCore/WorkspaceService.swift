import Foundation

public struct WorkspaceService: Sendable {
    public init() {}

    public func addList(named name: String, to workspace: inout Workspace) throws {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { throw WorkspaceError.emptyListName }
        workspace.lists.append(TaskList(name: clean, order: workspace.lists.count))
    }

    public func renameList(_ id: UUID, to name: String, in workspace: inout Workspace) throws {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { throw WorkspaceError.emptyListName }
        guard let index = workspace.lists.firstIndex(where: { $0.id == id }) else { throw WorkspaceError.missingList }
        workspace.lists[index].name = clean
    }

    public func deleteList(_ id: UUID, movingTasksTo destinationID: UUID, in workspace: inout Workspace) throws {
        guard workspace.lists.count > 1 else { throw WorkspaceError.lastList }
        guard id != destinationID, workspace.lists.contains(where: { $0.id == id }), workspace.lists.contains(where: { $0.id == destinationID }) else { throw WorkspaceError.missingList }
        for index in workspace.tasks.indices where workspace.tasks[index].listID == id {
            workspace.tasks[index].listID = destinationID
        }
        workspace.lists.removeAll { $0.id == id }
        for index in workspace.lists.indices { workspace.lists[index].order = index }
    }

    public func moveList(_ id: UUID, by offset: Int, in workspace: inout Workspace) throws {
        guard let index = workspace.lists.firstIndex(where: { $0.id == id }) else { throw WorkspaceError.missingList }
        let destination = index + offset
        guard workspace.lists.indices.contains(destination) else { throw WorkspaceError.invalidMove }
        workspace.lists.swapAt(index, destination)
        for index in workspace.lists.indices { workspace.lists[index].order = index }
    }

    public func moveTask(_ id: UUID, by offset: Int, in workspace: inout Workspace) throws {
        guard let index = workspace.tasks.firstIndex(where: { $0.id == id }) else { throw WorkspaceError.missingTask }
        let listID = workspace.tasks[index].listID
        let peers = workspace.tasks.indices.filter { workspace.tasks[$0].listID == listID }
        guard let peerIndex = peers.firstIndex(of: index), peers.indices.contains(peerIndex + offset) else { throw WorkspaceError.invalidMove }
        workspace.tasks.swapAt(index, peers[peerIndex + offset])
    }

    public func updateTask(_ taskID: UUID, title: String, notes: String, dueAt: Date?, priority: Int?, listID: UUID, isStarred: Bool, in workspace: inout Workspace) throws {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { throw WorkspaceError.emptyTitle }
        guard workspace.lists.contains(where: { $0.id == listID }) else { throw WorkspaceError.missingList }
        guard let index = workspace.tasks.firstIndex(where: { $0.id == taskID }) else { throw WorkspaceError.missingTask }
        workspace.tasks[index].title = clean
        workspace.tasks[index].notes = notes
        workspace.tasks[index].dueAt = dueAt
        workspace.tasks[index].priority = priority
        workspace.tasks[index].listID = listID
        workspace.tasks[index].isStarred = isStarred
    }

    public func deleteTask(_ taskID: UUID, in workspace: inout Workspace) throws {
        guard workspace.tasks.contains(where: { $0.id == taskID }) else { throw WorkspaceError.missingTask }
        workspace.tasks.removeAll { $0.id == taskID }
        workspace.blocks.removeAll { $0.taskID == taskID }
    }

    public func addAttachment(_ attachment: TaskAttachment, to taskID: UUID, in workspace: inout Workspace) throws {
        guard let index = workspace.tasks.firstIndex(where: { $0.id == taskID }) else { throw WorkspaceError.missingTask }
        var attachments = workspace.tasks[index].attachments ?? []
        attachments.append(attachment)
        workspace.tasks[index].attachments = attachments
    }

    public func removeAttachment(_ attachmentID: UUID, from taskID: UUID, in workspace: inout Workspace) throws {
        guard let index = workspace.tasks.firstIndex(where: { $0.id == taskID }) else { throw WorkspaceError.missingTask }
        var attachments = workspace.tasks[index].attachments ?? []
        guard attachments.contains(where: { $0.id == attachmentID }) else { throw WorkspaceError.missingAttachment }
        attachments.removeAll { $0.id == attachmentID }
        workspace.tasks[index].attachments = attachments
    }

    public func addTask(to workspace: inout Workspace, title: String, listID: UUID) throws {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { throw WorkspaceError.emptyTitle }
        guard workspace.lists.contains(where: { $0.id == listID }) else { throw WorkspaceError.missingList }
        workspace.tasks.append(LoopTask(listID: listID, title: cleanTitle))
    }

    public func setCompleted(_ completed: Bool, taskID: UUID, in workspace: inout Workspace) throws {
        guard let index = workspace.tasks.firstIndex(where: { $0.id == taskID }) else { throw WorkspaceError.missingTask }
        workspace.tasks[index].completedAt = completed ? .now : nil
    }

    public func schedule(taskID: UUID, startAt: Date?, endAt: Date?, in workspace: inout Workspace) throws {
        guard let index = workspace.tasks.firstIndex(where: { $0.id == taskID }) else { throw WorkspaceError.missingTask }
        if startAt == nil && endAt == nil {
            workspace.tasks[index].startAt = nil
            workspace.tasks[index].endAt = nil
            workspace.blocks.removeAll { $0.taskID == taskID }
            return
        }
        guard let startAt, let endAt else { throw WorkspaceError.incompleteInterval }
        guard endAt > startAt else { throw WorkspaceError.invalidInterval }
        workspace.tasks[index].startAt = startAt
        workspace.tasks[index].endAt = endAt
        if let blockIndex = workspace.blocks.firstIndex(where: { $0.taskID == taskID }) {
            workspace.blocks[blockIndex].startAt = startAt
            workspace.blocks[blockIndex].endAt = endAt
        } else {
            workspace.blocks.append(CalendarBlock(taskID: taskID, startAt: startAt, endAt: endAt))
        }
    }
}
