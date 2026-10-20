import SwiftUI
import PearlCore

/// Le poisson voleur a filé avec la perle : un mot pour en rire, et on passe à l'huître suivante
/// (toucher, ou sur le Duo refermer le téléphone).
struct StolenView: View {
    @Environment(GameModel.self) private var game
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let reveal: Reveal

    var body: some View {
        VStack(spacing: 16) {
            TimelineView(.animation(paused: reduceMotion)) { timeline in
                Canvas { c, size in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    let center = CGPoint(x: size.width / 2 + sin(t * 1.3) * 10, y: size.height / 2 + sin(t * 2.1) * 5)
                    ThiefFishArt.drawFish(&c, at: center, length: size.width * 0.62, heading: 0, flap: sin(t * 10) * 0.3, time: t,
                                          carrying: look, pearlRadius: size.width * 0.06, glow: pearl?.glow)
                }
            }
            .frame(width: 170, height: 100)
            .accessibilityHidden(true)

            Text(title)
                .font(.system(size: 22, weight: .bold))
                .multilineTextAlignment(.center)
            Text("Ça arrive aux meilleurs pêcheurs. La prochaine fois, touche-le pendant qu’il s’enfuit.")
                .font(.system(size: 15))
                .multilineTextAlignment(.center)
                .opacity(0.85)
            Group {
                if game.hasHinge { Text("Referme le téléphone pour l’huître suivante") } else { Text("Touche pour l’huître suivante") }
            }
            .font(.system(size: 14, weight: .semibold))
            .opacity(0.75)
            .padding(.top, 4)
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.2), radius: 2)
        .padding(24)
        .frame(maxWidth: 340)
        .glassPanel(cornerRadius: 28, shade: 0.35)
        .padding(.horizontal, 24)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    private var pearl: PearlType? {
        if case .pearl(let card) = reveal { return game.catalog.pearl(card.pearlId) }
        return nil
    }

    private var look: PearlLook? {
        guard case .pearl(let card) = reveal, let pearl else { return nil }
        return PearlLook(pearl, traits: card.traits, catalog: game.catalog)
    }

    private var title: String {
        let name = pearl?.name.lowercased() ?? ""
        return String(localized: "Un poisson a filé avec ta \(name) !", comment: "Le poisson voleur a emporté la perle")
    }
}
