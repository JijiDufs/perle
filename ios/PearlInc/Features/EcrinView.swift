import SwiftUI
import PearlCore

/// L'onglet Écrins (lot 1.4) : le salon du joaillier, l'écrin en cuir qui s'ouvre au pouce (ou à la charnière du Duo).
/// Quelque part, le bijou se met à scintiller : s'y arrêter et tenir donne l'éclat parfait. Probabilités affichées
/// avant d'ouvrir. Aucune règle ici : tout vient de GlintEngine et de PlayerState (par GameModel).
struct EcrinView: View {
    @Environment(GameModel.self) private var game
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showOdds = false

    var body: some View {
        ZStack {
            TimelineView(.animation(paused: reduceMotion && game.ecrinPhase == .closed)) { timeline in
                Canvas { context, size in draw(context, size: size, date: timeline.date) }
            }
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { game.ecrinDrag(translation: $0.translation.height) }
                    .onEnded { _ in game.ecrinEndDrag() }
            )
            .accessibilityElement()
            .accessibilityLabel(game.shownEcrin == nil ? Text("Pas d’écrin à ouvrir") : Text("Écrin fermé"))
            .accessibilityHint("Glisse le doigt vers le haut pour l'ouvrir, et arrête-toi quand le bijou scintille.")
            .accessibilityAction(named: "Ouvrir l'écrin") { game.openEcrinForAccessibility() }

            VStack(spacing: 12) {
                header
                if let coach = coachText { CoachBubble(text: coach).padding(.horizontal, 24) }
                Spacer()
                if game.shownEcrin != nil && game.ecrinStage == .playing {
                    if game.firstEcrin { glintGauge }
                    status
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
            .besideFold(game.foldX)

            if game.shownEcrin == nil && game.ecrinStage == .playing {
                EmptyEcrins()
                    .besideFold(game.foldX)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if case .card(let card) = game.ecrinStage {
                Color(hex: 0x0A0306).opacity(0.35).ignoresSafeArea().allowsHitTesting(false)
                JewelRevealView(card: card)
                    .besideFold(game.foldX)
                    .transition(.scale(scale: 0.3).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.45, bounce: 0.35), value: game.ecrinStage)
        .animation(.easeInOut(duration: 0.3), value: game.shownEcrin == nil)
        .onAppear { game.prepareEcrin() }
        .sheet(isPresented: $showOdds) {
            NavigationStack {
                ScrollView { EcrinOddsList().padding(20) }
                    .navigationTitle("Ce que contient un écrin")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { Button("Fermer") { showOdds = false } }
            }
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Interface

    /// Sur une ligne ; sur la moitié d'écran du Duo, le bouton des probabilités passe dessous.
    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack { title; Spacer(); oddsButton }
            VStack(alignment: .leading, spacing: 8) { title; oddsButton }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
    }

    private var title: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("Écrins").font(.title2.weight(.bold))
            if game.ecrinsToOpen > 0 {
                Text("\(game.ecrinsToOpen) à ouvrir").font(.subheadline).opacity(0.75)
            }
        }
        .lineLimit(1)
        .fixedSize()
    }

    /// Les probabilités avant d'ouvrir (règle 3.1.1).
    @ViewBuilder private var oddsButton: some View {
        if game.ecrinStage == .playing && game.ecrinPhase == .closed {
            Button { showOdds = true } label: { Label("Probabilités", systemImage: "percent") }
                .buttonStyle(GlassButtonStyle(compact: true))
                .fixedSize()
        }
    }

    private var status: some View {
        Text(statusText)
            .font(.headline)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .glass(Capsule())
            .foregroundStyle(game.glintPerfect ? Palette.gold : .white)
            .padding(.horizontal, 16)
    }

    /// Jauge d'éclat, pour le premier écrin seulement (l'angle d'éclat guidé, cahier §15).
    private var glintGauge: some View {
        let fill = game.glintPerfect ? 1 : max(game.glintCloseness * 0.6, game.glintHold)
        return HStack(spacing: 10) {
            Text(game.glintPerfect ? "Éclat parfait" : "Éclat").font(.caption.weight(.bold))
            GeometryReader { proxy in
                Capsule().fill(.white.opacity(0.2))
                    .overlay(alignment: .leading) { Capsule().fill(Palette.gold).frame(width: proxy.size.width * fill) }
            }
            .frame(height: 8)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .glass(Capsule())
        .frame(maxWidth: 260)
        .padding(.horizontal, 16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Éclat"))
        .accessibilityValue(Text(fill.formatted(.percent.precision(.fractionLength(0)))))
    }

    private var statusText: String {
        let t = game.tuning
        switch game.ecrinPhase {
        case .closed:
            if game.hasHinge {
                return game.hingeArmed ? String(localized: "Ouvre le téléphone doucement") : String(localized: "Referme le téléphone, puis ouvre-le")
            }
            return (game.shownRarity?.tier ?? 0) >= 4 ? String(localized: "Un éclat filtre… Glisse le pouce vers le haut")
                : String(localized: "Ouvre l’écrin : glisse le pouce vers le haut")
        case .resisting:
            return String(localized: "Ouvre doucement…")
        default:
            if game.glintPerfect, game.variantRevealed, let variant = game.pendingVariant {
                return String(localized: "Variante rare : \(variant.label) ! Ouvre jusqu’au bout")
            }
            if game.glintPerfect { return String(localized: "Éclat parfait ! Ouvre jusqu’au bout") }
            if game.ecrinAngle > t.fragileMinAngle && game.ecrinAngle < t.revealAngle {
                return game.glintCloseness > 0.75 ? String(localized: "Ça scintille… ne bouge plus") : String(localized: "Cherche l’angle d’éclat")
            }
            return String(localized: "Encore un peu…")
        }
    }

    /// La bulle du premier écrin : comment trouver l'éclat parfait.
    private var coachText: String? {
        guard game.firstEcrin, game.ecrinStage == .playing, game.shownEcrin != nil, !game.glintPerfect else { return nil }
        if game.ecrinPhase == .closed || game.ecrinPhase == .resisting {
            return String(localized: "Ton premier écrin ! Ouvre lentement : quelque part, le bijou se met à scintiller. Arrête-toi pile là et tiens une seconde.")
        }
        return game.glintCloseness > 0.75 ? String(localized: "C’est là ! Ne bouge plus…")
            : String(localized: "Monte ou descends doucement jusqu’à ce que ça brille fort.")
    }

    // MARK: - Dessin

    private func draw(_ context: GraphicsContext, size: CGSize, date: Date) {
        let c = Canvas2D(context)
        let w = Double(size.width), h = Double(size.height)
        let t = reduceMotion ? 0 : date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3600)
        let visible = h - 190
        // Sur l'iPhone Duo, l'écrin est vu de dessus comme l'huître. Écran intérieur : sa charnière sur le pli, le
        // plateau à droite, le couvercle ouvert à plat à gauche (c'est le téléphone qui le soulève) ; ouvrir le
        // téléphone éclaire l'intérieur. Écran extérieur : fermé, charnière à gauche. iPhone classique : trois quarts.
        let top = game.hasHinge || game.foldX != nil
        let cx, cy, bw: Double
        if let fold = game.foldX {
            // Chaque moitié de l'écrin (plateau, couvercle) tient dans sa moitié d'écran.
            bw = min(min(fold, w - fold) * 1.2, visible * 0.68)
            cx = fold + bw * 0.35
            cy = 100 + visible * 0.5
        } else if top {
            bw = min(w * 0.9, visible * 0.68)
            cx = w / 2
            cy = 100 + visible * 0.5
        } else {
            bw = min(w * 0.86, visible * 0.68)
            cx = w / 2
            cy = 100 + visible * 0.62
        }
        let salon = SalonArt(time: t, focus: .init(x: cx, y: cy, w: bw * 0.8, h: bw * 0.45))
        salon.draw(c, w: w, h: h)
        guard let pending = game.shownEcrin, let rarity = game.shownRarity else {
            salon.drawOverlay(c, w: w, h: h)
            return
        }

        let angle = game.ecrinAngle
        let sparkle = game.glintPerfect ? 1 : game.glintCloseness
        let open = smoothstep(1, 25, angle)
        let suspense = game.ecrinRevealStartedAt.map { smoothstep(0, max(game.ecrinSuspenseMs, 1), date.timeIntervalSince($0) * 1000) } ?? 0
        let variant = game.variantRevealed ? game.pendingVariant : nil
        let glow = variant?.glow ?? rarity.glow
        let sparkleTier = variant != nil ? max(rarity.tier, 5) : rarity.tier
        let look = JewelArt.Look(pending.jewel, variant: variant?.id, catalog: game.catalog)

        EcrinArt.drawShadow(c, cx: cx, cy: cy, width: bw, top: top)
        let anchors = EcrinArt.draw(
            c, cx: cx, cy: cy, width: bw, leather: EcrinArt.leathers[game.leather], angle: game.foldX == nil ? angle : 180,
            dim: 1 - smoothstep(4, 140, angle),
            sweep: rarity.tier >= 4 && game.ecrinPhase == .closed && !reduceMotion ? (t * 0.5).truncatingRemainder(dividingBy: 1.6) - 0.3 : nil,
            top: top,
            drawJewel: { JewelArt.draw(c, 0, (JewelArt.yOffset(pending.jewel) - 0.5) * 0.66, 0.66 / 440, look) },
            drawEffects: { x, y, unit in
                guard let glow else { return }
                drawGlow(c, x, y, unit * (0.32 + Double(sparkleTier) * 0.04), glow, open * (0.12 + 0.45 * sparkle) + suspense * 0.3)
                JewelArt.drawSparkles(c, x, y, tier: sparkleTier, glow: glow, t: t, alpha: open * (0.15 + 0.85 * sparkle) + suspense * 0.5, scale: unit / 700)
            }
        )

        // La lumière filtre par l'entrebâillement, au bord avant du couvercle.
        // (Pas sur l'écran intérieur du Duo : le couvercle y est déjà ouvert à plat.)
        let leak = game.foldX == nil ? smoothstep(0.5, 10, angle) * (1 - smoothstep(40, 95, angle)) : 0
        if leak > 0.001 { drawGlow(c, anchors.lidEdge.0, anchors.lidEdge.1, bw * 0.5, rarity.glow ?? "#fff1d6", leak * 0.6) }

        // Gerbe d'étoiles de l'éclat parfait ; deux vagues, à la couleur de la variante, si elle apparaît.
        if let perfectAt = game.perfectAt, !reduceMotion {
            let elapsed = date.timeIntervalSince(perfectAt) * 1000
            for wave in 0..<(variant != nil ? 2 : 1) {
                let delay = Double(wave) * 250
                let burst = 1 - smoothstep(0, 700 + Double(wave) * 400, elapsed - delay)
                guard burst > 0, elapsed >= delay else { continue }
                for i in 0..<14 {
                    let a = Double(i) / 14 * 2 * .pi + Double(wave) * 0.22
                    let radius = bw / 600 * (120 + (1 - burst) * (300 + Double(wave) * 120))
                    JewelArt.drawStar(c, anchors.jewel.0 + cos(a) * radius, anchors.jewel.1 + sin(a) * radius * 0.8,
                                      bw / 600 * (30 * burst + 8), burst, wave == 1 ? glow ?? "#fff3c4" : "#fff3c4")
                }
            }
        }
        salon.drawOverlay(c, w: w, h: h)
    }
}

/// Plus d'écrin à ouvrir : d'où en viennent d'autres (niveaux, comptoir), sans rien annoncer qui n'existe pas.
/// Les probabilités sont à côté, dans l'en-tête.
private struct EmptyEcrins: View {
    @Environment(GameModel.self) private var game

    var body: some View {
        let price = game.ecrinPrice
        let level = game.catalog.levelProgress(reputation: game.player.reputation).level
        let next = ((level + 1)...(level + 10)).first { game.catalog.levelReward($0).ecrins > 0 } ?? level + 1
        VStack(spacing: 14) {
            Text("Pas d’écrin pour l’instant").font(.title3.weight(.bold)).multilineTextAlignment(.center)
            Text("Tu en gagnes un tous les \(game.economy.ecrins.levelEvery) niveaux et à chaque nouveau rang : le prochain au niveau \(next).")
                .font(.subheadline).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true).opacity(0.85)
            Button { game.buyEcrin() } label: { Text("Acheter un écrin · \(price) ✦") }
                .buttonStyle(PearlButtonStyle())
                .disabled(game.player.dust < price)
            Text("Tu as \(game.player.dust) ✦").font(.footnote.monospacedDigit()).opacity(0.75)
        }
        .foregroundStyle(.white)
        .padding(22)
        .frame(maxWidth: 360)
        .glassPanel(cornerRadius: 26, rim: Palette.gold, shade: 0.4)
        .padding(.horizontal, game.foldX == nil ? 24 : 8)
        .environment(\.buttonLabelWraps, game.foldX != nil)
    }
}

/// La carte du bijou révélé, son partage, et l'invitation à passer à l'écrin suivant.
private struct JewelRevealView: View {
    @Environment(GameModel.self) private var game
    let card: JewelCard

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 16) {
                if game.firstEcrin {
                    CoachBubble(text: card.perfect ? String(localized: "Éclat parfait ! Le bijou vaut 50 % de plus.")
                        : String(localized: "Pas d’éclat parfait cette fois : arrête-toi pile quand ça brille le plus, et tiens une seconde."))
                }
                PearlCardView(content: .jewel(card), width: min(300, proxy.size.width - 48, (proxy.size.height - 200) * 63 / 88))
                    .overlay(alignment: .topTrailing) {
                        if game.ecrinIsNew { newBadge }
                    }
                    .cardTilt { withAnimation(.snappy) { game.nextEcrin() } }
                    .background { RevealBurst(glow: glow, tier: tier).frame(width: 700, height: 900) }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityHint("Touche la carte pour continuer")
                    .accessibilityAction { withAnimation(.snappy) { game.nextEcrin() } }
                    // Place pour le badge « Nouveau ! », qui dépasse au-dessus de la carte.
                    .padding(.top, game.ecrinIsNew ? 12 : 0)
                VStack(spacing: 10) {
                    Group {
                        if game.hasHinge {
                            Text("Referme le téléphone pour continuer")
                        } else if game.player.currentEcrin != nil || game.player.ecrins > 0 {
                            Text("Touche la carte pour l’écrin suivant (\(game.ecrinsToOpen))")
                        } else {
                            Text("Touche la carte pour continuer")
                        }
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 6)
                    .frame(minHeight: 38)
                    .glass(RoundedRectangle(cornerRadius: 19, style: .continuous))
                    if let message = PearlCardView.Content.jewel(card).shareMessage(game.catalog) {
                        ShareLink(item: message) { Label("Partager", systemImage: "square.and.arrow.up") }
                            .buttonStyle(GlassButtonStyle(compact: true))
                            .fixedSize()
                            .simultaneousGesture(TapGesture().onEnded { game.recordShare() })
                    }
                }
            }
            .padding(.horizontal, 24)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    private var newBadge: some View {
        Text("Nouveau !")
            .font(.system(size: 14, weight: .heavy))
            .foregroundStyle(Color(hex: "#2a1600"))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Palette.gold))
            .overlay(Capsule().stroke(.white.opacity(0.7), lineWidth: 1.5))
            .rotationEffect(.degrees(6))
            .offset(x: 12, y: -24)
    }

    private var glow: String? {
        card.variant.flatMap { game.catalog.jewelVariant($0)?.glow } ?? game.catalog.jewelRarity(card.jewel.rarityId).glow
    }

    private var tier: Int {
        card.variant != nil ? 3 : max(0, min(3, game.catalog.jewelRarity(card.jewel.rarityId).tier - 1))
    }
}

