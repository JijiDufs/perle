import SwiftUI
import PearlCore

/// La révélation : la carte (comme dans le prototype de pearl-inc.app), le partage, et l'invitation
/// à passer à l'huître suivante. Toucher la carte (sur le Duo : refermer le téléphone) passe à la suivante.
struct RevealCardView: View {
    @Environment(GameModel.self) private var game
    let reveal: Reveal
    var body: some View {
        // Largeur disponible : sur l'écran intérieur du Duo, la moitié droite est plus étroite que la carte.
        GeometryReader { proxy in
            layout(available: proxy.size.width)
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    private func layout(available: CGFloat) -> some View {
        VStack(spacing: 18) {
            if let coach = Coach.afterReveal(step: game.step, cracked: game.cracked) {
                CoachBubble(text: coach)
            }
            PearlCardView(content: content, width: min(300, available - 48))
                // Au-dessus de la rareté, et sous la carte : les badges ne cachent rien de la carte.
                .overlay(alignment: .topTrailing) {
                    if game.revealIsNew { badge(Text("Nouvelle !"), color: Palette.gold).rotationEffect(.degrees(6)).offset(x: 12, y: -24) }
                }
                .overlay(alignment: .bottom) {
                    if let dust = game.rescuedDust {
                        badge(Text("Rattrapée au vol ! + \(dust) ✦"), color: Color(hex: "#ff9d3c")).rotationEffect(.degrees(-3)).offset(y: 14)
                    }
                }
                // Rester appuyé et bouger le doigt fait jouer la carte dans la lumière ; un toucher bref passe à la suivante.
                .cardTilt { withAnimation(.snappy) { game.nextOyster() } }
                .background { RevealBurst(glow: glow, tier: tier).frame(width: 700, height: 900) }
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Touche la carte pour l'huître suivante")
                // Place pour le badge « Nouvelle ! », qui dépasse au-dessus de la carte (sinon il mord sur la bulle).
                .padding(.top, game.revealIsNew ? 12 : 0)
                .accessibilityAction { withAnimation(.snappy) { game.nextOyster() } }

            VStack(spacing: 10) {
                Group {
                    if game.hasHinge { Text("Referme le téléphone pour l’huître suivante") } else { Text("Touche la carte pour l’huître suivante") }
                }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.25), radius: 3)
                    // Sur plusieurs lignes si la place manque (moitié d’écran du Duo).
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 6)
                    .frame(minHeight: 38)
                    .glass(RoundedRectangle(cornerRadius: 19, style: .continuous))
                if let message = content.shareMessage(game.catalog) {
                    ShareLink(item: message) {
                        Label("Partager", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(GlassButtonStyle(compact: true))
                    .fixedSize()
                    .simultaneousGesture(TapGesture().onEnded { game.recordShare() })
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private func badge(_ text: Text, color: Color) -> some View {
        text
            .font(.system(size: 14, weight: .heavy))
            .foregroundStyle(Color(hex: "#2a1600"))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(color))
            .overlay(Capsule().stroke(.white.opacity(0.7), lineWidth: 1.5))
            .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
            .transition(.scale.combined(with: .opacity))
    }

    /// La lumière et l'ampleur de la révélation, pour la gerbe d'étincelles.
    private var glow: String? {
        switch reveal {
        case .pearl(let card): game.catalog.pearl(card.pearlId).glow
        case .find(let card, _): game.catalog.find(card.findId).glow
        case .empty: nil
        }
    }

    private var tier: Int {
        switch reveal {
        case .pearl(let card): game.catalog.pearl(card.pearlId).revealTier
        case .find(let card, _): min(3, game.catalog.find(card.findId).tier - 1)
        case .empty: 0
        }
    }

    private var content: PearlCardView.Content {
        switch reveal {
        case .pearl(let card): .pearl(card)
        case .find(let card, let dust): .find(card, dust: dust)
        case .empty(let serial): .empty(serial: serial)
        }
    }
}

extension PearlCardView.Content {
    /// Texte partagé (l'image story viendra ensuite) ; nil pour une huître vide.
    func shareMessage(_ catalog: Catalog) -> String? {
        switch self {
        case .pearl(let card):
            let pearl = catalog.pearl(card.pearlId)
            let name = pearl.name.lowercased(), rarity = pearl.rarity, serial = GameText.serial(card.serial)
            return String(localized: "J’ai trouvé une \(name) \(rarity) dans Pearl Inc. (\(serial)) 🦪 pearl-inc.app", comment: "Message partagé")
        case .find(let card, _):
            let name = catalog.find(card.findId).name
            return String(localized: "Il y avait « \(name) » dans mon huître. Pearl Inc. 🦪 pearl-inc.app", comment: "Message partagé")
        case .empty:
            return nil
        }
    }
}

/// Une trouvaille en relief avec sa lumière, pour les petites cases (collection), comme findCanvas de la webapp.
struct FindThumb: View {
    let find: FindType
    var size: CGFloat = 30

    var body: some View {
        Canvas { c, canvasSize in
            let mid = Double(canvasSize.width) / 2
            PearlArt.glow(&c, mid, mid, Double(size) * 0.5, find.glow, 0.45)
            FindArt.draw(c, mid, mid, Double(size) * 0.36, id: find.id)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Une perle dessinée avec son halo, pour les petites cases (collection).
struct PearlThumb: View {
    let look: PearlLook?
    let glow: String?
    var size: CGFloat = 40

    var body: some View {
        Canvas { c, canvasSize in
            let x = Double(canvasSize.width) / 2, y = Double(canvasSize.height) / 2
            PearlArt.glow(&c, x, y, Double(size) * 1.1, glow, 0.45)
            if let look { PearlArt.draw(&c, x, y, Double(size) / 2, look, cracked: false) }
        }
        .frame(width: size * 2.2, height: size * 2.2)
        .accessibilityHidden(true)
    }
}
