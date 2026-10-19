import SwiftUI
import PearlCore

/// La révélation : la carte (comme dans le prototype de pearl-inc.app), le partage, et l'invitation
/// à passer à l'huître suivante. Toucher la carte (sur le Duo : refermer le téléphone) passe à la suivante.
struct RevealCardView: View {
    @Environment(GameModel.self) private var game
    let reveal: Reveal

    var body: some View {
        VStack(spacing: 18) {
            PearlCardView(content: content, width: 300)
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Touche la carte pour l'huître suivante")

            VStack(spacing: 10) {
                Group {
                    if game.hasHinge { Text("Referme le téléphone pour l’huître suivante") } else { Text("Touche la carte pour l’huître suivante") }
                }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.25), radius: 3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 18)
                    .frame(minHeight: 38)
                    .glass(Capsule())
                if let message = shareMessage {
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

    private var content: PearlCardView.Content {
        switch reveal {
        case .pearl(let card): .pearl(card)
        case .find(let card, let dust): .find(card, dust: dust)
        case .empty(let serial): .empty(serial: serial)
        }
    }

    /// Texte partagé (l'image story viendra ensuite).
    private var shareMessage: String? {
        switch reveal {
        case .pearl(let card):
            let pearl = game.catalog.pearl(card.pearlId)
            let name = pearl.name.lowercased(), rarity = pearl.rarity, serial = GameText.serial(card.serial)
            return String(localized: "J’ai trouvé une \(name) \(rarity) dans Pearl Inc. (\(serial)) 🦪 pearl-inc.app", comment: "Message partagé")
        case .find(let card, _):
            let name = game.catalog.find(card.findId).name
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
