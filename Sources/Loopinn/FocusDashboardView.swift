import LoopinnCore
import SwiftUI

struct FocusDashboardView: View {
    @ObservedObject var state: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var utilityMode: UtilityMode = .stopwatch
    @State private var deepWorkMinutes = 90
    @State private var deepWorkTaskID: UUID?

    private enum UtilityMode: String, CaseIterable {
        case stopwatch = "Stopwatch"
        case countdown = "Countdown"
    }

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
                            Text(state.pomodoro.mode == .deepWork ? "DEEP WORK" : (state.pomodoro.phase == .focus ? "FOCUS" : "BREAK"))
                                .font(.caption.weight(.semibold)).tracking(3).foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 260, height: 260)
                    VStack(alignment: .leading, spacing: 16) {
                        Text(state.pomodoro.mode == .deepWork ? "Deep Work session" : "Cycle \(state.pomodoro.completedCycles + 1)")
                            .font(.title2.weight(.semibold))
                        Text(state.pomodoro.status == .completed ? "Session complete." : (state.pomodoro.status == .running ? "Your session is in motion." : "Start when you're ready."))
                            .foregroundStyle(.secondary)
                        if let taskName = linkedTaskName {
                            Label(taskName, systemImage: "checkmark.circle").font(.subheadline)
                        }
                        HStack {
                            if state.pomodoro.status == .running {
                                Button("Pause", systemImage: "pause.fill") { state.pausePomodoro() }
                                    .buttonStyle(.borderedProminent)
                            } else if state.pomodoro.status != .completed {
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
                deepWorkCard
                focusReminderCard
                utilityTimersCard
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

    private var linkedTaskName: String? {
        guard state.pomodoro.mode == .deepWork, let id = state.pomodoro.linkedTaskID else { return nil }
        return state.workspace.tasks.first(where: { $0.id == id })?.title ?? "Linked task no longer available"
    }

    private var deepWorkCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Deep Work", systemImage: "moon.stars.fill").font(.title2.weight(.semibold))
            Text("Set aside a longer session. A task link stays visible, and time is never logged automatically.")
                .foregroundStyle(.secondary)
            Stepper("Length: \(deepWorkMinutes) minutes", value: $deepWorkMinutes, in: 30...240, step: 15)
            Picker("Focus on", selection: $deepWorkTaskID) {
                Text("No task").tag(nil as UUID?)
                ForEach(state.workspace.tasks.filter { $0.completedAt == nil }) { task in
                    Text(task.title).tag(Optional(task.id))
                }
            }
            .frame(maxWidth: 420)
            Button("Start Deep Work", systemImage: "play.fill") {
                state.startDeepWork(minutes: deepWorkMinutes, taskID: deepWorkTaskID)
            }
            .buttonStyle(.borderedProminent)
            .disabled(state.pomodoro.status == .running || state.pomodoro.status == .paused)
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
    }

    private var focusReminderCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Focus reminders", systemImage: "bell.badge").font(.title2.weight(.semibold))
            Text("Get one gentle check-in at each interval. Missed reminders never pile up.")
                .foregroundStyle(.secondary)
            Toggle("Repeat reminders", isOn: Binding(
                get: { state.focusReminder.isEnabled },
                set: { state.setFocusReminderEnabled($0) }
            ))
            if state.focusReminder.isEnabled {
                Stepper("Every \(state.focusReminder.intervalMinutes) minutes", value: Binding(
                    get: { state.focusReminder.intervalMinutes },
                    set: { state.setFocusReminderInterval($0) }
                ), in: 5...180, step: 5)
                if let next = state.focusReminder.nextFireAt {
                    Text("Next check-in \(next, style: .relative)")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Button("Snooze 10 minutes", systemImage: "moon.zzz") { state.snoozeFocusReminder() }
            }
            if let banner = state.focusReminderBanner {
                HStack {
                    Label(banner, systemImage: "bell.fill")
                    Spacer()
                    Button("Snooze") { state.snoozeFocusReminder() }
                    Button("Dismiss") { state.dismissFocusReminder() }
                }
                .padding(12)
                .background(state.settings.accent.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
    }

    private var utilityTimersCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("More ways to focus").font(.title2.weight(.semibold))
                    Text("Simple timers that keep their place when you leave.").foregroundStyle(.secondary)
                }
                Spacer()
                Picker("Timer", selection: $utilityMode) {
                    ForEach(UtilityMode.allCases, id: \.self) { mode in Text(mode.rawValue).tag(mode) }
                }
                .pickerStyle(.segmented)
                .frame(width: 260)
            }
            Group {
                switch utilityMode {
                case .stopwatch: stopwatchControls
                case .countdown: countdownControls
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: utilityMode)
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
    }

    private var stopwatchControls: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(timerText(state.utilityTimers.stopwatch.elapsed()))
                .font(.system(size: 44, weight: .medium, design: .rounded))
                .monospacedDigit()
                .accessibilityLabel("Stopwatch elapsed \(timerText(state.utilityTimers.stopwatch.elapsed()))")
            HStack {
                if state.utilityTimers.stopwatch.status == .running {
                    Button("Pause", systemImage: "pause.fill") { state.pauseStopwatch() }
                        .buttonStyle(.borderedProminent)
                    Button("Lap", systemImage: "flag.fill") { state.lapStopwatch() }
                } else {
                    Button(state.utilityTimers.stopwatch.status == .paused ? "Resume" : "Start", systemImage: "play.fill") {
                        state.startStopwatch()
                    }
                    .buttonStyle(.borderedProminent)
                }
                Button("Reset", systemImage: "arrow.counterclockwise") { state.resetStopwatch() }
                    .disabled(state.utilityTimers.stopwatch.status == .idle)
            }
            if !state.utilityTimers.stopwatch.laps.isEmpty {
                Divider()
                ForEach(Array(state.utilityTimers.stopwatch.laps.enumerated().reversed()), id: \.element.id) { index, lap in
                    HStack {
                        Text("Lap \(index + 1)")
                        Spacer()
                        Text(timerText(lap.split)).foregroundStyle(.secondary)
                        Text(timerText(lap.elapsed)).monospacedDigit()
                    }
                    .font(.subheadline)
                }
            }
        }
    }

    private var countdownControls: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(timerText(state.utilityTimers.countdown.remaining()))
                .font(.system(size: 44, weight: .medium, design: .rounded))
                .monospacedDigit()
                .accessibilityLabel("Countdown remaining \(timerText(state.utilityTimers.countdown.remaining()))")
            if state.utilityTimers.countdown.status == .idle || state.utilityTimers.countdown.status == .completed {
                Stepper("Duration: \(Int(state.utilityTimers.countdown.duration / 60)) minutes", value: Binding(
                    get: { Int(state.utilityTimers.countdown.duration / 60) },
                    set: { state.setCountdownMinutes($0) }
                ), in: 1...240)
            }
            if state.utilityTimers.countdown.status == .completed {
                Label("Time is up", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(state.settings.accent.color)
            }
            HStack {
                if state.utilityTimers.countdown.status == .running {
                    Button("Pause", systemImage: "pause.fill") { state.pauseCountdown() }
                        .buttonStyle(.borderedProminent)
                } else if state.utilityTimers.countdown.status != .completed {
                    Button(state.utilityTimers.countdown.status == .paused ? "Resume" : "Start", systemImage: "play.fill") {
                        state.startCountdown()
                    }
                    .buttonStyle(.borderedProminent)
                }
                Button("Reset", systemImage: "arrow.counterclockwise") { state.resetCountdown() }
                    .disabled(state.utilityTimers.countdown.status == .idle)
            }
        }
    }

    private func timerText(_ seconds: TimeInterval) -> String {
        let value = Int(max(0, seconds.rounded(.up)))
        return String(format: "%02d:%02d:%02d", value / 3600, (value / 60) % 60, value % 60)
    }
}

