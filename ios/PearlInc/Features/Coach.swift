import SwiftUI
import PearlCore

/// Textes d'accompagnement des premières huîtres (cahier §15), repris de src/features/oyster/coach.ts.
/// Uniquement de l'affichage : le déroulé (perles imposées, protection) est décidé dans PearlCore/Tutorial.
enum Coach {
    /// Bulle au-dessus de l'huître pendant le geste. `step` = huîtres déjà ouvertes.
    static func duringGesture(step: Int, phase: OpeningPhase, hinge: Bool, hingeArmed: Bool, tuning: Tuning) -> String? {
        switch (step, phase) {
        case (0, .closed):
            if hinge {
                return hingeArmed
                    ? String(localized: "Ouvre doucement le téléphone : ta première huître s’ouvre avec lui.")
                    : String(localized: "Referme le téléphone, puis ouvre-le doucement : ta première huître s’ouvre avec lui.")
            }
            return String(localized: "Glisse le pouce vers le haut pour ouvrir ta première huître.")
        case (0, .resisting):
            return String(localized: "Elle résiste… continue, elle va céder.")
        case (0, .opening):
            return String(localized: "Voilà ! Ouvre-la jusqu’au bout.")
        case (1, .closed), (1, .resisting):
            return String(localized: "Attention : à mi-ouverture, la perle est fragile. Si tu vas trop vite, elle se fêle et perd la moitié de sa valeur.")
        case (1, .opening):
            return String(localized: "Doucement…")
        case (let step, .closed) where step == Catalog.shared.tutorialPearls.count:
            // Première huître hors tutoriel : le stock apparaît, on l'explique une fois.
            let minutes = Int(tuning.oysterRechargeMinutes)
            return String(localized: "Tes huîtres sont en haut. Elles reviennent seules, une toutes les \(minutes) min. Tes perles t’attendent dans l’onglet Collection.")
        default:
            return nil
        }
    }

    /// Phrase au-dessus de la carte, après la révélation.
    static func afterReveal(step: Int, cracked: Bool) -> String? {
        switch step {
        case 0: String(localized: "Ta première perle ! Elle rejoint ta collection.")
        case 1: cracked
            ? String(localized: "Fêlée… La prochaine fois, ralentis à mi-ouverture.")
            : String(localized: "Bien joué : ouverte en douceur, perle intacte.")
        case 2: String(localized: "Parfois, rien. C’est la mer. La prochaine sera peut-être la bonne.")
        case 3: String(localized: "Plus une perle est rare, plus elle se fait attendre. Les plus précieuses tremblent avant même qu’on les touche. Bonne pêche !")
        default: nil
        }
    }
}

/// La bulle d'accompagnement : verre clair, texte centré, arrive en douceur.
struct CoachBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 17, weight: .semibold))
            .multilineTextAlignment(.center)
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.25), radius: 3)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: 340)
            .glassPanel(cornerRadius: 22, shade: 0.2)
            .id(text)
            .transition(.opacity.combined(with: .scale(scale: 0.92)))
    }
}

/// La main fantôme : un pouce qui glisse vers le haut sur l'huître, pour montrer le geste
/// (cahier §15). Elle s'efface dès qu'on touche ; « Réduire les animations » la laisse immobile.
struct GhostHand: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Course du pouce, en points.
    var travel: CGFloat = 150

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            let cycle = 2.2
            let t = reduceMotion ? 0.35 : timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: cycle) / cycle
            // Le pouce se pose, glisse vers le haut en ralentissant, puis se lève.
            let slide = smooth(t, 0.15, 0.75)
            let opacity = smooth(t, 0, 0.12) * (1 - smooth(t, 0.78, 0.95))
            ZStack {
                Capsule()
                    .fill(LinearGradient(colors: [.white.opacity(0), .white.opacity(0.45)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 10, height: max(1, travel * slide))
                    .offset(y: travel * (0.5 - slide / 2))
                    .blur(radius: 2)
                Image(systemName: "hand.point.up.left.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 6, y: 3)
                    .offset(x: 14, y: travel * (0.5 - slide) + 30)
                    .scaleEffect(1 - 0.08 * smooth(t, 0.05, 0.15) + 0.08 * smooth(t, 0.75, 0.85))
            }
            .opacity(opacity)
        }
        .frame(width: 120, height: travel + 90)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func smooth(_ x: Double, _ from: Double, _ to: Double) -> Double {
        let t = min(1, max(0, (x - from) / (to - from)))
        return t * t * (3 - 2 * t)
    }
}
