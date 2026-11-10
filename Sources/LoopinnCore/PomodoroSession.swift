import Foundation

public enum PomodoroPhase: String, Codable, Sendable { case focus, breakTime }
public enum PomodoroStatus: String, Codable, Sendable { case idle, running, paused }

public struct PomodoroSession: Codable, Equatable, Sendable {
    public var phase: PomodoroPhase = .focus
    public var status: PomodoroStatus = .idle
    public var focusMinutes: Int = 25
    public var breakMinutes: Int = 5
    public var completedCycles: Int = 0
    public var deadline: Date?
    public var pausedRemaining: TimeInterval?

    public init() {}

    public func remaining(at now: Date = .now) -> TimeInterval {
        switch status {
        case .idle: Double((phase == .focus ? focusMinutes : breakMinutes) * 60)
        case .paused: max(0, pausedRemaining ?? 0)
        case .running: max(0, deadline?.timeIntervalSince(now) ?? 0)
        }
    }

    public mutating func start(at now: Date = .now) {
        guard status != .running else { return }
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

    public mutating func reconcile(at now: Date = .now) {
        guard status == .running, var next = deadline else { return }
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
