import AVFoundation
import Speech
import SwiftUI

@MainActor
final class VoiceLogService: ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var transcript = ""
    @Published var errorMessage: String?

    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    func start() {
        Task {
            let microphone = await AVCaptureDevice.requestAccess(for: .audio)
            guard microphone else { errorMessage = "Allow microphone access in System Settings to dictate an activity."; return }
            let speech = await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
            }
            guard speech == .authorized else { errorMessage = "Allow speech recognition in System Settings to dictate an activity."; return }
            guard let recognizer = SFSpeechRecognizer(), recognizer.isAvailable else {
                errorMessage = "Speech recognition is unavailable right now. Type the activity instead."
                return
            }
            do {
                let request = SFSpeechAudioBufferRecognitionRequest()
                request.shouldReportPartialResults = true
                let input = engine.inputNode
                input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { buffer, _ in
                    request.append(buffer)
                }
                engine.prepare()
                try engine.start()
                self.request = request
                recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                    Task { @MainActor in
                        if let result { self?.transcript = result.bestTranscription.formattedString }
                        if let error { self?.errorMessage = error.localizedDescription; self?.stop() }
                    }
                }
                isRecording = true
                errorMessage = nil
            } catch {
                engine.inputNode.removeTap(onBus: 0)
                errorMessage = error.localizedDescription
            }
        }
    }

    func stop() {
        guard isRecording else { return }
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        recognitionTask?.cancel()
        request = nil
        recognitionTask = nil
        isRecording = false
    }
}
