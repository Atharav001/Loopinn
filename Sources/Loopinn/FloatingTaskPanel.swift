import AppKit
import LoopinnCore
import SwiftUI

@MainActor
final class FloatingPanelManager: ObservableObject {
    static let shared = FloatingPanelManager()
    private var panels: [String: NSPanel] = [:]
    @Published private(set) var pinned: [String: Bool] = [:]
    private let tasksID = "tasks"
    private let pomodoroID = "pomodoro"
    private let rippleID = "ripple"
    private let quickLogID = "quick-log"

    func setPinned(_ pinned: Bool) {
        setPinned(pinned, for: tasksID)
    }

    func isPinned(_ id: String) -> Bool {
        pinned[id] ?? UserDefaults.standard.object(forKey: "Loopinn.\(id).pinned") as? Bool ?? true
    }

    func togglePinned(_ id: String) {
        setPinned(!isPinned(id), for: id)
    }

    private func setPinned(_ value: Bool, for id: String) {
        pinned[id] = value
        UserDefaults.standard.set(value, forKey: "Loopinn.\(id).pinned")
        panels[id]?.level = value ? .floating : .normal
        panels[id]?.collectionBehavior = value ? [.canJoinAllSpaces, .fullScreenAuxiliary] : [.moveToActiveSpace, .fullScreenAuxiliary]
    }

    func showTasks(state: AppState) {
        show(id: tasksID, title: "Loopinn Tasks", size: NSSize(width: 360, height: 450), state: state, content: AnyView(FloatingTasksView(state: state)))
    }

    func showPomodoro(state: AppState) {
        show(id: pomodoroID, title: "Loopinn Focus", size: NSSize(width: 350, height: 330), state: state, content: AnyView(FloatingPomodoroView(state: state)))
    }

    func showRipple(state: AppState) {
        show(id: rippleID, title: "Ripple Focus", size: NSSize(width: 370, height: 420), state: state, content: AnyView(RippleFocusView(state: state)))
    }

    func showQuickLog(state: AppState) {
        show(id: quickLogID, title: "Log activity", size: NSSize(width: 440, height: 400), state: state, content: AnyView(QuickLogView(state: state)))
    }

    private func show(id: String, title: String, size: NSSize, state: AppState, content: AnyView) {
        if id == tasksID { setPinned(state.settings.pinFloatingTasks != false, for: tasksID) }
        if let panel = panels[id] {
            panel.hidesOnDeactivate = false
            panel.level = isPinned(id) ? .floating : .normal
            NSApp.activate(ignoringOtherApps: true)
            panel.orderFrontRegardless()
            panel.makeKeyAndOrderFront(nil)
            return
        }
        let panel = NSPanel(
            contentRect: NSRect(origin: NSPoint(x: 120, y: 120), size: size),
            styleMask: [.titled, .closable, .resizable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = title
        panel.hidesOnDeactivate = false
        panel.level = isPinned(id) ? .floating : .normal
        panel.collectionBehavior = isPinned(id) ? [.canJoinAllSpaces, .fullScreenAuxiliary] : [.moveToActiveSpace, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.titlebarAppearsTransparent = false
        panel.titleVisibility = .visible
        panel.hasShadow = true
        panel.minSize = NSSize(width: id == quickLogID ? 390 : 280,
                               height: id == rippleID ? 390 : (id == quickLogID ? 380 : 285))
        panel.setFrameAutosaveName("Loopinn.\(id).Panel")
        if let screen = NSScreen.screens.first(where: { $0.visibleFrame.contains(NSPoint(x: panel.frame.midX, y: panel.frame.midY)) }) ?? NSScreen.main {
            var frame = panel.frame
            let visible = screen.visibleFrame
            frame.origin.x = min(max(frame.origin.x, visible.minX), visible.maxX - frame.width)
            frame.origin.y = min(max(frame.origin.y, visible.minY), visible.maxY - frame.height)
            panel.setFrame(frame, display: false)
        }
        panel.contentView = NSHostingView(rootView: FloatingPanelChrome(id: id, title: title, state: state, content: content))
        panels[id] = panel
        let animate = !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        if animate { panel.alphaValue = 0 }
        NSApp.activate(ignoringOtherApps: true)
        panel.orderFrontRegardless()
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

private struct FloatingPanelChrome: View {
    @ObservedObject private var manager = FloatingPanelManager.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hoveringPin = false
    let id: String
    let title: String
    @ObservedObject var state: AppState
    let content: AnyView

    private var accent: Color {
        switch id {
        case "pomodoro": .orange
        case "ripple": .cyan
        case "tasks": .green
        default: .purple
        }
    }

    private var icon: String {
        switch id {
        case "pomodoro": "timer"
        case "ripple": "waveform.path"
        case "tasks": "checklist"
        default: "clock.badge.checkmark"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(accent)
                    .frame(width: 32, height: 32)
                    .background(accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 9))
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.subheadline.weight(.semibold)).lineLimit(1)
                    Text(manager.isPinned(id) ? "Always on top" : "Regular window")
                        .font(.system(size: 10)).foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    if id == "tasks" { state.setPinFloatingTasks(!manager.isPinned(id)) }
                    else { manager.togglePinned(id) }
                } label: {
                    Image(systemName: manager.isPinned(id) ? "pin.fill" : "pin")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 32, height: 28)
                        .foregroundStyle(manager.isPinned(id) ? accent : Color.secondary)
                        .background(accent.opacity(hoveringPin ? 0.25 : 0.12), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(accent.opacity(hoveringPin ? 0.45 : 0.15)))
                        .scaleEffect(hoveringPin && !reduceMotion ? 1.08 : 1)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.15)) { hoveringPin = hovering }
                }
                .help(manager.isPinned(id) ? "Unpin window from the top" : "Pin window above other apps")
                .accessibilityLabel(manager.isPinned(id) ? "Unpin window" : "Pin window")
            }
            .padding(.leading, 18).padding(.trailing, 12).padding(.top, 9).padding(.bottom, 9)
            .background(LinearGradient(colors: [accent.opacity(0.18), Color(nsColor: .windowBackgroundColor).opacity(0.85)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(alignment: .bottom) { Rectangle().fill(accent.opacity(0.25)).frame(height: 1) }
            content.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .preferredColorScheme(state.settings.theme.colorScheme)
        .tint(state.settings.accent.color)
    }

    private func addTask() {
        state.addTask(draft, to: selectedListID ?? state.workspace.lists[0].id)
        if state.errorMessage == nil { draft = "" }
    }
}
