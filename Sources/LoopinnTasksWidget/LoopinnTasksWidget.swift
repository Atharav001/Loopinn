import LoopinnCore
import SwiftUI
import WidgetKit

private struct TaskEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTask]
}

private struct TaskProvider: TimelineProvider {
    func placeholder(in context: Context) -> TaskEntry { TaskEntry(date: .now, tasks: []) }
    func getSnapshot(in context: Context, completion: @escaping (TaskEntry) -> Void) {
        completion(TaskEntry(date: .now, tasks: WidgetSnapshotStore.load()?.tasks ?? []))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskEntry>) -> Void) {
        let entry = TaskEntry(date: .now, tasks: WidgetSnapshotStore.load()?.tasks ?? [])
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60))))
    }
}

private struct TaskWidgetView: View {
    let entry: TaskEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Loopinn Tasks", systemImage: "checklist").font(.headline)
            if entry.tasks.isEmpty {
                Text("All caught up").foregroundStyle(.secondary)
            } else {
                ForEach(entry.tasks.prefix(4)) { task in
                    Link(destination: URL(string: "loopinn://complete-task/\(task.id.uuidString)")!) {
                        Label(task.title, systemImage: "circle").lineLimit(1)
                    }
                }
            }
            Spacer(minLength: 0)
            Link("Add a task", destination: URL(string: "loopinn://tasks")!)
                .font(.caption.weight(.semibold))
        }
        .padding(14)
        .containerBackground(.regularMaterial, for: .widget)
    }
}

@main
struct LoopinnTasksWidget: Widget {
    let kind = "LoopinnTasksWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskProvider()) { entry in
            TaskWidgetView(entry: entry)
        }
        .configurationDisplayName("Loopinn Tasks")
        .description("See and complete your next tasks.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
