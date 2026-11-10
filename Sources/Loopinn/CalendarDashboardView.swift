import LoopinnCore
import SwiftUI

struct CalendarDashboardView: View {
    @ObservedObject var state: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scope: CalendarScope = .week
    @State private var selectedDate = Date()
    @State private var editingBlock: CalendarBlock?
    @State private var showingNewBlock = false
    @State private var proposedStart = Date()
    @State private var proposedEnd = Date().addingTimeInterval(3600)

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 7), count: 7)
    private var externalEvents: [ExternalCalendarEvent] { state.visibleCalendarEvents }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Picker("View", selection: $scope) {
                    ForEach(CalendarScope.allCases) { option in Text(option.rawValue.capitalized).tag(option) }
                }
                .pickerStyle(.segmented)
                .frame(width: 340)
                Spacer()
                Button("Previous", systemImage: "chevron.left") { shift(-1) }.labelStyle(.iconOnly)
                Button("Today") { select(.now) }
                Button("Next", systemImage: "chevron.right") { shift(1) }.labelStyle(.iconOnly)
                Button("New Block", systemImage: "plus") { prepareNew(on: selectedDate) }
                    .buttonStyle(.borderedProminent)
            }
            Text(heading).font(.title2.weight(.semibold))
            switch scope {
            case .day: dayContent
            case .week: weekContent
            case .month: monthContent
            case .year: yearContent
            }
        }
        .sheet(isPresented: $showingNewBlock) {
            BlockEditor(state: state, block: nil, start: proposedStart, end: proposedEnd)
        }
        .sheet(item: $editingBlock) { block in
            BlockEditor(state: state, block: block, start: block.startAt, end: block.endAt)
        }
        .onAppear { if state.appleCalendarConnected { state.refreshAppleCalendar(around: selectedDate) } }
        .onAppear { if state.googleCalendarConnected { state.refreshGoogleCalendar(around: selectedDate) } }
        .onChange(of: selectedDate) { _, date in
            if state.appleCalendarConnected { state.refreshAppleCalendar(around: date) }
            if state.googleCalendarConnected { state.refreshGoogleCalendar(around: date) }
        }
    }

    private var heading: String {
        let interval = CalendarLayout.interval(containing: selectedDate, scope: scope)
        switch scope {
        case .day: return selectedDate.formatted(date: .complete, time: .omitted)
        case .week: return "\(interval.start.formatted(.dateTime.month(.abbreviated).day())) – \(interval.end.addingTimeInterval(-1).formatted(.dateTime.month(.abbreviated).day()))"
        case .month: return selectedDate.formatted(.dateTime.month(.wide).year())
        case .year: return selectedDate.formatted(.dateTime.year())
        }
    }

    private var dayContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                let blocks = CalendarLayout.blocks(on: selectedDate, from: state.workspace.blocks)
                if blocks.isEmpty {
                    ContentUnavailableView("A clear day", systemImage: "calendar", description: Text("Drag on Week or add a block to make a plan."))
                }
                ForEach(blocks) { block in blockRow(block) }
                ForEach(events(on: selectedDate)) { event in
                    HStack {
                        Image(systemName: "calendar.badge.clock").foregroundStyle(.secondary)
                        VStack(alignment: .leading) {
                            Text(event.title).font(.headline)
                            Text("\(event.isHoliday ? "Holiday" : event.source) · \(event.isAllDay ? "All day" : event.startAt.formatted(date: .omitted, time: .shortened))")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(15).frame(maxWidth: .infinity, alignment: .leading)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    private var weekContent: some View {
        let start = CalendarLayout.interval(containing: selectedDate, scope: .week).start
        return ScrollView([.vertical, .horizontal]) {
            HStack(alignment: .top, spacing: 8) {
                ForEach(0..<7, id: \.self) { offset in
                    let day = calendar.date(byAdding: .day, value: offset, to: start)!
                    WeekDayColumn(day: day, blocks: CalendarLayout.blocks(on: day, from: state.workspace.blocks),
                                  events: events(on: day),
                                  title: title(for:), onBlock: { editingBlock = $0 },
                                  onMove: { block, dayShift, minutes in
                                      let shiftedStart = calendar.date(byAdding: .day, value: dayShift, to: block.startAt) ?? block.startAt
                                      let shiftedEnd = calendar.date(byAdding: .day, value: dayShift, to: block.endAt) ?? block.endAt
                                      state.updateBlock(block, title: title(for: block), start: shiftedStart.addingTimeInterval(Double(minutes * 60)), end: shiftedEnd.addingTimeInterval(Double(minutes * 60)))
                                  },
                                  onResize: { block, minutes in
                                      state.updateBlock(block, title: title(for: block), start: block.startAt, end: block.endAt.addingTimeInterval(Double(minutes * 60)))
                                  },
                                  onCreate: { proposedStart = $0; proposedEnd = $1; showingNewBlock = true })
                        .frame(minWidth: 140)
                }
            }
            .frame(minWidth: 1010)
        }
    }

    private var monthContent: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 7) {
                ForEach(CalendarLayout.gridDays(for: selectedDate), id: \.self) { day in
                    let blocks = CalendarLayout.blocks(on: day, from: state.workspace.blocks)
                    let events = events(on: day)
                    Button { select(day); scope = .day } label: {
                        VStack(alignment: .leading, spacing: 7) {
                            Text(day.formatted(.dateTime.day())).font(.subheadline.weight(calendar.isDateInToday(day) ? .bold : .medium))
                            ForEach(blocks.prefix(2)) { block in
                                Text(title(for: block)).font(.caption2).lineLimit(1)
                                    .padding(.horizontal, 6).padding(.vertical, 3)
                                    .background(state.settings.accent.color.opacity(0.15), in: Capsule())
                            }
                            if let event = events.first {
                                Text(event.title).font(.caption2).lineLimit(1)
                                    .padding(.horizontal, 6).padding(.vertical, 3)
                                    .background(.secondary.opacity(0.12), in: Capsule())
                            }
                            if blocks.count + events.count > 3 { Text("+\(blocks.count + events.count - 3) more").font(.caption2).foregroundStyle(.secondary) }
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity, minHeight: 95, alignment: .topLeading)
                        .padding(9)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 13))
                        .opacity(calendar.isDate(day, equalTo: selectedDate, toGranularity: .month) ? 1 : 0.55)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(day.formatted(date: .complete, time: .omitted)), \(blocks.count) blocks, \(events.count) external events")
                }
            }
        }
    }

    private var yearContent: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(1...12, id: \.self) { month in
                    let date = calendar.date(from: DateComponents(year: calendar.component(.year, from: selectedDate), month: month, day: 1))!
                    let interval = CalendarLayout.interval(containing: date, scope: .month)
                    let count = state.workspace.blocks.filter { $0.startAt < interval.end && $0.endAt > interval.start }.count
                    let externalCount = externalEvents.filter { $0.startAt < interval.end && $0.endAt > interval.start }.count
                    Button { select(date); scope = .month } label: {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(date.formatted(.dateTime.month(.wide))).font(.headline)
                            Text("\(count) blocks · \(externalCount) events").font(.subheadline).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
                        .padding(16)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func blockRow(_ block: CalendarBlock) -> some View {
        Button { editingBlock = block } label: {
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 3).fill(state.settings.accent.color).frame(width: 4)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title(for: block)).font(.headline)
                    Text("\(block.startAt.formatted(date: .omitted, time: .shortened)) – \(block.endAt.formatted(date: .omitted, time: .shortened))")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private func title(for block: CalendarBlock) -> String {
        block.title ?? state.workspace.tasks.first(where: { $0.id == block.taskID })?.title ?? "Untitled block"
    }

    private func events(on day: Date) -> [ExternalCalendarEvent] {
        let interval = CalendarLayout.interval(containing: day, scope: .day)
        return externalEvents.filter { $0.startAt < interval.end && $0.endAt > interval.start }
    }

    private func shift(_ amount: Int) { select(CalendarLayout.shifted(selectedDate, by: amount, scope: scope)) }
    private func select(_ date: Date) {
        if reduceMotion { selectedDate = date }
        else { withAnimation(.easeInOut(duration: 0.2)) { selectedDate = date } }
    }
    private func prepareNew(on date: Date) {
        proposedStart = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
        proposedEnd = proposedStart.addingTimeInterval(3600)
        showingNewBlock = true
    }
}

private struct WeekDayColumn: View {
    let day: Date
    let blocks: [CalendarBlock]
    let events: [ExternalCalendarEvent]
    let title: (CalendarBlock) -> String
    let onBlock: (CalendarBlock) -> Void
    let onMove: (CalendarBlock, Int, Int) -> Void
    let onResize: (CalendarBlock, Int) -> Void
    let onCreate: (Date, Date) -> Void
    @State private var dragStart: CGFloat?
    @State private var dragEnd: CGFloat?
    private let hourHeight: CGFloat = 48

    var body: some View {
        VStack(spacing: 0) {
            Text(day.formatted(.dateTime.weekday(.abbreviated).day()))
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity).padding(12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            VStack(spacing: 3) {
                ForEach(events.prefix(3)) { event in
                    Text(event.title).font(.caption2).lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(4)
                        .background(.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                        .accessibilityLabel("\(event.source): \(event.title)")
                }
            }
            .frame(height: 66, alignment: .top)
            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    ForEach(0..<24, id: \.self) { hour in
                        HStack(alignment: .top) {
                            Text(hour.formatted(.number.precision(.integerLength(2))) + ":00")
                                .font(.system(size: 10, design: .monospaced)).foregroundStyle(.tertiary)
                            Spacer()
                        }
                        .frame(height: hourHeight, alignment: .top)
                        .overlay(alignment: .bottom) { Divider().opacity(0.35) }
                    }
                }
                if let dragStart, let dragEnd {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.tint.opacity(0.24))
                        .frame(height: max(12, abs(dragEnd - dragStart)))
                        .offset(y: min(dragStart, dragEnd))
                        .allowsHitTesting(false)
                }
                ForEach(blocks) { block in
                    let dayStart = Calendar.current.startOfDay(for: day)
                    let top = max(0, block.startAt.timeIntervalSince(dayStart) / 3600 * hourHeight)
                    let bottom = min(24 * hourHeight, block.endAt.timeIntervalSince(dayStart) / 3600 * hourHeight)
                    let overlapping = blocks.filter { $0.startAt < block.endAt && $0.endAt > block.startAt }
                    let lane = overlapping.firstIndex(where: { $0.id == block.id }) ?? 0
                    let laneWidth = max(38, 130 / CGFloat(overlapping.count))
                    VStack(alignment: .leading, spacing: 2) {
                        Button { onBlock(block) } label: {
                            Text(title(block)).font(.caption).lineLimit(2)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        }
                        .buttonStyle(.plain)
                        .gesture(DragGesture(minimumDistance: 8).onEnded { value in
                            let dayShift = Int((value.translation.width / 148).rounded())
                            let minutes = Int((value.translation.height / hourHeight * 4).rounded()) * 15
                            if dayShift != 0 || minutes != 0 { onMove(block, dayShift, minutes) }
                        })
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 10)).frame(maxWidth: .infinity)
                            .accessibilityLabel("Resize \(title(block))")
                            .gesture(DragGesture(minimumDistance: 5).onEnded { value in
                                let minutes = Int((value.translation.height / hourHeight * 4).rounded()) * 15
                                if block.endAt.addingTimeInterval(Double(minutes * 60)) > block.startAt { onResize(block, minutes) }
                            })
                    }
                    .padding(6)
                    .background(.tint.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
                    .frame(width: laneWidth, height: max(18, bottom - top))
                    .offset(x: CGFloat(lane) * laneWidth, y: top)
                }
            }
            .frame(height: 24 * hourHeight)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 7)
                .onChanged { value in
                    if dragStart == nil { dragStart = value.startLocation.y }
                    dragEnd = value.location.y
                }
                .onEnded { value in
                    let first = min(dragStart ?? value.startLocation.y, value.location.y)
                    let last = max(dragStart ?? value.startLocation.y, value.location.y)
                    let startMinute = max(0, min(1425, Int(first / hourHeight * 4) * 15))
                    let endMinute = max(startMinute + 15, min(1440, Int(ceil(last / hourHeight * 4)) * 15))
                    let midnight = Calendar.current.startOfDay(for: day)
                    onCreate(midnight.addingTimeInterval(Double(startMinute * 60)), midnight.addingTimeInterval(Double(endMinute * 60)))
                    dragStart = nil; dragEnd = nil
                })
        }
        .background(.regularMaterial.opacity(0.55), in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct BlockEditor: View {
    @ObservedObject var state: AppState
    let block: CalendarBlock?
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var start: Date
    @State private var end: Date
    @State private var confirmDelete = false
    @State private var confirmPublish = false
    @State private var publishCalendarID = ""
    @State private var googlePublishCalendarID = ""
    @State private var confirmGooglePublish = false

    init(state: AppState, block: CalendarBlock?, start: Date, end: Date) {
        self.state = state
        self.block = block
        _title = State(initialValue: block?.title ?? "")
        _start = State(initialValue: start)
        _end = State(initialValue: end)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(block == nil ? "New time block" : "Edit time block").font(.title2.bold())
            if block?.taskID == nil {
                TextField("What are you planning?", text: $title)
                    .textFieldStyle(.roundedBorder)
            } else {
                Text(state.workspace.tasks.first(where: { $0.id == block?.taskID })?.title ?? "Task")
                    .font(.headline)
            }
            DatePicker("Starts", selection: $start)
            DatePicker("Ends", selection: $end)
            if overlapCount > 0 {
                Label("Overlaps \(overlapCount) planned block\(overlapCount == 1 ? "" : "s")", systemImage: "exclamationmark.triangle")
                    .font(.caption).foregroundStyle(.orange)
            }
            Text("This stays in Loopinn until you explicitly publish it to a calendar.")
                .font(.caption).foregroundStyle(.secondary)
            if block != nil, state.appleCalendarConnected, !state.appleCalendars.isEmpty {
                Picker("Publish to", selection: $publishCalendarID) {
                    ForEach(state.appleCalendars) { calendar in Text(calendar.title).tag(calendar.id) }
                }
                Button("Preview Apple Calendar Publish…") {
                    if publishCalendarID.isEmpty { publishCalendarID = state.appleCalendars[0].id }
                    confirmPublish = true
                }
            }
            if block != nil, state.googleCalendarConnected, !state.googleCalendars.isEmpty {
                Picker("Google calendar", selection: $googlePublishCalendarID) {
                    ForEach(state.googleCalendars) { calendar in Text(calendar.title).tag(calendar.id) }
                }
                Button("Preview Google Calendar Publish…") {
                    if googlePublishCalendarID.isEmpty { googlePublishCalendarID = state.googleCalendars[0].id }
                    confirmGooglePublish = true
                }
            }
            HStack {
                if block != nil { Button("Delete", role: .destructive) { confirmDelete = true } }
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") {
                    if let block { state.updateBlock(block, title: title, start: start, end: end) }
                    else { state.createBlock(title: title, start: start, end: end) }
                    if state.errorMessage == nil { dismiss() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(end <= start || (block?.taskID == nil && title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
            }
        }
        .padding(26).frame(width: 430)
        .background(.regularMaterial)
        .onAppear {
            publishCalendarID = state.appleCalendars.first?.id ?? ""
            googlePublishCalendarID = state.googleCalendars.first?.id ?? ""
        }
        .confirmationDialog("Publish this block to Apple Calendar?", isPresented: $confirmPublish) {
            Button("Publish Event") {
                if let block { state.publishAppleBlock(block, title: block.title ?? state.workspace.tasks.first(where: { $0.id == block.taskID })?.title ?? "Planned block", calendarID: publishCalendarID) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\(title.isEmpty ? "Task block" : title) · \(start.formatted(date: .abbreviated, time: .shortened)) – \(end.formatted(date: .abbreviated, time: .shortened)). Only this event will be written.")
        }
        .confirmationDialog("Publish this block to Google Calendar?", isPresented: $confirmGooglePublish) {
            Button("Publish Event") {
                if let block { state.publishGoogleBlock(block, title: block.title ?? state.workspace.tasks.first(where: { $0.id == block.taskID })?.title ?? "Planned block", calendarID: googlePublishCalendarID) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\(title.isEmpty ? "Task block" : title) · \(start.formatted(date: .abbreviated, time: .shortened)) – \(end.formatted(date: .abbreviated, time: .shortened)). Only this event will be written.")
        }
        .confirmationDialog("Delete this time block?", isPresented: $confirmDelete) {
            Button("Delete Block", role: .destructive) {
                if let block { state.deleteBlock(block); if state.errorMessage == nil { dismiss() } }
            }
        } message: {
            Text("Any event already published to Apple or Google Calendar remains there. Remove it in that calendar if needed.")
        }
    }

    private var overlapCount: Int {
        state.workspace.blocks.filter { $0.id != block?.id && $0.startAt < end && $0.endAt > start }.count
    }
}
