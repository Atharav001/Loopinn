import LoopinnCore
import SwiftUI
import UniformTypeIdentifiers

struct MenuContent: View {
    @ObservedObject var state: AppState
    @Environment(\.openWindow) private var openWindow
    @State private var quickTitle = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.title3)
                    .foregroundStyle(state.settings.accent.color)
                    .frame(width: 34, height: 34)
                    .background(state.settings.accent.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 1) {
                    Text("Loopinn").font(.headline)
                    Text("A little more room to focus").font(.caption2).foregroundStyle(.secondary)
                }
            }
            HStack(spacing: 8) {
                TextField("Capture a task…", text: $quickTitle)
                    .textFieldStyle(.plain)
                    .onSubmit(add)
                Button("Add", action: add).buttonStyle(.borderedProminent)
            }
            .padding(10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
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
            Button("Open Calendar", systemImage: "calendar.circle") { show(.calendar) }
            Button("Open Settings", systemImage: "gearshape") { show(.settings) }
            Button("Floating Tasks", systemImage: "square.on.square") {
                FloatingPanelManager.shared.showTasks(state: state)
            }
            Button("Floating Pomodoro", systemImage: "timer") { FloatingPanelManager.shared.showPomodoro(state: state) }
            Divider()
            Label("Stored locally on this Mac", systemImage: "lock.shield")
                .font(.caption).foregroundStyle(.secondary)
            if let error = state.errorMessage {
                Text(error).font(.caption).foregroundStyle(.red).lineLimit(3)
            }
            Button("Quit Loopinn") { NSApp.terminate(nil) }
        }
        .padding(16)
        .frame(width: 280)
        .preferredColorScheme(state.settings.theme.colorScheme)
        .tint(state.settings.accent.color)
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
    case today = "Today", tasks = "Tasks", planner = "Planner", calendar = "Calendar", focus = "Focus", analytics = "Analytics", settings = "Settings"
    var id: Self { self }
    var icon: String {
        switch self {
        case .today: "sun.max"
        case .tasks: "checklist"
        case .planner: "calendar"
        case .calendar: "calendar.circle"
        case .focus: "timer"
        case .analytics: "chart.bar"
        case .settings: "gearshape"
        }
    }
}

struct DashboardView: View {
    @ObservedObject var state: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var taskTitle = ""
    @State private var selectedTask: LoopTask?
    @State private var taskToEdit: LoopTask?
    @State private var selectedListID: UUID?
    @State private var newListName = ""
    @State private var renamingList: TaskList?
    @State private var renamedListName = ""
    @State private var listToDelete: TaskList?
    @State private var showCommandPalette = false
    @State private var confirmRestore = false
    @State private var confirmErase = false
    @State private var backupToRestore: URL?
    @FocusState private var taskInputFocused: Bool

    var body: some View {
        NavigationSplitView {
            List(DashboardPage.allCases, selection: $state.selectedPage) { item in
                Label(item.rawValue, systemImage: item.icon).tag(item)
            }
            .navigationTitle("Loopinn")
            .listStyle(.sidebar)
            .frame(minWidth: LoopinnDesign.sidebarWidth)
        } detail: {
            VStack(alignment: .leading, spacing: state.settings.compactLayout == true ? 12 : 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(state.selectedPage.rawValue).font(.largeTitle.bold())
                        Text(Date.now.formatted(date: .complete, time: .omitted))
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Commands", systemImage: "command") { showCommandPalette = true }
                        .keyboardShortcut("k", modifiers: .command)
                    Button("New Task", systemImage: "plus") {
                        state.selectedPage = .tasks
                        taskInputFocused = true
                    }
                    .keyboardShortcut("n", modifiers: .command)
                    Button("Floating Tasks", systemImage: "square.on.square") {
                        FloatingPanelManager.shared.showTasks(state: state)
                    }
                    Button("Undo", systemImage: "arrow.uturn.backward") { state.undoLastChange() }
                        .disabled(!state.canUndo)
                        .keyboardShortcut("z", modifiers: .command)
                }
                switch state.selectedPage {
                case .today:
                    todayContent
                case .tasks:
                    taskContent
                case .planner:
                    CalendarDashboardView(state: state)
                case .calendar:
                    CalendarDashboardView(state: state)
                case .focus:
                    FocusDashboardView(state: state)
                case .analytics:
                    ContentUnavailableView("No activity yet", systemImage: "chart.bar", description: Text("Reports will use recorded activity, separate from planned time."))
                case .settings:
                    settingsContent
                }
                Spacer(minLength: 0)
            }
            .padding(state.settings.compactLayout == true ? 18 : 28)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(nsColor: .windowBackgroundColor))
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
        .sheet(isPresented: $showCommandPalette) {
            CommandPaletteView(state: state)
        }
        .sheet(isPresented: Binding(
            get: { state.canEditSettings && state.settings.hasCompletedOnboarding != true },
            set: { if !$0 { state.completeOnboarding() } }
        )) {
            OnboardingView(state: state)
        }
        .preferredColorScheme(state.settings.theme.colorScheme)
        .tint(state.settings.accent.color)
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
        .confirmationDialog("Restore this backup?", isPresented: $confirmRestore) {
            Button("Restore Backup") {
                if let backupToRestore { state.restoreBackup(from: backupToRestore) }
                backupToRestore = nil
            }
            Button("Cancel", role: .cancel) { backupToRestore = nil }
        } message: {
            Text("Your current data will be saved in a local safety backup first.")
        }
        .confirmationDialog("Erase all Loopinn data on this Mac?", isPresented: $confirmErase) {
            Button("Erase Local Data", role: .destructive) { state.eraseLocalData() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes tasks, lists, schedules, attachments, settings and local safety backups. Export a backup first if you need a copy.")
        }
    }

