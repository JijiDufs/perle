import SwiftUI
import PearlCore

/// La carte d'une perle, d'une trouvaille ou d'une huître vide, dessinée comme dans le prototype de
/// pearl-inc.app : cadre de la couleur de la perle, vitrine où elle brille, taille / lustre / valeur / N°,
/// texte d'ambiance ; reflet holographique qui passe sur les plus rares.
struct PearlCardView: View {
    enum Content {
        case pearl(PearlCard)
        case find(FindCard, dust: Int)
        case empty(serial: Int)
    }

    @Environment(GameModel.self) private var game
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Le doigt qui fait jouer la carte dans la lumière (`CardTilt`).
    @Environment(\.cardLight) private var light
    let content: Content
    var width: CGFloat = 300

    /// Échelle du prototype (carte de 690 px de haut, 63 × 88).
    private var s: CGFloat { width / (690 * 63 / 88) }
    private var height: CGFloat { width * 88 / 63 }

    var body: some View {
        let frame = self.frame
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.system(size: 40 * s, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.6)
                Spacer(minLength: 8)
                Text(rarity).font(.system(size: 28 * s, weight: .semibold))
            }
            .padding(.horizontal, 6 * s)
            .frame(height: 74 * s)

            well(frame)
                .frame(height: height * 0.47)
                .clipShape(RoundedRectangle(cornerRadius: 20 * s, style: .continuous))

