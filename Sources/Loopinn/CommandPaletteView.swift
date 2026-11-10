import SwiftUI

private enum QuickCommand: String, CaseIterable, Identifiable {
    case floatingTasks = "Show floating tasks"
    case completeNext = "Complete next task"
    var id: Self { self }
    var symbol: String { self == .floatingTasks ? "square.on.square" : "checkmark.circle" }
}

struct CommandPaletteView: View {
    @ObservedObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @FocusState private var searchFocused: Bool

    private var pages: [DashboardPage] {
        DashboardPage.allCases.filter {
            query.isEmpty || $0.rawValue.localizedCaseInsensitiveContains(query)
        }
    }

    private var commands: [QuickCommand] {
        QuickCommand.allCases.filter { query.isEmpty || $0.rawValue.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField("Where would you like to go?", text: $query)
                .textFieldStyle(.plain)
                .font(.title3)
                .focused($searchFocused)
            Divider()
            if pages.isEmpty && commands.isEmpty {
                ContentUnavailableView.search(text: query)
            } else {
                ForEach(pages) { page in
                    Button {
                        state.selectedPage = page
                        dismiss()
                    } label: {
                        Label(page.rawValue, systemImage: page.icon)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
                if !commands.isEmpty { Divider() }
                ForEach(commands) { command in
                    Button {
                        switch command {
                        case .floatingTasks: FloatingPanelManager.shared.showTasks(state: state)
                        case .completeNext:
                            if let task = state.nextTask { state.toggleTask(task) }
                        }
                        dismiss()
                    } label: {
                        Label(command.rawValue, systemImage: command.symbol)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    .disabled(command == .completeNext && state.nextTask == nil)
                }
            }
            Text("⌘K opens commands while the dashboard is active")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 460)
        .onAppear { searchFocused = true }
    }
}
