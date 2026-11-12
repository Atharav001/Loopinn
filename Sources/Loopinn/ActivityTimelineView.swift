import LoopinnCore
import SwiftUI

struct ActivityTimelineView: View {
    @ObservedObject var state: AppState
    @State private var day = Date()
    @State private var editingBlock: CalendarBlock?
    @State private var editingEntry: ActivityEntry?

    private var planned: [CalendarBlock] { CalendarLayout.blocks(on: day, from: state.workspace.blocks) }
    private var logged: [ActivityEntry] {
        state.activityLogbook.entries.filter { $0.startAt < dayEnd && $0.endAt > dayStart }
    }
    private var dayStart: Date { Calendar.current.startOfDay(for: day) }
    private var dayEnd: Date { Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart.addingTimeInterval(86400) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("Planned and logged").font(.title2.bold())
                    Spacer()
                    DatePicker("Day", selection: $day, displayedComponents: .date).labelsHidden()
                }
                Text("A plan never becomes an activity log automatically.").foregroundStyle(.secondary)
                LoopinTimesheetRails(day: day, planned: planned, logged: logged,
                                    title: { block in block.title ?? state.workspace.tasks.first(where: { $0.id == block.taskID })?.title ?? "Planned block" },
                                    onSelectPlanned: { id in editingBlock = planned.first(where: { $0.id == id }) },
                                    onSelectLogged: { id in editingEntry = logged.first(where: { $0.id == id }) })
                HStack(alignment: .top, spacing: 14) {
                    rail("Planned", icon: "calendar", isEmpty: planned.isEmpty) {
                        ForEach(planned) { block in
                            row(title: block.title ?? "Planned block", start: block.startAt, end: block.endAt)
                        }
                    }
                    rail("Logged", icon: "text.book.closed", isEmpty: logged.isEmpty) {
                        ForEach(logged) { entry in
                            row(title: entry.title, start: entry.startAt, end: entry.endAt)
                        }
                    }
                }
            }
        }
        .sheet(item: $editingBlock) { block in
            BlockEditor(state: state, block: block, start: block.startAt, end: block.endAt)
        }
        .sheet(item: $editingEntry) { entry in
            ActivityEntryEditor(state: state, entry: entry)
        }
    }

    private func rail<Content: View>(_ title: String, icon: String, isEmpty: Bool, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon).font(.headline)
            if isEmpty { Text("No \(title.lowercased()) time").foregroundStyle(.secondary) }
            content()
        }
        .padding(18).frame(maxWidth: .infinity, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private func row(title: String, start: Date, end: Date) -> some View {
        HStack(alignment: .top) {
            Text("\(start.formatted(date: .omitted, time: .shortened))–\(end.formatted(date: .omitted, time: .shortened))")
                .font(.caption).monospacedDigit().foregroundStyle(.secondary)
            Text(title).font(.subheadline)
        }
        .padding(10).frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct ActivityEntryEditor: View {
    @ObservedObject var state: AppState
    let entry: ActivityEntry
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var start: Date
    @State private var end: Date
    @State private var category: String

    init(state: AppState, entry: ActivityEntry) {
        self.state = state
        self.entry = entry
        _title = State(initialValue: entry.title)
        _start = State(initialValue: entry.startAt)
        _end = State(initialValue: entry.endAt)
        _category = State(initialValue: entry.category)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit logged activity").font(.title2.bold())
            TextField("Activity", text: $title)
            DatePicker("From", selection: $start)
            DatePicker("To", selection: $end)
            TextField("Category", text: $category)
            HStack {
                Button("Delete", role: .destructive) { state.deleteActivity(entry.id); if state.errorMessage == nil { dismiss() } }
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") {
                    state.saveActivity(title: title, start: start, end: end, category: category, id: entry.id)
                    if state.errorMessage == nil { dismiss() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24).frame(minWidth: 380)
    }
}
