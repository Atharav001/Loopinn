import Foundation

public enum PomodoroPhase: String, Codable, Sendable { case focus, breakTime }
public enum PomodoroStatus: String, Codable, Sendable { case idle, running, paused, completed }
public enum PomodoroMode: String, Codable, Sendable { case pomodoro, deepWork }

public struct FocusRecord: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let startAt: Date
    public let endAt: Date
    public let activeSeconds: TimeInterval
    public let mode: PomodoroMode
    public let taskID: UUID?
    public init(id: UUID = UUID(), startAt: Date, endAt: Date, activeSeconds: TimeInterval, mode: PomodoroMode, taskID: UUID?) {
        self.id = id; self.startAt = startAt; self.endAt = endAt; self.activeSeconds = activeSeconds; self.mode = mode; self.taskID = taskID
    }
}

public struct PomodoroSession: Codable, Equatable, Sendable {
    public var phase: PomodoroPhase = .focus
    public var status: PomodoroStatus = .idle
    public var focusMinutes: Int = 25
    public var breakMinutes: Int = 5
    public var longBreakMinutes: Int = 15
    public var cyclesBeforeLongBreak: Int = 4
    public var autoAdvance: Bool = true
    public var completedCycles: Int = 0
    public var deadline: Date?
    public var pausedRemaining: TimeInterval?
    public var mode: PomodoroMode = .pomodoro
    public var linkedTaskID: UUID?
    public var deepWorkMinutes: Int = 90
    public var completedAt: Date?
    public var focusHistory: [FocusRecord] = []
    public var focusStartedAt: Date?
    public var activeSegmentStartedAt: Date?
    public var accumulatedFocusSeconds: TimeInterval = 0

    public init() {}

    private enum CodingKeys: String, CodingKey {
        case phase, status, focusMinutes, breakMinutes, longBreakMinutes, cyclesBeforeLongBreak, autoAdvance, completedCycles, deadline, pausedRemaining
        case mode, linkedTaskID, deepWorkMinutes, completedAt, focusHistory, focusStartedAt, activeSegmentStartedAt, accumulatedFocusSeconds
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        phase = try container.decode(PomodoroPhase.self, forKey: .phase)
        status = try container.decode(PomodoroStatus.self, forKey: .status)
        focusMinutes = try container.decode(Int.self, forKey: .focusMinutes)
        breakMinutes = try container.decode(Int.self, forKey: .breakMinutes)
        longBreakMinutes = try container.decodeIfPresent(Int.self, forKey: .longBreakMinutes) ?? 15
        cyclesBeforeLongBreak = try container.decodeIfPresent(Int.self, forKey: .cyclesBeforeLongBreak) ?? 4
        autoAdvance = try container.decodeIfPresent(Bool.self, forKey: .autoAdvance) ?? true
        completedCycles = try container.decode(Int.self, forKey: .completedCycles)
        deadline = try container.decodeIfPresent(Date.self, forKey: .deadline)
        pausedRemaining = try container.decodeIfPresent(TimeInterval.self, forKey: .pausedRemaining)
        mode = try container.decodeIfPresent(PomodoroMode.self, forKey: .mode) ?? .pomodoro
        linkedTaskID = try container.decodeIfPresent(UUID.self, forKey: .linkedTaskID)
        deepWorkMinutes = try container.decodeIfPresent(Int.self, forKey: .deepWorkMinutes) ?? 90
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        focusHistory = try container.decodeIfPresent([FocusRecord].self, forKey: .focusHistory) ?? []
        focusStartedAt = try container.decodeIfPresent(Date.self, forKey: .focusStartedAt)
        activeSegmentStartedAt = try container.decodeIfPresent(Date.self, forKey: .activeSegmentStartedAt)
        accumulatedFocusSeconds = try container.decodeIfPresent(TimeInterval.self, forKey: .accumulatedFocusSeconds) ?? 0
    }

    public func remaining(at now: Date = .now) -> TimeInterval {
        switch status {
        case .idle: Double(phaseMinutes * 60)
        case .paused: max(0, pausedRemaining ?? 0)
        case .running: max(0, deadline?.timeIntervalSince(now) ?? 0)
        case .completed: 0
        }
    }

    public mutating func start(at now: Date = .now) {
        guard status == .idle || status == .paused else { return }
        if phase == .focus {
            if status == .idle { focusStartedAt = now; accumulatedFocusSeconds = 0 }
            activeSegmentStartedAt = now
        }
        deadline = now.addingTimeInterval(status == .paused ? (pausedRemaining ?? 0) : remaining(at: now))
        pausedRemaining = nil
        status = .running
    }

    public mutating func pause(at now: Date = .now) {
        guard status == .running else { return }
        if phase == .focus, let activeSegmentStartedAt {
            accumulatedFocusSeconds += max(0, now.timeIntervalSince(activeSegmentStartedAt))
            self.activeSegmentStartedAt = nil
        }
        pausedRemaining = remaining(at: now)
        deadline = nil
        status = .paused
    }

    public mutating func reset() {
        let history = focusHistory
        let settings = (focusMinutes, breakMinutes, longBreakMinutes, cyclesBeforeLongBreak, autoAdvance)
        self = PomodoroSession()
        focusHistory = history
        (focusMinutes, breakMinutes, longBreakMinutes, cyclesBeforeLongBreak, autoAdvance) = settings
    }

    public mutating func configure(focus: Int, shortBreak: Int, longBreak: Int, longBreakEvery: Int, autoAdvance: Bool) {
        guard status == .idle || status == .completed else { return }
        focusMinutes = min(180, max(1, focus))
        breakMinutes = min(60, max(1, shortBreak))
        longBreakMinutes = min(120, max(1, longBreak))
        cyclesBeforeLongBreak = min(12, max(2, longBreakEvery))
        self.autoAdvance = autoAdvance
    }

    public mutating func startDeepWork(minutes: Int, taskID: UUID?, at now: Date = .now) {
        guard status == .idle || status == .completed else { return }
        let history = focusHistory
        self = PomodoroSession()
        focusHistory = history
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
                recordFocus(endingAt: next)
                completedAt = next
                deadline = nil
                status = .completed
            }
            return
        }
        var transitions = 0
        while next <= now && transitions < 1000 {
            if phase == .focus {
                recordFocus(endingAt: next)
                completedCycles += 1
                phase = .breakTime
            } else {
                phase = .focus
                focusStartedAt = next
                activeSegmentStartedAt = next
                accumulatedFocusSeconds = 0
            }
            if !autoAdvance {
                status = .idle
                deadline = nil
                return
            }
            next = next.addingTimeInterval(Double(phaseMinutes * 60))
            transitions += 1
        }
        if transitions == 1000 { next = now.addingTimeInterval(Double(phaseMinutes * 60)) }
        deadline = next
    }

    private var phaseMinutes: Int {
        if phase == .focus { return focusMinutes }
        return completedCycles > 0 && completedCycles % max(2, cyclesBeforeLongBreak) == 0 ? longBreakMinutes : breakMinutes
    }

    private mutating func recordFocus(endingAt end: Date) {
        let start = focusStartedAt ?? end.addingTimeInterval(-Double(focusMinutes * 60))
        let active = accumulatedFocusSeconds + max(0, end.timeIntervalSince(activeSegmentStartedAt ?? end))
        focusHistory.append(FocusRecord(startAt: start, endAt: end, activeSeconds: min(Double(focusMinutes * 60), max(0, active)), mode: mode, taskID: linkedTaskID))
        focusStartedAt = nil
        activeSegmentStartedAt = nil
        accumulatedFocusSeconds = 0
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
