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

    public func updateTask(_ taskID: UUID, title: String, notes: String, dueAt: Date?, priority: Int?, listID: UUID, isStarred: Bool, firstStep: String? = nil, estimateMinutes: Int? = nil, colorTag: String? = nil, in workspace: inout Workspace) throws {
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
        workspace.tasks[index].firstStep = firstStep?.trimmingCharacters(in: .whitespacesAndNewlines)
        workspace.tasks[index].estimateMinutes = estimateMinutes.flatMap { $0 > 0 ? $0 : nil }
        workspace.tasks[index].colorTag = colorTag
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

    public func captureTasks(_ text: String, listID: UUID, in workspace: inout Workspace) throws {
        let titles = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !titles.isEmpty else { throw WorkspaceError.emptyTitle }
        guard workspace.lists.contains(where: { $0.id == listID }) else { throw WorkspaceError.missingList }
        for title in titles { workspace.tasks.append(LoopTask(listID: listID, title: title)) }
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

    public func createBlock(title: String, startAt: Date, endAt: Date, in workspace: inout Workspace) throws {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { throw WorkspaceError.emptyTitle }
        guard endAt > startAt else { throw WorkspaceError.invalidInterval }
        workspace.blocks.append(CalendarBlock(title: clean, startAt: startAt, endAt: endAt))
    }

    public func updateBlock(_ id: UUID, title: String, startAt: Date, endAt: Date, in workspace: inout Workspace) throws {
        guard let index = workspace.blocks.firstIndex(where: { $0.id == id }) else { throw WorkspaceError.missingBlock }
        guard endAt > startAt else { throw WorkspaceError.invalidInterval }
        if let taskID = workspace.blocks[index].taskID {
            try schedule(taskID: taskID, startAt: startAt, endAt: endAt, in: &workspace)
        } else {
            let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !clean.isEmpty else { throw WorkspaceError.emptyTitle }
            workspace.blocks[index].title = clean
            workspace.blocks[index].startAt = startAt
            workspace.blocks[index].endAt = endAt
        }
    }

    public func deleteBlock(_ id: UUID, in workspace: inout Workspace) throws {
        guard let block = workspace.blocks.first(where: { $0.id == id }) else { throw WorkspaceError.missingBlock }
        if let taskID = block.taskID {
            try schedule(taskID: taskID, startAt: nil, endAt: nil, in: &workspace)
        } else {
            workspace.blocks.removeAll { $0.id == id }
        }
    }

    public func recordPublishedEvent(_ link: ExternalCalendarLink, for blockID: UUID, in workspace: inout Workspace) throws {
        guard let index = workspace.blocks.firstIndex(where: { $0.id == blockID }) else { throw WorkspaceError.missingBlock }
        var links = workspace.blocks[index].externalLinks ?? []
        links.removeAll { $0.provider == link.provider && $0.calendarID == link.calendarID }
        links.append(link)
        workspace.blocks[index].externalLinks = links
    }
}
