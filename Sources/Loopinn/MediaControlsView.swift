import AppKit
import SwiftUI

private enum MusicSource: String, CaseIterable, Identifiable {
    case music = "Apple Music", spotify = "Spotify"
    var id: Self { self }
    var bundleID: String { self == .music ? "com.apple.Music" : "com.spotify.client" }
    var appName: String { self == .music ? "Music" : "Spotify" }
}

struct MediaControlsView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var source: MusicSource = .music
    @State private var title = ""
    @State private var artist = ""
    @State private var isPlaying = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Music", systemImage: "music.note").font(.headline)
                Spacer()
                Picker("Player", selection: $source) {
                    ForEach(MusicSource.allCases) { Text($0.rawValue).tag($0) }
                }
                .frame(width: 170)
                Button("Refresh", action: refresh)
            }
            if let errorMessage { Text(errorMessage).font(.subheadline).foregroundStyle(.secondary) }
            else {
                Text(title.isEmpty ? "No track selected" : title).font(.title3.weight(.semibold))
                Text(artist).foregroundStyle(.secondary)
                if isPlaying && !reduceMotion && !ProcessInfo.processInfo.isLowPowerModeEnabled {
                    TimelineView(.animation) { context in
                        HStack(alignment: .bottom, spacing: 5) {
                            ForEach(0..<12, id: \.self) { index in
                                Capsule().fill(.tint)
                                    .frame(width: 6, height: 8 + 22 * abs(sin(context.date.timeIntervalSinceReferenceDate * 2.5 + Double(index))))
                            }
                        }
                        .frame(height: 34)
                        .accessibilityLabel("Music is playing")
                    }
                }
                HStack {
                    Button("Previous", systemImage: "backward.fill") { command("previous track") }
                    Button(isPlaying ? "Pause" : "Play", systemImage: isPlaying ? "pause.fill" : "play.fill") { command("playpause") }
                        .buttonStyle(.borderedProminent)
                    Button("Next", systemImage: "forward.fill") { command("next track") }
                }
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .onChange(of: source) { _, _ in refresh() }
        .onAppear(perform: refresh)
    }

    private func command(_ action: String) {
        guard run("tell application \"\(source.appName)\" to \(action)") != nil else { return }
        refresh()
    }

    private func refresh() {
        guard !NSRunningApplication.runningApplications(withBundleIdentifier: source.bundleID).isEmpty else {
            title = ""; artist = ""; isPlaying = false
            errorMessage = "\(source.rawValue) is not running. Open it to use these controls."
            return
        }
        let script = "tell application \"\(source.appName)\" to return (player state as text) & \"|||\" & (name of current track) & \"|||\" & (artist of current track)"
        guard let result = run(script) else { return }
        let parts = result.components(separatedBy: "|||")
        guard parts.count == 3 else { errorMessage = "The player did not provide track details."; return }
        isPlaying = parts[0].lowercased() == "playing"
        title = parts[1]
        artist = parts[2]
        errorMessage = nil
    }

    private func run(_ sourceText: String) -> String? {
        guard let script = NSAppleScript(source: sourceText) else { errorMessage = "Could not prepare the player command."; return nil }
        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)
        if let error {
            errorMessage = "Music control is unavailable: \(error[NSAppleScript.errorMessage] ?? "Permission or player error")"
            return nil
        }
        return result.stringValue ?? ""
    }
}
