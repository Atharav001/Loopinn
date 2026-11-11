import AppKit
import LoopinnCore
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var workspace: Workspace
    @Published private(set) var settings: AppSettings
    @Published var selectedPage: DashboardPage = .today
    @Published var errorMessage: String?
    @Published private(set) var canUndo = false
    @Published var dismissedRecommendationID: UUID?
    @Published private(set) var pomodoro: PomodoroSession
    @Published private(set) var utilityTimers: UtilityTimers
    @Published private(set) var focusReminder: FocusReminder
    @Published var focusReminderBanner: String?
    @Published private(set) var appleEvents: [ExternalCalendarEvent] = []
    @Published private(set) var appleCalendars: [CalendarChoice] = []
    @Published private(set) var appleCalendarConnected = false
    @Published private(set) var googleEvents: [ExternalCalendarEvent] = []
    @Published private(set) var googleCalendars: [CalendarChoice] = []
    @Published private(set) var googleCalendarConnected = false
    private let service = WorkspaceService()
    private let settingsStore = SettingsStore()
    private let pomodoroStore = PomodoroStore()
    private let utilityTimersStore = UtilityTimersStore()
    private let focusReminderStore = FocusReminderStore()
    private let appleCalendar = AppleCalendarService()
    private let googleCalendar = GoogleCalendarService()
    private var appleLoadedRange: DateInterval?
    private var googleLoadedRange: DateInterval?
    private var googleRefreshInFlight = false
    private var pendingGoogleDate: Date?
    private var timer: Timer?
    private var settingsWritable = true
    private var database: WorkspaceDatabase?
    private var attachmentStore: AttachmentStore?
    private var previousWorkspace: Workspace?
    private let dataDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Loopinn", isDirectory: true)
    var canEditSettings: Bool { settingsWritable }

    init() {
        var restoredPomodoro = (try? pomodoroStore.load()) ?? PomodoroSession()
        restoredPomodoro.reconcile()
        pomodoro = restoredPomodoro
        var restoredTimers = (try? utilityTimersStore.load()) ?? UtilityTimers()
        if restoredTimers.countdown.reconcile() { try? utilityTimersStore.save(restoredTimers) }
        utilityTimers = restoredTimers
        focusReminder = (try? focusReminderStore.load()) ?? FocusReminder()
        do {
            let loadedSettings = try settingsStore.load()
            settings = loadedSettings
        } catch {
            settings = AppSettings()
            settingsWritable = false
            errorMessage = "Saved settings could not be opened. Appearance editing is disabled: \(error.localizedDescription)"
        }
        do {
            let database = try WorkspaceDatabase(directory: dataDirectory)
            workspace = try database.load()
            self.database = database
            let attachmentStore = try AttachmentStore(directory: dataDirectory)
            self.attachmentStore = attachmentStore
            try? attachmentStore.prune(keeping: workspace.tasks.flatMap { $0.attachments ?? [] })
        } catch {
            workspace = Workspace()
            database = nil
            attachmentStore = nil
            errorMessage = "Saved data could not be opened. Editing is disabled to protect it: \(error.localizedDescription)"
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.reconcilePomodoro()
                self?.reconcileUtilityTimers()
                self?.reconcileFocusReminder()
            }
        }
        appleCalendarConnected = appleCalendar.isAuthorized
        if appleCalendarConnected { refreshAppleCalendar() }
        googleCalendarConnected = googleCalendar.isConnected && !(settings.googleClientID ?? "").isEmpty
        if googleCalendarConnected { refreshGoogleCalendar() }
    }

    func connectAppleCalendar() {
        Task {
            do {
                try await appleCalendar.requestAccess()
                appleCalendarConnected = true
                appleCalendars = appleCalendar.calendars()
                refreshAppleCalendar()
            } catch { errorMessage = error.localizedDescription }
        }
    }

    func refreshAppleCalendar(around date: Date = .now, force: Bool = false) {
        guard appleCalendar.isAuthorized else {
            appleCalendarConnected = false
            appleEvents = []
            appleCalendars = []
            appleLoadedRange = nil
            return
        }
        appleCalendarConnected = true
        appleCalendars = appleCalendar.calendars()
        if !force, appleLoadedRange?.contains(date) == true { return }
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .month, value: -1, to: date) ?? date
        let end = calendar.date(byAdding: .month, value: 13, to: date) ?? date
        do {
            appleEvents = try appleCalendar.events(from: start, to: end)
            appleLoadedRange = DateInterval(start: start, end: end)
        }
        catch { errorMessage = error.localizedDescription }
    }

    func setShowAppleEvents(_ enabled: Bool) {
        var draft = settings
        draft.showAppleEvents = enabled
        saveSettings(draft)
    }

    func setAppleCalendarVisible(_ id: String, visible: Bool) {
        var draft = settings
        var hidden = Set(draft.hiddenAppleCalendarIDs ?? [])
        if visible { hidden.remove(id) } else { hidden.insert(id) }
        draft.hiddenAppleCalendarIDs = hidden.sorted()
        saveSettings(draft)
    }

    var visibleAppleEvents: [ExternalCalendarEvent] {
        guard settings.showAppleEvents != false else { return [] }
        let hidden = Set(settings.hiddenAppleCalendarIDs ?? [])
        let visible = appleEvents.filter { !hidden.contains($0.calendarID) }
        var seen: Set<String> = []
        return visible.filter { event in
            guard event.isHoliday else { return true }
            return seen.insert("\(event.title)|\(event.startAt.timeIntervalSince1970)|\(event.endAt.timeIntervalSince1970)").inserted
        }
    }

    func setGoogleClientID(_ id: String) {
        var draft = settings
        draft.googleClientID = id.trimmingCharacters(in: .whitespacesAndNewlines)
        saveSettings(draft)
    }

    func setGoogleCalendarVisible(_ id: String, visible: Bool) {
        var draft = settings
        var hidden = Set(draft.hiddenGoogleCalendarIDs ?? [])
        if visible { hidden.remove(id) } else { hidden.insert(id) }
        draft.hiddenGoogleCalendarIDs = hidden.sorted()
        saveSettings(draft)
        if visible { refreshGoogleCalendar(force: true) }
    }

    func connectGoogleCalendar() {
        guard let clientID = settings.googleClientID else { errorMessage = GoogleCalendarError.missingClientID.localizedDescription; return }
        Task {
            do {
                try await googleCalendar.connect(clientID: clientID)
                googleCalendarConnected = true
                await loadGoogleCalendar(around: .now)
            } catch { errorMessage = error.localizedDescription }
        }
    }

    func disconnectGoogleCalendar() {
        do {
            try googleCalendar.disconnect()
            googleCalendarConnected = false
            googleEvents = []
            googleCalendars = []
            googleLoadedRange = nil
        } catch { errorMessage = error.localizedDescription }
    }

    func refreshGoogleCalendar(around date: Date = .now, force: Bool = false) {
        guard force || googleLoadedRange?.contains(date) != true else { return }
        Task { await loadGoogleCalendar(around: date) }
    }

    private func loadGoogleCalendar(around date: Date) async {
        guard googleCalendar.isConnected, let clientID = settings.googleClientID, !clientID.isEmpty else { return }
        guard !googleRefreshInFlight else { pendingGoogleDate = date; return }
        googleRefreshInFlight = true
        defer {
            googleRefreshInFlight = false
            if let pendingGoogleDate {
                self.pendingGoogleDate = nil
                Task { await loadGoogleCalendar(around: pendingGoogleDate) }
            }
        }
        do {
            let choices = try await googleCalendar.calendars(clientID: clientID)
            googleCalendars = choices
            let start = Calendar.current.date(byAdding: .month, value: -1, to: date) ?? date
            let end = Calendar.current.date(byAdding: .month, value: 13, to: date) ?? date
            var events: [ExternalCalendarEvent] = []
            for choice in choices where !(settings.hiddenGoogleCalendarIDs ?? []).contains(choice.id) {
                events += try await googleCalendar.events(calendarID: choice.id, calendarTitle: choice.title, from: start, to: end, clientID: clientID)
            }
            googleEvents = events
            googleLoadedRange = DateInterval(start: start, end: end)
        } catch { errorMessage = error.localizedDescription }
    }

    var visibleGoogleEvents: [ExternalCalendarEvent] {
        let hidden = Set(settings.hiddenGoogleCalendarIDs ?? [])
        return googleEvents.filter { !hidden.contains($0.calendarID.replacingOccurrences(of: "google:", with: "")) }
    }

    var visibleCalendarEvents: [ExternalCalendarEvent] {
        var seenHolidays: Set<String> = []
        return (visibleAppleEvents + visibleGoogleEvents).filter { event in
            guard event.isHoliday else { return true }
            let day = Calendar.current.startOfDay(for: event.startAt).timeIntervalSince1970
            return seenHolidays.insert("\(event.title.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current))|\(day)").inserted
        }
    }

    func publishGoogleBlock(_ block: CalendarBlock, title: String, calendarID: String) {
        guard let clientID = settings.googleClientID else { errorMessage = GoogleCalendarError.missingClientID.localizedDescription; return }
        Task {
            do {
                let link = try await googleCalendar.publish(block: block, title: title, calendarID: calendarID, clientID: clientID)
                mutate { try service.recordPublishedEvent(link, for: block.id, in: &$0) }
                refreshGoogleCalendar(around: block.startAt, force: true)
            } catch { errorMessage = error.localizedDescription }
        }
    }

    func unpublishGoogleBlock(_ block: CalendarBlock, link: ExternalCalendarLink) {
        guard let clientID = settings.googleClientID else { errorMessage = GoogleCalendarError.missingClientID.localizedDescription; return }
        Task {
            do {
                try await googleCalendar.remove(link, clientID: clientID)
                mutate { try service.removePublishedEvent(link, from: block.id, in: &$0) }
                refreshGoogleCalendar(around: block.startAt, force: true)
            } catch { errorMessage = error.localizedDescription }
        }
    }

    func publishAppleBlock(_ block: CalendarBlock, title: String, calendarID: String) {
        do {
            let link = try appleCalendar.publish(block: block, title: title, calendarID: calendarID)
            mutate { try service.recordPublishedEvent(link, for: block.id, in: &$0) }
            refreshAppleCalendar(around: block.startAt, force: true)
        } catch { errorMessage = error.localizedDescription }
    }

    func unpublishAppleBlock(_ block: CalendarBlock, link: ExternalCalendarLink) {
        do {
            try appleCalendar.remove(link)
            mutate { try service.removePublishedEvent(link, from: block.id, in: &$0) }
            refreshAppleCalendar(around: block.startAt, force: true)
        } catch { errorMessage = error.localizedDescription }
    }

    private func reconcilePomodoro() {
        let previous = pomodoro
        pomodoro.reconcile()
        if pomodoro != previous { try? pomodoroStore.save(pomodoro) }
        objectWillChange.send()
    }

    func startPomodoro() {
        pomodoro.start()
        savePomodoro()
    }

    func startDeepWork(minutes: Int, taskID: UUID?) {
        pomodoro.startDeepWork(minutes: minutes, taskID: taskID)
        savePomodoro()
    }

    func pausePomodoro() {
        pomodoro.pause()
        savePomodoro()
    }

    func resetPomodoro() {
        pomodoro.reset()
        savePomodoro()
    }

    private func savePomodoro() {
        do { try pomodoroStore.save(pomodoro); errorMessage = nil }
        catch { errorMessage = error.localizedDescription }
    }

    private func reconcileUtilityTimers() {
        if utilityTimers.countdown.reconcile() {
            saveUtilityTimers()
            NSSound.beep()
        }
        if utilityTimers.stopwatch.status == .running || utilityTimers.countdown.status == .running {
            objectWillChange.send()
        }
    }

    func startStopwatch() { utilityTimers.stopwatch.start(); saveUtilityTimers() }
    func pauseStopwatch() { utilityTimers.stopwatch.pause(); saveUtilityTimers() }
    func lapStopwatch() { utilityTimers.stopwatch.addLap(); saveUtilityTimers() }
    func resetStopwatch() { utilityTimers.stopwatch.reset(); saveUtilityTimers() }
    func startCountdown() { utilityTimers.countdown.start(); saveUtilityTimers() }
    func pauseCountdown() { utilityTimers.countdown.pause(); saveUtilityTimers() }
    func resetCountdown() { utilityTimers.countdown.reset(); saveUtilityTimers() }
    func setCountdownMinutes(_ minutes: Int) { utilityTimers.countdown.setDuration(minutes: minutes); saveUtilityTimers() }

    private func saveUtilityTimers() {
        do { try utilityTimersStore.save(utilityTimers); errorMessage = nil }
        catch { errorMessage = error.localizedDescription }
    }

    private func reconcileFocusReminder() {
        guard focusReminder.reconcile() else { return }
        do {
            try focusReminderStore.save(focusReminder)
            focusReminderBanner = "Time for a short focus check-in."
            NSSound.beep()
            NSApp.requestUserAttention(.informationalRequest)
        } catch { errorMessage = error.localizedDescription }
    }

    func setFocusReminderEnabled(_ enabled: Bool) {
        focusReminder.setEnabled(enabled)
        if !enabled { focusReminderBanner = nil }
        saveFocusReminder()
    }

    func setFocusReminderInterval(_ minutes: Int) {
        focusReminder.setInterval(minutes: minutes)
        saveFocusReminder()
    }

    func snoozeFocusReminder() {
        focusReminder.snooze()
        focusReminderBanner = nil
        saveFocusReminder()
    }

    func dismissFocusReminder() { focusReminderBanner = nil }

    private func saveFocusReminder() {
        do { try focusReminderStore.save(focusReminder); errorMessage = nil }
        catch { errorMessage = error.localizedDescription }
    }

    func setTheme(_ theme: ThemeMode) {
        var draft = settings
        draft.theme = theme
        saveSettings(draft)
    }

    func setAccent(_ accent: AccentChoice) {
        var draft = settings
        draft.accent = accent
        saveSettings(draft)
    }

    func resetAppearance() {
        var draft = settings
        draft.theme = .system
        draft.accent = .blue
        draft.compactLayout = false
        saveSettings(draft)
    }

    func setCompactLayout(_ enabled: Bool) {
        var draft = settings
        draft.compactLayout = enabled
        saveSettings(draft)
    }

    func setShowTodayPlan(_ enabled: Bool) {
        var draft = settings
        draft.showTodayPlan = enabled
        saveSettings(draft)
    }

    func setPinFloatingTasks(_ enabled: Bool) {
        var draft = settings
        draft.pinFloatingTasks = enabled
        saveSettings(draft)
        if errorMessage == nil { FloatingPanelManager.shared.setPinned(enabled) }
    }

    func setShowDockIcon(_ enabled: Bool) {
        var draft = settings
        draft.showDockIcon = enabled
        saveSettings(draft)
        if errorMessage == nil { NSApp.setActivationPolicy(enabled ? .regular : .accessory) }
    }

    func completeOnboarding() {
        var draft = settings
        draft.hasCompletedOnboarding = true
        saveSettings(draft)
    }

    func reopenOnboarding() {
        var draft = settings
        draft.hasCompletedOnboarding = false
        saveSettings(draft)
    }

    func exportBackup(to destination: URL) {
        guard database != nil else { errorMessage = "The local database is unavailable."; return }
        do {
            try WorkspaceBackup.create(workspace: workspace, settings: settings,
                                       attachmentsDirectory: dataDirectory.appendingPathComponent("attachments"),
                                       at: destination)
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }

    func restoreBackup(from source: URL) {
        guard let database, settingsWritable else { errorMessage = "Saved data is unavailable to restore."; return }
        let accessed = source.startAccessingSecurityScopedResource()
        defer { if accessed { source.stopAccessingSecurityScopedResource() } }
        do {
            let snapshot = try WorkspaceBackup.inspect(at: source)
            let safetyDirectory = dataDirectory.appendingPathComponent("backups", isDirectory: true)
            try FileManager.default.createDirectory(at: safetyDirectory, withIntermediateDirectories: true)
            let safetyURL = safetyDirectory.appendingPathComponent("before-restore-\(UUID().uuidString).loopinnbackup", isDirectory: true)
            try WorkspaceBackup.create(workspace: workspace, settings: settings,
                                       attachmentsDirectory: dataDirectory.appendingPathComponent("attachments"),
                                       at: safetyURL)
            try WorkspaceBackup.installAttachments(from: source, workspace: snapshot.workspace,
                                                   into: dataDirectory.appendingPathComponent("attachments"))
            try database.save(snapshot.workspace)
            do { try settingsStore.save(snapshot.settings) }
            catch {
                try? database.save(workspace)
                throw error
            }
            previousWorkspace = workspace
            canUndo = true
            workspace = snapshot.workspace
            settings = snapshot.settings
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }

    func eraseLocalData() {
        guard let database, let attachmentStore, settingsWritable else {
            errorMessage = "Saved data is unavailable to erase."
            return
        }
        do {
            let empty = Workspace()
            var freshSettings = AppSettings()
            freshSettings.hasCompletedOnboarding = true
            try database.save(empty)
            workspace = empty
            previousWorkspace = nil
            canUndo = false
            try attachmentStore.prune(keeping: [])
            let backups = dataDirectory.appendingPathComponent("backups", isDirectory: true)
            if FileManager.default.fileExists(atPath: backups.path) { try FileManager.default.removeItem(at: backups) }
            try settingsStore.save(freshSettings)
            settings = freshSettings
            try googleCalendar.disconnect()
            googleCalendarConnected = false
            googleEvents = []
            googleCalendars = []
            pomodoro.reset()
            try pomodoroStore.save(pomodoro)
            utilityTimers = UtilityTimers()
            try utilityTimersStore.save(utilityTimers)
            focusReminder = FocusReminder()
            try focusReminderStore.save(focusReminder)
            focusReminderBanner = nil
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }

    private func saveSettings(_ draft: AppSettings) {
        guard settingsWritable else {
            errorMessage = "Settings are unavailable to edit."
            return
        }
        do {
            try settingsStore.save(draft)
            settings = draft
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addTask(_ title: String) {
        guard let listID = workspace.lists.first?.id else { errorMessage = "No task list is available."; return }
        addTask(title, to: listID)
    }

    func addTask(_ title: String, to listID: UUID) {
        mutate { try service.addTask(to: &$0, title: title, listID: listID) }
    }

    func captureTasks(_ text: String, to listID: UUID) {
        mutate { try service.captureTasks(text, listID: listID, in: &$0) }
    }

    func addList(_ name: String) {
        mutate { try service.addList(named: name, to: &$0) }
    }

    func renameList(_ list: TaskList, to name: String) {
        mutate { try service.renameList(list.id, to: name, in: &$0) }
    }

    func deleteList(_ list: TaskList) {
        guard let destination = workspace.lists.first(where: { $0.id != list.id }) else { errorMessage = "Keep at least one list."; return }
        mutate { try service.deleteList(list.id, movingTasksTo: destination.id, in: &$0) }
    }

    func updateTask(_ task: LoopTask, title: String, notes: String, dueAt: Date?, priority: Int?, listID: UUID, isStarred: Bool, firstStep: String?, estimateMinutes: Int?, colorTag: String?) {
        mutate { try service.updateTask(task.id, title: title, notes: notes, dueAt: dueAt, priority: priority, listID: listID, isStarred: isStarred, firstStep: firstStep, estimateMinutes: estimateMinutes, colorTag: colorTag, in: &$0) }
    }

    func deleteTask(_ task: LoopTask) {
        mutate { try service.deleteTask(task.id, in: &$0) }
    }

    func addAttachment(to task: LoopTask, from source: URL) {
        guard let attachmentStore else { errorMessage = "Attachment storage is unavailable."; return }
        do {
            let attachment = try attachmentStore.copy(source)
            mutate { try service.addAttachment(attachment, to: task.id, in: &$0) }
            if errorMessage != nil { try? attachmentStore.remove(attachment) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeAttachment(_ attachment: TaskAttachment, from task: LoopTask) {
        mutate { try service.removeAttachment(attachment.id, from: task.id, in: &$0) }
    }

    func addLink(to task: LoopTask, rawURL: String) {
        guard let url = URL(string: rawURL.trimmingCharacters(in: .whitespacesAndNewlines)),
              (url.scheme == "https" || url.scheme == "http"), let host = url.host else {
            errorMessage = "Enter a valid http or https link."
            return
        }
        let attachment = TaskAttachment(id: UUID(), originalName: host, storedName: "", byteCount: 0, linkURLString: url.absoluteString)
        mutate { try service.addAttachment(attachment, to: task.id, in: &$0) }
    }

    func openAttachment(_ attachment: TaskAttachment) {
        if let string = attachment.linkURLString, let url = URL(string: string) {
            NSWorkspace.shared.open(url)
            return
        }
        guard let attachmentStore else { errorMessage = "Attachment storage is unavailable."; return }
        let url = attachmentStore.fileURL(for: attachment)
        guard FileManager.default.fileExists(atPath: url.path) else {
            errorMessage = "The attachment file is missing."
            return
        }
        NSWorkspace.shared.open(url)
    }

    func moveList(_ list: TaskList, by offset: Int) {
        mutate { try service.moveList(list.id, by: offset, in: &$0) }
    }

    func moveTask(_ task: LoopTask, by offset: Int) {
        mutate { try service.moveTask(task.id, by: offset, in: &$0) }
    }

    func undoLastChange() {
        guard let previousWorkspace, let database else { return }
        do {
            try database.save(previousWorkspace)
            workspace = previousWorkspace
            self.previousWorkspace = nil
            canUndo = false
            errorMessage = nil
            try? attachmentStore?.prune(keeping: workspace.tasks.flatMap { $0.attachments ?? [] })
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleTask(_ task: LoopTask) {
        mutate { try service.setCompleted(task.completedAt == nil, taskID: task.id, in: &$0) }
    }

    var nextTask: LoopTask? {
        guard let recommendation = TaskRecommendations.next(in: workspace, excluding: dismissedRecommendationID) else { return nil }
        return workspace.tasks.first { $0.id == recommendation.taskID }
    }

    var nextTaskReason: String? { TaskRecommendations.next(in: workspace, excluding: dismissedRecommendationID)?.reason }

    func schedule(_ task: LoopTask, start: Date?, end: Date?) {
        mutate { try service.schedule(taskID: task.id, startAt: start, endAt: end, in: &$0) }
    }

    func createBlock(title: String, start: Date, end: Date) {
        mutate { try service.createBlock(title: title, startAt: start, endAt: end, in: &$0) }
    }

    func updateBlock(_ block: CalendarBlock, title: String, start: Date, end: Date) {
        mutate { try service.updateBlock(block.id, title: title, startAt: start, endAt: end, in: &$0) }
    }

    func deleteBlock(_ block: CalendarBlock) {
        mutate { try service.deleteBlock(block.id, in: &$0) }
    }

    private func mutate(_ change: (inout Workspace) throws -> Void) {
        guard let database else {
            errorMessage = "The local database is unavailable. Editing is disabled to protect saved data."
            return
        }
        var draft = workspace
        do {
            try change(&draft)
            try database.save(draft)
            previousWorkspace = workspace
            canUndo = true
            workspace = draft
            errorMessage = nil
            if let attachmentStore {
                let current = draft.tasks.flatMap { $0.attachments ?? [] }
                let previous = previousWorkspace?.tasks.flatMap { $0.attachments ?? [] } ?? []
                try? attachmentStore.prune(keeping: current + previous)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let settings = try? SettingsStore().load()
        NSApp.setActivationPolicy(settings?.showDockIcon == true ? .regular : .accessory)
    }
}

@main
struct LoopinnApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var state = AppState()

    var body: some Scene {
        MenuBarExtra("Loopinn", systemImage: "circle.hexagongrid.fill") {
            MenuContent(state: state)
        }
        Window("Loopinn", id: "dashboard") {
            DashboardView(state: state)
                .frame(minWidth: 900, minHeight: 600)
        }
        .defaultLaunchBehavior(.suppressed)
        .commands { DashboardCommands(state: state) }
    }
}
