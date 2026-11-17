import AppKit
import LoopinnCore
import SwiftUI

/// Adapted from Aura-mac-app/Aura/Features/MenuBar/MenuBarView.swift.
/// Actions are routed to Loopinn's single workspace and panel manager.
struct AuraCommandMenu: View {
    @ObservedObject var state: AppState
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) private var dismissMenu
    @State private var hoveredButton: String?
    @State private var quickTask = ""
    @State private var quickListID: UUID?
    @State private var justAdded = false
    @FocusState private var quickFocused: Bool

    private var lists: [TaskList] { state.workspace.lists }
    private var targetListID: UUID { quickListID.flatMap { id in lists.first(where: { $0.id == id })?.id } ?? lists.first?.id ?? UUID() }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider().padding(.horizontal, 16)
            quickAddSection
            Divider().padding(.horizontal, 16)
            commandCenterSection
            Divider().padding(.horizontal, 16)
            actionRow(id: "application", icon: "rectangle.3.group.fill", title: "Open Application", subtitle: "Browse all Loopinn sections") { show(.today) }
                .padding(.horizontal, 14).padding(.vertical, 6)
            Divider().padding(.horizontal, 16)
            footerSection
        }
        .frame(width: 300)
        .fixedSize(horizontal: true, vertical: true)
        .background(.regularMaterial)
        .onAppear { quickListID = targetListID }
        .onChange(of: lists.map(\.id)) { _, _ in quickListID = targetListID }
        .preferredColorScheme(state.settings.theme.colorScheme)
        .tint(state.settings.accent.color)
        .onOpenURL { url in
            state.handleWidgetURL(url)
            openWindow(id: "dashboard")
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private var headerSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "circle.hexagongrid.fill")
                .font(.system(size: 14, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(state.settings.accent.color, in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 2) {
                Text("Loopinn").font(.system(size: 15, weight: .semibold))
                Text("Command Center").font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 10)
    }

    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                sectionLabel("NEW TASK")
                Spacer()
                if justAdded { Text("Added ✓").font(.system(size: 10, weight: .semibold)).foregroundStyle(.green) }
            }
            if lists.count > 1 {
                Picker("List", selection: $quickListID) {
                    ForEach(lists) { list in Text(list.name).tag(Optional(list.id)) }
                }
                .labelsHidden().pickerStyle(.menu)
            }
            HStack(spacing: 8) {
                TextField("Type a task and press Enter…", text: $quickTask)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium))
                    .focused($quickFocused)
                    .onSubmit(submitQuickTask)
                    .padding(.horizontal, 10).padding(.vertical, 8)
                    .background(Color.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 9))
                Button(action: submitQuickTask) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(state.settings.accent.color, in: RoundedRectangle(cornerRadius: 9))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add task")
            }
            if let error = state.errorMessage {
                Text(error).font(.caption2).foregroundStyle(.red).lineLimit(2)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 9)
    }

    private var commandCenterSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionLabel("QUICK ACTIONS")
            actionRow(id: "pomodoro", icon: "timer", title: "Pomodoro Timer", subtitle: "Floating focus and break timer") {
                launch { FloatingPanelManager.shared.showPomodoro(state: state) }
            }
            actionRow(id: "ripple", icon: "waveform.path", title: "Ripple Focus", subtitle: "Flexible interval alerts") {
                launch { FloatingPanelManager.shared.showRipple(state: state) }
            }
            actionRow(id: "tasks", icon: "checklist", title: "To-Do Lists", subtitle: "Floating task editor") {
                launch { FloatingPanelManager.shared.showTasks(state: state) }
            }
            actionRow(id: "log", icon: "clock.badge.checkmark", title: "Log Activity", subtitle: "Quick floating entry") {
                launch { FloatingPanelManager.shared.showQuickLog(state: state) }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
    }

    private var footerSection: some View {
        HStack {
            Button("Quit Loopinn") { NSApp.terminate(nil) }
                .buttonStyle(.plain).foregroundStyle(.secondary).font(.system(size: 11))
            Spacer()
            Text("Stored locally").font(.system(size: 10)).foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title).font(.system(size: 10, weight: .semibold)).tracking(1.1)
            .foregroundStyle(.tertiary).padding(.leading, 4)
    }

    private func actionRow(id: String, icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        let accent = rowColor(for: id)
        let isHovered = hoveredButton == id
        return Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(accent)
                    .frame(width: 30, height: 30)
                    .background(accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.system(size: 12, weight: .semibold))
                    Text(subtitle).font(.system(size: 10)).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(isHovered ? accent : Color.secondary)
            }
            .padding(.horizontal, 10).padding(.vertical, 7)
            .contentShape(Rectangle())
            .background(RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(isHovered ? accent.opacity(0.11) : Color.primary.opacity(0.035)))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.16)) { hoveredButton = hovering ? id : nil }
        }
    }

    private func rowColor(for id: String) -> Color {
        switch id {
        case "pomodoro": .orange
        case "ripple": .cyan
        case "tasks": .green
        case "log": .purple
        default: state.settings.accent.color
        }
    }

    private func submitQuickTask() {
        let trimmed = quickTask.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { quickFocused = true; return }
        guard lists.contains(where: { $0.id == targetListID }) else {
            state.errorMessage = "Create a task list in the application first."
            return
        }
        state.addTask(trimmed, to: targetListID)
        guard state.errorMessage == nil else { return }
        quickTask = ""
        justAdded = true
        closeMenu()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { justAdded = false }
    }

    private func show(_ page: DashboardPage) {
        state.selectedPage = page
        launch {
            openWindow(id: "dashboard")
            NSApp.activate(ignoringOtherApps: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                NSApp.windows.first(where: { $0.title == "Loopinn" })?.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    private func launch(_ action: @escaping () -> Void) {
        // Close the menu popover before activating another window.
        closeMenu()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            NSApp.activate(ignoringOtherApps: true)
            action()
        }
    }

    private func closeMenu() {
        let presentingWindow = NSApp.keyWindow
        dismissMenu()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
            if let presentingWindow, presentingWindow.isVisible && presentingWindow.isKeyWindow {
                presentingWindow.orderOut(nil)
            }
        }
    }
}
