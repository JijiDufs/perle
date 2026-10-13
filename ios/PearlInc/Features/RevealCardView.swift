import SwiftUI
import PearlCore

/// La carte de révélation : nom, rareté, taille, lustre, valeur, numéro de série.
/// Toucher la carte (sur le Duo : refermer le téléphone) passe à l'huître suivante.
struct RevealCardView: View {
    @Environment(GameModel.self) private var game
    let reveal: Reveal

    var body: some View {
        VStack(spacing: 14) {
            content
            if let message = shareMessage {
                ShareLink(item: message) {
                    Label("Partager", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(GlassButtonStyle(compact: true))
                .simultaneousGesture(TapGesture().onEnded { game.recordShare() })
            }
            Text("Touche la carte pour l'huître suivante")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.top, 6)
        }
        .padding(24)
        .frame(maxWidth: 320)
        .glassPanel(cornerRadius: 28, rim: Palette.gold, shade: 0.4)
        .shadow(color: .black.opacity(0.4), radius: 30, y: 12)
        .padding(.horizontal, 24)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder private var content: some View {
        switch reveal {
        case .pearl(let card):
            let pearl = game.catalog.pearl(card.pearlId)
            PearlDot(color: Color(hex: pearl.color), glow: pearl.glow.map { Color(hex: $0) }, size: 84)
            Text(card.cracked ? "\(pearl.name) fêlée" : pearl.name)
                .font(.title2.weight(.bold))
            Text(pearl.rarity).font(.title3).foregroundStyle(Palette.gold)
            if let traits = card.traits { Text(traitsLabel(traits)).font(.subheadline).foregroundStyle(.white.opacity(0.8)) }
            HStack(spacing: 18) {
                Stat(label: "Taille", value: String(format: "%.1f mm", card.sizeMm))
                Stat(label: "Lustre", value: card.lustre.rawValue)
                Stat(label: "Valeur", value: "\(Int(card.value))")
            }
            Text(pearl.flavor).font(.callout.italic()).multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.85))
            Text(serialLabel(card.serial)).font(.caption.monospaced()).foregroundStyle(.white.opacity(0.6))
        case .find(let card, let dust):
            let find = game.catalog.find(card.findId)
            PearlDot(color: Color(hex: find.glow), glow: Color(hex: find.glow), size: 70)
            Text("Trouvaille !").font(.caption.weight(.semibold)).foregroundStyle(Palette.gold)
            Text(find.name).font(.title2.weight(.bold)).multilineTextAlignment(.center)
            Text(String(repeating: "◆", count: min(find.tier, 3)) + (find.tier > 3 ? String(repeating: "★", count: find.tier - 3) : ""))
                .foregroundStyle(Palette.gold)
            Text(find.flavor).font(.callout.italic()).multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.85))
            if dust > 0 { Text("+ \(dust) ✦").font(.headline).foregroundStyle(Palette.gold) }
            Text(serialLabel(card.serial)).font(.caption.monospaced()).foregroundStyle(.white.opacity(0.6))
        case .empty(let serial):
            let pearl = game.catalog.pearl("empty")
            Text(pearl.name).font(.title2.weight(.bold))
            Text(pearl.flavor).font(.callout.italic()).multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.85))
            Text(serialLabel(serial)).font(.caption.monospaced()).foregroundStyle(.white.opacity(0.6))
        }
    }

    /// Texte partagé (l'image story viendra ensuite).
    private var shareMessage: String? {
        switch reveal {
        case .pearl(let card):
            let pearl = game.catalog.pearl(card.pearlId)
            return "J’ai trouvé une \(pearl.name.lowercased()) \(pearl.rarity) dans Pearl Inc. (\(serialLabel(card.serial))) 🦪 pearl-inc.app"
        case .find(let card, _):
            return "Il y avait « \(game.catalog.find(card.findId).name) » dans mon huître. Pearl Inc. 🦪 pearl-inc.app"
        case .empty:
            return nil
        }
    }

    private func traitsLabel(_ traits: PearlTraits) -> String {
        let shape = game.catalog.shapes[traits.shape]?.label ?? traits.shape
        let overtone = game.catalog.overtones[traits.overtone]?.label ?? traits.overtone
        let mark = traits.mark.flatMap { game.catalog.marks[$0]?.label }.map { " · \($0)" } ?? ""
        return "\(shape) · reflet \(overtone)\(mark)"
    }
}

private struct Stat: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.headline)
            Text(label).font(.caption).foregroundStyle(.white.opacity(0.6))
        }
    }
}

/// Une perle ronde avec son halo.
struct PearlDot: View {
    let color: Color
    let glow: Color?
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(RadialGradient(colors: [.white, color, color.opacity(0.75)], center: UnitPoint(x: 0.35, y: 0.3), startRadius: 0, endRadius: size * 0.7))
            .frame(width: size, height: size)
            .background(Circle().fill(glow ?? .clear).blur(radius: size * 0.35).opacity(0.8))
    }
}
