import EventKit
import Foundation
import LoopinnCore

struct ExternalCalendarEvent: Identifiable, Sendable {
    let id: String
    let title: String
    let startAt: Date
    let endAt: Date
    let source: String
    let isAllDay: Bool
    let calendarID: String
    let isHoliday: Bool
}

struct CalendarChoice: Identifiable, Sendable {
    let id: String
    let title: String
}

@MainActor
final class AppleCalendarService {
    private let store = EKEventStore()

    var isAuthorized: Bool { EKEventStore.authorizationStatus(for: .event) == .fullAccess }

    func requestAccess() async throws {
        guard try await store.requestFullAccessToEvents() else {
            throw CalendarIntegrationError.permissionDenied
        }
    }

    func calendars() -> [CalendarChoice] {
        guard isAuthorized else { return [] }
        return store.calendars(for: .event).map { CalendarChoice(id: $0.calendarIdentifier, title: $0.title) }
    }

    func events(from start: Date, to end: Date, calendarIDs: Set<String> = []) throws -> [ExternalCalendarEvent] {
        guard isAuthorized else { throw CalendarIntegrationError.permissionDenied }
        let calendars = store.calendars(for: .event).filter { calendarIDs.isEmpty || calendarIDs.contains($0.calendarIdentifier) }
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: calendars)
        return store.events(matching: predicate).map {
            ExternalCalendarEvent(id: $0.eventIdentifier, title: $0.title ?? "Untitled event", startAt: $0.startDate,
                                  endAt: $0.endDate, source: "Apple Calendar", isAllDay: $0.isAllDay,
                                  calendarID: $0.calendar.calendarIdentifier,
                                  isHoliday: $0.calendar.title.localizedCaseInsensitiveContains("holiday") || $0.calendar.calendarIdentifier.localizedCaseInsensitiveContains("holiday"))
        }
    }

    func publish(block: CalendarBlock, title: String, calendarID: String) throws -> ExternalCalendarLink {
        guard isAuthorized else { throw CalendarIntegrationError.permissionDenied }
        guard let calendar = store.calendar(withIdentifier: calendarID), calendar.allowsContentModifications else {
            throw CalendarIntegrationError.calendarUnavailable
        }
        let existing = block.externalLinks?.first { $0.provider == "apple" && $0.calendarID == calendarID }
        let event = existing.flatMap { store.event(withIdentifier: $0.eventID) } ?? EKEvent(eventStore: store)
        event.calendar = calendar
        event.title = title
        event.startDate = block.startAt
        event.endDate = block.endAt
        try store.save(event, span: .thisEvent, commit: true)
        guard let eventID = event.eventIdentifier else { throw CalendarIntegrationError.saveFailed }
        return ExternalCalendarLink(provider: "apple", calendarID: calendarID, eventID: eventID)
    }
}

enum CalendarIntegrationError: LocalizedError {
    case permissionDenied, calendarUnavailable, saveFailed
    var errorDescription: String? {
        switch self {
        case .permissionDenied: "Calendar access was not granted. Your local plan is unchanged."
        case .calendarUnavailable: "Choose an editable Apple calendar."
        case .saveFailed: "The event was not saved to Apple Calendar."
        }
    }
}