struct FloatingPomodoroView: View {
    @ObservedObject var state: AppState

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Focus timer", systemImage: "timer").font(.headline)
                Spacer()
                Text(state.pomodoro.mode == .deepWork ? "Deep Work" : "Cycle \(state.pomodoro.completedCycles + 1)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Text(String(format: "%02d:%02d", Int(ceil(state.pomodoro.remaining())) / 60, Int(ceil(state.pomodoro.remaining())) % 60))
                .font(.system(size: 52, weight: .medium, design: .rounded)).monospacedDigit()
            Text(state.pomodoro.mode == .deepWork ? "DEEP WORK" : (state.pomodoro.phase == .focus ? "FOCUS" : "BREAK"))
                .font(.caption.weight(.semibold)).tracking(3).foregroundStyle(.secondary)
            if state.pomodoro.mode == .deepWork, let id = state.pomodoro.linkedTaskID {
                Text(state.workspace.tasks.first(where: { $0.id == id })?.title ?? "Linked task no longer available")
                    .font(.subheadline).lineLimit(2)
            }
            HStack {
                if state.pomodoro.status == .running {
                    Button("Pause", systemImage: "pause.fill") { state.pausePomodoro() }.buttonStyle(.borderedProminent)
                } else if state.pomodoro.status != .completed {
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
