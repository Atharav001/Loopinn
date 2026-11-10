import LoopinnCore
import SwiftUI

struct FocusDashboardView: View {
    @ObservedObject var state: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SectionHeading("Make space for focus", subtitle: "One quiet session at a time")
                HStack(alignment: .center, spacing: 32) {
                    ZStack {
                        Circle().stroke(.secondary.opacity(0.14), lineWidth: 11)
                        Circle().trim(from: 0, to: progress)
                            .stroke(state.settings.accent.color, style: StrokeStyle(lineWidth: 11, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: progress)
                        VStack(spacing: 7) {
                            Text(timeText).font(.system(size: 48, weight: .medium, design: .rounded)).monospacedDigit()
                            Text(state.pomodoro.phase == .focus ? "FOCUS" : "BREAK")
                                .font(.caption.weight(.semibold)).tracking(3).foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 260, height: 260)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Cycle \(state.pomodoro.completedCycles + 1)").font(.title2.weight(.semibold))
                        Text(state.pomodoro.status == .running ? "Your session is in motion." : "Start when you're ready.")
                            .foregroundStyle(.secondary)
                        HStack {
                            if state.pomodoro.status == .running {
                                Button("Pause", systemImage: "pause.fill") { state.pausePomodoro() }
                                    .buttonStyle(.borderedProminent)
                            } else {
                                Button(state.pomodoro.status == .paused ? "Resume" : "Start Focus", systemImage: "play.fill") { state.startPomodoro() }
                                    .buttonStyle(.borderedProminent)
                            }
                            Button("Reset", systemImage: "arrow.counterclockwise") { state.resetPomodoro() }
                            Button("Floating Timer", systemImage: "square.on.square") { FloatingPanelManager.shared.showPomodoro(state: state) }
                        }
                    }
                }
                .padding(32)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
                HStack(spacing: 12) {
                    LoopinnCard {
                        Label("Focus", systemImage: "timer").foregroundStyle(.secondary)
                        Text("\(state.pomodoro.focusMinutes) min").font(.title2.weight(.semibold))
                    }
                    LoopinnCard {
                        Label("Break", systemImage: "cup.and.saucer").foregroundStyle(.secondary)
                        Text("\(state.pomodoro.breakMinutes) min").font(.title2.weight(.semibold))
                    }
                    LoopinnCard {
                        Label("Completed", systemImage: "checkmark.circle").foregroundStyle(.secondary)
                        Text("\(state.pomodoro.completedCycles)").font(.title2.weight(.semibold))
                    }
                }
            }
            .frame(maxWidth: 1000)
        }
    }

    private var progress: CGFloat {
        let total = Double((state.pomodoro.phase == .focus ? state.pomodoro.focusMinutes : state.pomodoro.breakMinutes) * 60)
        return CGFloat(max(0, min(1, 1 - state.pomodoro.remaining() / max(1, total))))
    }
    private var timeText: String {
        let seconds = Int(ceil(state.pomodoro.remaining()))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

struct FloatingPomodoroView: View {
    @ObservedObject var state: AppState

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Focus timer", systemImage: "timer").font(.headline)
                Spacer()
                Text("Cycle \(state.pomodoro.completedCycles + 1)").font(.caption).foregroundStyle(.secondary)
            }
            Text(String(format: "%02d:%02d", Int(ceil(state.pomodoro.remaining())) / 60, Int(ceil(state.pomodoro.remaining())) % 60))
                .font(.system(size: 52, weight: .medium, design: .rounded)).monospacedDigit()
            Text(state.pomodoro.phase == .focus ? "FOCUS" : "BREAK")
                .font(.caption.weight(.semibold)).tracking(3).foregroundStyle(.secondary)
            HStack {
                if state.pomodoro.status == .running {
                    Button("Pause", systemImage: "pause.fill") { state.pausePomodoro() }.buttonStyle(.borderedProminent)
                } else {
                    Button(state.pomodoro.status == .paused ? "Resume" : "Start", systemImage: "play.fill") { state.startPomodoro() }.buttonStyle(.borderedProminent)
                }
                Button("Reset", systemImage: "arrow.counterclockwise") { state.resetPomodoro() }
            }
        }
        .padding(24)
        .frame(minWidth: 300, minHeight: 210)
        .background(.ultraThinMaterial)
        .preferredColorScheme(state.settings.theme.colorScheme)
        .tint(state.settings.accent.color)
    }
}