/// Les probabilités des écrins, toujours affichées avant d'ouvrir (règle 3.1.1) et dans Réglages → Probabilités.
struct EcrinOddsList: View {
    @Environment(GameModel.self) private var game

    var body: some View {
        let t = game.tuning
        VStack(spacing: 10) {
            ForEach(game.catalog.jewels.rarities) { rarity in
                HStack {
                    Text(verbatim: "\(rarity.label)  \(rarity.rarity)").font(.subheadline)
                    Spacer()
                    Text(rarity.probability.formatted(.percent.precision(.fractionLength(0...2))))
                        .font(.subheadline.monospacedDigit()).foregroundStyle(.white.opacity(0.85))
                }
            }
            Group {
                Text("Garantie : un bijou ★ ou plus rare au plus tard au \(t.ecrinPityThreshold + 1)ᵉ écrin.")
                Text("Éclat parfait : valeur ×\(t.glintPerfectMultiplier.formatted()), et \(t.glintRareVariantChance.formatted(.percent.precision(.fractionLength(0)))) de chance d’une variante rare (Aurore, Nuit ou Givre) : valeur ×\(t.glintRareVariantMultiplier.formatted()).")
                Text("Les écrins se gagnent tous les \(game.economy.ecrins.levelEvery) niveaux et à chaque nouveau rang, ou s’achètent \(game.ecrinPrice) ✦ au comptoir. Jamais contre de l’argent réel.")
            }
            .font(.caption).foregroundStyle(.white.opacity(0.65)).frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(.white)
    }
}
