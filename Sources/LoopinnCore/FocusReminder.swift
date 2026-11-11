import Foundation

public struct FocusReminder: Codable, Equatable, Sendable {
    public private(set) var isEnabled = false
    public private(set) var intervalMinutes = 30
    public private(set) var nextFireAt: Date?
    public private(set) var lastFiredAt: Date?

    public init() {}

    public mutating func setEnabled(_ enabled: Bool, at now: Date = .now) {
        guard enabled != isEnabled else { return }
        isEnabled = enabled
        nextFireAt = enabled ? now.addingTimeInterval(Double(intervalMinutes * 60)) : nil
    }

    public mutating func setInterval(minutes: Int, at now: Date = .now) {
        intervalMinutes = min(180, max(5, minutes))
        if isEnabled { nextFireAt = now.addingTimeInterval(Double(intervalMinutes * 60)) }
    }

    public mutating func snooze(minutes: Int = 10, at now: Date = .now) {
        guard isEnabled else { return }
        nextFireAt = now.addingTimeInterval(Double(min(60, max(1, minutes)) * 60))
    }

    @discardableResult
    public mutating func reconcile(at now: Date = .now) -> Bool {
        guard isEnabled else { return false }
        guard let nextFireAt else {
            self.nextFireAt = now.addingTimeInterval(Double(intervalMinutes * 60))
            return false
        }
        guard nextFireAt <= now else { return false }
        lastFiredAt = now
        // Missed intervals collapse to one reminder. A new interval starts from delivery.
        self.nextFireAt = now.addingTimeInterval(Double(intervalMinutes * 60))
        return true
    }
}

public final class FocusReminderStore {
    private let defaults: UserDefaults
    private let key = "loopinn.focus-reminder.v1"

    public init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    public func load() throws -> FocusReminder {
        guard let data = defaults.data(forKey: key) else { return FocusReminder() }
        return try JSONDecoder().decode(FocusReminder.self, from: data)
    }

    public func save(_ reminder: FocusReminder) throws {
        defaults.set(try JSONEncoder().encode(reminder), forKey: key)
    }
}
