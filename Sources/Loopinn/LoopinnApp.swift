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
    private let service = WorkspaceService()
    private let settingsStore = SettingsStore()
    private var settingsWritable = true
    private var database: WorkspaceDatabase?
    private var attachmentStore: AttachmentStore?
    private var previousWorkspace: Workspace?
    private let dataDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Loopinn", isDirectory: true)
    var canEditSettings: Bool { settingsWritable }

    init() {
        do {
            settings = try settingsStore.load()
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
        var draft = AppSettings()
        draft.hasCompletedOnboarding = settings.hasCompletedOnboarding
        draft.showTodayPlan = settings.showTodayPlan
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

    func updateTask(_ task: LoopTask, title: String, notes: String, dueAt: Date?, priority: Int?, listID: UUID, isStarred: Bool) {
        mutate { try service.updateTask(task.id, title: title, notes: notes, dueAt: dueAt, priority: priority, listID: listID, isStarred: isStarred, in: &$0) }
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

    func openAttachment(_ attachment: TaskAttachment) {
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
        workspace.tasks.first(where: { $0.completedAt == nil })
    }

    func schedule(_ task: LoopTask, start: Date?, end: Date?) {
        mutate { try service.schedule(taskID: task.id, startAt: start, endAt: end, in: &$0) }
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
        NSApp.setActivationPolicy(.accessory)
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
    }
}
