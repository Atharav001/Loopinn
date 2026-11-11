import LoopinnCore
import SwiftUI

struct QuickLogView: View {
    @ObservedObject var state: AppState
    @State private var title = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("What did you do?", systemImage: "clock.badge.questionmark").font(.title2.bold())
            if let interval = state.activityPrompt {
                Text("\(interval.start.formatted(date: .omitted, time: .shortened)) – \(interval.end.formatted(date: .omitted, time: .shortened))")
                    .foregroundStyle(.secondary)
                TextField("Describe the last hour", text: $title)
                    .focused($focused).onSubmit(save)
                HStack {
                    Button("Skip") { state.skipActivityPrompt() }
                    Spacer()
                    Button("Log activity", action: save).buttonStyle(.borderedProminent)
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } else {
                ContentUnavailableView("No hour to log", systemImage: "checkmark.circle")
            }
        }
        .padding(24)
        .frame(minWidth: 350, minHeight: 230)
        .background(.ultraThinMaterial)
        .onAppear { focused = true }
    }

    private func save() {
        guard let interval = state.activityPrompt else { return }
        state.saveActivity(title: title, start: interval.start, end: interval.end)
        if state.errorMessage == nil { title = "" }
    }
}

struct ActivityLogView: View {
    @ObservedObject var state: AppState
    @State private var selectedDate = Date()
    @State private var title = ""
    @State private var start = Date().addingTimeInterval(-3600)
    @State private var end = Date()
    @State private var category = "Uncategorized"
    @State private var editingID: UUID?
    private let categories = ["Uncategorized", "Work", "Study", "Break", "Exercise", "Personal"]

    private var entries: [ActivityEntry] {
        state.activityLogbook.entries.filter { Calendar.current.isDate($0.startAt, inSameDayAs: selectedDate) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Logbook calendar").font(.title2.bold())
                    Spacer()
                    Button("Export CSV") { state.exportActivities(asJSON: false) }
                    Button("Export JSON") { state.exportActivities(asJSON: true) }
                    DatePicker("Day", selection: $selectedDate, displayedComponents: .date).labelsHidden()
                }
                HStack {
                    TextField("What did you do?", text: $title).onSubmit(add)
                    DatePicker("From", selection: $start, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("To", selection: $end, displayedComponents: [.date, .hourAndMinute])
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0).tag($0) }
                    }
                    .frame(width: 155)
                    Button(editingID == nil ? "Add" : "Save", action: add).buttonStyle(.borderedProminent)
                }
                if entries.isEmpty {
                    ContentUnavailableView("Nothing logged for this day", systemImage: "text.book.closed")
                }
                ForEach(entries) { entry in
                    HStack {
                        Text("\(entry.startAt.formatted(date: .omitted, time: .shortened))–\(entry.endAt.formatted(date: .omitted, time: .shortened))")
                            .monospacedDigit().foregroundStyle(.secondary)
                        Text(entry.title)
                        Spacer()
                        Text(entry.category).foregroundStyle(.secondary)
                        Button("Edit") {
                            editingID = entry.id
                            title = entry.title
                            start = entry.startAt
                            end = entry.endAt
                            category = entry.category
                        }
                        Button("Delete", role: .destructive) { state.deleteActivity(entry.id) }
                    }
                    .padding(14)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    private func add() {
        state.saveActivity(title: title, start: start, end: end, category: category, id: editingID)
        if state.errorMessage == nil { title = ""; editingID = nil }
    }
}
