import AppKit
import LoopinnCore
import SwiftUI

@MainActor
final class ScreenAlertOverlay {
    static let shared = ScreenAlertOverlay()
    private var panels: [NSPanel] = []
    private var generation = 0

    func show(label: String, color: Color, duration: Double, intensity: Double) {
        panels.forEach { $0.orderOut(nil) }
        panels.removeAll()
        generation += 1
        let currentGeneration = generation
        let end = Date.now.addingTimeInterval(duration)
        for screen in NSScreen.screens {
            let panel = NSPanel(contentRect: screen.frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            panel.level = .statusBar
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            panel.ignoresMouseEvents = true
            panel.hidesOnDeactivate = false
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = false
            panel.contentView = NSHostingView(rootView: ScreenAlertView(label: label, color: color, end: end, intensity: intensity))
            panel.orderFrontRegardless()
            panels.append(panel)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            guard let self, self.generation == currentGeneration else { return }
            self.panels.forEach { $0.orderOut(nil) }
            self.panels.removeAll()
        }
    }
}

private struct ScreenAlertView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let label: String
    let color: Color
    let end: Date
    let intensity: Double

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.08)) { context in
            let remaining = max(0, end.timeIntervalSince(context.date))
            let pulse = reduceMotion ? 0.55 : 0.42 + 0.36 * abs(sin(context.date.timeIntervalSinceReferenceDate * 7))
            let strength = (0.35 + 0.65 * min(1, max(0, intensity))) * pulse * min(1, remaining * 2)
            GeometryReader { geometry in
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(color.opacity(strength), lineWidth: 5)
                        .shadow(color: color.opacity(strength), radius: 22)
                        .shadow(color: color.opacity(strength * 0.75), radius: 45)
                        .padding(3)
                    if geometry.size.height > 300 {
                        Label(label, systemImage: "sparkle")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.horizontal, 18).padding(.vertical, 10)
                            .background(.regularMaterial, in: Capsule())
                            .overlay(Capsule().strokeBorder(color.opacity(strength), lineWidth: 1))
                            .opacity(remaining > 0 ? min(1, remaining * 2) : 0)
                            .padding(.top, 28)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .allowsHitTesting(false)
    }
}

@MainActor
final class FloatingPanelManager: ObservableObject {
    static let shared = FloatingPanelManager()
    private var panels: [String: NSPanel] = [:]
    @Published private(set) var pinned: [String: Bool] = [:]
    @Published private(set) var compact: [String: Bool] = [:]
    private var expandedFrames: [String: NSRect] = [:]
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

    func isCompact(_ id: String) -> Bool { compact[id] == true }

    func toggleCompact(_ id: String) {
        guard let panel = panels[id], id != quickLogID else { return }
        if isCompact(id) {
            compact[id] = false
            panel.minSize = NSSize(width: 280, height: id == rippleID ? 330 : 255)
            if let frame = expandedFrames[id] { panel.setFrame(frame, display: true, animate: true) }
        } else {
            expandedFrames[id] = panel.frame
            compact[id] = true
            panel.minSize = NSSize(width: 210, height: 88)
            dock(id, on: .right, y: panel.frame.midY)
        }
    }

    enum Edge { case left, right }

    func dock(_ id: String, on edge: Edge, y: CGFloat? = nil) {
        guard let panel = panels[id], let screen = panel.screen ?? NSScreen.main else { return }
        let visible = screen.visibleFrame
        var frame = panel.frame
        frame.size = NSSize(width: 210, height: 88)
        frame.origin.x = edge == .left ? visible.minX : visible.maxX - frame.width
        frame.origin.y = min(max((y ?? frame.midY) - frame.height / 2, visible.minY), visible.maxY - frame.height)
        panel.setFrame(frame, display: true, animate: true)
    }

    func moveDocked(_ id: String, by offset: CGFloat) {
        guard let panel = panels[id], let screen = panel.screen ?? NSScreen.main else { return }
        let edge: Edge = panel.frame.midX < screen.visibleFrame.midX ? .left : .right
        dock(id, on: edge, y: panel.frame.midY - offset)
    }

    private func setPinned(_ value: Bool, for id: String) {
        pinned[id] = value
        UserDefaults.standard.set(value, forKey: "Loopinn.\(id).pinned")
        panels[id]?.level = value ? .floating : .normal
        panels[id]?.collectionBehavior = value ? [.canJoinAllSpaces, .fullScreenAuxiliary] : [.moveToActiveSpace, .fullScreenAuxiliary]
    }

