import LoopinnCore
import SwiftUI

/// Adapted from Loopin-macOS/Views/Calendar/YearCalendarGrid.swift.
/// Month and day selection use Loopinn's calendar state and saved blocks.
struct LoopinYearCalendarGrid: View {
    let year: Int
    let blocks: [CalendarBlock]
    let events: [ExternalCalendarEvent]
    let onMonth: (Date) -> Void
    let onDay: (Date) -> Void

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 155), spacing: 14)], spacing: 14) {
                ForEach(1...12, id: \.self) { month in
                    LoopinYearMonthCard(year: year, month: month, blocks: blocks, events: events,
                                        onMonth: onMonth, onDay: onDay)
                }
            }
            .padding(14)
        }
    }
}

private struct LoopinYearMonthCard: View {
    let year: Int
    let month: Int
    let blocks: [CalendarBlock]
    let events: [ExternalCalendarEvent]
    let onMonth: (Date) -> Void
    let onDay: (Date) -> Void
    private let calendar = Calendar.current

    private var monthDate: Date {
        calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? .now
    }

    private var days: [Date] { CalendarLayout.gridDays(for: monthDate) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button { onMonth(monthDate) } label: {
                HStack {
                    Text(monthDate.formatted(.dateTime.month(.wide))).font(.system(size: 13, weight: .bold, design: .rounded))
                    Spacer()
                    Image(systemName: "arrow.up.forward.app").font(.caption2).foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 1), count: 7), spacing: 3) {
                ForEach(0..<7, id: \.self) { index in
                    Text(calendar.veryShortStandaloneWeekdaySymbols[(index + calendar.firstWeekday - 1) % 7])
                        .font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary)
                }
                ForEach(days, id: \.self) { day in
                    let inMonth = calendar.isDate(day, equalTo: monthDate, toGranularity: .month)
                    let hasEntry = blocks.contains { $0.startAt < dayEnd(day) && $0.endAt > calendar.startOfDay(for: day) }
                        || events.contains { $0.startAt < dayEnd(day) && $0.endAt > calendar.startOfDay(for: day) }
                    Button { onDay(day) } label: {
                        VStack(spacing: 1) {
                            Text("\(calendar.component(.day, from: day))")
                                .font(.system(size: 10, weight: calendar.isDateInToday(day) ? .bold : .regular))
                                .frame(maxWidth: .infinity, minHeight: 18)
                                .background(calendar.isDateInToday(day) ? Color.accentColor.opacity(0.22) : .clear, in: Circle())
                            Circle().fill(hasEntry && inMonth ? Color.accentColor : .clear).frame(width: 3, height: 3)
                        }
                        .opacity(inMonth ? 1 : 0.25)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(day.formatted(date: .complete, time: .omitted))
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 170, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func dayEnd(_ day: Date) -> Date {
        calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: day)) ?? day.addingTimeInterval(86400)
    }
}
