import AppKit
import LoopinnCore
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var workspace: Workspace
    @Published var errorMessage: String?
    private let service = WorkspaceService()
    private let fileURL: URL

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
        mutate { try service.addTask(to: &$0, title: title, listID: $0.lists[0].id) }
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
