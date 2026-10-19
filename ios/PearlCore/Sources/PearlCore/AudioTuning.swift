// Réglages des sons de l'app iOS, lus dans catalog.json (exporté depuis `APP_AUDIO`, src/tuning.ts).
// Le son est fabriqué par l'app (PearlInc/Platform/Audio.swift) ; ici, seulement les nombres.

/// Bruit bref filtré (craquement, pop, fêlure).
public struct NoiseSound: Codable, Sendable, Equatable {
    public var durationMs: Double
    /// Centre du filtre passe-bande (Hz).
    public var frequency: Double
    public var gain: Double
}

/// Notes égrenées (carillons, tintements).
public struct ToneSound: Codable, Sendable, Equatable {
    public enum Wave: String, Codable, Sendable { case sine, triangle, sawtooth, square }
    public var notes: [Double]
    public var wave: Wave
    public var gapMs: Double
    public var attackMs: Double
    public var decayMs: Double
    public var gain: Double
}

/// Musique d'ambiance et effets sonores (voir les commentaires de `AppAudio` dans src/tuning.ts).
public struct AudioTuning: Codable, Sendable, Equatable {
    public var sampleRate: Double
    public var effectsVolume: Double
    public var musicVolume: Double
    public var effectsReverbMix: Double
    public var musicReverbMix: Double
    public var noiseQ: Double

    public var tick: NoiseSound
    public var tickFrequencyStep: Double
    public var pop: NoiseSound
    public var crack: NoiseSound
    public var lid: NoiseSound

    public var pulseStartFrequency: Double
    public var pulseEndFrequency: Double
    public var pulseDurationMs: Double
    public var pulseAttackMs: Double
    public var pulseGain: Double
    public var pulseGainPerTier: Double
    public var pulseEveryMs: Double

    public var chime: ToneSound
    public var chimeBaseNotes: Int
    public var cursedChime: ToneSound
    public var emptyChime: ToneSound
    public var findChime: ToneSound
    public var ding: ToneSound
    public var tap: ToneSound
    public var rewardChimeLevel: Int
    public var purchaseChimeLevel: Int

    public var musicFadeMs: Double
    public var musicSuspenseDuck: Double
    public var chords: [[Double]]
    public var chordSeconds: Double
    public var chordCrossfadeSeconds: Double
    public var padGain: Double
    public var padHarmonic: Double
    public var padTremoloHz: Double
    public var padTremoloDepth: Double
    public var waveGain: Double
    public var waveCutoffHz: Double
    public var wavePeriodsSeconds: [Double]
    public var sparkleNotes: [Double]
    public var sparkleGapMinSeconds: Double
    public var sparkleGapMaxSeconds: Double
    public var sparkleDecaySeconds: Double
    public var sparkleGain: Double

    /// Les notes du carillon de révélation pour un niveau de rareté (0…3), comme la webapp.
    public func chimeNotes(_ sound: ToneSound, level: Int) -> [Double] {
        Array(sound.notes.prefix(chimeBaseNotes + max(0, level)))
    }
}
