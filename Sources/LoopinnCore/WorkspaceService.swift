import Foundation

public struct WorkspaceService: Sendable {
    public init() {}

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