    func showTasks(state: AppState) {
        show(id: tasksID, title: "Tasks", size: NSSize(width: 340, height: 390), state: state, content: AnyView(FloatingTasksView(state: state)))
    }

    func showPomodoro(state: AppState) {
        show(id: pomodoroID, title: "Focus timer", size: NSSize(width: 330, height: 340), state: state, content: AnyView(FloatingPomodoroView(state: state)))
    }

    func showRipple(state: AppState) {
        show(id: rippleID, title: "Ripple Focus", size: NSSize(width: 340, height: 350), state: state, content: AnyView(RippleFocusView(state: state)))
    }

    func showQuickLog(state: AppState) {
        show(id: quickLogID, title: "Log activity", size: NSSize(width: 380, height: 260), state: state, content: AnyView(QuickLogView(state: state)))
    }

    func hideQuickLog() {
        panels[quickLogID]?.orderOut(nil)
    }

    private func show(id: String, title: String, size: NSSize, state: AppState, content: AnyView) {
        if id == tasksID { setPinned(state.settings.pinFloatingTasks != false, for: tasksID) }
        if let panel = panels[id] {
            if id == quickLogID { panel.setContentSize(NSSize(width: 380, height: 260)) }
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
        panel.minSize = NSSize(width: id == quickLogID ? 340 : 280,
                               height: id == rippleID ? 330 : (id == quickLogID ? 250 : (id == pomodoroID ? 310 : 255)))
        panel.setFrameAutosaveName("Loopinn.\(id).Panel")
        if id == quickLogID { panel.setContentSize(NSSize(width: 380, height: 260)) }
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
    @State private var dragStartY: CGFloat?

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
            HStack(spacing: 9) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(accent)
                    .frame(width: 28, height: 28)
                    .background(accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
                Text(title).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                Spacer()
                if id != "quick-log" {
                    Button {
                        manager.toggleCompact(id)
                    } label: {
                        Image(systemName: manager.isCompact(id) ? "arrow.up.left.and.arrow.down.right" : "rectangle.compress.vertical")
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .help(manager.isCompact(id) ? "Expand window" : "Dock as edge bar")
                }
                Button {
                    if id == "tasks" { state.setPinFloatingTasks(!manager.isPinned(id)) }
                    else { manager.togglePinned(id) }
                } label: {
                    Image(systemName: manager.isPinned(id) ? "pin.fill" : "pin")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 30, height: 28)
                        .foregroundStyle(manager.isPinned(id) ? accent : Color.secondary)
                        .background(hoveringPin ? accent.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.easeOut(duration: 0.15)) { hoveringPin = hovering }
                }
                .help(manager.isPinned(id) ? "Unpin window from the top" : "Pin window above other apps")
                .accessibilityLabel(manager.isPinned(id) ? "Unpin window" : "Pin window")
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.7))
            Divider()
            if manager.isCompact(id) {
                HStack {
                    if id == "pomodoro" {
                        Text(String(format: "%02d:%02d", Int(ceil(state.pomodoro.remaining())) / 60, Int(ceil(state.pomodoro.remaining())) % 60))
                            .monospacedDigit()
                    } else if id == "tasks" {
                        Text("\(state.workspace.tasks.filter { $0.completedAt == nil }.count) open tasks")
                    } else {
                        Text("Interval alerts")
                    }
                    Spacer()
                    Button("Left") { manager.dock(id, on: .left) }.buttonStyle(.plain).font(.caption)
                    Button("Right") { manager.dock(id, on: .right) }.buttonStyle(.plain).font(.caption)
                }
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .frame(maxHeight: .infinity)
                .gesture(DragGesture().onChanged { value in
                    if dragStartY == nil { dragStartY = value.translation.height }
                    manager.moveDocked(id, by: value.translation.height - (dragStartY ?? 0))
                    dragStartY = value.translation.height
                }.onEnded { _ in dragStartY = nil })
            } else {
                content.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
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
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(state.workspace.tasks.filter { $0.completedAt == nil }.count) open tasks")
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
            if visibleTasks.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle").font(.title2).foregroundStyle(.tertiary)
                    Text("All caught up").font(.subheadline).foregroundStyle(.secondary)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
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
                            .padding(9)
                            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 9))
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preferredColorScheme(state.settings.theme.colorScheme)
        .tint(state.settings.accent.color)
    }

    private func addTask() {
        state.addTask(draft, to: selectedListID ?? state.workspace.lists[0].id)
        if state.errorMessage == nil { draft = "" }
    }
}
