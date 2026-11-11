import AVFoundation
import AppKit
import Foundation

@MainActor
final class OmBell {
    static let shared = OmBell()
    private var player: AVAudioPlayer?

    func play() {
        do {
            let player = try AVAudioPlayer(data: Self.render())
            player.volume = 0.55
            player.prepareToPlay()
            player.play()
            self.player = player
        } catch {
            NSSound.beep()
        }
    }

    private static func render() -> Data {
        let sampleRate = 22_050
        let count = sampleRate * 3 / 2
        let byteCount = count * 2
        var data = Data()
        func append<T: FixedWidthInteger>(_ value: T) {
            var little = value.littleEndian
            withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
        }
        data.append(contentsOf: "RIFF".utf8)
        append(UInt32(36 + byteCount))
        data.append(contentsOf: "WAVEfmt ".utf8)
        append(UInt32(16))
        append(UInt16(1))
        append(UInt16(1))
        append(UInt32(sampleRate))
        append(UInt32(sampleRate * 2))
        append(UInt16(2))
        append(UInt16(16))
        data.append(contentsOf: "data".utf8)
        append(UInt32(byteCount))
        for index in 0..<count {
            let time = Double(index) / Double(sampleRate)
            let attack = min(1, time / 0.035)
            let fade = pow(max(0, 1 - time / 1.5), 1.5)
            let fundamental = sin(2 * .pi * 136.1 * time)
            let octave = 0.34 * sin(2 * .pi * 272.2 * time)
            let shimmer = 0.13 * sin(2 * .pi * 408.3 * time)
            let sample = Int16(clamping: Int((fundamental + octave + shimmer) * attack * fade * 16_000))
            append(sample)
        }
        return data
    }
}
