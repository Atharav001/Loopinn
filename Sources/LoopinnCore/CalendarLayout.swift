import Foundation

public enum CalendarScope: String, CaseIterable, Identifiable, Sendable {
    case day, week, month, year
    public var id: String { rawValue }
}

public enum CalendarLayout {
    public static func interval(containing date: Date, scope: CalendarScope, calendar: Calendar = .current) -> DateInterval {
        let component: Calendar.Component
        switch scope {
        case .day: component = .day
        case .week: component = .weekOfYear
        case .month: component = .month
        case .year: component = .year
        }
        return calendar.dateInterval(of: component, for: date)!
    }

    public static func gridDays(for date: Date, calendar: Calendar = .current) -> [Date] {
        let month = interval(containing: date, scope: .month, calendar: calendar)
        let weekday = calendar.component(.weekday, from: month.start)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        let start = calendar.date(byAdding: .day, value: -leading, to: month.start)!
        let dayCount = calendar.dateComponents([.day], from: month.start, to: month.end).day ?? 30
        let count = ((leading + dayCount + 6) / 7) * 7
        return (0..<count).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    public static func blocks(on day: Date, from blocks: [CalendarBlock], calendar: Calendar = .current) -> [CalendarBlock] {
        let interval = calendar.dateInterval(of: .day, for: day)!
        return blocks.filter { $0.startAt < interval.end && $0.endAt > interval.start }
            .sorted { $0.startAt < $1.startAt }
    }

    public static func shifted(_ date: Date, by amount: Int, scope: CalendarScope, calendar: Calendar = .current) -> Date {
        let component: Calendar.Component
        switch scope {
        case .day: component = .day
        case .week: component = .weekOfYear
        case .month: component = .month
        case .year: component = .year
        }
        return calendar.date(byAdding: component, value: amount, to: date) ?? date
    }
}
