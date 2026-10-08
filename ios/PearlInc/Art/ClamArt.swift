import SwiftUI

/// Le bénitier (skin), dans la même direction artistique que l'huître (src/art/shell.ts) : bandes de
/// croissance en relief, lumière du dessus à gauche. Vu de dessus : deux valves crème aux gros plis
/// écailleux qui se rejoignent en zigzag, et le manteau sombre irisé qui ondule entre elles.
/// La valve du haut se soulève comme le couvercle de l'huître : le geste ne change pas.
///
/// Repère : charnière (hx, hy) en haut du coquillage, hauteur L, largeur ≈ 1,6 L.
enum ClamArt {
    /// Nombre d'ondulations du zigzag entre les valves.
    private static let waves = 2.5
    /// Bandes de croissance [éclairée, dans l'ombre], de l'extérieur vers le sommet de la valve.
    private static let bands: [(String, String)] = [
        ("#e9dcc0", "#8f7b5c"), ("#f7efde", "#b19c7a"), ("#dccdae", "#86734f"),
        ("#fff8ea", "#bfaa86"), ("#e6d8bb", "#937f5f"), ("#fbf3e3", "#b6a17f"),
    ]
    private static let mantleIris = ["#0f5e66", "#2fa38a", "#1d3f8f", "#5b3b8c", "#14868a", "#0f5e66"]

    struct Geometry {
        let cx: Double, cy: Double, a: Double, b: Double, L: Double
        /// Demi-écart entre les deux valves, où l'on voit le manteau.
        var gap: Double { L * 0.065 }
        var top: CGPoint { CGPoint(x: cx, y: cy - b) }
        var bottom: CGPoint { CGPoint(x: cx, y: cy + b) }
    }

    static func geometry(_ hx: Double, _ hy: Double, _ L: Double) -> Geometry {
        Geometry(cx: hx, cy: hy + L * 0.5, a: L * 0.82, b: L * 0.5, L: L)
    }

    /// Où se pose la perle, sur le manteau.
    static func pearlCenter(_ hx: Double, _ hy: Double, _ L: Double) -> CGPoint {
        let g = geometry(hx, hy, L)
        return CGPoint(x: g.cx, y: g.cy - g.b * 0.28)
    }

    /// Zigzag entre les valves, de gauche à droite, décalé verticalement de `offset`.
    private static func zigzag(_ g: Geometry, _ ph: ShellArt.Phases, offset: Double, wobble: Double = 0) -> [CGPoint] {
        (0...120).map { i in
            let u = Double(i) / 120
            let envelope = pow(sin(.pi * u), 0.7)
            let wave = sin(2 * .pi * waves * u + ph.0 * 0.2) + wobble * sin(u * 90 + ph.2)
            return CGPoint(x: g.cx + (2 * u - 1) * g.a * 0.985, y: g.cy + g.b * 0.3 * wave * envelope + offset * envelope)
        }
    }

    /// Demi-ellipse du haut (de gauche à droite) ou du bas (de droite à gauche), légèrement festonnée.
    private static func arc(_ g: Geometry, upper: Bool, _ ph: ShellArt.Phases) -> [CGPoint] {
        (0...80).map { i in
            let t = Double(i) / 80
            let phi = upper ? .pi + .pi * t : .pi * t
            let r = 1 + 0.018 * sin(phi * 14 + ph.1)
            return CGPoint(x: g.cx + cos(phi) * g.a * r, y: g.cy + sin(phi) * g.b * r)
        }
    }

    private static func upperValve(_ g: Geometry, _ ph: ShellArt.Phases) -> Path {
        ShellArt.path(arc(g, upper: true, ph) + zigzag(g, ph, offset: -g.gap).reversed())
    }

    private static func lowerValve(_ g: Geometry, _ ph: ShellArt.Phases) -> Path {
        ShellArt.path(zigzag(g, ph, offset: g.gap) + arc(g, upper: false, ph))
    }

    /// L'intérieur (le manteau), là où l'ombre tombe tant que le bénitier est fermé.
    static func interior(_ hx: Double, _ hy: Double, _ L: Double) -> Path {
        let g = geometry(hx, hy, L)
        return Path(ellipseIn: CGRect(x: g.cx - g.a * 0.96, y: g.cy - g.b * 0.94, width: g.a * 1.92, height: g.b * 1.88))
    }

