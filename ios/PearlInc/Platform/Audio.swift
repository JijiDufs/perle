import AVFoundation
import PearlCore

/// Musique d'ambiance et effets sonores, fabriqués par code comme dans la webapp : aucun fichier audio
/// (AGENTS.md §6). Les moments sont ceux de l'haptique : tic de résistance, pop, fêlure, battements du suspense,
/// révélation ; plus la poussière d'or, les récompenses, les achats et les boutons.
/// Catégorie « ambient » : muet en mode silencieux, se mêle à la musique du joueur sans la couper ;
/// notre musique se tait d'elle-même tant que le joueur écoute autre chose.
@MainActor
final class Audio {
    /// Réglages « Musique » et « Sons » (écran Réglages), activés par défaut.
    static let musicKey = "pearlinc.settings.music"
    static let soundsKey = "pearlinc.settings.sounds"
    private var musicEnabled: Bool { UserDefaults.standard.object(forKey: Self.musicKey) as? Bool ?? true }
    private var soundsEnabled: Bool { UserDefaults.standard.object(forKey: Self.soundsKey) as? Bool ?? true }

    /// Style du carillon de révélation (comme `chimeNotes` de la webapp).
    enum RevealStyle { case pearl, cursed, empty, find }

    private let settings: AudioTuning
    private let engine = AVAudioEngine()
    private let mono: AVAudioFormat
    private let stereo: AVAudioFormat
    private let music: AmbientMusic
    private let musicMixer = AVAudioMixerNode()
    private let musicReverb = AVAudioUnitReverb()
    private let effectsMixer = AVAudioMixerNode()
    private let effectsReverb = AVAudioUnitReverb()
    private var players: [AVAudioPlayerNode] = []
    private var nextPlayer = 0
    private var cache: [String: AVAudioPCMBuffer] = [:]
    private var built = false
    private var observers: [NSObjectProtocol] = []

    /// L'app est au premier plan, le jeu affiché.
    private var active = false
    /// Le joueur écoute déjà de la musique (ou un podcast) : la nôtre se tait.
    private var otherAudioPlaying = false
    private var inSuspense = false
    private var inAd = false

    /// Effets qui peuvent sonner en même temps (le tic suivant ne coupe pas le pop).
    private static let effectVoices = 8

    init(settings: AudioTuning) {
        self.settings = settings
        mono = AVAudioFormat(standardFormatWithSampleRate: settings.sampleRate, channels: 1)!
        stereo = AVAudioFormat(standardFormatWithSampleRate: settings.sampleRate, channels: 2)!
        music = AmbientMusic(audio: settings)
    }

    // MARK: - Cycle de vie

