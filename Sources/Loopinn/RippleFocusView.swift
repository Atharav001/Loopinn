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
        let dialSize = min(150, max(90, geometry.size.height - 220))
        VStack(spacing: 14) {
            Label("Ripple Focus", systemImage: "circle.dotted.circle").font(.title2.bold())
            TimelineView(.periodic(from: .now, by: 0.25)) { timeline in
                let remaining = max(0, Int(ceil(nextAlert?.timeIntervalSince(timeline.date) ?? Double(interval))))
                ZStack {
                    Circle().stroke(state.settings.accent.color.opacity(0.18), lineWidth: 12)
                    Circle().trim(from: 0, to: nextAlert == nil ? 0 : CGFloat(1 - Double(remaining) / Double(interval)))
                        .stroke(state.settings.accent.color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: remaining)
                    Text("\(remaining)s").font(.system(size: 36, weight: .semibold, design: .rounded)).monospacedDigit()
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
                    nextAlert = nextAlert == nil ? .now.addingTimeInterval(Double(interval)) : nil
                }
                .buttonStyle(.borderedProminent)
                if nextAlert != nil { Button("Restart") { nextAlert = .now.addingTimeInterval(Double(interval)) } }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        }
        .onReceive(Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()) { date in
            if let nextAlert, date >= nextAlert {
                if state.settings.playAlertSound != false { RippleBell.shared.play() }
                self.nextAlert = date.addingTimeInterval(Double(interval))
            }
        }
    }
}
