import LoopinnCore
import SwiftUI

/// Adapted from Loopin-macOS/Views/Calendar/MonthCalendarGrid.swift.
/// Displays Loopinn blocks beside read-only Apple and Google events.
struct LoopinMonthCalendarGrid: View {
    let month: Date
    let selectedDay: Date
    let blocks: [CalendarBlock]
    let events: [ExternalCalendarEvent]
    let blockTitle: (CalendarBlock) -> String
    let onDay: (Date) -> Void
    let onAdd: (Date) -> Void
    let onAddRange: (Date, Date) -> Void
    let onBlock: (CalendarBlock) -> Void
    let onEvent: (ExternalCalendarEvent) -> Void
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    @State private var dragStart: Date?
    @State private var dragEnd: Date?

    private var days: [Date] {
        var result = CalendarLayout.gridDays(for: month)
        if result.count < 35, let last = result.last {
            result += (1...7).compactMap { calendar.date(byAdding: .day, value: $0, to: last) }
        }
        return result
    }

    var body: some View {
        ScrollView([.vertical, .horizontal]) {
            VStack(spacing: 0) {
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(0..<7, id: \.self) { index in
                        let symbol = calendar.shortStandaloneWeekdaySymbols[(index + calendar.firstWeekday - 1) % 7]
                        Text(symbol.uppercased()).font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 28, alignment: .trailing)
                            .padding(.trailing, 9)
                    }
                }
                .background(Color(nsColor: .controlBackgroundColor))
                GeometryReader { geometry in
                    LazyVGrid(columns: columns, spacing: 0) {
                        ForEach(days, id: \.self) { day in
                            dayCell(day)
                        }
                    }
                    .simultaneousGesture(DragGesture(minimumDistance: 8).onChanged { value in
                        dragStart = day(at: value.startLocation, width: geometry.size.width)
                        dragEnd = day(at: value.location, width: geometry.size.width)
                    }.onEnded { _ in
                        if let dragStart, let dragEnd { onAddRange(min(dragStart, dragEnd), max(dragStart, dragEnd)) }
                        dragStart = nil
                        dragEnd = nil
                    })
                }
                .frame(height: CGFloat(days.count / 7) * 132)
            }
            .frame(minWidth: 805)
            .background(Color(nsColor: .windowBackgroundColor))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.primary.opacity(0.13)))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let inMonth = calendar.isDate(day, equalTo: month, toGranularity: .month)
        let dayStart = calendar.startOfDay(for: day)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart.addingTimeInterval(86_400)
        let dayBlocks = blocks.filter { $0.startAt < dayEnd && $0.endAt > dayStart }
        let dayEvents = events.filter { $0.startAt < dayEnd && $0.endAt > dayStart }
        let items = (dayBlocks.map { MonthItem.block($0, blockTitle($0)) } + dayEvents.map { MonthItem.external($0) })
            .sorted { lhs, rhs in
                if lhs.isAllDay != rhs.isAllDay { return lhs.isAllDay }
                return lhs.start < rhs.start
            }
        let inDragRange = dragStart.map { start in
            let end = dragEnd ?? start
            return day >= min(start, end) && day <= max(start, end)
        } ?? false
        return MonthCell(day: day, inMonth: inMonth, isSelected: calendar.isDate(day, inSameDayAs: selectedDay),
                         inDragRange: inDragRange,
                         items: items, onDay: { onDay(day) }, onAdd: { onAdd(day) }, onItem: { item in
            switch item {
            case .block(let block, _): onBlock(block)
            case .external(let event): onEvent(event)
            }
        })
    }

    private func day(at point: CGPoint, width: CGFloat) -> Date? {
        guard point.x >= 0, point.y >= 0, width > 0 else { return nil }
        let column = min(6, Int(point.x / (width / 7)))
        let row = min(days.count / 7 - 1, Int(point.y / 132))
        return days[safe: row * 7 + column]
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}

