import Foundation

public struct TimesheetRailEntry: Sendable {
    public let id: UUID
    public let start: Date
    public let end: Date

    public init(id: UUID, start: Date, end: Date) {
        self.id = id
        self.start = start
        self.end = end
    }
}

public struct TimesheetRailPlacement: Equatable, Sendable {
    public let id: UUID
    public let start: Date
    public let end: Date
    public let lane: Int
    public let laneCount: Int
}

/// Adapts Loopin-macOS's overlap-cluster lane assignment to clipped day intervals.
public enum TimesheetRailLayout {
    public static func place(_ entries: [TimesheetRailEntry], within visible: DateInterval) -> [TimesheetRailPlacement] {
        let sorted = entries.compactMap { entry -> TimesheetRailEntry? in
            let start = max(entry.start, visible.start)
            let end = min(entry.end, visible.end)
            return end > start ? TimesheetRailEntry(id: entry.id, start: start, end: end) : nil
        }
        .sorted { lhs, rhs in
            if lhs.start != rhs.start { return lhs.start < rhs.start }
            return lhs.end > rhs.end
        }

        var clusters: [[TimesheetRailEntry]] = []
        var current: [TimesheetRailEntry] = []
        var clusterEnd = Date.distantPast
        for entry in sorted {
            if !current.isEmpty && entry.start >= clusterEnd {
                clusters.append(current)
                current = []
            }
            current.append(entry)
            clusterEnd = max(clusterEnd, entry.end)
        }
        if !current.isEmpty { clusters.append(current) }

        return clusters.flatMap { cluster -> [TimesheetRailPlacement] in
            var laneEnds: [Date] = []
            var assigned: [(TimesheetRailEntry, Int)] = []
            for entry in cluster {
                if let reusable = laneEnds.firstIndex(where: { $0 <= entry.start }) {
                    laneEnds[reusable] = entry.end
                    assigned.append((entry, reusable))
                } else {
                    assigned.append((entry, laneEnds.count))
                    laneEnds.append(entry.end)
                }
            }
            return assigned.map { entry, lane in
                TimesheetRailPlacement(id: entry.id, start: entry.start, end: entry.end,
                                       lane: lane, laneCount: laneEnds.count)
            }
        }
    }
}
