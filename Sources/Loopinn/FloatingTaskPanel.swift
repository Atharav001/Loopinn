import AppKit
import LoopinnCore
import SwiftUI

@MainActor
final class FloatingPanelManager {
    static let shared = FloatingPanelManager()
    private var panels: [String: NSPanel] = [:]
    private let tasksID = "tasks"
    private let pomodoroID = "pomodoro"

    func setPinned(_ pinned: Bool) {
        panels[tasksID]?.level = .floating
    }

    func showTasks(state: AppState) {
        show(id: tasksID, title: "Loopinn Tasks", size: NSSize(width: 360, height: 450), content: AnyView(FloatingTasksView(state: state)))
    }

    func showPomodoro(state: AppState) {
        show(id: pomodoroID, title: "Loopinn Focus", size: NSSize(width: 340, height: 280), content: AnyView(FloatingPomodoroView(state: state)))
    }

    private func show(id: String, title: String, size: NSSize, content: AnyView) {
        if let panel = panels[id] {
            panel.makeKeyAndOrderFront(nil)
            return
        }
        let panel = NSPanel(
            contentRect: NSRect(origin: NSPoint(x: 120, y: 120), size: size),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = title
        panel.level = .floating
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.hasShadow = true
        panel.minSize = NSSize(width: 300, height: id == tasksID ? 300 : 220)
        panel.setFrameAutosaveName("Loopinn.\(id).Panel")
        if let screen = NSScreen.screens.first(where: { $0.visibleFrame.contains(NSPoint(x: panel.frame.midX, y: panel.frame.midY)) }) ?? NSScreen.main {
            var frame = panel.frame
            let visible = screen.visibleFrame
            frame.origin.x = min(max(frame.origin.x, visible.minX), visible.maxX - frame.width)
            frame.origin.y = min(max(frame.origin.y, visible.minY), visible.maxY - frame.height)
            panel.setFrame(frame, display: false)
        }
        panel.contentView = NSHostingView(rootView: content)
        panels[id] = panel
        let animate = !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        if animate { panel.alphaValue = 0 }
        panel.makeKeyAndOrderFront(nil)
        if animate {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().alphaValue = 1
            }
        }
    }
}

private struct FloatingTasksView: View {
    @ObservedObject var state: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedListID: UUID?
    @State private var draft = ""

    private var visibleTasks: [LoopTask] {
        state.workspace.tasks.filter { $0.completedAt == nil && (selectedListID == nil || $0.listID == selectedListID) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Tasks", systemImage: "checklist").font(.headline)
                Spacer()
                Text("\(state.workspace.tasks.filter { $0.completedAt == nil }.count) open")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Picker("List", selection: $selectedListID) {
                Text("All Lists").tag(UUID?.none)
                ForEach(state.workspace.lists) { list in Text(list.name).tag(Optional(list.id)) }
            }
            .labelsHidden()
            HStack {
                TextField("Add a task…", text: $draft).onSubmit(addTask)
                Button("Add", systemImage: "plus", action: addTask).labelStyle(.iconOnly)
                    .buttonStyle(.borderedProminent)
            }
            Divider()
            if visibleTasks.isEmpty {
                ContentUnavailableView("All caught up", systemImage: "checkmark.circle")
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(visibleTasks) { task in
                            HStack(alignment: .top) {
                                Button {
                                    if reduceMotion { state.toggleTask(task) }
                                    else { withAnimation(.easeInOut(duration: 0.18)) { state.toggleTask(task) } }
                                } label: { Image(systemName: "circle") }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Complete \(task.title)")
                                Text(task.title).lineLimit(2)
                                Spacer(minLength: 0)
                            }
                            .padding(10)
                            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }
        }
        .padding(18)
        .frame(minWidth: 300, minHeight: 300)
        .background(.ultraThinMaterial)
        .preferredColorScheme(state.settings.theme.colorScheme)
        .tint(state.settings.accent.color)
    }

    private func addTask() {
        state.addTask(draft, to: selectedListID ?? state.workspace.lists[0].id)
        if state.errorMessage == nil { draft = "" }
    }
}
