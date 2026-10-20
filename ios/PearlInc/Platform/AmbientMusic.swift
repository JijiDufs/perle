import AVFoundation
import Synchronization
import PearlCore

/// Musique d'ambiance du lagon, fabriquée en continu sur le fil audio : une nappe d'accords lente,
/// le ressac (bruit adouci qui enfle et retombe) et, de temps en temps, une note de carillon.
/// Rien n'est alloué pendant le rendu ; le volume voulu arrive du fil principal par une valeur atomique,
/// et la musique y glisse en douceur (`musicFadeMs`).
final class AmbientMusic: @unchecked Sendable {
    private let audio: AudioTuning
    private let sampleRate: Double
    /// Volume voulu (bits d'un Float), écrit par le fil principal.
    private let target = Atomic<UInt32>(Float(0).bitPattern)

    // État du fil audio uniquement.
    private var gain: Float = 0
    private let fadeStep: Float
    private var time = 0.0
    private var surfLow = 0.0, surfLower = 0.0
    private let surfCoefficient: Double
    private let surfNormalization: Double
    /// Oscillateurs : un point qui tourne sur un cercle (cos, sin), d'un petit angle à chaque échantillon.
    /// Quelques multiplications au lieu d'un `sin()` par échantillon ; l'octave vient gratuitement (sin 2φ = 2 sin φ cos φ).
    /// Deux accords à la fois (celui qui s'éteint et celui qui monte), `maxNotes` notes chacun, puis les carillons.
    private let maxNotes: Int
    private let oscillators: Int
    private let re: UnsafeMutablePointer<Double>
    private let im: UnsafeMutablePointer<Double>
    private let stepRe: UnsafeMutablePointer<Double>
    private let stepIm: UnsafeMutablePointer<Double>
    /// Volume de chaque oscillateur pour le bloc en cours (enveloppe × respiration), et celui des carillons qui s'éteint.
    private let level: UnsafeMutablePointer<Double>
    private let bellDecay: Double
    private var chordInSlot = [-1, -1]
    private var nextBell = 0
    private var nextBellAt: Double
    private var seed: UInt64 = 0x9E37_79B9_7F4A_7C15

    /// Carillons qui sonnent en même temps au plus, et volume sous lequel une note est finie.
    private static let bellVoices = 4
    private static let bellSilence = 0.0005
    /// Décalage entre les voix de la nappe, pour qu'elles ne respirent pas toutes ensemble.
    private static let voiceDrift = 0.37

    init(audio: AudioTuning) {
        self.audio = audio
        sampleRate = audio.sampleRate
        fadeStep = Float(1 / max(1, audio.musicFadeMs / 1000 * audio.sampleRate))
        surfCoefficient = 1 - exp(-2 * .pi * audio.waveCutoffHz / audio.sampleRate)
        // Deux filtres passe-bas d'affilée font perdre beaucoup de volume au bruit : on le rend.
        surfNormalization = (2 - surfCoefficient) / surfCoefficient
        maxNotes = audio.chords.map(\.count).max() ?? 0
        oscillators = 2 * maxNotes + Self.bellVoices
        re = .allocate(capacity: oscillators); re.initialize(repeating: 0, count: oscillators)
        im = .allocate(capacity: oscillators); im.initialize(repeating: 0, count: oscillators)
        stepRe = .allocate(capacity: oscillators); stepRe.initialize(repeating: 1, count: oscillators)
        stepIm = .allocate(capacity: oscillators); stepIm.initialize(repeating: 0, count: oscillators)
        level = .allocate(capacity: oscillators); level.initialize(repeating: 0, count: oscillators)
        bellDecay = exp(-1 / (audio.sparkleDecaySeconds * audio.sampleRate))
        nextBellAt = audio.sparkleGapMinSeconds
    }

    deinit {
        for pointer in [re, im, stepRe, stepIm, level] { pointer.deallocate() }
    }

    /// Volume voulu, 0…1 (déjà multiplié par le volume de la musique).
    func setLevel(_ level: Double) {
        target.store(Float(max(0, level)).bitPattern, ordering: .relaxed)
    }

    /// Le nœud qui joue la musique (mono). Créé ici, hors du fil principal : le rendu tourne sur le fil audio.
    func makeNode(format: AVAudioFormat) -> AVAudioSourceNode {
        AVAudioSourceNode(format: format) { [self] isSilence, _, frameCount, audioBufferList in
            render(isSilence: isSilence, frames: Int(frameCount), buffers: UnsafeMutableAudioBufferListPointer(audioBufferList))
            return noErr
        }
    }