    /// Ombre portée et manteau (sous la perle).
    static func drawBase(_ c: inout GraphicsContext, _ hx: Double, _ hy: Double, _ L: Double, _ ph: ShellArt.Phases, _ t: Double) {
        let g = geometry(hx, hy, L)
        c.fill(Path(ellipseIn: CGRect(x: g.cx - g.a * 1.02, y: g.cy - g.b * 0.6, width: g.a * 2.04, height: g.b * 2.0)),
               with: .radialGradient(Gradient(colors: [rgba(10, 30, 30, 0.35), rgba(10, 30, 30, 0)]),
                                     center: CGPoint(x: g.cx + L * 0.03, y: g.cy + g.b * 0.5), startRadius: 0, endRadius: g.a * 1.05))
        drawMantle(&c, g, ph, t)
    }

    /// La valve du bas, posée par-dessus le manteau (après la perle et la pénombre).
    static func drawLowerValve(_ c: inout GraphicsContext, _ hx: Double, _ hy: Double, _ L: Double, _ ph: ShellArt.Phases) {
        let g = geometry(hx, hy, L)
        drawValve(&c, lowerValve(g, ph), umbo: g.bottom, g, ph, upper: false)
    }

    /// La valve du haut, qui se soulève autour de la charnière (projection en cosinus, comme l'huître).
    static func drawLid(_ c: inout GraphicsContext, _ hx: Double, _ hy: Double, _ L: Double, _ ph: ShellArt.Phases, theta: Double) {
        let g = geometry(hx, hy, L)
        let lift = cos(theta)
        var lid = c
        lid.translateBy(x: hx, y: hy)
        lid.scaleBy(x: 1, y: lift)
        lid.translateBy(x: -hx, y: -hy)
        let valve = upperValve(g, ph)
        if lift > 0 {
            drawValve(&lid, valve, umbo: g.top, g, ph, upper: true)
            // La valve s'assombrit en se redressant.
            lid.fill(valve, with: .color(.black.opacity(sin(theta) * 0.35)))
        } else {
            // Dessous de la valve : porcelaine blanche, côtes à peine marquées.
            lid.fill(valve, with: .radialGradient(Gradient(colors: [Color(hex: "#ffffff"), Color(hex: "#efe8db"), Color(hex: "#c8bca6")]),
                                                  center: CGPoint(x: g.cx, y: g.cy - g.b * 0.3), startRadius: 0, endRadius: g.a))
            var folds = lid
            folds.clip(to: valve)
            drawFolds(&folds, umbo: g.top, g, ph, upper: true, strength: 0.5)
            lid.stroke(valve, with: .color(rgba(150, 132, 104, 0.6)), lineWidth: L * 0.01)
        }
    }

    /// Bord de la valve du haut (pour la lumière qui filtre) : ordonnée moyenne du zigzag, une fois soulevée.
    static func lidEdgeY(_ hx: Double, _ hy: Double, _ L: Double, theta: Double) -> Double {
        hy + L * 0.5 * cos(theta)
    }

    // MARK: - Matières

    private static func drawMantle(_ c: inout GraphicsContext, _ g: Geometry, _ ph: ShellArt.Phases, _ t: Double) {
        let body = Path(ellipseIn: CGRect(x: g.cx - g.a * 0.96, y: g.cy - g.b * 0.94, width: g.a * 1.92, height: g.b * 1.88))
        c.fill(body, with: .radialGradient(Gradient(colors: [Color(hex: "#123447"), Color(hex: "#081620")]),
                                           center: CGPoint(x: g.cx, y: g.cy), startRadius: 0, endRadius: g.a))
        var iris = c
        iris.clip(to: body)
        iris.opacity = 0.55
        iris.fill(body, with: .conicGradient(Gradient(colors: mantleIris.map { Color(hex: $0) }),
                                             center: CGPoint(x: g.cx, y: g.cy), angle: .radians(t * 0.12 + ph.1)))
        // Taches claires et reflets bleus du manteau.
        var spots = c
        spots.clip(to: body)
        for i in 0..<70 {
            let angle = Double(i) * 2.399 + ph.2
            let r = sqrt(Double(i) / 70)
            let p = CGPoint(x: g.cx + cos(angle) * r * g.a * 0.92, y: g.cy + sin(angle) * r * g.b * 0.9)
            let size = g.L * (0.006 + 0.006 * Double(i % 3))
            let color = i % 3 == 0 ? Color(hex: "#7fe9ff").opacity(0.55) : i % 3 == 1 ? Color(hex: "#3ad6a6").opacity(0.35) : Color(hex: "#8e7cff").opacity(0.3)
            spots.fill(Path(ellipseIn: CGRect(x: p.x - size, y: p.y - size, width: size * 2, height: size * 2)), with: .color(color))
        }
        // Lèvres ondulées du manteau, le long du zigzag.
        for (offset, color) in [(-g.gap * 0.45, Color(hex: "#3fd0c0").opacity(0.55)), (g.gap * 0.45, Color(hex: "#5b8cff").opacity(0.45))] {
            var lip = Path()
            lip.addLines(zigzag(g, ph, offset: offset, wobble: 0.04))
            spots.stroke(lip, with: .color(color), lineWidth: g.L * 0.012)
        }
    }

