import Foundation

public enum TaskCaptureParser {
    public static func parse(_ input: String, defaultListID: UUID, lists: [TaskList], now: Date = .now, calendar: Calendar = .current) throws -> LoopTask {
        guard lists.contains(where: { $0.id == defaultListID }) else { throw WorkspaceError.missingList }
        var listID = defaultListID
        var priority: Int?
        var dueAt: Date?
        let words = input.split(whereSeparator: \.isWhitespace)
        var titleWords: [String] = []
        for word in words {
            let token = String(word)
            switch token.lowercased() {
            case "!high": priority = 3
            case "!medium": priority = 2
            case "!low": priority = 1
            case "@today": dueAt = endOfDay(now, calendar: calendar)
            case "@tomorrow":
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
                dueAt = endOfDay(tomorrow, calendar: calendar)
            default:
                if token.hasPrefix("#"), let list = lists.first(where: { $0.name.localizedCaseInsensitiveCompare(String(token.dropFirst())) == .orderedSame }) {
                    listID = list.id
                } else {
                    titleWords.append(token)
                }
            }
        }
        let title = titleWords.joined(separator: " ")
        guard !title.isEmpty else { throw WorkspaceError.emptyTitle }
        var task = LoopTask(listID: listID, title: title)
        task.priority = priority
        task.dueAt = dueAt
        return task
    }

    private static func endOfDay(_ date: Date, calendar: Calendar) -> Date {
        let start = calendar.startOfDay(for: date)
        return (calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)).addingTimeInterval(-1)
    }
}
