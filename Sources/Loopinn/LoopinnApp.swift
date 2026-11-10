import AppKit
import LoopinnCore
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var workspace: Workspace
    @Published var errorMessage: String?
    @Published private(set) var canUndo = false
    private let service = WorkspaceService()
    private let fileURL: URL
    private var previousWorkspace: Workspace?

    init() {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Loopinn", isDirectory: true)
        fileURL = directory.appendingPathComponent("workspace.json")
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                workspace = try JSONDecoder().decode(Workspace.self, from: Data(contentsOf: fileURL))
            } else {
                workspace = Workspace()
            }
        } catch {
            workspace = Workspace()
            errorMessage = "Saved data could not be opened: \(error.localizedDescription)"
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

    func moveList(_ list: TaskList, by offset: Int) {
        mutate { try service.moveList(list.id, by: offset, in: &$0) }
    }

    func moveTask(_ task: LoopTask, by offset: Int) {
        mutate { try service.moveTask(task.id, by: offset, in: &$0) }
    }

    func undoLastChange() {
        guard let previousWorkspace else { return }
        do {
            try JSONEncoder().encode(previousWorkspace).write(to: fileURL, options: .atomic)
            workspace = previousWorkspace
            self.previousWorkspace = nil
            canUndo = false
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleTask(_ task: LoopTask) {
        mutate { try service.setCompleted(task.completedAt == nil, taskID: task.id, in: &$0) }
    }

    func schedule(_ task: LoopTask, start: Date?, end: Date?) {
        mutate { try service.schedule(taskID: task.id, startAt: start, endAt: end, in: &$0) }
    }

    private func mutate(_ change: (inout Workspace) throws -> Void) {
        var draft = workspace
        do {
            try change(&draft)
            let data = try JSONEncoder().encode(draft)
            try data.write(to: fileURL, options: .atomic)
            previousWorkspace = workspace
            canUndo = true
            workspace = draft
            errorMessage = nil
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
