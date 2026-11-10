import LoopinnCore
import SwiftUI

struct MenuContent: View {
    @ObservedObject var state: AppState
    @Environment(\.openWindow) private var openWindow
    @State private var quickTitle = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Loopinn").font(.headline)
            HStack {
                TextField("Quick task", text: $quickTitle)
                    .onSubmit(add)
                Button("Add", action: add)
            }
            if let task = state.workspace.tasks.first(where: { $0.completedAt == nil }) {
                Text("Next: \(task.title)").font(.caption)
            }
            Button("Open Dashboard") {
                openWindow(id: "dashboard")
                NSApp.activate(ignoringOtherApps: true)
            }
            Button("Quit Loopinn") { NSApp.terminate(nil) }
        }
        .padding(16)
        .frame(width: 280)
    }

    private func add() {
        state.addTask(quickTitle)
        if state.errorMessage == nil { quickTitle = "" }
    }
}

private enum Page: String, CaseIterable, Identifiable {
    case today = "Today", tasks = "Tasks", planner = "Planner", focus = "Focus", analytics = "Analytics", settings = "Settings"
    var id: Self { self }
    var icon: String {
        switch self {
        case .today: "sun.max"
        case .tasks: "checklist"
        case .planner: "calendar"
        case .focus: "timer"
        case .analytics: "chart.bar"
        case .settings: "gearshape"
        }
    }
}

struct DashboardView: View {
    @ObservedObject var state: AppState
    @State private var page: Page = .today
    @State private var taskTitle = ""
    @State private var selectedTask: LoopTask?

    var body: some View {
        NavigationSplitView {
            List(Page.allCases, selection: $page) { item in
                Label(item.rawValue, systemImage: item.icon).tag(item)
            }
            .navigationTitle("Loopinn")
            .frame(minWidth: 200)
        } detail: {
            VStack(alignment: .leading, spacing: 20) {
                Text(page.rawValue).font(.largeTitle.bold())
                switch page {
                case .today, .tasks:
                    taskContent
                case .planner:
                    plannerContent
                case .focus:
                    ContentUnavailableView("Focus is next", systemImage: "timer", description: Text("Timer sessions will appear here."))
                case .analytics:
                    ContentUnavailableView("No activity yet", systemImage: "chart.bar", description: Text("Reports will use recorded activity, separate from planned time."))
                case .settings:
                    ContentUnavailableView("Settings", systemImage: "gearshape", description: Text("Preferences and integrations will appear here."))
                }
                Spacer(minLength: 0)
            }
            .padding(28)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .alert("Loopinn", isPresented: Binding(get: { state.errorMessage != nil }, set: { if !$0 { state.errorMessage = nil } })) {
            Button("OK", role: .cancel) { state.errorMessage = nil }
        } message: {
            Text(state.errorMessage ?? "")
        }
        .sheet(item: $selectedTask) { task in
            ScheduleSheet(task: task, state: state)
        }
    }

    private var taskContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                TextField("Add a task", text: $taskTitle).onSubmit(addTask)
                Button("Add Task", action: addTask).buttonStyle(.borderedProminent)
            }
            if state.workspace.tasks.isEmpty {
                ContentUnavailableView("Start with one task", systemImage: "checklist", description: Text("Tasks save locally and are available offline."))
            } else {
                List(state.workspace.tasks) { task in
                    HStack {
                        Button { state.toggleTask(task) } label: {
                            Image(systemName: task.completedAt == nil ? "circle" : "checkmark.circle.fill")
                        }
                        .buttonStyle(.plain)
                        Text(task.title).strikethrough(task.completedAt != nil)
                        Spacer()
                        if task.startAt != nil { Image(systemName: "calendar").foregroundStyle(.secondary) }
                        Button("Schedule") { selectedTask = task }
                    }
                }
            }
        }
    }

    private var plannerContent: some View {
        VStack(alignment: .leading) {
            Text("Scheduled tasks").font(.title2)
            if state.workspace.blocks.isEmpty {
                ContentUnavailableView("No time blocks", systemImage: "calendar", description: Text("Set a start and end time on a task to add it here."))
            } else {
                List(state.workspace.blocks.sorted(by: { $0.startAt < $1.startAt })) { block in
                    VStack(alignment: .leading) {
                        Text(state.workspace.tasks.first(where: { $0.id == block.taskID })?.title ?? "Task")
                        Text("\(block.startAt.formatted(date: .abbreviated, time: .shortened)) – \(block.endAt.formatted(date: .omitted, time: .shortened))")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func addTask() {
        state.addTask(taskTitle)
        if state.errorMessage == nil { taskTitle = "" }
    }
}

private struct ScheduleSheet: View {
    let task: LoopTask
    @ObservedObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var start = Date()
    @State private var end = Date().addingTimeInterval(3600)

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Schedule \(task.title)").font(.title2.bold())
            DatePicker("Start", selection: $start)
            DatePicker("End", selection: $end)
            Text("This creates one block in Loopinn’s local planner. External calendars are never changed automatically.")
                .foregroundStyle(.secondary)
            HStack {
                if task.startAt != nil {
                    Button("Remove Schedule", role: .destructive) {
                        state.schedule(task, start: nil, end: nil)
                        if state.errorMessage == nil { dismiss() }
                    }
                }
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") {
                    state.schedule(task, start: start, end: end)
                    if state.errorMessage == nil { dismiss() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 440)
        .onAppear {
            start = task.startAt ?? .now
            end = task.endAt ?? Date().addingTimeInterval(3600)
        }
    }
}
