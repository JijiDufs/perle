import SwiftUI

/// Le bénitier (skin), dans la même direction artistique que l'huître (src/art/shell.ts) : bandes de
/// croissance en relief, lumière du dessus à gauche. Vu de dessus : deux valves crème aux gros plis
/// écailleux qui se rejoignent en zigzag, et le manteau sombre irisé qui ondule entre elles.
/// La valve du haut est modélisée en 3D (un dôme à gros plis) : elle bascule en arrière sur sa charnière
/// et on voit son relief en raccourci (et son intérieur de porcelaine là où il se présente).
/// Le manteau apparaît dessous, avec la perle. Le geste ne change pas.
///
/// Repère : charnière (hx, hy) en haut du coquillage, hauteur L, largeur ≈ 1,6 L.
/// Les phases rendent chaque bénitier unique : largeur, nombre et profondeur des ondulations.
enum ClamArt {
    /// Bascule maximale de la valve du haut (grande ouverture) : assez pour dégager le manteau,
    /// pas trop pour que la coquille reste en relief (de profil, elle paraîtrait plate).
    private static let maxTilt = 72.0 * .pi / 180
    /// Maillage de la valve 3D : colonnes (le long du zigzag) et rangées (de la charnière au bord).
    private static let meshColumns = 48
    private static let meshRows = 14
    /// Lumière : du haut à gauche, vers l'écran.
    private static let light: (Double, Double, Double) = {
        let v = (-0.3, -0.5, 0.8)
        let n = (v.0 * v.0 + v.1 * v.1 + v.2 * v.2).squareRoot()
        return (v.0 / n, v.1 / n, v.2 / n)
    }()
    /// Bandes de croissance [éclairée, dans l'ombre], de l'extérieur vers le sommet de la valve.
    private static let bands: [(String, String)] = [
        ("#e9dcc0", "#8f7b5c"), ("#f7efde", "#b19c7a"), ("#dccdae", "#86734f"),
        ("#fff8ea", "#bfaa86"), ("#e6d8bb", "#937f5f"), ("#fbf3e3", "#b6a17f"),
    ]
    private static let mantleIris = ["#0f5e66", "#2fa38a", "#1d3f8f", "#5b3b8c", "#14868a", "#0f5e66"]

    struct Geometry {
        let cx: Double, cy: Double, a: Double, b: Double, L: Double
        /// Ondulations du zigzag : nombre, profondeur (fraction de b), décalage.
        let waves: Double, depth: Double, shift: Double
        /// Demi-écart entre les deux valves, où l'on voit le manteau.
        var gap: Double { L * 0.065 }
        var top: CGPoint { CGPoint(x: cx, y: cy - b) }
        var bottom: CGPoint { CGPoint(x: cx, y: cy + b) }
    }

    static func geometry(_ hx: Double, _ hy: Double, _ L: Double, _ ph: ShellArt.Phases) -> Geometry {
        Geometry(cx: hx, cy: hy + L * 0.5, a: L * (0.82 + 0.04 * sin(ph.1)), b: L * 0.5, L: L,
                 waves: ph.2 > 3.15 ? 3.5 : 2.5, depth: 0.29 + 0.05 * sin(ph.0 * 1.7), shift: ph.0 * 0.2)
    }

    /// Où se pose la perle, sur le manteau.
    static func pearlCenter(_ hx: Double, _ hy: Double, _ L: Double) -> CGPoint {
        CGPoint(x: hx, y: hy + L * 0.36)
    }

    private static func wave(_ g: Geometry, _ u: Double) -> Double {
        sin(2 * .pi * g.waves * u + g.shift)
    }