    /// Une valve : bandes de croissance en relief autour du sommet (umbo), plis, lèvre blanche.
    private static func drawValve(_ c: inout GraphicsContext, _ valve: Path, umbo: CGPoint, _ g: Geometry, _ ph: ShellArt.Phases, upper: Bool) {
        let light = CGPoint(x: g.cx - g.a * 0.35, y: g.cy - g.b * 0.75)
        for (k, band) in bands.enumerated() {
            let scale = 1 - Double(k) * 0.13
            let shape = valve.applying(CGAffineTransform(translationX: umbo.x, y: umbo.y).scaledBy(x: scale, y: scale).translatedBy(x: -umbo.x, y: -umbo.y))
            var shadow = c
            shadow.translateBy(x: g.L * 0.006, y: g.L * 0.016)
            shadow.fill(shape, with: .color(rgba(40, 30, 18, 0.32)))
            c.fill(shape, with: .radialGradient(Gradient(colors: [Color(hex: band.0), Color(hex: band.1)]),
                                                center: light, startRadius: g.L * 0.05, endRadius: g.L * 1.5))
            c.stroke(shape, with: .color(rgba(255, 252, 242, 0.35 + Double(k) * 0.04)), lineWidth: max(1, g.L * 0.008))
        }
        var folds = c
        folds.clip(to: valve)
        drawFolds(&folds, umbo: umbo, g, ph, upper: upper, strength: 1)
        // Lèvre blanche épaisse au bord du zigzag.
        var lip = Path()
        lip.addLines(zigzag(g, ph, offset: upper ? -g.gap : g.gap))
        c.stroke(lip, with: .color(rgba(255, 253, 246, 0.95)), lineWidth: g.L * 0.022)
        c.stroke(lip.offsetBy(dx: 0, dy: upper ? -g.L * 0.016 : g.L * 0.016), with: .color(rgba(120, 100, 70, 0.35)), lineWidth: g.L * 0.008)
        // Reflet de la lumière du dessus.
        folds.fill(Path(CGRect(x: g.cx - g.a, y: g.cy - g.b, width: g.a * 2, height: g.b * 2)),
                   with: .radialGradient(Gradient(colors: [rgba(255, 252, 240, 0.22), rgba(255, 252, 240, 0)]),
                                         center: light, startRadius: 0, endRadius: g.L * 0.8))
    }

    /// Les gros plis : lumière sur les crêtes qui avancent vers le zigzag, ombre dans les creux.
    private static func drawFolds(_ c: inout GraphicsContext, umbo: CGPoint, _ g: Geometry, _ ph: ShellArt.Phases, upper: Bool, strength: Double) {
        let edge = zigzag(g, ph, offset: 0)
        let width = g.a * 2 / Double(edge.count) * 2.2
        // Les plis partent de loin derrière le sommet : de larges ondulations presque parallèles.
        let origin = CGPoint(x: umbo.x, y: g.cy + (umbo.y - g.cy) * 2.6)
        for (i, point) in edge.enumerated() {
            let u = Double(i) / Double(edge.count - 1)
            let wave = sin(2 * .pi * waves * u + ph.0 * 0.2)
            let crest = upper ? wave : -wave
            var line = Path()
            line.move(to: origin)
            line.addLine(to: CGPoint(x: point.x + (point.x - origin.x) * 0.1, y: point.y + (point.y - origin.y) * 0.1))
            let color = crest > 0 ? rgba(255, 252, 240, 0.2 * crest * strength) : rgba(60, 44, 24, 0.2 * -crest * strength)
            c.stroke(line, with: .color(color), lineWidth: width)
        }
    }
}
