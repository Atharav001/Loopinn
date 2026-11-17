import AVFoundation
import AppKit
import Foundation

/// A distinct, sharper two-strike bell for Ripple Focus intervals.
@MainActor
final class RippleBell {
    static let shared = RippleBell()
    private var player: AVAudioPlayer?
    private lazy var sound = Self.render()

    func play() {
        do {
            let player = try AVAudioPlayer(data: sound)
            player.volume = 0.9
            player.prepareToPlay()
            player.play()
            self.player = player
        } catch {
            NSSound.beep()
        }
    }

    private static func render() -> Data {
        let sampleRate = 44_100
        let duration = 1.45
        let count = Int(Double(sampleRate) * duration)
        let byteCount = count * MemoryLayout<Int16>.size
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
            var sample = 0.0
            for (start, strength) in [(0.0, 1.0), (0.34, 0.92)] {
                let elapsed = time - start
                guard elapsed >= 0 else { continue }
                let attack = min(1, elapsed / 0.003)
                let decay = exp(-elapsed * 5.5)
                let tone = 0.55 * sin(2 * .pi * 880 * elapsed)
                    + 0.28 * sin(2 * .pi * 1320 * elapsed)
                    + 0.14 * sin(2 * .pi * 1760 * elapsed)
                sample += strength * attack * decay * tone
            }
            append(Int16(clamping: Int(max(-1, min(1, sample)) * 23_000)))
        }
        return data
    }
}
