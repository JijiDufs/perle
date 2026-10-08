import Foundation
import Observation
import PearlCore

/// Relie le moteur (PearlCore), la source de geste, l'haptique et la sauvegarde.
/// Les règles restent dans PearlCore ; les vues affichent cet état et transmettent les gestes.
@MainActor
@Observable
final class GameModel {
    enum Stage: Equatable {
        /// Le joueur ouvre l'huître.
        case playing
        /// Révélée : suspense avant la carte.
        case suspense
        /// La carte est affichée.
        case card(Reveal)
    }

    let catalog = Catalog.shared
    var tuning: Tuning { catalog.tuning }

    private(set) var player: PlayerState
    private(set) var stage: Stage = .playing
    private(set) var angle = 0.0
    private(set) var cracked = false
    private(set) var inFragileZone = false
    private(set) var tooFast = false

    @ObservationIgnored private var engine: OpeningEngine
    @ObservationIgnored private let thumb = ThumbSource()
    @ObservationIgnored private let haptics = Haptics()
    @ObservationIgnored private let rng: Rng = systemRng()
    @ObservationIgnored private var lastTickDistance = 0.0

    init() {
        let catalog = Catalog.shared
        player = Storage.load() ?? PlayerState.new(systemRng(), catalog.tuning)
        engine = OpeningEngine(tuning: catalog.tuning)
        thumb.onSample = { [weak self] sample, distance in self?.handle(sample, distance: distance) }
        thumb.onRelease = { [weak self] in self?.handleRelease() }
        Storage.save(player)
    }

    // MARK: - Ce que voit le joueur

    /// La perle (ou l'huître vide) de l'huître en cours.
    var pearl: PearlType { catalog.pearl(player.oyster.pearlId) }
    /// La trouvaille cachée, s'il y en a une.
    var find: FindType? { player.oyster.findId.map { catalog.find($0) } }
    /// Couleur de la lumière qui filtre : celle de la perle ou de la trouvaille ; nil = reste noire.
    var glowHex: String? { find?.glow ?? pearl.glow }
    var trembles: Bool { find.map { $0.tier >= 4 } ?? pearl.trembles }
    var revealTier: Int { find.map { min(3, $0.tier - 1) } ?? pearl.revealTier }

    // MARK: - Gestes

    func drag(translation: Double) {
        guard stage == .playing else { return }
        if engine.phase == .closed { haptics.prepare() }
        thumb.drag(translation: translation, tuning: tuning)
    }

    func endDrag() {
        guard stage == .playing else { return }
        thumb.end(tuning: tuning, autoOpenFrom: engine.phase == .opening ? tuning.autoOpenFromAngle : nil)
    }

    /// VoiceOver : ouverture lente et régulière, sans fêlure.
    func openForAccessibility() {
        guard stage == .playing else { return }
        thumb.openSlowly(tuning: tuning, durationMs: 2600)
    }

    /// Toucher la carte (sur le Duo : refermer le téléphone) : huître suivante.
    func nextOyster() {
        guard case .card = stage else { return }
        engine = OpeningEngine(tuning: tuning)
        thumb.reset()
        lastTickDistance = 0
        angle = 0
        cracked = false
        inFragileZone = false
        tooFast = false
        stage = .playing
    }

    // MARK: - Moteur

    private func handle(_ sample: OpeningSample, distance: Double) {
        let events = engine.push(sample)
        angle = engine.angle
        inFragileZone = engine.inFragileZone && engine.phase == .opening
        // Même seuil d'alerte que la webapp (features/oyster/oysterScreen.ts).
        tooFast = inFragileZone && engine.velocity > tuning.maxSafeVelocity * 0.6

        if engine.phase == .resisting, distance - lastTickDistance >= tuning.resistanceTickDistance {
            lastTickDistance = distance
            haptics.tick()
        }
        for event in events {
            switch event {
            case .pop:
                haptics.pop()
                thumb.lockAfterPop(tuning: tuning)
            case .crack:
                cracked = true
                haptics.crack()
            case .reveal(let lustre, let wasCracked):
                startReveal(lustre: lustre, cracked: wasCracked)
            }
        }
    }

    private func handleRelease() {
        engine.release()
        angle = engine.angle
        inFragileZone = false
        tooFast = false
        if engine.phase == .closed {
            thumb.reset()
            lastTickDistance = 0
        }
    }

    private func startReveal(lustre: Lustre, cracked: Bool) {
        stage = .suspense
        let tier = revealTier
        let reveal = player.reveal(lustre: lustre, cracked: cracked, now: Date().timeIntervalSince1970 * 1000, rng: rng, tuning: tuning)
        Storage.save(player)
        let suspense = tuning.revealSuspenseMs(tier: tier)
        Task { [weak self] in
            var elapsed = 0.0
            let pulse = 350.0
            while elapsed + pulse < suspense {
                try? await Task.sleep(for: .milliseconds(Int(pulse)))
                elapsed += pulse
                self?.haptics.suspensePulse(tier: tier)
            }
            try? await Task.sleep(for: .milliseconds(Int(max(0, suspense - elapsed))))
            guard let self else { return }
            self.haptics.reveal(tier: tier)
            self.stage = .card(reveal)
        }
    }
}
