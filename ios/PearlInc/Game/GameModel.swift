import Foundation
import Observation
import PearlCore

/// Relie le moteur (PearlCore), la source de geste, l'haptique, le son et la sauvegarde.
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
        /// Un poisson a chipé la perle et s'enfuit avec : le toucher à temps la rend.
        case theft(Reveal)
        /// Il a filé : la perle est perdue.
        case stolen(Reveal)
    }

    /// Le catalogue dans la langue de l'app (les textes seulement : les règles sont les mêmes).
    let catalog = Catalog.shared.localized(AppLanguage.code)
    var tuning: Tuning { catalog.tuning }
    var economy: Economy { catalog.economy }

    private(set) var player: PlayerState
    private(set) var stage: Stage = .playing
    private(set) var angle = 0.0
    /// Où en est le geste (bulles d'accompagnement, main fantôme).
    private(set) var phase: OpeningPhase = .closed
    private(set) var cracked = false
    private(set) var inFragileZone = false
    private(set) var tooFast = false
    /// Dernier gain de poussière d'or, pour faire rebondir le compteur.
    private(set) var dustBump = 0
    /// Graine de la forme de l'huître posée (bosses, dentelure, taches) : elle ne change pas
    /// pendant la révélation, seulement quand l'huître suivante arrive.
    private(set) var shapeSeed = 0
    /// L'huître à l'écran. Le Core tire la suivante dès la révélation (invariant 5) : on garde celle qu'on
    /// vient d'ouvrir jusqu'à ce que la carte soit refermée, sinon la perle changerait sous les yeux du joueur.
    private(set) var current: Oyster
    /// Huîtres déjà ouvertes quand l'huître à l'écran a été posée (0 = la toute première) :
    /// c'est elle qui dit où en sont les premières minutes, même pendant la carte.
    private(set) var step = 0
    /// Début de la révélation, angle du couvercle à cet instant, et durée du suspense.
    private(set) var revealStartedAt: Date?
    private(set) var revealAngle = 0.0
    private(set) var suspenseMs = 0.0
    /// Éclair blanc des ★, au moment où la carte arrive.
    private(set) var flashAt: Date?
    /// Début du vol de la perle par le poisson.
    private(set) var theftStartedAt: Date?
    /// La carte affichée est celle d'une perle rattrapée au vol (avec la poussière d'or gagnée).
    private(set) var rescuedDust: Int?
    /// La carte affichée est la première de sa sorte (perle ou trouvaille).
    private(set) var revealIsNew = false

    /// Achats intégrés et pub récompensée (plateforme).
    let store = Store()
    let ads = RewardedAds()

    @ObservationIgnored private var engine: OpeningEngine
    @ObservationIgnored private let thumb = ThumbSource()
    /// iPhone Duo : la charnière, et si c'est elle qui ouvre l'huître posée (le pouce attend alors son tour).
    @ObservationIgnored private var hinge: HingeTracker
    @ObservationIgnored private var hingeDriving = false
    /// L'iPhone a une charnière (Duo) : messages « ouvre / referme le téléphone ».
    private(set) var hasHinge = false
    /// La charnière peut ouvrir l'huître (téléphone refermé depuis son arrivée).
    private(set) var hingeArmed = false
    /// iPhone Duo, écran intérieur : abscisse du pli (points, dans la fenêtre) ; nil sur l'écran extérieur.
    private(set) var foldX: Double?
    @ObservationIgnored private let haptics = Haptics()
    /// Musique d'ambiance et effets sonores (aux mêmes moments que l'haptique).
    @ObservationIgnored let audio = Audio(settings: Catalog.shared.audio)
    @ObservationIgnored private let rng: Rng = systemRng()
    /// Le poisson voleur a son propre tirage (le tirage des huîtres reste celui de la webapp).
    /// Outil de test (`-AlwaysFishThief`, Debug) : il vole toutes les perles qu'il peut.
    @ObservationIgnored private let thiefRng: Rng = {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-AlwaysFishThief") { return { 0 } }
        #endif
        return systemRng()
    }()
    @ObservationIgnored private var lastTickDistance = 0.0

    init() {
        let catalog = Catalog.shared
        var saved = Storage.load() ?? PlayerState.new(systemRng(), catalog.tuning, now: Clock.nowMs)
        // App fermée pendant la fuite du poisson : on rend la perle.
        _ = saved.resolveTheft(caught: true)
        player = saved
        current = saved.oyster
        step = saved.oystersOpened
        engine = OpeningEngine(tuning: catalog.tuning, crackProtected: catalog.isCrackProtected(oystersOpened: saved.oystersOpened))
        hinge = HingeTracker(tuning: catalog.tuning)
        thumb.onSample = { [weak self] sample, distance in self?.handle(sample, distance: distance) }
        thumb.onRelease = { [weak self] in self?.handleRelease() }
        shapeSeed = player.nextSerial
        // Le calendrier ne s'ouvre pas tout seul le jour de la toute première séance, même si l'app est relancée.
        if saved.isInTutorial() { calendarOffered() }
        refresh()
        store.onDeliver = { [weak self] productId in self?.deliver(productId) }
        store.start(productIds: catalog.economy.consumables.map(\.id) + catalog.economy.skins.compactMap(\.productId))
    }

    // MARK: - Ce que voit le joueur

    /// La perle (ou l'huître vide) de l'huître en cours.
    var pearl: PearlType { catalog.pearl(current.pearlId) }
    /// La trouvaille cachée, s'il y en a une.
    var find: FindType? { current.findId.map { catalog.find($0) } }
    /// Couleur de la lumière qui filtre : celle de la perle ou de la trouvaille ; nil = reste noire.
    var glowHex: String? { find?.glow ?? pearl.glow }
    var trembles: Bool { find.map { $0.tier >= 4 } ?? pearl.trembles }
    var revealTier: Int { find.map { min(3, $0.tier - 1) } ?? pearl.revealTier }
    var equippedSkin: AppSkin { economy.skin(player.equippedSkin) ?? economy.skins[0] }
    var fishThief: FishThief { economy.fishThief }

    /// Millisecondes depuis que le poisson a chipé la perle ; nil s'il n'y a pas de vol en cours.
    func theftElapsedMs(at date: Date) -> Double? {
        guard case .theft = stage, let start = theftStartedAt else { return nil }
        return date.timeIntervalSince(start) * 1000
    }

    /// La perle n'est plus dans l'huître : le poisson l'a dans la bouche, ou il a filé avec.
    func pearlTaken(at date: Date) -> Bool {
        if case .stolen = stage { return true }
        return theftElapsedMs(at: date).map { $0 >= fishThief.arriveMs } ?? false
    }

    /// Premières minutes : l'huître à l'écran est une de celles du tutoriel. Les fonctions
    /// (onglets, missions, compteurs) n'apparaissent qu'après (cahier §15 : une à une).
    var inTutorial: Bool { catalog.isInTutorial(oystersOpened: step) }

    /// On peut ouvrir l'huître posée : celles du tutoriel sont offertes, les autres coûtent une huître du stock.
    private var canOpen: Bool {
        inTutorial || player.oystersAvailable(now: Clock.nowMs, tuning: tuning) > 0
    }

    func oystersAvailable(at date: Date) -> Int {
        player.oystersAvailable(now: date.timeIntervalSince1970 * 1000, tuning: tuning)
    }

    /// Secondes avant la prochaine huître, nil si le stock est plein.
    func nextOysterIn(at date: Date) -> TimeInterval? {
        nextRefillIn(player.stock, now: date.timeIntervalSince1970 * 1000, tuning).map { $0 / 1000 }
    }

    /// Le stock est vide : la marée remonte.
    func isTideOut(at date: Date) -> Bool {
        stage == .playing && engine.phase == .closed && !inTutorial && oystersAvailable(at: date) == 0
    }

    // MARK: - Temps qui passe

    /// Recharge le stock et renouvelle les missions (au lancement, au retour dans l'app, chaque minute).
    func refresh() {
        player.refresh(now: Clock.nowMs, day: Clock.dayKey(), tuning: tuning)
        Storage.save(player)
    }

    /// En quittant l'app : la notification « tes huîtres sont revenues » pour quand le stock sera plein
    /// (jamais pendant le tutoriel, où les huîtres sont offertes).
    func scheduleRefillNotification() {
        let fullIn = inTutorial ? nil : fullStockIn(player.stock, now: Clock.nowMs, tuning).map { $0 / 1000 }
        Notifications.scheduleRefill(in: fullIn, stockMax: tuning.oysterStockMax)
    }

    // MARK: - Gestes

    func drag(translation: Double) {
        guard stage == .playing, !hingeDriving else { return }
        if engine.phase == .closed {
            guard canOpen else { return }
            haptics.prepare()
        }
        thumb.drag(translation: translation, tuning: tuning)
    }

    func endDrag() {
        guard stage == .playing, !hingeDriving else { return }
        thumb.end(tuning: tuning, autoOpenFrom: engine.phase == .opening ? tuning.autoOpenFromAngle : nil)
    }

    /// iPhone Duo : nouvel angle de la charnière en degrés (nil = pas de charnière).
    /// Ouvrir le téléphone ouvre l'huître ; le refermer passe à la suivante (docs/duo-gadget.md §7).
    func hingeChanged(degrees: Double?) {
        guard let degrees else { hasHinge = false; return }
        hasHinge = true
        let action = hinge.update(degrees: degrees)
        hingeArmed = hinge.armed
        switch action {
        case .none:
            break
        case .closed:
            if stage.showsResult {
                nextOyster()
            } else if stage == .playing, engine.phase == .resisting {
                handleRelease()
            }
            // Refermé pendant l'ouverture : la charnière garde la main, rouvrir reprend l'huître.
            if engine.phase != .opening { hingeDriving = false }
        case .sample(let angle):
            guard stage == .playing, thumb.distance == 0 || hingeDriving else { return }
            if engine.phase == .closed {
                guard canOpen else { return }
                haptics.prepare()
            }
            hingeDriving = true
            // Tics de résistance espacés comme au pouce : l'angle est ramené à la course équivalente.
            let distance = angle / tuning.popAngle * tuning.resistanceDistance
            handle(OpeningSample(angle: angle, time: ThumbSource.now), distance: distance)
        }
    }

    /// Le pli de l'écran intérieur a bougé (on est passé d'un écran à l'autre).
    func foldChanged(x: Double?) {
        foldX = x
    }

    /// VoiceOver : ouverture lente et régulière, sans fêlure.
    func openForAccessibility() {
        guard stage == .playing, canOpen else { return }
        thumb.openSlowly(tuning: tuning, durationMs: 2600)
    }

    /// Toucher le poisson pendant qu'il s'enfuit : la perle revient (avec un peu de poussière d'or).
    func catchFish() {
        guard case .theft(let reveal) = stage, let elapsed = theftElapsedMs(at: Date()), fishThief.canCatch(elapsedMs: elapsed) else { return }
        let gained = player.resolveTheft(caught: true)
        rescuedDust = gained
        if gained > 0 { dustBump += 1 }
        save()
        haptics.reveal(tier: 1)
        audio.reveal(.pearl, tier: 1)
        theftStartedAt = nil
        stage = .card(reveal)
    }

    /// Toucher la carte (sur le Duo : refermer le téléphone) : huître suivante.
    func nextOyster() {
        guard stage.showsResult else { return }
        step = player.oystersOpened
        engine = OpeningEngine(tuning: tuning, crackProtected: catalog.isCrackProtected(oystersOpened: step))
        thumb.reset()
        hinge.disarmIfOpen()
        hingeArmed = hinge.armed
        hingeDriving = false
        lastTickDistance = 0
        angle = 0
        phase = .closed
        cracked = false
        inFragileZone = false
        tooFast = false
        shapeSeed = player.nextSerial
        current = player.oyster
        revealStartedAt = nil
        flashAt = nil
        theftStartedAt = nil
        rescuedDust = nil
        revealIsNew = false
        stage = .playing
    }

    /// Avancée du suspense (0 → 1) et angle du couvercle, qui finit de s'ouvrir en douceur après la révélation.
    func revealProgress(at date: Date) -> (suspense: Double, lidAngle: Double, flash: Double) {
        guard let start = revealStartedAt else { return (0, angle, 0) }
        let elapsed = date.timeIntervalSince(start) * 1000
        let suspense = smoothstep(0, max(suspenseMs, 1), elapsed)
        let lid = revealAngle + (180 - revealAngle) * smoothstep(0, tuning.revealLidSettleMs, elapsed)
        let flash = flashAt.map { 1 - smoothstep(0, tuning.revealFlashMs, date.timeIntervalSince($0) * 1000) } ?? 0
        return (suspense, lid, flash)
    }

    // MARK: - Comptoir, boutique, missions

    func sell(_ card: PearlCard) {
        if let gained = player.sell(serial: card.serial) { gainedDust(gained) }
    }

    func sellAllDuplicates() {
        gainedDust(player.sellAllDuplicates())
    }

    func buyOyster() {
        if player.buyOyster() { haptics.pop(); audio.purchase(); save() }
    }

    func buySkin(_ skinId: String) {
        if player.buySkin(skinId) { _ = player.equip(skinId); haptics.reveal(tier: 2); audio.purchase(); save() }
    }

    func equip(_ skinId: String) {
        if player.equip(skinId) { haptics.tick(); audio.tap(); save() }
    }

    // MARK: - Compte supprimé

    /// Efface la partie sur cet iPhone (après la suppression du compte) : on repart d'une partie neuve.
    /// Les skins achetés reviennent tout seuls (droits relus auprès d'Apple).
    func eraseLocalGame() {
        player = PlayerState.new(rng, tuning, now: Clock.nowMs)
        calendarOffered()
        step = 0
        engine = OpeningEngine(tuning: tuning, crackProtected: catalog.isCrackProtected(oystersOpened: 0))
        thumb.reset()
        hingeDriving = false
        lastTickDistance = 0
        angle = 0
        phase = .closed
        cracked = false
        inFragileZone = false
        tooFast = false
        current = player.oyster
        shapeSeed = player.nextSerial
        revealStartedAt = nil
        flashAt = nil
        theftStartedAt = nil
        rescuedDust = nil
        revealIsNew = false
        stage = .playing
        refresh()
        store.refreshEntitlements()
    }

    // MARK: - Pub récompensée

    func adRewardsLeft(at date: Date = Date()) -> Int {
        player.adRewardsLeft(day: Clock.dayKey(date))
    }

    /// Regarder une pub jusqu'au bout : des huîtres en plus (limite par jour dans le Core).
    func watchAd() {
        guard adRewardsLeft() > 0 else { return }
        // La pub a son propre son : la musique se tait pendant qu'elle passe.
        audio.setAdShowing(true)
        ads.show { [weak self] rewarded in
            self?.audio.setAdShowing(false)
            guard let self, rewarded, self.player.claimAdReward(day: Clock.dayKey()) != nil else { return }
            self.haptics.reveal(tier: 1)
            self.audio.reward()
            self.save()
        }
    }

    // MARK: - Achats intégrés

    /// Acheter un produit de la boutique Apple ; un skin acheté est équipé tout de suite.
    func purchase(_ productId: String) {
        Task {
            guard await store.purchase(productId) else { return }
            if let skin = economy.skins.first(where: { $0.productId == productId }) { equip(skin.id) }
        }
    }

    func restorePurchases() {
        Task { await store.restore() }
    }

    /// Un achat validé par StoreKit : le Core décide de ce qu'il donne.
    private func deliver(_ productId: String) {
        if let product = economy.consumables.first(where: { $0.id == productId }) {
            player.grant(product)
            if product.dust > 0 { dustBump += 1 }
            haptics.reveal(tier: 2)
            audio.purchase()
            save()
        } else if let skin = economy.skins.first(where: { $0.productId == productId }), !player.ownedSkins.contains(skin.id) {
            player.grantSkin(skin.id)
            save()
        }
    }

    // MARK: - Calendrier de connexion

    var canClaimDaily: Bool { player.canClaimDaily(day: Clock.dayKey()) }

    /// Au lancement ou au retour dans l'app : ouvrir le calendrier tout seul, une seule fois par jour
    /// (même si on le referme sans récupérer : il reste dans les missions du jour).
    var shouldOfferCalendar: Bool {
        canClaimDaily && UserDefaults.standard.string(forKey: Self.calendarOfferedKey) != Clock.dayKey()
    }

    /// Le calendrier vient de s'ouvrir tout seul aujourd'hui.
    func calendarOffered() {
        UserDefaults.standard.set(Clock.dayKey(), forKey: Self.calendarOfferedKey)
    }

    private static let calendarOfferedKey = "pearlinc.calendar.offeredDay"

    func claimDaily() {
        guard let reward = player.claimDaily(day: Clock.dayKey()) else { return }
        if reward.dust > 0 { dustBump += 1 }
        haptics.reveal(tier: 1)
        audio.reward()
        save()
    }

    func claimMission(at index: Int) {
        if let gained = player.claimMission(at: index) { gainedDust(gained) }
    }

    func recordShare() {
        player.recordShare()
        save()
    }

    private func gainedDust(_ amount: Int) {
        guard amount > 0 else { return }
        dustBump += 1
        haptics.tick()
        audio.dust()
        save()
    }

    private func save() { Storage.save(player) }

    // MARK: - Moteur

    private func handle(_ sample: OpeningSample, distance: Double) {
        let events = engine.push(sample)
        angle = engine.angle
        phase = engine.phase
        inFragileZone = engine.inFragileZone && engine.phase == .opening
        // Même seuil d'alerte que la webapp (features/oyster/oysterScreen.ts).
        tooFast = inFragileZone && engine.velocity > tuning.maxSafeVelocity * 0.6

        if engine.phase == .resisting, distance - lastTickDistance >= tuning.resistanceTickDistance {
            lastTickDistance = distance
            haptics.tick()
            audio.tick(step: Int(distance / tuning.resistanceTickDistance))
        }
        for event in events {
            switch event {
            case .pop:
                haptics.pop()
                audio.pop()
                if !hingeDriving { thumb.lockAfterPop(tuning: tuning) }
            case .crack:
                cracked = true
                haptics.crack()
                // Comme la webapp : une huître vide n'a rien à fêler.
                if pearl.glow != nil { audio.crack() }
            case .reveal(let lustre, let wasCracked):
                startReveal(lustre: lustre, cracked: wasCracked)
            }
        }
    }

    private func handleRelease() {
        engine.release()
        angle = engine.angle
        phase = engine.phase
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
        revealStartedAt = Date()
        revealAngle = engine.angle
        suspenseMs = tuning.revealSuspenseMs(tier: tier)
        player.refresh(now: Clock.nowMs, day: Clock.dayKey(), tuning: tuning)
        if let findId = current.findId {
            revealIsNew = !player.findCards.contains { $0.findId == findId }
        } else {
            revealIsNew = current.pearlId != "empty" && player.count(of: current.pearlId) == 0
        }
        let reveal = player.reveal(lustre: lustre, cracked: cracked, now: Clock.nowMs, rng: rng, thiefRng: thiefRng, tuning: tuning)
        if case .find(_, let dust) = reveal, dust > 0 { dustBump += 1 }
        save()
        let suspense = tuning.revealSuspenseMs(tier: tier)
        let style: Audio.RevealStyle = find != nil ? .find : pearl.id == "cursed" ? .cursed : pearl.glow == nil ? .empty : .pearl
        audio.lid()
        audio.setSuspense(true)
        Task { [weak self] in
            var elapsed = 0.0
            let pulse = self?.catalog.audio.pulseEveryMs ?? suspense
            while elapsed + pulse < suspense {
                try? await Task.sleep(for: .milliseconds(Int(pulse)))
                elapsed += pulse
                self?.haptics.suspensePulse(tier: tier)
                self?.audio.suspensePulse(tier: tier)
            }
            try? await Task.sleep(for: .milliseconds(Int(max(0, suspense - elapsed))))
            guard let self else { return }
            self.haptics.reveal(tier: tier)
            self.audio.setSuspense(false)
            self.audio.reveal(style, tier: tier)
            if tier >= 3 { self.flashAt = Date() }
            if case .pearl(let card) = reveal, self.player.stolenCard?.serial == card.serial {
                self.beginTheft(reveal)
            } else {
                self.stage = .card(reveal)
            }
        }
    }

    /// Le poisson fond sur la perle, la happe, puis s'enfuit avec ; s'il n'est pas touché à temps, elle est perdue.
    private func beginTheft(_ reveal: Reveal) {
        theftStartedAt = Date()
        stage = .theft(reveal)
        audio.lid()
        let fish = fishThief
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(Int(fish.arriveMs)))
            guard let self, case .theft = self.stage else { return }
            self.haptics.pop()
            self.audio.fish()
            try? await Task.sleep(for: .milliseconds(Int(fish.fleeMs)))
            guard case .theft = self.stage else { return }
            _ = self.player.resolveTheft(caught: false)
            self.save()
            self.haptics.crack()
            self.audio.reveal(.empty, tier: 0)
            self.theftStartedAt = nil
            self.stage = .stolen(reveal)
        }
    }
}

extension GameModel.Stage {
    /// La carte (ou le message du poisson qui a filé) est à l'écran : toucher passe à l'huître suivante.
    var showsResult: Bool {
        switch self {
        case .card, .stolen: true
        default: false
        }
    }
}
