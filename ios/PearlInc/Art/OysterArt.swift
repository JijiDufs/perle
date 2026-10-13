import SwiftUI

/// La scène de l'ouverture, composée comme dans la webapp (features/oyster/oysterScreen.ts) :
/// valve du bas, nacre, chair, perle, pénombre, halo, puis le couvercle qui se soulève vers le haut
/// de l'écran et la lumière qui filtre par l'entrebâillement. Pendant le suspense, la perle palpite
/// et son halo envahit l'écran (éclair blanc pour les ★). Le skin habille la coquille.
/// Aucune règle de jeu ici : on dessine l'état qu'on reçoit.
struct OysterArt {
    /// Halo selon l'ampleur de la révélation (comme GLOW_STRENGTH dans la webapp).
    private static let glowStrength = [0.55, 0.7, 0.85, 1.0]

    var angle: Double
    /// nil : huître vide.
    var pearl: PearlLook?
    /// Couleur de la lumière qui filtre ; nil : reste noire.
    var glowColor: String?
    var sizeMm: Double
    /// Une trouvaille à la place de la perle : un objet lumineux qui vacille.
    var isFind = false
    var revealTier = 0
    var cracked: Bool
    var trembles: Bool
    var revealed: Bool
    /// Avancée du suspense de la révélation (0 → 1), puis 1 tant que la carte est là.
    var suspense = 0.0
    /// Éclair blanc des ★ (1 → 0).
    var flash = 0.0
    var time: Double
    var look: SkinLook = .lagoon
    /// Graine des irrégularités de la coquille (une huître = une forme).
    var shapeSeed = 1
    /// Taille de la valve (L) : nil = calculée d'après la place disponible.
    var length: Double?

    /// Où se pose la coquille : charnière (hx, hy) et longueur L. Le lagon s'en sert pour son horizon et l'ombre.
    struct Layout {
        var hx: Double
        var hy: Double
        var L: Double
    }

    static func layout(size: CGSize, look: SkinLook, length: Double? = nil) -> Layout {
        let top = Double(size.height) * 0.08
        let visible = Double(size.height) * 0.84
        var L = length ?? min(Double(size.width) * 0.6, visible * 0.42)
        if case .clam = look { L *= ClamArt.lengthFactor }
        let hy = length != nil ? Double(size.height) / 2 - L * 0.5 : top + visible * 0.52
        return Layout(hx: Double(size.width) / 2, hy: hy, L: L)
    }

    private var isClam: Bool { if case .clam = look { true } else { false } }

