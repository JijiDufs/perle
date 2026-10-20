import SwiftUI

/// Derrière la carte qui arrive : une gerbe d'étincelles de la couleur de la perle, plus fournie pour les rares,
/// et, pour les ◆◆◆ et plus, des rayons de lumière qui tournent lentement tant que la carte est là.
struct RevealBurst: View {
    /// Couleur de la lumière (celle de la perle ou de la trouvaille) ; nil = pas d'éclat (huître vide).
    let glow: String?
    /// Ampleur de la révélation (0…3).
    let tier: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()

    /// Durée de la gerbe (s).
    private static let burstSeconds = 1.4

    var body: some View {
        if let glow, !reduceMotion {
            TimelineView(.animation) { timeline in
                Canvas { c, size in
                    let elapsed = timeline.date.timeIntervalSince(start)
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let color = Color(hex: glow)
                    if tier >= 2 { rays(&c, center, size, elapsed, color) }
                    sparks(&c, center, size, elapsed, color)
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear { start = Date() }
        }
    }

    /// Rayons de lumière qui tournent lentement, en fondu d'entrée.
    private func rays(_ c: inout GraphicsContext, _ center: CGPoint, _ size: CGSize, _ elapsed: Double, _ color: Color) {
        let count = 12
        let reach = max(size.width, size.height) * 0.75
        let fade = min(1, elapsed / 0.6) * (tier >= 3 ? 0.32 : 0.2)
        var layer = c
        layer.blendMode = .plusLighter
        for i in 0..<count {
            let angle = Double(i) / Double(count) * 2 * .pi + elapsed * 0.15
            var ray = Path()
            ray.move(to: center)
            ray.addLine(to: CGPoint(x: center.x + cos(angle - 0.07) * reach, y: center.y + sin(angle - 0.07) * reach))
            ray.addLine(to: CGPoint(x: center.x + cos(angle + 0.07) * reach, y: center.y + sin(angle + 0.07) * reach))
            ray.closeSubpath()
            layer.fill(ray, with: .radialGradient(Gradient(colors: [color.opacity(fade), color.opacity(0)]),
                                                 center: center, startRadius: 40, endRadius: reach))
        }
    }

    /// Étincelles en étoile qui jaillissent du centre, ralentissent et s'éteignent.
    private func sparks(_ c: inout GraphicsContext, _ center: CGPoint, _ size: CGSize, _ elapsed: Double, _ color: Color) {
        let k = elapsed / Self.burstSeconds
        guard k < 1 else { return }
        let count = 14 + tier * 10
        let reach = min(size.width, size.height) * (0.42 + Double(tier) * 0.08)
        var layer = c
        layer.blendMode = .plusLighter
        for i in 0..<count {
            // Pseudo-hasard fixe par étincelle : la gerbe est la même à chaque image.
            let a = Double(i) * 2.399963 + 0.4
            let speed = 0.55 + 0.45 * abs(sin(Double(i) * 12.9898))
            let distance = reach * speed * (1 - pow(1 - k, 3))
            let point = CGPoint(x: center.x + cos(a) * distance, y: center.y + sin(a) * distance + k * k * 40)
            let r = (3 + 4 * abs(sin(Double(i) * 78.233))) * (1 - k)
            let tint = i % 3 == 0 ? Color.white : color
            var star = Path()
            star.move(to: CGPoint(x: point.x, y: point.y - r * 2))
            star.addQuadCurve(to: CGPoint(x: point.x + r * 2, y: point.y), control: point)
            star.addQuadCurve(to: CGPoint(x: point.x, y: point.y + r * 2), control: point)
            star.addQuadCurve(to: CGPoint(x: point.x - r * 2, y: point.y), control: point)
            star.addQuadCurve(to: CGPoint(x: point.x, y: point.y - r * 2), control: point)
            layer.fill(star, with: .color(tint.opacity(1 - k * 0.8)))
        }
    }
}