            details.padding(.top, 18 * s).padding(.horizontal, 2 * s)
            Spacer(minLength: 0)
        }
        .foregroundStyle(frame.ink)
        .padding(.horizontal, 22 * s)
        .padding(.bottom, 22 * s)
        .frame(width: width, height: height)
        .background(LinearGradient(colors: frame.colors.map { Color(hex: $0) }, startPoint: .topLeading, endPoint: .bottomTrailing))
        .overlay { if showsHolo { holo } }
        .overlay { if let light { glare(light) } }
        .clipShape(RoundedRectangle(cornerRadius: 30 * s, style: .continuous))
        .shadow(color: .black.opacity(0.45), radius: 22 * s, y: 18 * s)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Contenu

    private var frame: CardFrame {
        switch content {
        case .pearl(let card): CardFrame.pearl(card.pearlId)
        case .find(let card, _): CardFrame.find(tier: game.catalog.find(card.findId).tier)
        case .empty: CardFrame.pearl("empty")
        }
    }

    private var title: String {
        switch content {
        case .pearl(let card):
            return GameText.pearlName(game.catalog.pearl(card.pearlId).name, cracked: card.cracked)
        case .find(let card, _): return game.catalog.find(card.findId).name
        case .empty: return game.catalog.pearl("empty").name
        }
    }

    private var rarity: String {
        switch content {
        case .pearl(let card): return game.catalog.pearl(card.pearlId).rarity
        case .find(let card, _):
            let tier = game.catalog.find(card.findId).tier
            return String(repeating: "◆", count: min(tier, 3)) + String(repeating: "★", count: max(0, tier - 3))
        case .empty: return game.catalog.pearl("empty").rarity
        }
    }

    private var showsHolo: Bool {
        guard case .pearl(let card) = content, !card.cracked else { return false }
        return game.catalog.pearl(card.pearlId).revealTier >= 2
    }

    /// La vitrine : fond nacré (ou nuit pour les cartes sombres), halo, perle ou trouvaille (certaines s'animent).
    private func well(_ frame: CardFrame) -> some View {
        TimelineView(.animation(paused: reduceMotion || !isFind)) { timeline in
        Canvas { c, size in
            let time = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3600)
            let w = Double(size.width), h = Double(size.height)
            let colors = frame.well.map { Color(hex: $0) }
            c.fill(Path(CGRect(origin: .zero, size: size)), with: .radialGradient(
                Gradient(colors: colors), center: CGPoint(x: w / 2, y: h * 0.55), startRadius: 6, endRadius: w * 0.75))
            switch content {
            case .pearl(let card):
                let pearl = game.catalog.pearl(card.pearlId)
                let look = PearlLook(pearl, traits: card.traits, catalog: game.catalog)
                PearlArt.glow(&c, w / 2, h / 2, w * 0.5, pearl.glow, 0.55, additive: false)
                PearlArt.draw(&c, w / 2, h / 2, w * (pearl.id == "giant" ? 0.2 : 0.15), look, cracked: card.cracked)
            case .find(let card, _):
                let find = game.catalog.find(card.findId)
                PearlArt.glow(&c, w / 2, h / 2, w * 0.5, find.glow, 0.6, additive: false)
                FindArt.draw(c, w / 2, h / 2, h * 0.36, id: find.id, t: time)
            case .empty:
                let r = w * 0.17
                c.stroke(Path(ellipseIn: CGRect(x: w / 2 - r, y: h / 2 - r, width: r * 2, height: r * 2)),
                         with: .color(rgba(30, 40, 40, 0.35)), style: StrokeStyle(lineWidth: 3 * s, dash: [10 * s, 10 * s]))
            }
        }
        }
        .accessibilityHidden(true)
    }

    private var isFind: Bool { if case .find = content { true } else { false } }

    @ViewBuilder private var details: some View {
        switch content {
        case .pearl(let card):
            let pearl = game.catalog.pearl(card.pearlId)
            VStack(alignment: .leading, spacing: 10 * s) {
                HStack(alignment: .top, spacing: 10 * s) {
                    stat("Taille", card.sizeMm.formatted(.number.precision(.fractionLength(1))) + " mm")
                    stat("Lustre", card.lustre.rawValue)
                    stat("Valeur", "\(Int(card.value))")
                    stat("N°", GameText.serialTag(card.serial))
                }
                if let traits = card.traits {
                    Text(traitsLabel(traits)).font(.system(size: 20 * s, weight: .medium)).opacity(0.75).lineLimit(1).minimumScaleFactor(0.7)
                }
                Text(pearl.flavor).font(.system(size: 23 * s)).opacity(0.88).lineLimit(3).minimumScaleFactor(0.8)
                if card.cracked {
                    Text("Fêlée : sa valeur est divisée par deux").font(.system(size: 21 * s, weight: .bold))
                        .foregroundStyle(Color(hex: frame.dark ? "#ffb3a6" : "#8a2a1e"))
                }
            }
        case .find(let card, let dust):
            let find = game.catalog.find(card.findId)
            VStack(alignment: .leading, spacing: 10 * s) {
                HStack {
                    Text("Trouvaille").font(.system(size: 22 * s, weight: .bold)).opacity(0.75)
                    Spacer()
                    Text(GameText.serialTag(card.serial)).font(.system(size: 22 * s, weight: .bold))
                }
                Text(find.flavor).font(.system(size: 23 * s)).opacity(0.88).lineLimit(4).minimumScaleFactor(0.8)
                if dust > 0 { Text("+ \(dust) ✦ de poussière d’or").font(.system(size: 24 * s, weight: .bold)) }
            }
        case .empty(let serial):
            VStack(spacing: 10 * s) {
                Text(game.catalog.pearl("empty").flavor).font(.system(size: 25 * s)).multilineTextAlignment(.center)
                Text(GameText.serialTag(serial)).font(.system(size: 20 * s, weight: .semibold)).opacity(0.6)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 24 * s)
        }
    }

    private func stat(_ label: LocalizedStringKey, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2 * s) {
            Text(label).font(.system(size: 19 * s, weight: .medium)).opacity(0.7)
            Text(value).font(.system(size: 26 * s, weight: .bold)).lineLimit(1).minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func traitsLabel(_ traits: PearlTraits) -> String {
        let shape = game.catalog.shapes[traits.shape]?.label ?? traits.shape
        let overtone = game.catalog.overtones[traits.overtone]?.label ?? traits.overtone
        let mark = traits.mark.flatMap { game.catalog.marks[$0]?.label }
        return GameText.traits(shape: shape, overtone: overtone, mark: mark)
    }

    /// Le reflet du doigt : une tache de lumière qui glisse sur la carte quand on l'incline.
    private func glare(_ point: CGPoint) -> some View {
        RadialGradient(colors: [.white.opacity(0.38), .white.opacity(0.1), .white.opacity(0)],
                       center: UnitPoint(x: point.x, y: point.y), startRadius: 0, endRadius: width * 0.7)
            .blendMode(.plusLighter)
            .allowsHitTesting(false)
    }

    /// Reflet holographique qui balaie la carte (perles ◆◆◆ et plus) ; il suit le doigt quand on fait jouer la carte.
    private var holo: some View {
        TimelineView(.animation(paused: reduceMotion || light != nil)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let q = light.map { ($0.x + $0.y) / 2 * 1.3 - 0.15 } ?? (t * 0.35).truncatingRemainder(dividingBy: 1.6) - 0.3
            let st = { (v: Double) in min(1, max(0, v)) }
            LinearGradient(stops: [
                .init(color: .white.opacity(0), location: st(q - 0.15)),
                .init(color: rgba(255, 120, 200, 0.45), location: st(q - 0.05)),
                .init(color: rgba(120, 240, 255, 0.5), location: st(q)),
                .init(color: rgba(255, 240, 120, 0.45), location: st(q + 0.06)),
                .init(color: .white.opacity(0), location: st(q + 0.16)),
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
            .blendMode(.overlay)
        }
        .allowsHitTesting(false)
    }
}