    /// Zigzag entre les valves, de gauche à droite, décalé verticalement de `offset`.
    private static func zigzag(_ g: Geometry, _ ph: ShellArt.Phases, offset: Double, wobble: Double = 0) -> [CGPoint] {
        (0...120).map { i in
            let u = Double(i) / 120
            let envelope = pow(sin(.pi * u), 0.7)
            let w = wave(g, u) + wobble * sin(u * 90 + ph.2)
            return CGPoint(x: g.cx + (2 * u - 1) * g.a * 0.985, y: g.cy + g.b * g.depth * w * envelope + offset * envelope)
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
    static func interior(_ hx: Double, _ hy: Double, _ L: Double, _ ph: ShellArt.Phases) -> Path {
        mantleBody(geometry(hx, hy, L, ph))
    }

    private static func mantleBody(_ g: Geometry) -> Path {
        Path(ellipseIn: CGRect(x: g.cx - g.a * 0.96, y: g.cy - g.b * 0.94, width: g.a * 1.92, height: g.b * 1.88))
    }

    /// Ombre portée et manteau (sous la perle).
    static func drawBase(_ c: inout GraphicsContext, _ hx: Double, _ hy: Double, _ L: Double, _ ph: ShellArt.Phases, _ t: Double) {
        let g = geometry(hx, hy, L, ph)
        c.fill(Path(ellipseIn: CGRect(x: g.cx - g.a * 1.02, y: g.cy - g.b * 0.6, width: g.a * 2.04, height: g.b * 2.0)),
               with: .radialGradient(Gradient(colors: [rgba(10, 30, 30, 0.35), rgba(10, 30, 30, 0)]),
                                     center: CGPoint(x: g.cx + L * 0.03, y: g.cy + g.b * 0.5), startRadius: 0, endRadius: g.a * 1.05))
        drawMantle(&c, g, ph, t)
    }

    /// La valve du bas, posée par-dessus le manteau (après la perle et la pénombre).
    static func drawLowerValve(_ c: inout GraphicsContext, _ hx: Double, _ hy: Double, _ L: Double, _ ph: ShellArt.Phases) {
        let g = geometry(hx, hy, L, ph)
        drawValve(&c, lowerValve(g, ph), umbo: g.bottom, g, ph, upper: false, tilt: 0)
    }

    /// Bascule de la valve du haut pour un angle d'ouverture (radians, 0 à π).
    private static func tilt(_ theta: Double) -> Double {
        min(max(theta, 0), .pi) / .pi * maxTilt
    }

    /// La valve du haut bascule en arrière autour de la charnière. Fermée, c'est le même dessin que la valve
    /// du bas ; dès qu'elle bouge, un modèle 3D prend le relais (fondu sur les premiers degrés).
    static func drawLid(_ c: inout GraphicsContext, _ hx: Double, _ hy: Double, _ L: Double, _ ph: ShellArt.Phases, theta: Double) {
        let g = geometry(hx, hy, L, ph)
        let phi = tilt(theta)
        let flat = 1 - smoothstep(0, 0.2, phi)
        if flat < 1 {
            var solid = c
            solid.opacity = 1 - flat * 0.999
            drawLidMesh(&solid, g, ph, phi)
        }
        if flat > 0 {
            var lid = c
            lid.opacity = flat
            lid.translateBy(x: hx, y: hy)
            lid.scaleBy(x: 1, y: cos(phi))
            lid.translateBy(x: -hx, y: -hy)
            drawValve(&lid, upperValve(g, ph), umbo: g.top, g, ph, upper: true, tilt: 0)
        }
    }

    /// Bord de la valve du haut (pour la lumière qui filtre), une fois basculée.
    static func lidEdgeY(_ hx: Double, _ hy: Double, _ L: Double, theta: Double) -> Double {
        hy + L * 0.5 * cos(tilt(theta))
    }

    // MARK: - Valve en 3D

    private struct Point3 { var x, y, z: Double; var hingeY = 0.0 }

    /// Un point de la valve du haut, à plat (avant bascule) : u le long du zigzag (0 à 1),
    /// v de la charnière (0) au bord (1). z : hauteur du dôme vers l'écran, avec les plis.
    private static func valvePoint(_ g: Geometry, _ u: Double, _ v: Double) -> Point3 {
        let side = 2 * u - 1
        let x = g.cx + side * g.a * 0.985
        let topY = g.cy - g.b * (max(0, 1 - side * side)).squareRoot()
        let envelope = pow(sin(.pi * u), 0.7)
        let edgeY = g.cy + g.b * g.depth * wave(g, u) * envelope - g.gap * envelope
        let y = topY + (edgeY - topY) * v
        let across = pow(sin(.pi * u), 0.6)
        let dome = g.L * 0.3 * across * pow(sin(.pi * v), 0.8)
        let folds = g.L * 0.07 * wave(g, u) * pow(v, 1.4) * pow(sin(.pi * u), 0.5)
        return Point3(x: x, y: y, z: dome + folds, hingeY: topY)
    }

    /// Bascule autour de la charnière : le bord libre monte vers l'écran. Chaque colonne pivote sur le bord
    /// du haut de la coquille, pour que la valve reste attachée tout le long.
    private static func rotate(_ p: Point3, _ phi: Double) -> Point3 {
        let dy = p.y - p.hingeY
        return Point3(x: p.x, y: p.hingeY + dy * cos(phi) - p.z * sin(phi), z: dy * sin(phi) + p.z * cos(phi), hingeY: p.hingeY)
    }

    private static func drawLidMesh(_ c: inout GraphicsContext, _ g: Geometry, _ ph: ShellArt.Phases, _ phi: Double) {
        let columns = meshColumns, rows = meshRows
        // Sommets basculés.
        var vertices = [[Point3]](repeating: [], count: rows + 1)
        for row in 0...rows {
            vertices[row] = (0...columns).map { col in
                rotate(valvePoint(g, Double(col) / Double(columns), Double(row) / Double(rows)), phi)
            }
        }
        // Lèvre du manteau, sous le bord de la valve.
        var mantleLip = Path()
        mantleLip.addLines(vertices[rows].map { CGPoint(x: $0.x, y: $0.y + g.L * 0.014) })
        c.stroke(mantleLip, with: .color(Color(hex: "#3fd0c0").opacity(0.55)), lineWidth: g.L * 0.014)

        struct Facet { let path: Path; let depth: Double; let color: Color }
        var facets: [Facet] = []
        facets.reserveCapacity(rows * columns)
        let porcelain = hexComponents("#f7f1e6")
        for row in 0..<rows {
            for col in 0..<columns {
                let p00 = vertices[row][col], p10 = vertices[row][col + 1]
                let p01 = vertices[row + 1][col], p11 = vertices[row + 1][col + 1]
                let e1 = (p10.x - p00.x, p10.y - p00.y, p10.z - p00.z)
                let e2 = (p01.x - p00.x, p01.y - p00.y, p01.z - p00.z)
                var n = (e1.1 * e2.2 - e1.2 * e2.1, e1.2 * e2.0 - e1.0 * e2.2, e1.0 * e2.1 - e1.1 * e2.0)
                let length = (n.0 * n.0 + n.1 * n.1 + n.2 * n.2).squareRoot()
                guard length > 1e-9 else { continue }
                n = (n.0 / length, n.1 / length, n.2 / length)
                let outside = n.2 >= 0
                if !outside { n = (-n.0, -n.1, -n.2) }
                let diffuse = max(0, n.0 * light.0 + n.1 * light.1 + n.2 * light.2)
                let v = (Double(row) + 0.5) / Double(rows)
                let base: (Double, Double, Double)
                var shade = 0.42 + 0.7 * diffuse
                if outside {
                    // Extérieur : bandes de croissance crème, une ombre sous chaque écaille.
                    let scale = (1 - v) * Double(bands.count)
                    let band = bands[min(bands.count - 1, Int(scale))]
                    base = hexComponents(band.0)
                    let within = scale - scale.rounded(.down)
                    if within < 0.18 { shade *= 0.84 }
                } else {
                    // Intérieur : porcelaine, un peu plus chaude près de la charnière.
                    base = porcelain
                    shade *= 0.92 + 0.08 * v
                }
                let color = Color(red: min(1, base.0 / 255 * shade), green: min(1, base.1 / 255 * shade), blue: min(1, base.2 / 255 * shade))
                var path = Path()
                path.addLines([p00, p10, p11, p01].map { CGPoint(x: $0.x, y: $0.y) })
                path.closeSubpath()
                facets.append(Facet(path: path, depth: (p00.z + p10.z + p01.z + p11.z) / 4, color: color))
            }
        }
        // Du plus loin au plus proche de l'écran.
        for facet in facets.sorted(by: { $0.depth < $1.depth }) {
            c.fill(facet.path, with: .color(facet.color))
            c.stroke(facet.path, with: .color(facet.color), lineWidth: 0.6)
        }
        // Lèvre blanche du bord libre (on voit l'épaisseur de la coquille), liseré du sommet.
        var edge = Path()
        edge.addLines(vertices[rows].map { CGPoint(x: $0.x, y: $0.y) })
        c.stroke(edge, with: .color(rgba(255, 253, 246, 0.95)), lineWidth: g.L * 0.02 * (1 + 0.8 * abs(sin(phi))))
        c.stroke(edge.offsetBy(dx: 0, dy: g.L * 0.012), with: .color(rgba(110, 92, 64, 0.3)), lineWidth: g.L * 0.006)
        var rim = Path()
        rim.addLines(vertices[0].map { CGPoint(x: $0.x, y: $0.y) })
        c.stroke(rim, with: .color(rgba(120, 100, 70, 0.45)), lineWidth: g.L * 0.008)
    }

    // MARK: - Matières

    private static func drawMantle(_ c: inout GraphicsContext, _ g: Geometry, _ ph: ShellArt.Phases, _ t: Double) {
        let body = mantleBody(g)
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
        // Plis du manteau, en douces ondulations sombres.
        for k in 1...3 {
            var ruffle = Path()
            ruffle.addLines(zigzag(g, ph, offset: -g.b * 0.18 * Double(k), wobble: 0.06))
            spots.stroke(ruffle, with: .color(.black.opacity(0.18)), lineWidth: g.L * 0.018)
        }
        // Lèvre du manteau contre la valve du bas.
        var lip = Path()
        lip.addLines(zigzag(g, ph, offset: g.gap * 0.45, wobble: 0.04))
        spots.stroke(lip, with: .color(Color(hex: "#5b8cff").opacity(0.45)), lineWidth: g.L * 0.012)
    }

    /// Une valve : bandes de croissance en relief autour du sommet (umbo), plis, lèvre blanche.
    /// `tilt` : bascule de la valve (la lèvre s'épaissit, on voit sa tranche).
    private static func drawValve(_ c: inout GraphicsContext, _ valve: Path, umbo: CGPoint, _ g: Geometry, _ ph: ShellArt.Phases, upper: Bool, tilt: Double) {
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
        drawFolds(&folds, umbo: umbo, g, ph, upper: upper)
        // Lèvre blanche épaisse au bord du zigzag (plus épaisse quand la valve bascule : on voit sa tranche).
        var lip = Path()
        lip.addLines(zigzag(g, ph, offset: upper ? -g.gap : g.gap))
        c.stroke(lip, with: .color(rgba(255, 253, 246, 0.95)), lineWidth: g.L * 0.022 * (1 + 1.5 * sin(tilt)))
        c.stroke(lip.offsetBy(dx: 0, dy: upper ? -g.L * 0.016 : g.L * 0.016), with: .color(rgba(120, 100, 70, 0.35)), lineWidth: g.L * 0.008)
        // Reflet de la lumière du dessus.
        folds.fill(Path(CGRect(x: g.cx - g.a, y: g.cy - g.b, width: g.a * 2, height: g.b * 2)),
                   with: .radialGradient(Gradient(colors: [rgba(255, 252, 240, 0.22), rgba(255, 252, 240, 0)]),
                                         center: light, startRadius: 0, endRadius: g.L * 0.8))
    }

    /// Les gros plis : lumière sur les crêtes qui avancent vers le zigzag, ombre dans les creux.
    private static func drawFolds(_ c: inout GraphicsContext, umbo: CGPoint, _ g: Geometry, _ ph: ShellArt.Phases, upper: Bool) {
        let edge = zigzag(g, ph, offset: 0)
        let width = g.a * 2 / Double(edge.count) * 2.2
        // Les plis partent de loin derrière le sommet : de larges ondulations presque parallèles.
        let origin = CGPoint(x: umbo.x, y: g.cy + (umbo.y - g.cy) * 2.6)
        for (i, point) in edge.enumerated() {
            let crest = (upper ? 1 : -1) * wave(g, Double(i) / Double(edge.count - 1))
            var line = Path()
            line.move(to: origin)
            line.addLine(to: CGPoint(x: point.x + (point.x - origin.x) * 0.1, y: point.y + (point.y - origin.y) * 0.1))
            let color = crest > 0 ? rgba(255, 252, 240, 0.2 * crest) : rgba(60, 44, 24, 0.2 * -crest)
            c.stroke(line, with: .color(color), lineWidth: width)
        }
    }
}
