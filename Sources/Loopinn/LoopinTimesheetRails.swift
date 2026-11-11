import LoopinnCore
import SwiftUI

/// Adapted from Loopin-macOS/Views/Rails/TimesheetRailsView.swift.
/// The rails share Loopinn's planned blocks and activity logbook.
struct LoopinTimesheetRails: View {
    let day: Date
    let planned: [CalendarBlock]
    let logged: [ActivityEntry]
    let title: (CalendarBlock) -> String
    @State private var now = Date()
    @State private var showFullDay = true
    private let calendar = Calendar.current
    private let hourWidth: CGFloat = 64
    private let railHeight: CGFloat = 42
    private var hours: [Int] { showFullDay ? Array(0..<24) : Array(6..<23) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Timesheet", systemImage: "timeline.selection").font(.headline)
                Spacer()
                Button(showFullDay ? "24h" : "6am–11pm", systemImage: showFullDay ? "moon.zzz" : "moon.zzz.fill") {
                    withAnimation(.easeInOut(duration: 0.2)) { showFullDay.toggle() }
                }
                .font(.caption).buttonStyle(.borderless)
                legend("Planned", .blue)
                legend("Logged", .green)
            }
            ScrollView(.horizontal) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 0) {
                        ForEach(hours, id: \.self) { hour in
                            Text(String(format: "%02d:00", hour)).font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.secondary).frame(width: hourWidth, alignment: .leading)
                        }
                    }
                    rail("PLANNED", color: .blue, entries: planned.map { RailEntry(id: $0.id, title: title($0), start: $0.startAt, end: $0.endAt) })
                    rail("LOGGED", color: .green, entries: logged.map { RailEntry(id: $0.id, title: $0.title, start: $0.startAt, end: $0.endAt) })
                }
                .padding(.vertical, 5)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 17))
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { now = $0 }
    }

    private func legend(_ label: String, _ color: Color) -> some View {
        HStack(spacing: 4) { Circle().fill(color).frame(width: 7, height: 7); Text(label).font(.caption2) }
            .foregroundStyle(.secondary)
    }

    private func rail(_ label: String, color: Color, entries: [RailEntry]) -> some View {
        let width = CGFloat(hours.count) * hourWidth
        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 8).fill(.quaternary.opacity(0.3))
            HStack(spacing: 0) {
                ForEach(hours, id: \.self) { _ in
                    Rectangle().fill(.primary.opacity(0.08)).frame(width: 1)
                        .frame(width: hourWidth, height: railHeight, alignment: .leading)
                }
            }
            Text(label).font(.system(size: 9, weight: .bold)).foregroundStyle(color.opacity(0.7))
                .padding(.leading, 8).padding(.top, 15)
            ForEach(entries) { entry in
                if let placement = position(entry) {
                    Text(entry.title).font(.caption2.weight(.medium)).lineLimit(1)
                        .padding(.horizontal, 7).frame(width: placement.width, height: 28, alignment: .leading)
                        .background(color.opacity(0.35), in: RoundedRectangle(cornerRadius: 6))
                        .offset(x: placement.x, y: 7)
                        .help("\(entry.title) · \(entry.start.formatted(date: .omitted, time: .shortened))–\(entry.end.formatted(date: .omitted, time: .shortened))")
                }
            }
            if calendar.isDate(day, inSameDayAs: now), let x = positionOfNow {
                Rectangle().fill(.orange).frame(width: 2, height: railHeight).offset(x: x)
            }
        }
        .frame(width: width, height: railHeight)
    }

    private func position(_ entry: RailEntry) -> (x: CGFloat, width: CGFloat)? {
        let origin = calendar.startOfDay(for: day).addingTimeInterval(Double(hours.first ?? 0) * 3600)
        let visibleEnd = origin.addingTimeInterval(Double(hours.count) * 3600)
        let start = max(entry.start, origin)
        let end = min(entry.end, visibleEnd)
        guard end > start else { return nil }
        return (CGFloat(start.timeIntervalSince(origin) / 3600) * hourWidth,
                max(4, CGFloat(end.timeIntervalSince(start) / 3600) * hourWidth))
    }

    private var positionOfNow: CGFloat? {
        let origin = calendar.startOfDay(for: day).addingTimeInterval(Double(hours.first ?? 0) * 3600)
        let x = CGFloat(now.timeIntervalSince(origin) / 3600) * hourWidth
        return x >= 0 && x <= CGFloat(hours.count) * hourWidth ? x : nil
    }
}

private struct RailEntry: Identifiable {
    let id: UUID
    let title: String
    let start: Date
    let end: Date
}
