import LoopinnCore
import SwiftUI

struct QuickLogView: View {
    @ObservedObject var state: AppState
    @State private var title = ""
    @State private var category = "Uncategorized"
    @State private var manualStart = Date().addingTimeInterval(-3600)
    @State private var manualEnd = Date()
    @FocusState private var focused: Bool
    private let suggestions = ["Coding", "Deep Work", "Meeting", "Planning", "Research", "Break"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("What did you do?", systemImage: "clock.badge.questionmark").font(.title2.bold())
            if let interval = state.activityPrompt {
                Text("\(interval.start.formatted(date: .omitted, time: .shortened)) – \(interval.end.formatted(date: .omitted, time: .shortened))")
                    .foregroundStyle(.secondary)
            } else {
                HStack {
                    DatePicker("From", selection: $manualStart, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("To", selection: $manualEnd, displayedComponents: [.date, .hourAndMinute])
                }
            }
            TextField("What did you work on?", text: $title)
                .focused($focused).onSubmit(save)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button(suggestion) {
                                if title.isEmpty { title = suggestion }
                                category = suggestion == "Break" ? "Break" : "Work"
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
                HStack {
                    if state.activityPrompt != nil {
                        Button("Skip") { state.skipActivityPrompt() }
                    }
                    Spacer()
                    Button("Log activity", action: save).buttonStyle(.borderedProminent)
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .onAppear { focused = true }
    }

    private func save() {
        if state.activityPrompt == nil && manualEnd <= manualStart {
            state.errorMessage = "The end time must be after the start time."
            return
        }
        let interval = state.activityPrompt ?? DateInterval(start: manualStart, end: manualEnd)
        state.saveActivity(title: title, start: interval.start, end: interval.end, category: category)
        if state.errorMessage == nil { title = "" }
    }
}

struct ActivityLogView: View {
    @ObservedObject var state: AppState
    @StateObject private var voice = VoiceLogService()
    @State private var selectedDate = Date()
    @State private var title = ""
    @State private var start = Date().addingTimeInterval(-3600)
    @State private var end = Date()
    @State private var category = "Uncategorized"
    @State private var editingID: UUID?
    @State private var quietStart = 22
    @State private var quietEnd = 8
    @State private var rulePhrase = ""
    @State private var ruleCategory = "Work"
    @State private var naturalText = ""
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
                logbookMonth
                HStack {
                    Toggle("Quiet hours", isOn: Binding(
                        get: { state.activityLogbook.quietHours != nil },
                        set: { state.setActivityQuietHours(startHour: $0 ? quietStart : nil, endHour: $0 ? quietEnd : nil) }
                    ))
                    .frame(width: 140)
                    if state.activityLogbook.quietHours != nil {
                        Stepper("From \(quietStart):00", value: $quietStart, in: 0...23)
                        Stepper("Until \(quietEnd):00", value: $quietEnd, in: 0...23)
                        Button("Apply") { state.setActivityQuietHours(startHour: quietStart, endHour: quietEnd) }
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("Activity categories").font(.headline)
                    Text("Unknown activities stay Uncategorized. Add words you want Loopinn to recognize.")
                        .font(.caption).foregroundStyle(.secondary)
                    HStack {
                        TextField("Word or phrase", text: $rulePhrase)
                        Picker("Category", selection: $ruleCategory) {
                            ForEach(categories.filter { $0 != "Uncategorized" }, id: \.self) { Text($0).tag($0) }
                        }
                        Button("Add Rule") {
                            state.setActivityRule(phrase: rulePhrase, category: ruleCategory)
                            rulePhrase = ""
                        }
                    }
                    ForEach((state.activityLogbook.classificationRules ?? [:]).keys.sorted(), id: \.self) { phrase in
                        HStack {
                            Text(phrase)
                            Spacer()
                            Text(state.activityLogbook.classificationRules?[phrase] ?? "")
                            Button("Remove", role: .destructive) { state.removeActivityRule(phrase) }
                        }
                    }
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                HStack {
                    TextField("What did you do?", text: $title).onSubmit(add)
                    Button(voice.isRecording ? "Stop dictation" : "Dictate", systemImage: voice.isRecording ? "stop.fill" : "mic.fill") {
                        if voice.isRecording { voice.stop(); if !voice.transcript.isEmpty { title = voice.transcript } }
                        else { voice.start() }
                    }
                    DatePicker("From", selection: $start, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("To", selection: $end, displayedComponents: [.date, .hourAndMinute])
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0).tag($0) }
                    }
                    .frame(width: 155)
                    Button(editingID == nil ? "Add" : "Save", action: add).buttonStyle(.borderedProminent)
                }
                if let error = voice.errorMessage { Text(error).font(.caption).foregroundStyle(.red) }
                if voice.isRecording { Text(voice.transcript.isEmpty ? "Listening…" : voice.transcript).font(.caption).foregroundStyle(.secondary) }
                HStack {
                    TextField("Example: 11am to noon Design review", text: $naturalText)
                        .onSubmit(reviewTime)
                    Button("Review time", action: reviewTime)
                }
                Text("Review the filled times before saving. Ambiguous or overnight ranges use the manual fields.")
                    .font(.caption).foregroundStyle(.secondary)
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
        .onAppear {
            quietStart = (state.activityLogbook.quietHours?.startMinute ?? 1320) / 60
            quietEnd = (state.activityLogbook.quietHours?.endMinute ?? 480) / 60
        }
        .onDisappear { voice.stop() }
    }

    private func add() {
        state.saveActivity(title: title, start: start, end: end, category: category, id: editingID)
        if state.errorMessage == nil { title = ""; editingID = nil }
    }

    private var logbookMonth: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button("Previous month", systemImage: "chevron.left") { shiftMonth(-1) }.labelStyle(.iconOnly)
                Text(selectedDate.formatted(.dateTime.month(.wide).year())).font(.headline)
                Button("Next month", systemImage: "chevron.right") { shiftMonth(1) }.labelStyle(.iconOnly)
                Spacer()
                Button("Today") { selectedDate = .now }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 7), spacing: 5) {
                ForEach(CalendarLayout.gridDays(for: selectedDate), id: \.self) { day in
                    let count = state.activityLogbook.entries.filter { Calendar.current.isDate($0.startAt, inSameDayAs: day) }.count
                    Button { selectedDate = day } label: {
                        VStack(spacing: 4) {
                            Text(day.formatted(.dateTime.day())).font(.subheadline.weight(Calendar.current.isDate(day, inSameDayAs: selectedDate) ? .bold : .regular))
                            Circle().fill(count > 0 ? Color.accentColor : .clear).frame(width: 4, height: 4)
                        }
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(Calendar.current.isDate(day, inSameDayAs: selectedDate) ? Color.accentColor.opacity(0.17) : .clear,
                                    in: RoundedRectangle(cornerRadius: 8))
                        .opacity(Calendar.current.isDate(day, equalTo: selectedDate, toGranularity: .month) ? 1 : 0.35)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(day.formatted(date: .complete, time: .omitted)), \(count) logged activities")
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func shiftMonth(_ amount: Int) {
        selectedDate = Calendar.current.date(byAdding: .month, value: amount, to: selectedDate) ?? selectedDate
    }

    private func reviewTime() {
        guard let draft = ActivityTimeParser.parse(naturalText, on: selectedDate) else {
            state.errorMessage = "Use an explicit range such as 11am to noon Design review, or enter the times manually."
            return
        }
        title = draft.title
        start = draft.startAt
        end = draft.endAt
    }
}