    func draw(_ c: inout GraphicsContext, size: CGSize) {
        let t = time
        let theta = angle * .pi / 180
        let layout = Self.layout(size: size, look: look, length: length)
        let L = layout.L
        var hx = layout.hx
        var hy = layout.hy
        let ph = ShellArt.phases(seed: shapeSeed)
        let down = Double.pi / 2

        // Tremblement des plus rares.
        if trembles && angle == 0 && !revealed && t.truncatingRemainder(dividingBy: 2.4) < 0.45 {
            hx += sin(t * 90) * 3
            hy += cos(t * 70) * 2
        }

        // Valve du bas : extérieur, nacre (ou porcelaine et manteau), chair, perle.
        let interior: Path
        switch look {
        case .oyster(let palette, let rim, _):
            ShellArt.drawExterior(&c, hx, hy, down, L, ph, palette)
            if let rim { c.stroke(ShellArt.path(ShellArt.outline(hx, hy, down, L, ph, frill: 0.05)), with: .color(rim), lineWidth: max(1.5, L * 0.012)) }
            ShellArt.drawNacre(&c, hx, hy, down, L * 0.88, ph, t, palette)
            ShellArt.drawFlesh(&c, hx, hy, down, L, ph)
            interior = ShellArt.path(ShellArt.outline(hx, hy, down, L * 0.88, ph, frill: 0))
        case .clam:
            ClamArt.drawExterior(&c, hx, hy, down, L, ph)
            ClamArt.drawInterior(&c, hx, hy, down, L, ph, t, mantle: true)
            interior = ClamArt.interiorPath(hx, hy, down, L, ph)
        }
        let pearlCenter = CGPoint(x: hx, y: hy + L * 0.5)

        let flicker = isFind ? 0.8 + 0.2 * sin(t * 9) * sin(t * 2.3) : pearl?.id == "cursed" ? 0.75 + 0.25 * sin(t * 6) : 1
        let tier = min(max(revealTier, 0), 3)
        var radius = isFind ? L * 0.12 : L * (0.05 + sizeMm * 0.0055)
        if isClam { radius *= 1.1 }
        // Suspense : la perle palpite, de plus en plus vite selon la rareté.
        if revealed && suspense < 1 { radius *= 1 + 0.1 * suspense * max(0, sin(t * (6 + Double(tier) * 3))) }
        if let pearl { PearlArt.draw(&c, pearlCenter.x, pearlCenter.y, radius, pearl, cracked: cracked && !isFind) }

        // L'intérieur reste dans l'ombre tant que la coquille est peu ouverte.
        let dim = revealed ? 0 : 1 - smoothstep(4, 140, angle)
        if dim > 0.001 { c.fill(interior, with: .color(rgba(0, 6, 8, dim * 0.94))) }

        // Halo de la perle, puis couvercle par-dessus.
        let strength = Self.glowStrength[tier] * flicker * (cracked && !isFind ? 0.35 : 1)
        PearlArt.glow(&c, pearlCenter.x, pearlCenter.y, radius * (4 + Double(tier) * 0.8), glowColor,
                      (revealed ? 1 : smoothstep(1, 25, angle)) * strength, additive: false)

        let lift = cos(theta)
        var lid = c
        lid.translateBy(x: hx, y: hy)
        lid.scaleBy(x: 1, y: lift)
        lid.translateBy(x: -hx, y: -hy)
        switch look {
        case .oyster(let palette, let rim, let sparkles):
            ShellArt.drawExterior(&lid, hx, hy, down, L * 0.98, ph, palette)
            let lidOutline = ShellArt.path(ShellArt.outline(hx, hy, down, L * 0.98, ph, frill: 0.045))
            if let rim { lid.stroke(lidOutline, with: .color(rim), lineWidth: max(1.5, L * 0.012)) }
            if lift > 0 {
                // Le couvercle s'assombrit en se redressant.
                lid.fill(lidOutline, with: .color(.black.opacity(sin(theta) * 0.35)))
                if sparkles { drawSparkles(&lid, hx, hy, L * 0.98, t) }
            } else {
                ShellArt.drawNacre(&lid, hx, hy, down, L * 0.98 * 0.88, ph, t, palette)
            }
        case .clam:
            ClamArt.drawExterior(&lid, hx, hy, down, L * 0.98, ph)
            if lift > 0 {
                lid.fill(ShellArt.path(ClamArt.outline(hx, hy, down, L * 0.98, ph)), with: .color(.black.opacity(sin(theta) * 0.35)))
            } else {
                ClamArt.drawInterior(&lid, hx, hy, down, L * 0.98, ph, t, mantle: false)
            }
        }

        // La lumière filtre par l'entrebâillement, au bord du couvercle.
        if lift > 0 && !revealed {
            let leak = smoothstep(0.5, 10, angle) * (1 - smoothstep(40, 95, angle))
            PearlArt.glow(&c, hx, hy + L * 0.98 * lift, L * 0.8, glowColor, leak * strength * 0.9)
        }
    }

    /// Par-dessus le décor (après la vignette du lagon) : le halo qui envahit l'écran pendant la révélation,
    /// et l'éclair blanc des ★.
    func drawRevealEffects(_ c: inout GraphicsContext, size: CGSize) {
        guard revealed else { return }
        let layout = Self.layout(size: size, look: look, length: length)
        let tier = Double(min(max(revealTier, 0), 3))
        let flicker = isFind ? 0.8 + 0.2 * sin(time * 9) * sin(time * 2.3) : pearl?.id == "cursed" ? 0.75 + 0.25 * sin(time * 6) : 1
        PearlArt.glow(&c, layout.hx, layout.hy + layout.L * 0.5, layout.L * (1.4 + tier * 0.5), glowColor, suspense * 0.5 * flicker, additive: false)
        if flash > 0 { c.fill(Path(CGRect(origin: .zero, size: size)), with: .color(rgba(255, 250, 235, flash * 0.7))) }
    }

    /// Éclats qui scintillent sur l'huître d'or.
    private func drawSparkles(_ c: inout GraphicsContext, _ hx: Double, _ hy: Double, _ L: Double, _ t: Double) {
        let spots: [(Double, Double, Double)] = [(-0.3, 0.35, 0), (0.25, 0.55, 1.3), (-0.05, 0.75, 2.1), (0.38, 0.3, 3.4), (-0.42, 0.62, 4.4)]
        for (dx, dy, phase) in spots {
            let twinkle = max(0, sin(t * 2.2 + phase))
            guard twinkle > 0.05 else { continue }
            let point = CGPoint(x: hx + dx * L, y: hy + dy * L)
            let size = L * 0.05 * twinkle
            var star = Path()
            star.move(to: CGPoint(x: point.x, y: point.y - size))
            star.addQuadCurve(to: CGPoint(x: point.x + size, y: point.y), control: point)
            star.addQuadCurve(to: CGPoint(x: point.x, y: point.y + size), control: point)
            star.addQuadCurve(to: CGPoint(x: point.x - size, y: point.y), control: point)
            star.addQuadCurve(to: CGPoint(x: point.x, y: point.y - size), control: point)
            var bright = c
            bright.blendMode = .plusLighter
            bright.fill(star, with: .color(.white.opacity(0.9 * twinkle)))
        }
    }
}
