import Foundation

public enum UtilityTimerStatus: String, Codable, Sendable {
    case idle, running, paused, completed
}

public struct StopwatchLap: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let elapsed: TimeInterval
    public let split: TimeInterval

    public init(id: UUID = UUID(), elapsed: TimeInterval, split: TimeInterval) {
        self.id = id
        self.elapsed = elapsed
        self.split = split
    }
}

public struct StopwatchSession: Codable, Equatable, Sendable {
    public private(set) var status: UtilityTimerStatus = .idle
    public private(set) var accumulated: TimeInterval = 0
    public private(set) var startedAt: Date?
    public private(set) var laps: [StopwatchLap] = []

    public init() {}

    public func elapsed(at now: Date = .now) -> TimeInterval {
        max(0, accumulated + (status == .running ? max(0, now.timeIntervalSince(startedAt ?? now)) : 0))
    }

    public mutating func start(at now: Date = .now) {
        guard status == .idle || status == .paused else { return }
        startedAt = now
        status = .running
    }

    public mutating func pause(at now: Date = .now) {
        guard status == .running else { return }
        accumulated = elapsed(at: now)
        startedAt = nil
        status = .paused
    }

    public mutating func addLap(at now: Date = .now) {
        guard status == .running else { return }
        let total = elapsed(at: now)
        let previous = laps.last?.elapsed ?? 0
        laps.append(StopwatchLap(elapsed: total, split: max(0, total - previous)))
    }

    public mutating func reset() { self = StopwatchSession() }
}

public struct CountdownSession: Codable, Equatable, Sendable {
    public private(set) var status: UtilityTimerStatus = .idle
    public private(set) var duration: TimeInterval = 10 * 60
    public private(set) var deadline: Date?
    public private(set) var pausedRemaining: TimeInterval?
    public private(set) var completedAt: Date?

    public init() {}

    public func remaining(at now: Date = .now) -> TimeInterval {
        switch status {
        case .idle: duration
        case .paused: max(0, pausedRemaining ?? 0)
        case .running: max(0, deadline?.timeIntervalSince(now) ?? 0)
        case .completed: 0
        }
    }

    public mutating func setDuration(minutes: Int) {
        guard status == .idle || status == .completed else { return }
        duration = Double(min(240, max(1, minutes)) * 60)
        if status == .completed { status = .idle; completedAt = nil }
    }

    public mutating func start(at now: Date = .now) {
        guard status == .idle || status == .paused else { return }
        deadline = now.addingTimeInterval(status == .paused ? (pausedRemaining ?? duration) : duration)
        pausedRemaining = nil
        completedAt = nil
        status = .running
    }

    public mutating func pause(at now: Date = .now) {
        guard status == .running else { return }
        pausedRemaining = remaining(at: now)
        deadline = nil
        status = .paused
    }

    @discardableResult
    public mutating func reconcile(at now: Date = .now) -> Bool {
        guard status == .running, remaining(at: now) == 0 else { return false }
        status = .completed
        completedAt = deadline
        deadline = nil
        pausedRemaining = nil
        return true
    }

    public mutating func reset() {
        let savedDuration = duration
        self = CountdownSession()
        duration = savedDuration
    }
}

public struct UtilityTimers: Codable, Equatable, Sendable {
    public var stopwatch = StopwatchSession()
    public var countdown = CountdownSession()

    public init() {}
}

public final class UtilityTimersStore {
    private let defaults: UserDefaults
    private let key = "loopinn.utility-timers.v1"

    public init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    public func load() throws -> UtilityTimers {
        guard let data = defaults.data(forKey: key) else { return UtilityTimers() }
        return try JSONDecoder().decode(UtilityTimers.self, from: data)
    }

    public func save(_ timers: UtilityTimers) throws {
        defaults.set(try JSONEncoder().encode(timers), forKey: key)
    }
}
