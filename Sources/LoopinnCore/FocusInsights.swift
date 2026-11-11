import Foundation

public struct FocusInsights: Equatable, Sendable {
    public let focusedSeconds: TimeInterval
    public let completedSessions: Int
    public let longestSessionSeconds: TimeInterval

    public init(records: [FocusRecord], during interval: DateInterval) {
        var total: TimeInterval = 0
        var count = 0
        var longest: TimeInterval = 0
        for record in records {
            let overlap = max(0, min(record.endAt, interval.end).timeIntervalSince(max(record.startAt, interval.start)))
            guard overlap > 0 else { continue }
            let ratio = min(1, overlap / max(1, record.endAt.timeIntervalSince(record.startAt)))
            total += record.activeSeconds * ratio
            count += 1
            longest = max(longest, record.activeSeconds)
        }
        focusedSeconds = total
        completedSessions = count
        longestSessionSeconds = longest
    }
}
