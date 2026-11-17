import LoopinnCore
import SwiftUI

struct RippleFocusView: View {
    @ObservedObject var state: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var interval = 60
    @State private var nextAlert: Date?
    private let intervals = [10, 30, 60, 120, 180, 300, 600]

    var body: some View {
        GeometryReader { geometry in
        let dialSize = min(124, max(84, geometry.size.height - 180))
        VStack(spacing: 10) {
            TimelineView(.periodic(from: .now, by: 0.25)) { timeline in
                let remaining = max(0, Int(ceil(nextAlert?.timeIntervalSince(timeline.date) ?? Double(interval))))
                ZStack {
                    Circle().stroke(state.settings.accent.color.opacity(0.12), lineWidth: 8)
                    Circle().trim(from: 0, to: nextAlert == nil ? 0 : CGFloat(1 - Double(remaining) / Double(interval)))
                        .stroke(state.settings.accent.color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: remaining)
                    Text("\(remaining)s").font(.system(size: 30, weight: .medium, design: .rounded)).monospacedDigit()
                }
                .frame(width: dialSize, height: dialSize)
            }
            Picker("Alert every", selection: $interval) {
                ForEach(intervals, id: \.self) { seconds in
                    Text(seconds < 60 ? "\(seconds) seconds" : "\(seconds / 60) minute\(seconds == 60 ? "" : "s")").tag(seconds)
                }
            }
            .onChange(of: interval) { _, _ in if nextAlert != nil { nextAlert = .now.addingTimeInterval(Double(interval)) } }
            Text("A sharp double bell sounds at each interval.")
                .font(.caption).foregroundStyle(.secondary)
            HStack {
                Button(nextAlert == nil ? "Start" : "Stop") {
                    if nextAlert == nil {
                        nextAlert = .now.addingTimeInterval(Double(interval))
                        state.triggerRippleAlert()
                    } else { nextAlert = nil }
                }
                .buttonStyle(.borderedProminent)
                if nextAlert != nil { Button("Restart") { nextAlert = .now.addingTimeInterval(Double(interval)) } }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onReceive(Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()) { date in
            if let nextAlert, date >= nextAlert {
                state.triggerRippleAlert()
                self.nextAlert = date.addingTimeInterval(Double(interval))
            }
        }
    }
}
