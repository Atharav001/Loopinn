import Foundation

public enum ThemeMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case system, light, dark
    public var id: String { rawValue }
}

public enum AccentChoice: String, Codable, CaseIterable, Identifiable, Sendable {
    case blue, indigo, teal, orange
    public var id: String { rawValue }
}

public struct AppSettings: Codable, Equatable, Sendable {
    public var version: Int
    public var theme: ThemeMode
    public var accent: AccentChoice
    public var hasCompletedOnboarding: Bool?
    public var compactLayout: Bool?
    public var showTodayPlan: Bool?
    public var pinFloatingTasks: Bool?
    public var showDockIcon: Bool?
    public var showAppleEvents: Bool?
    public var hiddenAppleCalendarIDs: [String]?
    public var googleClientID: String?
    public var hiddenGoogleCalendarIDs: [String]?
    public var playAlertSound: Bool?

    public init(theme: ThemeMode = .system, accent: AccentChoice = .blue) {
        version = 1
        self.theme = theme
        self.accent = accent
        hasCompletedOnboarding = false
        compactLayout = false
        showTodayPlan = true
        pinFloatingTasks = true
        showDockIcon = false
        showAppleEvents = true
        hiddenAppleCalendarIDs = []
        googleClientID = nil
        hiddenGoogleCalendarIDs = []
        playAlertSound = true
    }
}

public final class SettingsStore {
    private let defaults: UserDefaults
    private let key = "loopinn.settings.v1"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() throws -> AppSettings {
        guard let data = defaults.data(forKey: key) else { return AppSettings() }
        let settings = try JSONDecoder().decode(AppSettings.self, from: data)
        guard settings.version == 1 else { throw SettingsError.unsupportedVersion }
        return settings
    }

    public func save(_ settings: AppSettings) throws {
        guard settings.version == 1 else { throw SettingsError.unsupportedVersion }
        defaults.set(try JSONEncoder().encode(settings), forKey: key)
    }
}

public enum SettingsError: LocalizedError {
    case unsupportedVersion

    public var errorDescription: String? {
        "These settings were saved by a newer version of Loopinn."
    }
}
