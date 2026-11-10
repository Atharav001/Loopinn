import AppKit
import LoopinnCore
import SwiftUI

@MainActor
final class FloatingPanelManager {
    static let shared = FloatingPanelManager()
    private var taskPanel: NSPanel?

    func setPinned(_ pinned: Bool) {
        taskPanel?.level = pinned ? .floating : .normal
    }

    func showTasks(state: AppState) {
        if let taskPanel {
            taskPanel.makeKeyAndOrderFront(nil)
            return
        }
        let panel = NSPanel(
            contentRect: NSRect(x: 120, y: 120, width: 350, height: 440),
            styleMask: [.titled, .closable, .resizable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = "Loopinn Tasks"
        panel.level = state.settings.pinFloatingTasks == false ? .normal : .floating
        panel.collectionBehavior = [.moveToActiveSpace]
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        panel.minSize = NSSize(width: 300, height: 300)
        panel.setFrameAutosaveName("Loopinn.TasksPanel")
        if let screen = NSScreen.screens.first(where: { $0.visibleFrame.contains(NSPoint(x: panel.frame.midX, y: panel.frame.midY)) }) ?? NSScreen.main {
            var frame = panel.frame
            let visible = screen.visibleFrame
            frame.origin.x = min(max(frame.origin.x, visible.minX), visible.maxX - frame.width)
            frame.origin.y = min(max(frame.origin.y, visible.minY), visible.maxY - frame.height)
            panel.setFrame(frame, display: false)
        }
        panel.contentView = NSHostingView(rootView: FloatingTasksView(state: state))
        taskPanel = panel
        panel.makeKeyAndOrderFront(nil)
    }
}

private struct FloatingTasksView: View {
    @ObservedObject var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Tasks", systemImage: "checklist").font(.headline)
                Spacer()
                Text("\(state.workspace.tasks.filter { $0.completedAt == nil }.count) open")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Divider()
            if state.workspace.tasks.allSatisfy({ $0.completedAt != nil }) {
                ContentUnavailableView("All caught up", systemImage: "checkmark.circle")
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(state.workspace.tasks.filter { $0.completedAt == nil }) { task in
                            HStack(alignment: .top) {
                                Button { state.toggleTask(task) } label: { Image(systemName: "circle") }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Complete \(task.title)")
                                Text(task.title).lineLimit(2)
                                Spacer(minLength: 0)
                            }
                        }
                    }
                }
            }
        }
        .padding(18)
        .frame(minWidth: 300, minHeight: 300)
        .preferredColorScheme(state.settings.theme.colorScheme)
        .tint(state.settings.accent.color)
    }
}
