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
    /// Une trouvaille à la place de la perle : l'objet en relief (FindArt), dans sa lumière qui vacille.
    var findId: String?
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
    var pose: Pose = .thumb

    /// Comment l'huître est posée. Au pouce : vue de dessus, charnière en haut, le couvercle se soulève
    /// vers le haut de l'écran. Sur l'iPhone Duo, comme le prototype de pearl-inc.app : couchée,
    /// sa charnière du côté de celle du téléphone.
    enum Pose: Equatable {
        case thumb
        /// Écran extérieur (téléphone fermé) : charnière au bord gauche, la coquille part vers la droite.
        case cover
        /// Écran intérieur : charnière de l'huître sur le pli du téléphone (abscisse x) ; le couvercle,
        /// ouvert à plat, occupe la moitié gauche (c'est le téléphone qui le soulève), la perle la droite.
        case fold(x: Double)
    }

    /// Où se pose la coquille : charnière (hx, hy), longueur L et direction de la valve du bas.
    struct Layout {
        var hx: Double
        var hy: Double
        var L: Double
        /// Direction de la valve du bas depuis la charnière (π/2 : vers le bas ; 0 : vers la droite).
        var dir = Double.pi / 2

        /// Centre de la perle (ou de la trouvaille), au milieu de la valve du bas.
        var pearlCenter: CGPoint { CGPoint(x: hx + L * 0.5 * cos(dir), y: hy + L * 0.5 * sin(dir)) }

        /// Repère du lagon (horizon, ombre sur le sable) : la charnière quand l'huître est vue de dessus,
        /// le milieu de la coquille quand elle est couchée.
        var focus: LagoonArt.Focus {
            if dir == Double.pi / 2 { return LagoonArt.Focus(x: hx, y: hy, size: L) }
            let center = pearlCenter
            return LagoonArt.Focus(x: center.x, y: center.y - L * 0.32, size: L * 0.75)
        }
    }

    static func layout(size: CGSize, look: SkinLook, length: Double? = nil, pose: Pose = .thumb) -> Layout {
        let width = Double(size.width), height = Double(size.height)
        let top = height * 0.08
        let visible = height * 0.84
        let clam = if case .clam = look { ClamArt.lengthFactor } else { 1.0 }
        switch pose {
        case .thumb:
            // Fermée, l'huître prend une bonne partie de l'écran (≈ 85 % de la largeur), centrée un peu sous le milieu.
            let L = (length ?? min(width * 0.7, visible * 0.48)) * clam
            let hy = length != nil ? height / 2 - L * 0.5 : height * 0.55 - L * 0.42
            return Layout(hx: width / 2, hy: hy, L: L)
        case .cover:
            // Comme drawCover du prototype : la charnière déborde un peu à gauche. Plus grande que sur le
            // prototype, et centrée un peu sous le milieu (bien dégagée de la barre du haut).
            let L = min(width * 0.99, visible * 0.68) * clam
            return Layout(hx: -width * 0.06, hy: height * 0.53, L: L, dir: 0)
        case .fold(let x):
            // Comme drawInner du prototype : chaque valve tient dans sa moitié d'écran.
            let half = min(x, width - x)
            let L = min(half * 0.86, visible * 0.62) * clam
            return Layout(hx: x, hy: top + visible * 0.5, L: L, dir: 0)
        }
    }

    private var isClam: Bool { if case .clam = look { true } else { false } }
    private var isFind: Bool { findId != nil }

    func draw(_ c: inout GraphicsContext, size: CGSize) {
        let t = time
        let theta = angle * .pi / 180
        var layout = Self.layout(size: size, look: look, length: length, pose: pose)
        let L = layout.L
        let ph = ShellArt.phases(seed: shapeSeed)
        let down = layout.dir

        // Tremblement des plus rares.
        if trembles && angle == 0 && !revealed && t.truncatingRemainder(dividingBy: 2.4) < 0.45 {
            layout.hx += sin(t * 90) * 3
            layout.hy += cos(t * 70) * 2
        }
        let hx = layout.hx, hy = layout.hy

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
        let pearlCenter = layout.pearlCenter

        let flicker = isFind ? 0.8 + 0.2 * sin(t * 9) * sin(t * 2.3) : pearl?.id == "cursed" ? 0.75 + 0.25 * sin(t * 6) : 1
        let tier = min(max(revealTier, 0), 3)
        var radius = isFind ? L * 0.12 : L * (0.05 + sizeMm * 0.0055)
        if isClam { radius *= 1.1 }
        // Suspense : la perle palpite, de plus en plus vite selon la rareté.
        let pulse = revealed && suspense < 1 ? 1 + 0.1 * suspense * max(0, sin(t * (6 + Double(tier) * 3))) : 1
        radius *= pulse
        if let findId {
            // Une trouvaille ne se fêle pas (comme la webapp : drawFind à 0,2 L).
            FindArt.draw(c, pearlCenter.x, pearlCenter.y, L * 0.2 * pulse, id: findId, t: t)
        } else if let pearl {
            PearlArt.draw(&c, pearlCenter.x, pearlCenter.y, radius, pearl, cracked: cracked)
        }

        // Sur le pli du Duo, le couvercle est ouvert à plat sur l'autre moitié : on voit son intérieur.
        if case .fold = pose { drawFlatLid(&c, hx, hy, L, ph, t, dim: revealed ? 0 : 1 - smoothstep(4, 140, angle)) }

        // L'intérieur reste dans l'ombre tant que la coquille est peu ouverte.
        let dim = revealed ? 0 : 1 - smoothstep(4, 140, angle)
        if dim > 0.001 { c.fill(interior, with: .color(rgba(0, 6, 8, dim * 0.94))) }

        // Halo de la perle, puis couvercle par-dessus.
        let strength = Self.glowStrength[tier] * flicker * (cracked && !isFind ? 0.35 : 1)
        PearlArt.glow(&c, pearlCenter.x, pearlCenter.y, radius * (4 + Double(tier) * 0.8), glowColor,
                      (revealed ? 1 : smoothstep(1, 25, angle)) * strength, additive: false)

        if case .fold = pose { return }

        // Le couvercle se replie vers sa charnière : vers le haut au pouce, vers la gauche sur l'écran extérieur du Duo.
        let lift = cos(theta)
        var lid = c
        lid.translateBy(x: hx, y: hy)
        lid.scaleBy(x: pose == .cover ? lift : 1, y: pose == .cover ? 1 : lift)
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
            PearlArt.glow(&c, hx + L * 0.98 * lift * cos(down), hy + L * 0.98 * lift * sin(down), L * 0.8, glowColor, leak * strength * 0.9)
        }
    }

    /// Le couvercle ouvert à plat de l'autre côté du pli (prototype : valve gauche), intérieur visible,
    /// dans l'ombre tant que le téléphone est peu ouvert.
    private func drawFlatLid(_ c: inout GraphicsContext, _ hx: Double, _ hy: Double, _ L: Double, _ ph: ShellArt.Phases, _ t: Double, dim: Double) {
        let left = layoutDir + Double.pi
        let interior: Path
        switch look {
        case .oyster(let palette, let rim, _):
            ShellArt.drawExterior(&c, hx, hy, left, L * 0.98, ph, palette)
            if let rim { c.stroke(ShellArt.path(ShellArt.outline(hx, hy, left, L * 0.98, ph, frill: 0.045)), with: .color(rim), lineWidth: max(1.5, L * 0.012)) }
            ShellArt.drawNacre(&c, hx, hy, left, L * 0.98 * 0.88, ph, t, palette)
            interior = ShellArt.path(ShellArt.outline(hx, hy, left, L * 0.98 * 0.88, ph, frill: 0))
        case .clam:
            ClamArt.drawExterior(&c, hx, hy, left, L * 0.98, ph)
            ClamArt.drawInterior(&c, hx, hy, left, L * 0.98, ph, t, mantle: false)
            interior = ClamArt.interiorPath(hx, hy, left, L * 0.98, ph)
        }
        if dim > 0.001 { c.fill(interior, with: .color(rgba(0, 6, 8, dim * 0.94))) }
    }

    private var layoutDir: Double { if case .thumb = pose { Double.pi / 2 } else { 0 } }

    /// Par-dessus le décor (après la vignette du lagon) : le halo qui envahit l'écran pendant la révélation,
    /// et l'éclair blanc des ★.
    func drawRevealEffects(_ c: inout GraphicsContext, size: CGSize) {
        guard revealed else { return }
        let layout = Self.layout(size: size, look: look, length: length, pose: pose)
        let tier = Double(min(max(revealTier, 0), 3))
        let flicker = isFind ? 0.8 + 0.2 * sin(time * 9) * sin(time * 2.3) : pearl?.id == "cursed" ? 0.75 + 0.25 * sin(time * 6) : 1
        let center = layout.pearlCenter
        PearlArt.glow(&c, center.x, center.y, layout.L * (1.4 + tier * 0.5), glowColor, suspense * 0.5 * flicker, additive: false)
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
