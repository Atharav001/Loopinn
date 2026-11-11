import Foundation

public struct ActivitySummary: Equatable, Sendable {
    public let trackedSeconds: TimeInterval
    public let categorySeconds: [String: TimeInterval]
    public let entryCount: Int

    public init(entries: [ActivityEntry], during interval: DateInterval) {
        var categories: [String: TimeInterval] = [:]
        var count = 0
        for entry in entries {
            let seconds = max(0, min(entry.endAt, interval.end).timeIntervalSince(max(entry.startAt, interval.start)))
            guard seconds > 0 else { continue }
            categories[entry.category, default: 0] += seconds
            count += 1
        }
        trackedSeconds = categories.values.reduce(0, +)
        categorySeconds = categories
        entryCount = count
    }
}
