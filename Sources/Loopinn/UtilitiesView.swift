import LoopinnCore
import SwiftUI

struct UtilitiesView: View {
    @ObservedObject var state: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Utilities").font(.title2.bold())
                Text("Files and clipboard text are saved only when you choose to add them.")
                    .foregroundStyle(.secondary)
                MediaControlsView()
                SystemUtilitiesView()
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label("File shelf", systemImage: "folder").font(.headline)
                        Spacer()
                        Button("Add File", systemImage: "plus") { state.addShelfFile() }
                    }
                    if state.utilityShelf.files.isEmpty { Text("No saved files").foregroundStyle(.secondary) }
                    ForEach(state.utilityShelf.files) { file in
                        HStack {
                            Button(file.name) { state.openShelfFile(file) }
                            Spacer()
                            Button("Remove", role: .destructive) { state.removeShelfFile(file.id) }
                        }
                    }
                }
                .padding(20).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label("Clipboard", systemImage: "doc.on.clipboard").font(.headline)
                        Spacer()
                        Button("Capture Current Text") { state.captureClipboard() }
                    }
                    Text("Capture is manual. Review clipboard text before saving sensitive information.")
                        .font(.caption).foregroundStyle(.secondary)
                    if state.utilityShelf.clips.isEmpty { Text("No captured text").foregroundStyle(.secondary) }
                    ForEach(state.utilityShelf.clips) { clip in
                        HStack {
                            Text(clip.text).lineLimit(2)
                            Spacer()
                            Button("Copy") { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(clip.text, forType: .string) }
                            Button(clip.isPinned ? "Unpin" : "Pin") { state.toggleClipPin(clip.id) }
                            Button("Remove", role: .destructive) { state.removeClip(clip.id) }
                        }
                        .padding(10)
                        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(20).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
            }
        }
    }
}
