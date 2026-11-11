import Charts
import LoopinnCore
import SwiftUI

struct AnalyticsView: View {
    @ObservedObject var state: AppState
    @State private var selectedDate = Date()
    @State private var scope: CalendarScope = .week

    private var interval: DateInterval { CalendarLayout.interval(containing: selectedDate, scope: scope) }
    private var summary: ActivitySummary { ActivitySummary(entries: state.activityLogbook.entries, during: interval) }
    private var focus: FocusInsights { FocusInsights(records: state.pomodoro.focusHistory, during: interval) }
    private var categories: [(name: String, seconds: TimeInterval)] {
        summary.categorySeconds.map { ($0.key, $0.value) }.sorted { $0.seconds > $1.seconds }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("Activity insights").font(.title2.bold())
                    Spacer()
                    Picker("Period", selection: $scope) {
                        ForEach(CalendarScope.allCases) { option in Text(option.rawValue.capitalized).tag(option) }
                    }
                    .pickerStyle(.segmented).frame(width: 320)
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date).labelsHidden()
                }
                HStack(spacing: 12) {
                    metric("Tracked", value: String(format: "%.1f h", summary.trackedSeconds / 3600), icon: "clock")
                    metric("Entries", value: "\(summary.entryCount)", icon: "text.book.closed")
                    metric("Focused", value: String(format: "%.1f h", focus.focusedSeconds / 3600), icon: "timer")
                    metric("Sessions", value: "\(focus.completedSessions)", icon: "checkmark.circle")
                }
                Text("Tracked time comes only from activity entries. Planned calendar blocks are kept separate.")
                    .font(.subheadline).foregroundStyle(.secondary)
                Text("Focus time uses completed timer sessions and is separate from activity logs. Boundary splits are proportional when a session spans a period.")
                    .font(.caption).foregroundStyle(.secondary)
                if categories.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("No activity in this period", systemImage: "chart.bar").font(.headline)
                        Text("Record work in Logbook to see tracked time and categories here.")
                            .foregroundStyle(.secondary)
                        Button("Open Logbook", systemImage: "square.and.pencil") { state.selectedPage = .logbook }
                            .buttonStyle(.borderedProminent)
                    }
                    .padding(22)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
                } else {
                    Text("By category").font(.title3.bold())
                    Chart(categories, id: \.name) { category in
                        BarMark(x: .value("Hours", category.seconds / 3600), y: .value("Category", category.name))
                            .foregroundStyle(state.settings.accent.color)
                    }
                    .frame(height: max(180, CGFloat(categories.count * 48)))
                    .padding(20)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
                }
            }
        }
    }

    private func metric(_ title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon).foregroundStyle(.secondary)
            Text(value).font(.title.bold())
        }
        .padding(20).frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
}