    private func render(isSilence: UnsafeMutablePointer<ObjCBool>, frames: Int, buffers: UnsafeMutableAudioBufferListPointer) {
        let goal = Float(bitPattern: target.load(ordering: .relaxed))
        guard let channel = buffers.first?.mData?.assumingMemoryBound(to: Float.self) else { return }
        if goal == 0 && gain == 0 {
            channel.update(repeating: 0, count: frames)
            isSilence.pointee = true
            return
        }
        prepareBlock()
        let pads = 2 * maxNotes
        let harmonic = audio.padHarmonic
        let padGain = audio.padGain, sparkleGain = audio.sparkleGain
        let surfGain = audio.waveGain * swell() * surfNormalization
        for i in 0..<frames {
            let t = time + Double(i) / sampleRate
            if t >= nextBellAt { ringBell() }
            var pad = 0.0, bells = 0.0
            for k in 0..<oscillators where level[k] > 0 {
                let r = re[k] * stepRe[k] - im[k] * stepIm[k]
                let m = re[k] * stepIm[k] + im[k] * stepRe[k]
                re[k] = r
                im[k] = m
                if k < pads {
                    pad += level[k] * (m + harmonic * 2 * m * r)
                } else {
                    let a = level[k]
                    bells += a * (m + harmonic * a * 2 * m * r)
                    level[k] = a > Self.bellSilence ? a * bellDecay : 0
                }
            }
            surfLow += surfCoefficient * (random() - surfLow)
            surfLower += surfCoefficient * (surfLow - surfLower)
            let sample = padGain * pad + surfGain * surfLower + sparkleGain * bells
            if gain < goal { gain = min(goal, gain + fadeStep) } else if gain > goal { gain = max(goal, gain - fadeStep) }
            channel[i] = Float(sample) * gain
        }
        time += Double(frames) / sampleRate
        // Les arrondis font lentement grandir ou rétrécir les cercles : on les remet à 1.
        for k in 0..<oscillators {
            let radius = (re[k] * re[k] + im[k] * im[k]).squareRoot()
            if radius > 0 { re[k] /= radius; im[k] /= radius }
        }
        isSilence.pointee = false
    }

    /// Ce qui bouge lentement (accords en cours, enveloppes, respiration) est calculé une fois par bloc.
    private func prepareBlock() {
        let chords = audio.chords
        let length = audio.chordSeconds, fade = audio.chordCrossfadeSeconds
        let current = Int(time / length)
        for index in max(0, current - 1)...current {
            let slot = index % 2
            let chord = chords[index % chords.count]
            if chordInSlot[slot] != index {
                // Nouvel accord dans cette case : ses notes repartent de zéro (il monte depuis le silence).
                chordInSlot[slot] = index
                for note in 0..<maxNotes {
                    let k = slot * maxNotes + note
                    let w = note < chord.count ? 2 * Double.pi * chord[note] / sampleRate : 0
                    re[k] = 1; im[k] = 0
                    stepRe[k] = cos(w); stepIm[k] = sin(w)
                }
            }
            let envelope = chordEnvelope(index, length: length, fade: fade)
            for note in 0..<maxNotes {
                let drift = 1 + Self.voiceDrift * Double(note)
                let breath = 1 - audio.padTremoloDepth * 0.5 * (1 + sin(2 * .pi * audio.padTremoloHz * drift * time + Double(note)))
                level[slot * maxNotes + note] = note < chord.count ? envelope * breath : 0
            }
        }
    }

    /// Le ressac : deux houles de périodes différentes, qui enflent et retombent.
    private func swell() -> Double {
        audio.wavePeriodsSeconds.reduce(0.0) { sum, period in
            sum + pow(0.5 * (1 - cos(2 * .pi * time / period)), 2)
        } / Double(audio.wavePeriodsSeconds.count)
    }

    /// Un accord monte pendant `fade`, tient, puis s'éteint pendant `fade` sous l'accord suivant.
    private func chordEnvelope(_ index: Int, length: Double, fade: Double) -> Double {
        let start = Double(index) * length
        let rise = smooth((time - start) / fade)
        let fall = 1 - smooth((time - start - length) / fade)
        return min(rise, fall)
    }

    private func ringBell() {
        let notes = audio.sparkleNotes
        let k = 2 * maxNotes + nextBell
        let w = 2 * Double.pi * notes[min(notes.count - 1, Int(uniform() * Double(notes.count)))] / sampleRate
        re[k] = 1; im[k] = 0
        stepRe[k] = cos(w); stepIm[k] = sin(w)
        level[k] = 1
        nextBell = (nextBell + 1) % Self.bellVoices
        nextBellAt += audio.sparkleGapMinSeconds + uniform() * (audio.sparkleGapMaxSeconds - audio.sparkleGapMinSeconds)
    }

    private func smooth(_ x: Double) -> Double {
        let c = min(1, max(0, x))
        return c * c * (3 - 2 * c)
    }

    /// Hasard du fil audio (xorshift), sans verrou ni allocation : 0…1, et −1…1 pour le bruit.
    private func uniform() -> Double {
        seed ^= seed << 13
        seed ^= seed >> 7
        seed ^= seed << 17
        return Double(seed >> 11) / Double(1 << 53)
    }

    private func random() -> Double { uniform() * 2 - 1 }
}
