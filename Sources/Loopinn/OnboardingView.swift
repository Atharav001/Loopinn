import SwiftUI

struct OnboardingView: View {
    @ObservedObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0

    private let pages: [(symbol: String, title: String, detail: String)] = [
        ("circle.hexagongrid.fill", "Welcome to Loopinn", "Plan your day from the menu bar. Open the dashboard only when you need more room."),
        ("checklist", "Capture what matters", "Tasks, lists and attachments stay on your Mac. Set both a start and end time to place a task in your local plan."),
        ("hand.raised", "Your data stays yours", "Tasks and plans stay on this Mac. Connect a calendar only when you want to view its events, and confirm each event before publishing. Cloud sync is not active.")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Image(systemName: pages[step].symbol)
                .font(.system(size: 42, weight: .medium))
                .foregroundStyle(state.settings.accent.color)
                .accessibilityHidden(true)
            Text(pages[step].title).font(.largeTitle.bold())
            Text(pages[step].detail)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 6) {
                ForEach(pages.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == step ? state.settings.accent.color : Color.secondary.opacity(0.25))
                        .frame(width: index == step ? 26 : 8, height: 8)
                }
            }
            Spacer()
            HStack {
                Button("Skip") { finish() }
                Spacer()
                if step > 0 { Button("Back") { step -= 1 } }
                Button(step == pages.count - 1 ? "Get Started" : "Continue") {
                    if step == pages.count - 1 { finish() }
                    else { step += 1 }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(36)
        .frame(width: 520, height: 390)
    }

    private func finish() {
        state.completeOnboarding()
        dismiss()
    }
}
