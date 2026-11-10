import LoopinnCore
import SwiftUI
import UniformTypeIdentifiers

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
            if let task = state.nextTask {
                Text("Next: \(task.title)").font(.caption).lineLimit(2)
                Button("Complete Next Task", systemImage: "checkmark.circle") {
                    state.toggleTask(task)
                }
            } else {
                Text("No open tasks").font(.caption).foregroundStyle(.secondary)
            }
            Divider()
            Button("Open Today", systemImage: "sun.max") { show(.today) }
            Button("Open Tasks", systemImage: "checklist") { show(.tasks) }
            Button("Open Planner", systemImage: "calendar") { show(.planner) }
            Divider()
            Text("Local data only").font(.caption).foregroundStyle(.secondary)
            if let error = state.errorMessage {
                Text(error).font(.caption).foregroundStyle(.red).lineLimit(3)
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

    private func show(_ page: DashboardPage) {
        state.selectedPage = page
        openWindow(id: "dashboard")
        NSApp.activate(ignoringOtherApps: true)
    }
}

enum DashboardPage: String, CaseIterable, Identifiable {
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
    @State private var taskTitle = ""
    @State private var selectedTask: LoopTask?
    @State private var taskToEdit: LoopTask?
    @State private var selectedListID: UUID?
    @State private var newListName = ""
    @State private var renamingList: TaskList?
    @State private var renamedListName = ""
    @State private var listToDelete: TaskList?

