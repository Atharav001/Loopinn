import AVFoundation
import AppKit
import IOKit.ps
import SwiftUI

@MainActor
private final class CameraMirror: ObservableObject {
    @Published var errorMessage: String?
    @Published var isActive = false
    let session = AVCaptureSession()

    func start() {
        Task {
            guard await AVCaptureDevice.requestAccess(for: .video) else {
                errorMessage = "Allow camera access in System Settings to use the mirror."
                return
            }
            guard let camera = AVCaptureDevice.default(for: .video) else {
                errorMessage = "No camera is available on this Mac."
                return
            }
            do {
                let input = try AVCaptureDeviceInput(device: camera)
                guard session.canAddInput(input) else { errorMessage = "This camera cannot be opened."; return }
                session.addInput(input)
                session.startRunning()
                isActive = true
                errorMessage = nil
            } catch { errorMessage = error.localizedDescription }
        }
    }

    func stop() {
        if session.isRunning { session.stopRunning() }
        session.inputs.forEach(session.removeInput)
        isActive = false
    }
}

private struct MirrorPreview: NSViewRepresentable {
    let session: AVCaptureSession
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.connection?.automaticallyAdjustsVideoMirroring = false
        layer.connection?.isVideoMirrored = true
        view.layer = layer
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

struct SystemUtilitiesView: View {
    @StateObject private var mirror = CameraMirror()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Mac controls", systemImage: "macbook").font(.headline)
            Text(batteryDescription).foregroundStyle(.secondary)
            HStack {
                Button("Sound Settings") { openSettings("x-apple.systempreferences:com.apple.Sound-Settings.extension") }
                Button("Display Settings") { openSettings("x-apple.systempreferences:com.apple.Displays-Settings.extension") }
            }
            Text("Volume and brightness controls open macOS settings; direct control is unavailable here.")
                .font(.caption).foregroundStyle(.secondary)
            HStack {
                Text("Camera mirror").font(.headline)
                Spacer()
                Button(mirror.isActive ? "Close Mirror" : "Open Mirror") {
                    if mirror.isActive { mirror.stop() } else { mirror.start() }
                }
            }
            if let error = mirror.errorMessage { Text(error).font(.caption).foregroundStyle(.red) }
            if mirror.isActive {
                MirrorPreview(session: mirror.session)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .onDisappear { mirror.stop() }
    }

    private var batteryDescription: String {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef],
              let source = sources.first,
              let details = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any],
              let capacity = details[kIOPSCurrentCapacityKey] as? Int else { return "Battery status unavailable" }
        return "Battery \(capacity)%"
    }

    private func openSettings(_ address: String) {
        if let url = URL(string: address) { NSWorkspace.shared.open(url) }
    }
}
