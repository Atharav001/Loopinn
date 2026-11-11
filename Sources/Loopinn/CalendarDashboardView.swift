import LoopinnCore
import SwiftUI

struct CalendarDashboardView: View {
    @ObservedObject var state: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scope: CalendarScope = .month
    @State private var selectedDate = Date()
    @State private var editingBlock: CalendarBlock?
    @State private var selectedExternalEvent: ExternalCalendarEvent?
    @State private var showingNewBlock = false
    @State private var proposedStart = Date()
    @State private var proposedEnd = Date().addingTimeInterval(3600)

    private let calendar = Calendar.current
    private var externalEvents: [ExternalCalendarEvent] { state.visibleCalendarEvents }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Button("New Event", systemImage: "plus") { prepareNew(on: selectedDate) }
                    .buttonStyle(.borderedProminent)
                Picker("View", selection: $scope) {
                    ForEach(CalendarScope.allCases) { option in Text(option.rawValue.capitalized).tag(option) }
                }
                .pickerStyle(.segmented)
                .frame(width: 340)
                Spacer()
                Menu {
                    if state.appleCalendarConnected {
                        Button("Refresh Apple Calendar", systemImage: "arrow.clockwise") { state.refreshAppleCalendar(around: selectedDate, force: true) }
                    } else {
                        Button("Connect Apple Calendar", systemImage: "calendar.badge.plus") { state.connectAppleCalendar() }
                    }
                    if state.googleCalendarConnected {
                        Button("Refresh Google Calendar", systemImage: "arrow.clockwise") { state.refreshGoogleCalendar(around: selectedDate, force: true) }
                    } else {
                        Button("Set Up Google Calendar", systemImage: "gearshape") { state.selectedPage = .settings }
                    }
                    Button("Calendar Settings", systemImage: "slider.horizontal.3") { state.selectedPage = .settings }
                } label: { Label("Calendars", systemImage: "calendar.badge.clock") }
                Button("Previous", systemImage: "chevron.left") { shift(-1) }.labelStyle(.iconOnly)
                Button("Today") { select(.now) }
                Button("Next", systemImage: "chevron.right") { shift(1) }.labelStyle(.iconOnly)
            }
            .padding(10)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
            Text(heading).font(.title2.weight(.semibold)).padding(.leading, 4)
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
        .sheet(item: $selectedExternalEvent) { event in
            VStack(alignment: .leading, spacing: 14) {
                Label(event.isHoliday ? "Holiday" : event.source, systemImage: "calendar.badge.clock")
                    .font(.caption).foregroundStyle(.secondary)
                Text(event.title).font(.title2.bold())
                Text(event.isAllDay ? "All day" : "\(event.startAt.formatted(date: .abbreviated, time: .shortened)) – \(event.endAt.formatted(date: .abbreviated, time: .shortened))")
                Text("This event is shown from your connected calendar. Edit it in its original calendar.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(24).frame(minWidth: 360)
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
            dayColumn(selectedDate).frame(maxWidth: .infinity)
        }
    }

    private var weekContent: some View {
        let start = CalendarLayout.interval(containing: selectedDate, scope: .week).start
        return ScrollView([.vertical, .horizontal]) {
            HStack(alignment: .top, spacing: 8) {
                ForEach(0..<7, id: \.self) { offset in
                    let day = calendar.date(byAdding: .day, value: offset, to: start)!
                    dayColumn(day)
                        .frame(minWidth: 140)
                }
            }
            .frame(minWidth: 1010)
        }
    }

    private var monthContent: some View {
        LoopinMonthCalendarGrid(month: selectedDate, selectedDay: selectedDate,
                                blocks: state.workspace.blocks, events: externalEvents,
                                blockTitle: title(for:),
                                onDay: { select($0); scope = .day },
                                onAdd: prepareNew(on:),
                                onBlock: { editingBlock = $0 },
                                onEvent: { selectedExternalEvent = $0 })
    }

    private var yearContent: some View {
        LoopinYearCalendarGrid(year: calendar.component(.year, from: selectedDate),
                               blocks: state.workspace.blocks, events: externalEvents,
                               onMonth: { select($0); scope = .month },
                               onDay: { select($0); scope = .day })
    }

    private func dayColumn(_ day: Date) -> some View {
        WeekDayColumn(day: day, blocks: CalendarLayout.blocks(on: day, from: state.workspace.blocks),
                      events: events(on: day), title: title(for:),
                      onBlock: { editingBlock = $0 },
                      onEvent: { selectedExternalEvent = $0 },
                      onMove: { block, dayShift, minutes in
                          let shiftedStart = calendar.date(byAdding: .day, value: dayShift, to: block.startAt) ?? block.startAt
                          let shiftedEnd = calendar.date(byAdding: .day, value: dayShift, to: block.endAt) ?? block.endAt
                          state.updateBlock(block, title: title(for: block), start: shiftedStart.addingTimeInterval(Double(minutes * 60)), end: shiftedEnd.addingTimeInterval(Double(minutes * 60)))
                      },
                      onResize: { block, minutes in
                          state.updateBlock(block, title: title(for: block), start: block.startAt, end: block.endAt.addingTimeInterval(Double(minutes * 60)))
                      },
                      onCreate: { proposedStart = $0; proposedEnd = $1; showingNewBlock = true })
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
    let onEvent: (ExternalCalendarEvent) -> Void
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
                ForEach(events.filter { $0.isAllDay || $0.isHoliday }.prefix(3)) { event in
                    Button { onEvent(event) } label: {
                        Text(event.title).font(.caption2).lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(4)
                            .background(.pink.opacity(0.2), in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
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
                ForEach(events.filter { !$0.isAllDay && !$0.isHoliday }) { event in
                    let dayStart = Calendar.current.startOfDay(for: day)
                    let top = max(0, event.startAt.timeIntervalSince(dayStart) / 3600 * hourHeight)
                    let bottom = min(24 * hourHeight, event.endAt.timeIntervalSince(dayStart) / 3600 * hourHeight)
                    Button { onEvent(event) } label: {
                        Text("\(event.startAt.formatted(date: .omitted, time: .shortened)) \(event.title)")
                            .font(.caption2).lineLimit(2)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }
                    .buttonStyle(.plain)
                    .padding(5)
                    .background((event.source.localizedCaseInsensitiveContains("Google") ? Color.orange : Color.green).opacity(0.3), in: RoundedRectangle(cornerRadius: 7))
                    .frame(maxWidth: .infinity)
                    .frame(height: max(20, bottom - top))
                    .offset(y: top)
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
    @State private var linkToRemove: ExternalCalendarLink?
    @State private var confirmUnpublish = false

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
            if hasUnsavedChanges {
                Text("Save your edits before publishing the updated event.")
                    .font(.caption).foregroundStyle(.orange)
            }
            if block != nil, state.appleCalendarConnected, !writableAppleCalendars.isEmpty {
                Picker("Publish to", selection: $publishCalendarID) {
                    ForEach(writableAppleCalendars) { calendar in Text(calendar.title).tag(calendar.id) }
                }
                Button("Preview Apple Calendar Publish…") {
                    if publishCalendarID.isEmpty { publishCalendarID = writableAppleCalendars[0].id }
                    confirmPublish = true
                }
                .disabled(hasUnsavedChanges)
            }
            if block != nil, state.googleCalendarConnected, !writableGoogleCalendars.isEmpty {
                Picker("Google calendar", selection: $googlePublishCalendarID) {
                    ForEach(writableGoogleCalendars) { calendar in Text(calendar.title).tag(calendar.id) }
                }
                Button("Preview Google Calendar Publish…") {
                    if googlePublishCalendarID.isEmpty { googlePublishCalendarID = writableGoogleCalendars[0].id }
                    confirmGooglePublish = true
                }
                .disabled(hasUnsavedChanges)
            }
            ForEach(currentLinks) { link in
                HStack {
                    Label("Published to \(link.provider.capitalized)", systemImage: "checkmark.circle")
                        .font(.caption)
                    Spacer()
                    Button("Remove Event…", role: .destructive) {
                        linkToRemove = link
                        confirmUnpublish = true
                    }
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
            publishCalendarID = writableAppleCalendars.first?.id ?? ""
            googlePublishCalendarID = writableGoogleCalendars.first?.id ?? ""
        }
        .confirmationDialog("Publish this block to Apple Calendar?", isPresented: $confirmPublish) {
            Button("Publish Event") {
                if let block = currentBlock { state.publishAppleBlock(block, title: blockTitle, calendarID: publishCalendarID) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(publicationPreview)
        }
        .confirmationDialog("Publish this block to Google Calendar?", isPresented: $confirmGooglePublish) {
            Button("Publish Event") {
                if let block = currentBlock { state.publishGoogleBlock(block, title: blockTitle, calendarID: googlePublishCalendarID) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(publicationPreview)
        }
        .confirmationDialog("Delete this time block?", isPresented: $confirmDelete) {
            Button("Delete Block", role: .destructive) {
                if let block { state.deleteBlock(block); if state.errorMessage == nil { dismiss() } }
            }
        } message: {
            Text("Any event already published to Apple or Google Calendar remains there. Remove it in that calendar if needed.")
        }
        .confirmationDialog("Remove the published event?", isPresented: $confirmUnpublish) {
            Button("Remove From Calendar", role: .destructive) {
                if let block, let linkToRemove {
                    if linkToRemove.provider == "apple" { state.unpublishAppleBlock(block, link: linkToRemove) }
                    if linkToRemove.provider == "google" { state.unpublishGoogleBlock(block, link: linkToRemove) }
                }
                linkToRemove = nil
            }
            Button("Cancel", role: .cancel) { linkToRemove = nil }
        } message: {
            Text("This removes the event from \(linkToRemove?.provider.capitalized ?? "the provider") Calendar. Your Loopinn block stays here.")
        }
    }

    private var overlapCount: Int {
        state.workspace.blocks.filter { $0.id != block?.id && $0.startAt < end && $0.endAt > start }.count
    }

    private var currentLinks: [ExternalCalendarLink] {
        guard let block else { return [] }
        return state.workspace.blocks.first(where: { $0.id == block.id })?.externalLinks ?? []
    }

    private var currentBlock: CalendarBlock? {
        guard let block else { return nil }
        return state.workspace.blocks.first(where: { $0.id == block.id })
    }

    private var hasUnsavedChanges: Bool {
        guard let currentBlock else { return false }
        return start != currentBlock.startAt || end != currentBlock.endAt || (currentBlock.taskID == nil && title != (currentBlock.title ?? ""))
    }

    private var blockTitle: String {
        guard let currentBlock else { return "Planned block" }
        return currentBlock.title ?? state.workspace.tasks.first(where: { $0.id == currentBlock.taskID })?.title ?? "Planned block"
    }

    private var publicationPreview: String {
        guard let currentBlock else { return "No block selected." }
        return "\(blockTitle) · \(currentBlock.startAt.formatted(date: .abbreviated, time: .shortened)) – \(currentBlock.endAt.formatted(date: .abbreviated, time: .shortened)). Only this event will be written."
    }

    private var writableAppleCalendars: [CalendarChoice] { state.appleCalendars.filter(\.canWrite) }
    private var writableGoogleCalendars: [CalendarChoice] { state.googleCalendars.filter(\.canWrite) }
}