    private var todayContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LoopinnDesign.contentSpacing) {
                HStack(spacing: 16) {
                    LoopinnCard {
                        Label("Open tasks", systemImage: "checklist").foregroundStyle(.secondary)
                        Text("\(state.workspace.tasks.filter { $0.completedAt == nil }.count)")
                            .font(.system(size: 34, weight: .semibold, design: .rounded))
                    }
                    LoopinnCard {
                        Label("Planned blocks", systemImage: "calendar").foregroundStyle(.secondary)
                        Text("\(state.workspace.blocks.count)")
                            .font(.system(size: 34, weight: .semibold, design: .rounded))
                    }
                }
                SectionHeading("Up next", subtitle: "A clear place to start")
                LoopinnCard {
                    if let task = state.nextTask {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(task.title).font(.title3.weight(.semibold))
                                Text(state.nextTaskReason ?? "Ready when you are")
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Dismiss", systemImage: "xmark") { state.dismissedRecommendationID = task.id }
                                .labelStyle(.iconOnly)
                            Button("Complete") { toggle(task) }.buttonStyle(.borderedProminent)
                        }
                    } else {
                        Text("Add a task to begin your day.").foregroundStyle(.secondary)
                    }
                }
                if state.settings.showTodayPlan != false {
                    SectionHeading("Your plan", subtitle: "Scheduled work stays separate from actual activity")
                    LoopinnCard {
                        if state.workspace.blocks.isEmpty {
                            Text("No blocks scheduled yet.").foregroundStyle(.secondary)
                        } else {
                            ForEach(state.workspace.blocks.sorted(by: { $0.startAt < $1.startAt }).prefix(3)) { block in
                                HStack {
                                    Text(state.workspace.tasks.first(where: { $0.id == block.taskID })?.title ?? "Task")
                                    Spacer()
                                    Text(block.startAt, style: .time).foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: 900)
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
                TextField("Add a task", text: $taskTitle).focused($taskInputFocused).onSubmit(addTask)
                Button("Add Task", action: addTask).buttonStyle(.borderedProminent)
                Button("Paste Tasks", systemImage: "doc.on.clipboard") {
                    if let text = NSPasteboard.general.string(forType: .string) {
                        state.captureTasks(text, to: selectedListID ?? state.workspace.lists[0].id)
                    }
                }
            }
            Text("Tip: use !high, @tomorrow or #ListName while capturing a task.")
                .font(.caption).foregroundStyle(.secondary)
            if visibleTasks.isEmpty {
                ContentUnavailableView("Start with one task", systemImage: "checklist", description: Text("Tasks save locally and are available offline."))
            } else {
                List(visibleTasks) { task in
                    HStack {
                        Button { toggle(task) } label: {
                            Image(systemName: task.completedAt == nil ? "circle" : "checkmark.circle.fill")
                        }
                        .buttonStyle(.plain)
                        if task.colorTag != nil {
                            Circle().fill(TaskAppearance.color(for: task.colorTag)).frame(width: 8, height: 8)
                                .accessibilityLabel("\(task.colorTag ?? "") task")
                        }
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
        .dropDestination(for: String.self) { items, _ in
            guard !items.isEmpty else { return false }
            state.captureTasks(items.joined(separator: "\n"), to: selectedListID ?? state.workspace.lists[0].id)
            return state.errorMessage == nil
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

    private var settingsContent: some View {
        Form {
            Section("General") {
                Toggle("Show Dock Icon", isOn: Binding(
                    get: { state.settings.showDockIcon == true },
                    set: { state.setShowDockIcon($0) }
                ))
                Text("Loopinn opens from the menu bar by default.")
                    .foregroundStyle(.secondary)
            }
            Section("Appearance") {
                Picker("Theme", selection: Binding(
                    get: { state.settings.theme },
                    set: { state.setTheme($0) }
                )) {
                    Text("System").tag(ThemeMode.system)
                    Text("Light").tag(ThemeMode.light)
                    Text("Dark").tag(ThemeMode.dark)
                }
                Picker("Accent", selection: Binding(
                    get: { state.settings.accent },
                    set: { state.setAccent($0) }
                )) {
                    ForEach(AccentChoice.allCases) { accent in
                        Text(accent.rawValue.capitalized).tag(accent)
                    }
                }
                Button("Reset Appearance") { state.resetAppearance() }
                Toggle("Compact Layout", isOn: Binding(
                    get: { state.settings.compactLayout == true },
                    set: { state.setCompactLayout($0) }
                ))
            }
            Section("Dashboard") {
                Toggle("Show Today Plan", isOn: Binding(
                    get: { state.settings.showTodayPlan != false },
                    set: { state.setShowTodayPlan($0) }
                ))
            }
            Section("Apple Calendar") {
                Toggle("Show Apple Events", isOn: Binding(
                    get: { state.settings.showAppleEvents != false },
                    set: { state.setShowAppleEvents($0) }
                ))
                if state.appleCalendarConnected {
                    Label("Connected for calendar access", systemImage: "checkmark.circle")
                    Button("Refresh Apple Events") { state.refreshAppleCalendar(force: true) }
                    ForEach(state.appleCalendars) { calendar in
                        Toggle(calendar.title, isOn: Binding(
                            get: { !(state.settings.hiddenAppleCalendarIDs ?? []).contains(calendar.id) },
                            set: { state.setAppleCalendarVisible(calendar.id, visible: $0) }
                        ))
                    }
                } else {
                    Text("Connect only when you want to view Apple Calendar events or publish a plan.")
                        .foregroundStyle(.secondary)
                    Button("Connect Apple Calendar…") { state.connectAppleCalendar() }
                }
            }
            Section("Google Calendar") {
                TextField("OAuth Desktop client ID", text: Binding(
                    get: { state.settings.googleClientID ?? "" },
                    set: { state.setGoogleClientID($0) }
                ))
                .textContentType(.none)
                .disabled(state.googleCalendarConnected)
                if state.googleCalendarConnected {
                    Label("Connected", systemImage: "checkmark.circle")
                    Button("Refresh Google Events") { state.refreshGoogleCalendar(force: true) }
                    ForEach(state.googleCalendars) { calendar in
                        Toggle(calendar.title, isOn: Binding(
                            get: { !(state.settings.hiddenGoogleCalendarIDs ?? []).contains(calendar.id) },
                            set: { state.setGoogleCalendarVisible(calendar.id, visible: $0) }
                        ))
                    }
                    Button("Disconnect Google Calendar", role: .destructive) { state.disconnectGoogleCalendar() }
                } else {
                    Text("Use a Google OAuth Desktop client ID. Sign-in opens in your browser; tokens stay in this Mac's Keychain.")
                        .foregroundStyle(.secondary)
                    Button("Connect Google Calendar…") { state.connectGoogleCalendar() }
                        .disabled((state.settings.googleClientID ?? "").isEmpty)
                }
            }
            Section("Floating tasks") {
                Label("Task and focus panels stay above other windows", systemImage: "square.on.square")
                Button("Open Floating Tasks") { FloatingPanelManager.shared.showTasks(state: state) }
                Button("Open Floating Pomodoro") { FloatingPanelManager.shared.showPomodoro(state: state) }
            }
            Section("About this build") {
                Text("Tasks and planning are stored locally. Apple and Google calendars connect only when you choose; cloud task sync is still in development.")
                    .foregroundStyle(.secondary)
                Button("Reopen Welcome") { state.reopenOnboarding() }
            }
            Section("Privacy & data") {
                Label("Stored on this Mac", systemImage: "internaldrive")
                Text("Loopinn does not request calendar access or send your tasks to a server in this build.")
                    .foregroundStyle(.secondary)
                Button("Export Backup…") { chooseBackupDestination() }
                Button("Restore Backup…") { chooseBackupSource() }
                Button("Erase Local Data…", role: .destructive) { confirmErase = true }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: 620)
    }

    private func chooseBackupDestination() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "Loopinn-\(Date.now.formatted(.iso8601.year().month().day())).loopinnbackup"
        panel.message = "Save your tasks, settings and attachments as a Loopinn backup folder."
        guard panel.runModal() == .OK, let url = panel.url else { return }
        state.exportBackup(to: url)
    }

    private func chooseBackupSource() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose a .loopinnbackup folder."
        guard panel.runModal() == .OK, let url = panel.url else { return }
        backupToRestore = url
        confirmRestore = true
    }

    private func addTask() {
        state.addTask(taskTitle, to: selectedListID ?? state.workspace.lists[0].id)
        if state.errorMessage == nil { taskTitle = "" }
    }

    private func toggle(_ task: LoopTask) {
        if reduceMotion { state.toggleTask(task) }
        else { withAnimation(.easeInOut(duration: 0.18)) { state.toggleTask(task) } }
    }

    private var visibleTasks: [LoopTask] {
        state.workspace.tasks.filter { selectedListID == nil || $0.listID == selectedListID }
    }

    private func addList() {
        state.addList(newListName)
        if state.errorMessage == nil { newListName = "" }
    }
}

extension ThemeMode {
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

extension AccentChoice {
    var color: Color {
        switch self {
        case .blue: .blue
        case .indigo: .indigo
        case .teal: .teal
        case .orange: .orange
        }
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
    @State private var firstStep = ""
    @State private var estimateMinutes = 0
    @State private var colorTag = "Default"
    @State private var confirmDelete = false
    @State private var showingImporter = false
    @State private var newLink = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Task details").font(.title2.bold())
            TextField("Title", text: $title)
            TextField("Notes", text: $notes, axis: .vertical).lineLimit(3...6)
            TextField("First step", text: $firstStep)
            Stepper("Estimate: \(estimateMinutes == 0 ? "None" : "\(estimateMinutes) min")", value: $estimateMinutes, in: 0...480, step: 5)
            Picker("Appearance", selection: $colorTag) {
                ForEach(["Default", "Blue", "Teal", "Orange", "Purple"], id: \.self) { Text($0).tag($0) }
            }
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
                    if attachment.linkURLString != nil {
                        Image(systemName: "link").foregroundStyle(.secondary)
                    } else {
                        Text(ByteCountFormatter.string(fromByteCount: attachment.byteCount, countStyle: .file))
                            .foregroundStyle(.secondary)
                    }
                    Button("Remove", role: .destructive) { state.removeAttachment(attachment, from: task) }
                }
            }
            Button("Attach File") { showingImporter = true }
            HStack {
                TextField("Paste a link", text: $newLink)
                Button("Attach Link") {
                    state.addLink(to: task, rawURL: newLink)
                    if state.errorMessage == nil { newLink = "" }
                }
            }
            HStack {
                Button("Delete Task", role: .destructive) { confirmDelete = true }
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") {
                    state.updateTask(task, title: title, notes: notes, dueAt: hasDueDate ? dueAt : nil, priority: priority == 0 ? nil : priority, listID: listID, isStarred: isStarred, firstStep: firstStep, estimateMinutes: estimateMinutes == 0 ? nil : estimateMinutes, colorTag: colorTag == "Default" ? nil : colorTag)
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
            firstStep = task.firstStep ?? ""
            estimateMinutes = task.estimateMinutes ?? 0
            colorTag = task.colorTag ?? "Default"
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
