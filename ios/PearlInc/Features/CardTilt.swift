import SwiftUI

/// Rester appuyé sur une carte et bouger le doigt : elle s'incline sous le doigt, comme une vraie carte
/// qu'on fait jouer dans la lumière (le reflet suit le doigt), sans quitter le milieu de l'écran.
/// En lâchant, elle revient à plat avec un petit rebond. Un toucher bref, sans bouger : `onTap`.
struct CardTilt: ViewModifier {
    var onTap: (() -> Void)?

    /// Inclinaison maximale (degrés) quand le doigt est au bord de la carte.
    private static let maxTilt = 16.0
    /// Au-delà de ce déplacement (pt), ce n'est plus un toucher mais un mouvement.
    private static let tapSlop = 10.0
    /// Un toucher plus long que ça (s) ne passe pas à l'huître suivante : on regardait la carte.
    private static let tapMaxSeconds = 0.35

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Le doigt sur la carte, de -1 (bord gauche / haut) à 1 (bord droit / bas) ; nil = pas de doigt.
    @State private var touch: CGPoint?
    @State private var cardSize = CGSize(width: 1, height: 1)
    @State private var pressedAt: Date?
    @State private var moved = false

    func body(content: Content) -> some View {
        let tilt = touch ?? .zero
        let amount = reduceMotion ? Self.maxTilt * 0.3 : Self.maxTilt
        content
            .environment(\.cardLight, touch.map { CGPoint(x: ($0.x + 1) / 2, y: ($0.y + 1) / 2) })
            .onGeometryChange(for: CGSize.self) { $0.size } action: { cardSize = $0 }
            // Le coin sous le doigt s'enfonce, le coin opposé se soulève.
            .rotation3DEffect(.degrees(-tilt.y * amount), axis: (x: 1, y: 0, z: 0), perspective: 0.45)
            .rotation3DEffect(.degrees(tilt.x * amount), axis: (x: 0, y: 1, z: 0), perspective: 0.45)
            .scaleEffect(touch == nil ? 1 : 1.04)
            .animation(touch == nil ? .spring(response: 0.55, dampingFraction: 0.42) : .interactiveSpring(response: 0.16, dampingFraction: 0.8),
                       value: touch)
            .sensoryFeedback(.impact(weight: .light, intensity: 0.5), trigger: touch == nil) { _, released in !released }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if pressedAt == nil { pressedAt = Date(); moved = false }
                        if hypot(value.translation.width, value.translation.height) > Self.tapSlop { moved = true }
                        touch = CGPoint(x: clamp(value.location.x / cardSize.width * 2 - 1), y: clamp(value.location.y / cardSize.height * 2 - 1))
                    }
                    .onEnded { _ in
                        let quick = pressedAt.map { Date().timeIntervalSince($0) < Self.tapMaxSeconds } ?? false
                        touch = nil
                        pressedAt = nil
                        if !moved && quick { onTap?() }
                    }
            )
    }

    private func clamp(_ value: Double) -> Double { min(1, max(-1, value)) }
}

extension View {
    /// Carte qu'on peut faire jouer dans la lumière du bout du doigt (voir `CardTilt`).
    func cardTilt(onTap: (() -> Void)? = nil) -> some View {
        modifier(CardTilt(onTap: onTap))
    }
}

extension EnvironmentValues {
    /// Où le doigt éclaire la carte (0…1 sur sa largeur et sa hauteur) ; nil = pas de doigt.
    @Entry var cardLight: CGPoint? = nil
}