private enum MonthItem: Identifiable {
    case block(CalendarBlock, String)
    case external(ExternalCalendarEvent)

    var id: String {
        switch self {
        case .block(let block, _): "block:\(block.id)"
        case .external(let event): "event:\(event.id)"
        }
    }
    var title: String {
        switch self {
        case .block(_, let title): title
        case .external(let event): event.title
        }
    }
    var start: Date {
        switch self {
        case .block(let block, _): block.startAt
        case .external(let event): event.startAt
        }
    }
    var isAllDay: Bool {
        if case .external(let event) = self { return event.isAllDay || event.isHoliday }
        return false
    }
    var color: Color {
        switch self {
        case .block: .blue
        case .external(let event): event.isHoliday ? .pink : (event.source.localizedCaseInsensitiveContains("Google") ? .orange : .green)
        }
    }
    var source: String {
        switch self {
        case .block: "Loopinn plan"
        case .external(let event): event.source
        }
    }
}

private struct MonthCell: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hovered = false
    let day: Date
    let inMonth: Bool
    let isSelected: Bool
    let inDragRange: Bool
    let items: [MonthItem]
    let onDay: () -> Void
    let onAdd: () -> Void
    let onItem: (MonthItem) -> Void
    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                if hovered {
                    Button(action: onAdd) {
                        Image(systemName: "plus.circle.fill").font(.system(size: 13)).foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain).help("Add a block on \(day.formatted(date: .abbreviated, time: .omitted))")
                }
                Spacer(minLength: 0)
                Button(action: onDay) {
                    Text(day.formatted(.dateTime.day()))
                        .font(.system(size: 12, weight: calendar.isDateInToday(day) ? .bold : .medium))
                        .foregroundStyle(calendar.isDateInToday(day) ? Color.white : Color.primary)
                        .frame(minWidth: 24, minHeight: 24)
                        .background(calendar.isDateInToday(day) ? Color.red : .clear, in: Circle())
                }
                .buttonStyle(.plain).help("Open day")
            }
            ForEach(items.prefix(4)) { item in
                Button { onItem(item) } label: {
                    HStack(spacing: 3) {
                        if !item.isAllDay {
                            Text(max(item.start, calendar.startOfDay(for: day)).formatted(date: .omitted, time: .shortened))
                                .font(.system(size: 8, weight: .medium)).lineLimit(1)
                        }
                        Text(item.title).font(.system(size: 9, weight: .semibold)).lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 4).frame(maxWidth: .infinity, minHeight: 19, alignment: .leading)
                    .foregroundStyle(item.isAllDay ? Color.white : Color.primary)
                    .background(item.isAllDay ? item.color : item.color.opacity(0.2), in: RoundedRectangle(cornerRadius: 4))
                    .overlay(alignment: .leading) {
                        if !item.isAllDay { RoundedRectangle(cornerRadius: 2).fill(item.color).frame(width: 3) }
                    }
                }
                .buttonStyle(.plain)
                .help("\(item.source): \(item.title)")
            }
            if items.count > 4 {
                Button("+\(items.count - 4) more", action: onDay)
                    .font(.system(size: 9, weight: .semibold)).buttonStyle(.plain).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(6)
        .frame(maxWidth: .infinity, minHeight: 132, maxHeight: 132, alignment: .topLeading)
        .background(inDragRange ? Color.accentColor.opacity(0.22) : (isSelected ? Color.accentColor.opacity(0.1) : (hovered ? Color.primary.opacity(0.06) : .clear)))
        .opacity(inMonth ? 1 : 0.48)
        .overlay(Rectangle().strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5))
        .onHover { value in withAnimation(reduceMotion ? nil : .easeOut(duration: 0.14)) { hovered = value } }
        .contextMenu {
            Button("Add time block", systemImage: "plus") { onAdd() }
            Button("Open day", systemImage: "calendar.day.timeline.left") { onDay() }
        }
        .accessibilityLabel("\(day.formatted(date: .complete, time: .omitted)), \(items.count) items")
    }
}
