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

    private var lists: [TaskList] { state.workspace.lists }
    private var targetListID: UUID { quickListID.flatMap { id in lists.first(where: { $0.id == id })?.id } ?? lists.first?.id ?? UUID() }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider().padding(.horizontal, 16)
            quickAddSection
            Divider().padding(.horizontal, 16)
            ScrollView {
                commandCenterSection
            }
            .frame(maxHeight: 470)
            Divider().padding(.horizontal, 16)
            settingsRow
            Divider().padding(.horizontal, 16)
            footerSection
        }
        .frame(width: 320)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(state.settings.accent.color.opacity(0.85), in: RoundedRectangle(cornerRadius: 9))
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
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13, weight: .medium))
                    .onSubmit(submitQuickTask)
                Button(action: submitQuickTask) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 24, weight: .semibold))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add task")
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    private var commandCenterSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("QUICK ACTIONS")
            actionRow(id: "pomodoro", icon: "timer", title: "Pomodoro Timer", subtitle: "Floating focus and break timer") {
                FloatingPanelManager.shared.showPomodoro(state: state)
            }
            actionRow(id: "focus", icon: "brain.head.profile", title: "Focus", subtitle: "Deep Work and timer settings") { show(.focus) }
            actionRow(id: "ripple", icon: "circle.dotted.circle", title: "Ripple Focus", subtitle: "Flexible interval alerts") {
                FloatingPanelManager.shared.showRipple(state: state)
            }
            actionRow(id: "tasks", icon: "checklist", title: "To-Do Lists", subtitle: "Floating task editor") {
                FloatingPanelManager.shared.showTasks(state: state)
            }
            actionRow(id: "calendar", icon: "calendar", title: "Calendar", subtitle: "Day, week, month and year") { show(.calendar) }
            actionRow(id: "today", icon: "sun.max", title: "Today", subtitle: "Your daily overview") { show(.today) }
            actionRow(id: "planner", icon: "calendar.badge.plus", title: "Planner", subtitle: "Plan tasks and time blocks") { show(.planner) }
            actionRow(id: "logbook", icon: "clock.badge.checkmark", title: "Logbook", subtitle: "Timesheet and activity history") { show(.logbook) }
            actionRow(id: "timeline", icon: "timeline.selection", title: "Timesheet", subtitle: "Planned and logged time rails") { show(.timeline) }
            actionRow(id: "log", icon: "square.and.pencil", title: "Log Activity", subtitle: "Quick floating entry") {
                FloatingPanelManager.shared.showQuickLog(state: state)
            }
            actionRow(id: "application", icon: "macwindow", title: "Open Application", subtitle: "All Loopinn sections") { show(.today) }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    private var settingsRow: some View {
        actionRow(id: "settings", icon: "gearshape", title: "Settings", subtitle: "Appearance, calendar and focus") { show(.settings) }
            .padding(.horizontal, 14).padding(.vertical, 6)
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
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 13, weight: .semibold)).frame(width: 20)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.system(size: 12, weight: .medium))
                    Text(subtitle).font(.system(size: 10)).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 9)).foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .contentShape(Rectangle())
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(hoveredButton == id ? Color.primary.opacity(0.10) : Color.primary.opacity(0.05)))
        }
        .buttonStyle(.plain)
        .onHover { hoveredButton = $0 ? id : nil }
    }

    private func submitQuickTask() {
        let trimmed = quickTask.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, lists.contains(where: { $0.id == targetListID }) else { return }
        state.addTask(trimmed, to: targetListID)
        guard state.errorMessage == nil else { return }
        quickTask = ""
        justAdded = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { justAdded = false }
    }

    private func show(_ page: DashboardPage) {
        state.selectedPage = page
        openWindow(id: "dashboard")
        NSApp.activate(ignoringOtherApps: true)
    }
}