    var body: some View {
        NavigationSplitView {
            List(DashboardPage.allCases, selection: $state.selectedPage) { item in
                Label(item.rawValue, systemImage: item.icon).tag(item)
            }
            .navigationTitle("Loopinn")
            .frame(minWidth: 200)
        } detail: {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text(state.selectedPage.rawValue).font(.largeTitle.bold())
                    Spacer()
                    Button("Undo", systemImage: "arrow.uturn.backward") { state.undoLastChange() }
                        .disabled(!state.canUndo)
                        .keyboardShortcut("z", modifiers: .command)
                }
                switch state.selectedPage {
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
        .sheet(item: $taskToEdit) { task in
            TaskDetailSheet(task: task, state: state)
        }
        .alert("Rename list", isPresented: Binding(get: { renamingList != nil }, set: { if !$0 { renamingList = nil } })) {
            TextField("List name", text: $renamedListName)
            Button("Save") {
                if let renamingList { state.renameList(renamingList, to: renamedListName) }
                renamingList = nil
            }
            Button("Cancel", role: .cancel) { renamingList = nil }
        }
        .confirmationDialog("Delete this list? Its tasks will move to another list.", isPresented: Binding(get: { listToDelete != nil }, set: { if !$0 { listToDelete = nil } })) {
            Button("Delete List", role: .destructive) {
                if let listToDelete { state.deleteList(listToDelete) }
                if state.errorMessage == nil { selectedListID = nil }
                listToDelete = nil
            }
        }
    }

    private var taskContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Picker("List", selection: $selectedListID) {
                    Text("All Lists").tag(UUID?.none)
                    ForEach(state.workspace.lists) { list in
                        Text(list.name).tag(Optional(list.id))
                    }
                }
                .frame(maxWidth: 250)
                if let list = state.workspace.lists.first(where: { $0.id == selectedListID }) {
                    Button("Move List Up", systemImage: "arrow.up") { state.moveList(list, by: -1) }
                        .disabled(state.workspace.lists.first?.id == list.id)
                    Button("Move List Down", systemImage: "arrow.down") { state.moveList(list, by: 1) }
                        .disabled(state.workspace.lists.last?.id == list.id)
                    Button("Rename") {
                        renamedListName = list.name
                        renamingList = list
                    }
                    Button("Delete List", role: .destructive) {
                        listToDelete = list
                    }
                    .disabled(state.workspace.lists.count == 1)
                }
                Spacer()
                TextField("New list", text: $newListName).frame(width: 140).onSubmit(addList)
                Button("Add List", action: addList)
            }
            HStack {
                TextField("Add a task", text: $taskTitle).onSubmit(addTask)
                Button("Add Task", action: addTask).buttonStyle(.borderedProminent)
            }
            if visibleTasks.isEmpty {
                ContentUnavailableView("Start with one task", systemImage: "checklist", description: Text("Tasks save locally and are available offline."))
            } else {
                List(visibleTasks) { task in
                    HStack {
                        Button { state.toggleTask(task) } label: {
                            Image(systemName: task.completedAt == nil ? "circle" : "checkmark.circle.fill")
                        }
                        .buttonStyle(.plain)
                        Text(task.title).strikethrough(task.completedAt != nil)
                        if task.isStarred == true { Image(systemName: "star.fill").foregroundStyle(.yellow) }
                        Spacer()
                        if let due = task.dueAt { Text(due, style: .date).foregroundStyle(.secondary) }
                        if task.startAt != nil { Image(systemName: "calendar").foregroundStyle(.secondary) }
                        Button("Move Up", systemImage: "arrow.up") { state.moveTask(task, by: -1) }
                            .disabled(visibleTasks.first(where: { $0.listID == task.listID })?.id == task.id)
                        Button("Move Down", systemImage: "arrow.down") { state.moveTask(task, by: 1) }
                            .disabled(visibleTasks.last(where: { $0.listID == task.listID })?.id == task.id)
                        Button("Details") { taskToEdit = task }
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
        state.addTask(taskTitle, to: selectedListID ?? state.workspace.lists[0].id)
        if state.errorMessage == nil { taskTitle = "" }
    }

    private var visibleTasks: [LoopTask] {
        state.workspace.tasks.filter { selectedListID == nil || $0.listID == selectedListID }
    }

    private func addList() {
        state.addList(newListName)
        if state.errorMessage == nil { newListName = "" }
    }
}

private struct TaskDetailSheet: View {
    let task: LoopTask
    @ObservedObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var notes = ""
    @State private var hasDueDate = false
    @State private var dueAt = Date()
    @State private var priority = 0
    @State private var listID = UUID()
    @State private var isStarred = false
    @State private var confirmDelete = false
    @State private var showingImporter = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Task details").font(.title2.bold())
            TextField("Title", text: $title)
            TextField("Notes", text: $notes, axis: .vertical).lineLimit(3...6)
            Picker("List", selection: $listID) {
                ForEach(state.workspace.lists) { list in Text(list.name).tag(list.id) }
            }
            Toggle("Starred", isOn: $isStarred)
            Toggle("Due date", isOn: $hasDueDate)
            if hasDueDate { DatePicker("Due", selection: $dueAt) }
            Picker("Priority", selection: $priority) {
                Text("None").tag(0)
                Text("Low").tag(1)
                Text("Medium").tag(2)
                Text("High").tag(3)
            }
            Text("A due date does not add a calendar block. Use Schedule to set a start and end time.")
                .font(.caption).foregroundStyle(.secondary)
            Text("Attachments").font(.headline)
            ForEach(currentTask.attachments ?? []) { attachment in
                HStack {
                    Button(attachment.originalName) { state.openAttachment(attachment) }
                    Spacer()
                    Text(ByteCountFormatter.string(fromByteCount: attachment.byteCount, countStyle: .file))
                        .foregroundStyle(.secondary)
                    Button("Remove", role: .destructive) { state.removeAttachment(attachment, from: task) }
                }
            }
            Button("Attach File") { showingImporter = true }
            HStack {
                Button("Delete Task", role: .destructive) { confirmDelete = true }
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") {
                    state.updateTask(task, title: title, notes: notes, dueAt: hasDueDate ? dueAt : nil, priority: priority == 0 ? nil : priority, listID: listID, isStarred: isStarred)
                    if state.errorMessage == nil { dismiss() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24).frame(width: 460)
        .onAppear {
            title = task.title
            notes = task.notes
            hasDueDate = task.dueAt != nil
            dueAt = task.dueAt ?? .now
            priority = task.priority ?? 0
            listID = task.listID
            isStarred = task.isStarred ?? false
        }
        .confirmationDialog("Delete this task and its local calendar block?", isPresented: $confirmDelete) {
            Button("Delete Task", role: .destructive) {
                state.deleteTask(task)
                if state.errorMessage == nil { dismiss() }
            }
        }
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.item]) { result in
            switch result {
            case .success(let url): state.addAttachment(to: task, from: url)
            case .failure(let error): state.errorMessage = error.localizedDescription
            }
        }
    }

    private var currentTask: LoopTask {
        state.workspace.tasks.first(where: { $0.id == task.id }) ?? task
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
