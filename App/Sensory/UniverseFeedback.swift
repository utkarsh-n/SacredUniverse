import AVFoundation
import UIKit

@MainActor
final class UniverseFeedback {
    var soundEnabled = false
    var hapticsEnabled = true
    private var player: AVAudioPlayer?
    private var lastTick = Date.distantPast
    func tick() {
        guard hapticsEnabled, Date().timeIntervalSince(lastTick) > 0.10 else { return }
        lastTick = Date()
        UISelectionFeedbackGenerator().selectionChanged()
    }
    func result(correct: Bool) {
        if hapticsEnabled { UINotificationFeedbackGenerator().notificationOccurred(correct ? .success : .warning) }
        if correct { chime(frequency: 528, duration: 0.22) }
    }
    func discovery() {
        if hapticsEnabled { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        chime(frequency: 660, duration: 0.65)
    }
    func stop() { player?.stop(); player = nil }
    private func chime(frequency: Double, duration: Double) {
        guard soundEnabled else { return }
        let rate = 22_050
        let count = Int(Double(rate) * duration)
        var samples = Data(capacity: count * 2)
        for index in 0..<count {
            let t = Double(index) / Double(rate)
            let envelope = min(1, t / 0.015) * pow(1 - t / duration, 2)
            let value = (sin(2 * .pi * frequency * t) + 0.25 * sin(2 * .pi * frequency * 1.5 * t)) * envelope * 0.17
            var sample = Int16(value * Double(Int16.max)).littleEndian
            withUnsafeBytes(of: &sample) { samples.append(contentsOf: $0) }
        }
        var wav = Data()
        func ascii(_ value: String) { wav.append(contentsOf: value.utf8) }
        func u32(_ value: UInt32) { var n = value.littleEndian; withUnsafeBytes(of: &n) { wav.append(contentsOf: $0) } }
        func u16(_ value: UInt16) { var n = value.littleEndian; withUnsafeBytes(of: &n) { wav.append(contentsOf: $0) } }
        ascii("RIFF"); u32(UInt32(36 + samples.count)); ascii("WAVEfmt "); u32(16); u16(1); u16(1)
        u32(UInt32(rate)); u32(UInt32(rate * 2)); u16(2); u16(16); ascii("data"); u32(UInt32(samples.count)); wav.append(samples)
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            player = try AVAudioPlayer(data: wav)
            player?.prepareToPlay(); player?.play()
        } catch { player = nil }
    }
}
