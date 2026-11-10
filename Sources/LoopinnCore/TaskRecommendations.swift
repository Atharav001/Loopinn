import Foundation

public struct TaskRecommendation: Equatable, Sendable {
    public let taskID: UUID
    public let reason: String
}

public enum TaskRecommendations {
    public static func next(in workspace: Workspace, now: Date = .now, excluding taskID: UUID? = nil) -> TaskRecommendation? {
        let candidates = workspace.tasks.filter { $0.completedAt == nil && $0.id != taskID }
        guard let task = candidates.sorted(by: { rank($0, now: now) < rank($1, now: now) }).first else { return nil }
        let reason: String
        if let due = task.dueAt, due <= now { reason = "Due now or overdue" }
        else if let due = task.dueAt, due <= now.addingTimeInterval(86_400) { reason = "Due within 24 hours" }
        else if task.isStarred == true { reason = "Starred priority" }
        else if task.priority == 3 { reason = "High priority" }
        else if task.startAt != nil { reason = "Scheduled work" }
        else if let minutes = task.estimateMinutes, minutes <= 15 { reason = "Quick win (\(minutes) min)" }
        else { reason = "Ready to start" }
        return TaskRecommendation(taskID: task.id, reason: reason)
    }

    private static func rank(_ task: LoopTask, now: Date) -> (Int, Int, Date, Int, Date, String) {
        let urgency: Int
        if let due = task.dueAt, due <= now { urgency = 0 }
        else if let due = task.dueAt, due <= now.addingTimeInterval(86_400) { urgency = 1 }
        else if task.isStarred == true { urgency = 2 }
        else if task.priority == 3 { urgency = 3 }
        else if task.startAt != nil { urgency = 4 }
        else { urgency = 5 }
        return (urgency, -(task.priority ?? 0), task.dueAt ?? .distantFuture, task.estimateMinutes ?? .max, task.createdAt, task.id.uuidString)
    }
}