    /// Le jeu s'affiche ou l'app revient au premier plan.
    func start() {
        active = true
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient)
        try? session.setActive(true)
        otherAudioPlaying = session.secondaryAudioShouldBeSilencedHint
        if !built { build() }
        startEngine()
        updateMusic()
    }

    /// L'app passe en arrière-plan (ou le jeu disparaît) : silence tout de suite.
    func stop() {
        active = false
        music.setLevel(0)
        if built { engine.pause() }
    }

    /// Les interrupteurs des Réglages ont changé.
    func settingsChanged() { updateMusic() }

    /// Pendant le suspense, la musique baisse pour laisser la place au carillon.
    func setSuspense(_ on: Bool) {
        inSuspense = on
        updateMusic()
    }

    /// Une pub (avec son propre son) va s'afficher, ou vient de se fermer.
    func setAdShowing(_ on: Bool) {
        inAd = on
        if !on, active { start() } else { updateMusic() }
    }

    private func updateMusic() {
        let audible = active && musicEnabled && !otherAudioPlaying && !inAd
        let level = audible ? settings.musicVolume * (inSuspense ? settings.musicSuspenseDuck : 1) : 0
        music.setLevel(level)
    }

    private func build() {
        built = true
        let musicNode = music.makeNode(format: mono)
        musicReverb.loadFactoryPreset(.mediumHall)
        musicReverb.wetDryMix = Float(settings.musicReverbMix)
        effectsReverb.loadFactoryPreset(.mediumRoom)
        effectsReverb.wetDryMix = Float(settings.effectsReverbMix)
        effectsMixer.outputVolume = Float(settings.effectsVolume)
        for node in [musicNode, musicMixer, musicReverb, effectsMixer, effectsReverb] as [AVAudioNode] { engine.attach(node) }
        engine.connect(musicNode, to: musicMixer, format: mono)
        engine.connect(musicMixer, to: musicReverb, format: stereo)
        engine.connect(musicReverb, to: engine.mainMixerNode, format: stereo)
        engine.connect(effectsMixer, to: effectsReverb, format: stereo)
        engine.connect(effectsReverb, to: engine.mainMixerNode, format: stereo)
        for _ in 0..<Self.effectVoices {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: effectsMixer, format: mono)
            players.append(player)
        }
        engine.prepare()
        observe()
    }

    private func startEngine() {
        guard active, !engine.isRunning else { return }
        try? engine.start()
    }

    private func observe() {
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            let ended = (note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt).flatMap(AVAudioSession.InterruptionType.init) == .ended
            MainActor.assumeIsolated { if ended { self?.startEngine() } }
        })
        observers.append(center.addObserver(forName: AVAudioSession.silenceSecondaryAudioHintNotification, object: nil, queue: .main) { [weak self] note in
            let type = (note.userInfo?[AVAudioSessionSilenceSecondaryAudioHintTypeKey] as? UInt).flatMap(AVAudioSession.SilenceSecondaryAudioHintType.init)
            MainActor.assumeIsolated {
                self?.otherAudioPlaying = type == .begin
                self?.updateMusic()
            }
        })
        // Écouteurs branchés ou débranchés : le moteur s'arrête, on le relance.
        observers.append(center.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.startEngine() }
        })
    }

    // MARK: - Effets

    /// Un cran de résistance ; il monte d'un ton à chaque tic, comme dans la webapp.
    func tick(step: Int) {
        let sound = settings.tick
        play(noise(sound, frequency: sound.frequency + settings.tickFrequencyStep * Double(step)))
    }

    /// La coquille cède.
    func pop() { play(noise(settings.pop, frequency: settings.pop.frequency)) }

    /// La perle se fêle.
    func crack() { play(noise(settings.crack, frequency: settings.crack.frequency)) }

    /// Le couvercle s'ouvre en grand : début du suspense.
    func lid() { play(noise(settings.lid, frequency: settings.lid.frequency)) }

    /// Battement du suspense, plus fort pour les perles rares.
    func suspensePulse(tier: Int) {
        play(cached("pulse\(tier)") { SoundSynth.pulse(settings, tier: tier) })
    }

    /// La carte apparaît : carillon qui monte avec la rareté ; la maudite grince, l'huître vide descend.
    func reveal(_ style: RevealStyle, tier: Int) {
        switch style {
        case .pearl: chime(settings.chime, level: tier, key: "chime")
        case .find: chime(settings.findChime, level: tier, key: "find")
        case .cursed: play(cached("cursed") { SoundSynth.tones(settings.cursedChime, notes: settings.cursedChime.notes, sampleRate: settings.sampleRate) })
        case .empty: chime(settings.emptyChime, level: 0, key: "empty")
        }
    }

    /// Poussière d'or gagnée.
    func dust() { play(cached("ding") { SoundSynth.tones(settings.ding, notes: settings.ding.notes, sampleRate: settings.sampleRate) }) }

    /// Une récompense : calendrier, pub regardée.
    func reward() { chime(settings.chime, level: settings.rewardChimeLevel, key: "chime") }

    /// Un achat : huître, coquille, produit de la boutique.
    func purchase() { chime(settings.chime, level: settings.purchaseChimeLevel, key: "chime") }

    /// Le poisson voleur file avec la perle.
    func fish() { play(cached("fish") { SoundSynth.tones(settings.fishChime, notes: settings.fishChime.notes, sampleRate: settings.sampleRate) }) }

    /// Bouton, onglet.
    func tap() { play(cached("tap") { SoundSynth.tones(settings.tap, notes: settings.tap.notes, sampleRate: settings.sampleRate) }) }

    private func chime(_ sound: ToneSound, level: Int, key: String) {
        play(cached("\(key)\(level)") { SoundSynth.tones(sound, notes: settings.chimeNotes(sound, level: level), sampleRate: settings.sampleRate) })
    }

    /// Les bruits sont tirés à chaque fois (deux craquements ne sont jamais identiques).
    private func noise(_ sound: NoiseSound, frequency: Double) -> AVAudioPCMBuffer? {
        guard soundsEnabled else { return nil }
        return buffer(SoundSynth.noise(sound, frequency: frequency, q: settings.noiseQ, sampleRate: settings.sampleRate))
    }

    private func cached(_ key: String, _ make: () -> [Float]) -> AVAudioPCMBuffer? {
        guard soundsEnabled else { return nil }
        if let buffer = cache[key] { return buffer }
        let buffer = buffer(make())
        cache[key] = buffer
        return buffer
    }

    private func buffer(_ samples: [Float]) -> AVAudioPCMBuffer? {
        guard !samples.isEmpty, let buffer = AVAudioPCMBuffer(pcmFormat: mono, frameCapacity: AVAudioFrameCount(samples.count)),
              let channel = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { channel.update(from: $0.baseAddress!, count: samples.count) }
        return buffer
    }

    private func play(_ buffer: AVAudioPCMBuffer?) {
        guard let buffer, soundsEnabled, active, engine.isRunning, !players.isEmpty else { return }
        let player = players[nextPlayer]
        nextPlayer = (nextPlayer + 1) % players.count
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !player.isPlaying { player.play() }
    }
}
