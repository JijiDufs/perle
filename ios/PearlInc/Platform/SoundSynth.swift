import Foundation
import PearlCore

/// Fabrique les effets sonores en échantillons (mono), comme le Web Audio de la webapp (src/platform/audio.ts) :
/// bruit filtré pour les craquements, notes égrenées pour les carillons. Aucun fichier audio.
enum SoundSynth {
    /// Bruit blanc qui s'éteint (courbe en (1 − t)³), passé dans un filtre passe-bande.
    static func noise(_ sound: NoiseSound, frequency: Double, q: Double, sampleRate: Double) -> [Float] {
        let count = max(1, Int(sampleRate * sound.durationMs / 1000))
        var filter = BandPass(frequency: frequency, q: q, sampleRate: sampleRate)
        return (0..<count).map { i in
            let envelope = pow(1 - Double(i) / Double(count), 3)
            return Float(filter.process(Double.random(in: -1...1) * envelope) * sound.gain)
        }
    }

    /// Notes jouées l'une après l'autre ; chacune monte en `attackMs` puis s'éteint (courbe exponentielle)
    /// jusqu'au silence à `decayMs`, comme `linearRamp` puis `exponentialRamp` en Web Audio.
    static func tones(_ sound: ToneSound, notes: [Double], sampleRate: Double) -> [Float] {
        guard !notes.isEmpty else { return [] }
        let gap = sound.gapMs / 1000, attack = sound.attackMs / 1000, decay = max(sound.decayMs / 1000, attack)
        let count = Int(sampleRate * (gap * Double(notes.count - 1) + decay)) + 1
        var samples = [Float](repeating: 0, count: count)
        for (index, frequency) in notes.enumerated() {
            let start = Int(sampleRate * gap * Double(index))
            let length = min(count - start, Int(sampleRate * decay))
            for i in 0..<max(0, length) {
                let t = Double(i) / sampleRate
                let level = t < attack
                    ? sound.gain * t / max(attack, .leastNonzeroMagnitude)
                    : sound.gain * pow(silence / sound.gain, (t - attack) / max(decay - attack, .leastNonzeroMagnitude))
                samples[start + i] += Float(level * wave(sound.wave, phase: frequency * t))
            }
        }
        return samples
    }

    /// Battement du suspense : un son grave qui descend de `pulseStartFrequency` à `pulseEndFrequency`.
    static func pulse(_ audio: AudioTuning, tier: Int) -> [Float] {
        let count = max(1, Int(audio.sampleRate * audio.pulseDurationMs / 1000))
        let attack = max(1, audio.sampleRate * audio.pulseAttackMs / 1000)
        let gain = audio.pulseGain + audio.pulseGainPerTier * Double(tier)
        let ratio = audio.pulseEndFrequency / audio.pulseStartFrequency
        var phase = 0.0
        return (0..<count).map { i in
            let progress = Double(i) / Double(count)
            phase += audio.pulseStartFrequency * pow(ratio, progress) / audio.sampleRate
            let envelope = min(1, Double(i) / attack) * pow(1 - progress, 2)
            return Float(gain * envelope * sin(2 * .pi * phase))
        }
    }

    /// Le « zéro » d'une extinction exponentielle (Web Audio ne descend pas jusqu'à 0).
    private static let silence = 0.0001

    /// Forme d'onde, `phase` en tours (fréquence × temps).
    static func wave(_ wave: ToneSound.Wave, phase: Double) -> Double {
        switch wave {
        case .sine: sin(2 * .pi * phase)
        case .triangle: 2 / .pi * asin(sin(2 * .pi * phase))
        case .sawtooth: 2 * (phase - (phase + 0.5).rounded(.down))
        case .square: sin(2 * .pi * phase) >= 0 ? 1 : -1
        }
    }
}

/// Filtre passe-bande à gain unité au centre (le `bandpass` du Web Audio, formules RBJ).
struct BandPass {
    private let b0, b2, a1, a2: Double
    private var x1 = 0.0, x2 = 0.0, y1 = 0.0, y2 = 0.0

    init(frequency: Double, q: Double, sampleRate: Double) {
        let w0 = 2 * Double.pi * min(frequency, sampleRate * 0.49) / sampleRate
        let alpha = sin(w0) / (2 * q)
        let a0 = 1 + alpha
        b0 = alpha / a0
        b2 = -alpha / a0
        a1 = -2 * cos(w0) / a0
        a2 = (1 - alpha) / a0
    }

    mutating func process(_ x: Double) -> Double {
        let y = b0 * x + b2 * x2 - a1 * y1 - a2 * y2
        x2 = x1; x1 = x
        y2 = y1; y1 = y
        return y
    }
}
