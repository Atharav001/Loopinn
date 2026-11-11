import AppKit
import LoopinnCore
import SwiftUI

/// Adapted from Aura-mac-app/Aura/Features/MenuBar/MenuBarView.swift.
/// Actions are routed to Loopinn's single workspace and panel manager.
struct AuraCommandMenu: View {
    @ObservedObject var state: AppState
    @Environment(\.openWindow) private var openWindow
    @State private var hoveredButton: String?
    @State private var quickTask = ""
    @State private var quickListID: UUID?
    @State private var justAdded = false
    @State private var hoveringAdd = false
    @FocusState private var quickFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
        .frame(width: 320)
        .fixedSize(horizontal: true, vertical: true)
        .background {
            LinearGradient(colors: [Color(nsColor: .windowBackgroundColor), state.settings.accent.color.opacity(0.09), Color(nsColor: .windowBackgroundColor)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(state.settings.accent.color.opacity(0.22), lineWidth: 1))
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
        HStack(spacing: 12) {
            Image(systemName: "circle.hexagongrid.fill")
                .font(.system(size: 17, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(LinearGradient(colors: [state.settings.accent.color, state.settings.accent.color.opacity(0.55)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: RoundedRectangle(cornerRadius: 11))
                .shadow(color: state.settings.accent.color.opacity(0.35), radius: 8, y: 3)
            VStack(alignment: .leading, spacing: 2) {
                Text("Loopinn").font(.system(size: 15, weight: .semibold))
                Text("Command Center").font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 18).padding(.top, 14).padding(.bottom, 10)
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
                    .padding(.horizontal, 11).padding(.vertical, 9)
                    .background(Color.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(state.settings.accent.color.opacity(quickFocused ? 0.75 : 0.16), lineWidth: quickFocused ? 2 : 1))
                Button(action: submitQuickTask) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 35, height: 35)
                        .background(LinearGradient(colors: [state.settings.accent.color, state.settings.accent.color.opacity(0.7)],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle())
                        .shadow(color: state.settings.accent.color.opacity(hoveringAdd ? 0.5 : 0.2), radius: hoveringAdd ? 9 : 4)
                        .scaleEffect(hoveringAdd && !reduceMotion ? 1.08 : 1)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.15)) { hoveringAdd = hovering }
                }
                .accessibilityLabel("Add task")
            }
            if let error = state.errorMessage {
                Text(error).font(.caption2).foregroundStyle(.red).lineLimit(2)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    private var commandCenterSection: some View {
        VStack(alignment: .leading, spacing: 6) {
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
        .padding(.horizontal, 14).padding(.vertical, 10)
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
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(accent)
                    .frame(width: 36, height: 36)
                    .background(LinearGradient(colors: [accent.opacity(0.25), accent.opacity(0.09)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.system(size: 12, weight: .semibold))
                    Text(subtitle).font(.system(size: 10)).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(isHovered ? accent : Color.secondary)
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .contentShape(Rectangle())
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isHovered ? accent.opacity(0.14) : Color.primary.opacity(0.045)))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(accent.opacity(isHovered ? 0.42 : 0.09), lineWidth: 1))
            .scaleEffect(isHovered && !reduceMotion ? 1.015 : 1)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.16)) { hoveredButton = hovering ? id : nil }
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
        // Allow the menu-bar popover to relinquish focus before opening a panel.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            NSApp.activate(ignoringOtherApps: true)
            action()
        }
    }
}
