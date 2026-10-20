import SwiftUI

/// Le verre du jeu (glassmorphism), comme dans le prototype de pearl-inc.app (glassPanel) : le lagon passe
/// flouté derrière, un voile clair, un reflet en haut, un liseré lumineux et une ombre douce.

extension View {
    /// Verre de n'importe quelle forme (capsule des pastilles, panneau arrondi…).
    /// `rim` : liseré coloré (or pour une coquille équipée) ; `shade` : assombrit le verre (panneaux pleins de texte).
    func glass<S: InsettableShape>(_ shape: S, rim: Color? = nil, shade: Double = 0) -> some View {
        modifier(Glass(shape: shape, rim: rim, shade: shade))
    }

    /// Panneau de verre arrondi.
    func glassPanel(cornerRadius: CGFloat = 24, rim: Color? = nil, shade: Double = 0) -> some View {
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
            .background {
                ZStack {
                    shape.fill(.ultraThinMaterial)
                    shape.fill(Color.white.opacity(0.14))
                    shape.fill(LinearGradient(stops: [.init(color: .white.opacity(0.26), location: 0), .init(color: .white.opacity(0.03), location: 0.45),
                                                      .init(color: .white.opacity(0.08), location: 1)], startPoint: .top, endPoint: .bottom))
                    if shade > 0 { shape.fill(Color(hex: 0x021218).opacity(shade)) }
                }
                .compositingGroup()
                .shadow(color: .black.opacity(0.22), radius: 14, y: 8)
            }
            .overlay(shape.strokeBorder(LinearGradient(colors: rimColors, startPoint: .topLeading, endPoint: .bottomTrailing),
                                        lineWidth: rim == nil ? 1 : 1.5))
    }

    private var rimColors: [Color] {
        if let rim { return [rim, rim.opacity(0.3), rim.opacity(0.8)] }
        return [.white.opacity(0.75), .white.opacity(0.18), .white.opacity(0.45)]
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
            Capsule().fill(.white.opacity(configuration.isPressed ? 0.18 : 0))
                .glass(Capsule())
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.25), radius: 3)
    }
}

/// Mise en forme commune des boutons : taille, appui qui s'enfonce, bouton désactivé estompé.
private struct PressableLabel<Background: View>: View {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.buttonLabelWraps) private var wraps
    let configuration: ButtonStyleConfiguration
    let compact: Bool
    @ViewBuilder let background: Background

    var body: some View {
        configuration.label
            .font(.system(size: compact ? 14 : 17, weight: .semibold))
            .lineLimit(wraps ? 3 : 1)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, compact ? 14 : 20)
            .padding(.vertical, wraps ? 6 : 0)
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

// MARK: - Barre d'état

extension View {
    /// Les écrans qui défilent sans barre de navigation : un voile d'eau profonde sous l'heure et la
    /// Dynamic Island, pour que le texte qui remonte ne passe pas dessous.
    func statusBarFade() -> some View {
        overlay {
            GeometryReader { proxy in
                let bar = proxy.safeAreaInsets.top, deep = Color(hex: 0x021218)
                LinearGradient(stops: [.init(color: deep, location: 0), .init(color: deep.opacity(0.9), location: bar / (bar + 28)),
                                       .init(color: deep.opacity(0), location: 1)], startPoint: .top, endPoint: .bottom)
                    .frame(height: bar + 28)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }
}

extension EnvironmentValues {
    /// Les boutons passent sur plusieurs lignes au lieu de rétrécir (moitié d'écran du Duo).
    @Entry var buttonLabelWraps = false
}
