import Foundation

public enum PomodoroPhase: String, Codable, Sendable { case focus, breakTime }
public enum PomodoroStatus: String, Codable, Sendable { case idle, running, paused, completed }
public enum PomodoroMode: String, Codable, Sendable { case pomodoro, deepWork }

public struct PomodoroSession: Codable, Equatable, Sendable {
    public var phase: PomodoroPhase = .focus
    public var status: PomodoroStatus = .idle
    public var focusMinutes: Int = 25
    public var breakMinutes: Int = 5
    public var completedCycles: Int = 0
    public var deadline: Date?
    public var pausedRemaining: TimeInterval?
    public var mode: PomodoroMode = .pomodoro
    public var linkedTaskID: UUID?
    public var deepWorkMinutes: Int = 90
    public var completedAt: Date?

    public init() {}

    private enum CodingKeys: String, CodingKey {
        case phase, status, focusMinutes, breakMinutes, completedCycles, deadline, pausedRemaining
        case mode, linkedTaskID, deepWorkMinutes, completedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        phase = try container.decode(PomodoroPhase.self, forKey: .phase)
        status = try container.decode(PomodoroStatus.self, forKey: .status)
        focusMinutes = try container.decode(Int.self, forKey: .focusMinutes)
        breakMinutes = try container.decode(Int.self, forKey: .breakMinutes)
        completedCycles = try container.decode(Int.self, forKey: .completedCycles)
        deadline = try container.decodeIfPresent(Date.self, forKey: .deadline)
        pausedRemaining = try container.decodeIfPresent(TimeInterval.self, forKey: .pausedRemaining)
        mode = try container.decodeIfPresent(PomodoroMode.self, forKey: .mode) ?? .pomodoro
        linkedTaskID = try container.decodeIfPresent(UUID.self, forKey: .linkedTaskID)
        deepWorkMinutes = try container.decodeIfPresent(Int.self, forKey: .deepWorkMinutes) ?? 90
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
    }

    public func remaining(at now: Date = .now) -> TimeInterval {
        switch status {
        case .idle: Double((phase == .focus ? focusMinutes : breakMinutes) * 60)
        case .paused: max(0, pausedRemaining ?? 0)
        case .running: max(0, deadline?.timeIntervalSince(now) ?? 0)
        case .completed: 0
        }
    }

    public mutating func start(at now: Date = .now) {
        guard status == .idle || status == .paused else { return }
        deadline = now.addingTimeInterval(status == .paused ? (pausedRemaining ?? 0) : remaining(at: now))
        pausedRemaining = nil
        status = .running
    }

    public mutating func pause(at now: Date = .now) {
        guard status == .running else { return }
        pausedRemaining = remaining(at: now)
        deadline = nil
        status = .paused
    }

    public mutating func reset() { self = PomodoroSession() }

    public mutating func startDeepWork(minutes: Int, taskID: UUID?, at now: Date = .now) {
        guard status == .idle || status == .completed else { return }
        self = PomodoroSession()
        mode = .deepWork
        deepWorkMinutes = min(240, max(30, minutes))
        focusMinutes = deepWorkMinutes
        linkedTaskID = taskID
        start(at: now)
    }

    public mutating func reconcile(at now: Date = .now) {
        guard status == .running, var next = deadline else { return }
        if mode == .deepWork {
            if next <= now {
                completedAt = next
                deadline = nil
                status = .completed
            }
            return
        }
        var transitions = 0
        while next <= now && transitions < 1000 {
            if phase == .focus { completedCycles += 1; phase = .breakTime }
            else { phase = .focus }
            next = next.addingTimeInterval(Double((phase == .focus ? focusMinutes : breakMinutes) * 60))
            transitions += 1
        }
        if transitions == 1000 { next = now.addingTimeInterval(Double((phase == .focus ? focusMinutes : breakMinutes) * 60)) }
        deadline = next
    }
}

public final class PomodoroStore {
    private let defaults: UserDefaults
    private let key = "loopinn.pomodoro.v1"
    public init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    public func load() throws -> PomodoroSession {
        guard let data = defaults.data(forKey: key) else { return PomodoroSession() }
        return try JSONDecoder().decode(PomodoroSession.self, from: data)
    }
    public func save(_ session: PomodoroSession) throws {
        defaults.set(try JSONEncoder().encode(session), forKey: key)
    }
}
