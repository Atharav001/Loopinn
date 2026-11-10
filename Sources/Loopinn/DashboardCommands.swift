import SwiftUI

struct DashboardCommands: Commands {
    @ObservedObject var state: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandMenu("Navigate") {
            Button("Today") { show(.today) }
                .keyboardShortcut("1", modifiers: .command)
            Button("Tasks") { show(.tasks) }
                .keyboardShortcut("2", modifiers: .command)
            Button("Planner") { show(.planner) }
                .keyboardShortcut("3", modifiers: .command)
            Divider()
            Button("Settings") { show(.settings) }
                .keyboardShortcut(",", modifiers: .command)
        }
    }

    private func show(_ page: DashboardPage) {
        state.selectedPage = page
        openWindow(id: "dashboard")
        NSApp.activate(ignoringOtherApps: true)
    }
}
