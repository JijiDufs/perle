import SwiftUI

/// Le verre du jeu (glassmorphism) : panneaux, boutons et champs, repris de l'écran de connexion.
/// Le lagon passe flouté derrière ; un liseré clair en dégradé dessine le bord.

extension View {
    /// Verre de n'importe quelle forme (capsule des pastilles, panneau arrondi…).
    /// `rim` : liseré coloré (or pour une carte révélée, une coquille équipée) ; `shade` : assombrit un peu le verre
    /// pour lire le texte blanc sur l'eau claire.
    func glass<S: InsettableShape>(_ shape: S, rim: Color? = nil, shade: Double = 0.18) -> some View {
        modifier(Glass(shape: shape, rim: rim, shade: shade))
    }

    /// Panneau de verre arrondi.
    func glassPanel(cornerRadius: CGFloat = 24, rim: Color? = nil, shade: Double = 0.18) -> some View {
        glass(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous), rim: rim, shade: shade)
    }

    /// Titre posé directement sur l'eau : blanc, avec une ombre douce pour rester lisible.
    func lagoonTitle() -> some View {
        font(.title3.weight(.bold))
            .foregroundStyle(.white)
            .shadow(color: Color(hex: 0x002832).opacity(0.35), radius: 8, y: 2)
    }
}

private struct Glass<S: InsettableShape>: ViewModifier {
    let shape: S
    let rim: Color?
    let shade: Double

    func body(content: Content) -> some View {
        content
            .background(Lagoon.abyss.opacity(shade), in: shape)
            .background(.ultraThinMaterial, in: shape)
            .overlay(shape.strokeBorder(LinearGradient(colors: rimColors, startPoint: .topLeading, endPoint: .bottomTrailing),
                                        lineWidth: rim == nil ? 1 : 1.5))
    }

    private var rimColors: [Color] {
        if let rim { return [rim, rim.opacity(0.3), rim.opacity(0.8)] }
        return [.white.opacity(0.6), .white.opacity(0.12), .white.opacity(0.35)]
    }
}

// MARK: - Boutons

/// Bouton principal couleur nacre. `compact` : petit bouton dans une case ou une ligne.
struct PearlButtonStyle: ButtonStyle {
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        PressableLabel(configuration: configuration, compact: compact) {
            Capsule().fill(LinearGradient(colors: [.white, Lagoon.pearl, Color(hex: 0xE4DCCB)],
                                          startPoint: .top, endPoint: .bottom))
        }
        .foregroundStyle(Lagoon.abyss)
    }
}

/// Bouton secondaire en verre.
struct GlassButtonStyle: ButtonStyle {
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        PressableLabel(configuration: configuration, compact: compact) {
            Capsule().fill(.white.opacity(configuration.isPressed ? 0.26 : 0.16))
                .overlay(Capsule().strokeBorder(.white.opacity(0.4), lineWidth: 1))
        }
        .foregroundStyle(.white)
    }
}

/// Mise en forme commune des boutons : taille, appui qui s'enfonce, bouton désactivé estompé.
private struct PressableLabel<Background: View>: View {
    @Environment(\.isEnabled) private var isEnabled
    let configuration: ButtonStyleConfiguration
    let compact: Bool
    @ViewBuilder let background: Background

    var body: some View {
        configuration.label
            .font(.system(size: compact ? 14 : 17, weight: .semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, compact ? 14 : 20)
            .frame(maxWidth: compact ? nil : .infinity, minHeight: compact ? 36 : 54)
            .background(background)
            .opacity(isEnabled ? 1 : 0.45)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Champs

/// Champ de saisie en verre.
struct GlassField: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(.white)
            .tint(.white)
            .padding(.horizontal, 18)
            .frame(minHeight: 56)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.black.opacity(0.18)))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(.white.opacity(0.3), lineWidth: 1))
    }
}
