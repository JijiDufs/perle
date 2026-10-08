import SwiftUI

/// Dessin procédural de la coquille d'huître, porté de src/art/shell.ts (même direction artistique
/// que la webapp). Chaque valve part de la charnière (ax, ay) dans la direction `angle`, sur une
/// longueur L. `phases` rend chaque huître unique (bosses, dentelure). Le skin choisit les couleurs.
enum ShellArt {
    typealias Phases = (Double, Double, Double)

    /// Phases d'une huître, reproductibles à partir d'une graine (numéro de série).
    static func phases(seed: Int) -> Phases {
        var state = UInt64(truncatingIfNeeded: seed &* 2_654_435_761 &+ 97)
        func next() -> Double {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Double(state >> 11) / Double(1 << 53)
        }
        return (next() * 6.3, next() * 6.3, next() * 6.3)
    }

    static func outline(_ ax: Double, _ ay: Double, _ angle: Double, _ L: Double, _ ph: Phases, frill: Double) -> [CGPoint] {
        let steps = 110
        let ca = cos(angle), sa = sin(angle)
        return (0...steps).map { i in
            let f = -1.42 + 2.84 * Double(i) / Double(steps)
            var r = L * pow(cos(f), 0.55) * (1 + 0.06 * sin(f * 3 + ph.0) + 0.04 * sin(f * 7 + ph.1))
            if frill != 0 { r *= 1 + frill * sin(f * 38 + ph.2) * pow(cos(f), 0.3) }
            let x = cos(f) * r
            let y = sin(f) * r * 1.05
            return CGPoint(x: ax + x * ca - y * sa, y: ay + x * sa + y * ca)
        }
    }

    static func path(_ points: [CGPoint]) -> Path {
        var path = Path()
        path.addLines(points)
        path.closeSubpath()
        return path
    }

    /// Petit hasard déterministe tiré des phases : chaque huître garde ses taches et ses balanes.
    private static func shellRandom(_ ph: Phases) -> () -> Double {
        var seed = ((ph.0 * 1000 + ph.1 * 100 + ph.2 * 10).truncatingRemainder(dividingBy: 2_147_483_646)).rounded(.down) + 1
        return {
            seed = (seed * 16807).truncatingRemainder(dividingBy: 2_147_483_647)
            return seed / 2_147_483_647
        }
    }

    /// Extérieur de la valve : bandes de croissance en relief, stries, taches, algues, balanes.
    static func drawExterior(_ c: inout GraphicsContext, _ ax: Double, _ ay: Double, _ angle: Double, _ L: Double, _ ph: Phases, _ palette: ShellPalette) {
        let rand = shellRandom(ph)
        let ca = cos(angle), sa = sin(angle)
        // Point le plus éclairé : vers la surface (en haut), un peu à gauche de la charnière.
        let light = CGPoint(x: ax - L * 0.25, y: ay + L * 0.15)

        for (k, band) in palette.bands.enumerated() {
            let kk = Double(k)
            let points = outline(ax, ay, angle, L * (1 - kk * 0.085), (ph.0 + kk * 0.2, ph.1, ph.2 + kk), frill: 0.045 - kk * 0.004)
            let shape = path(points)
            // Ombre portée de la bande sur la précédente.
            var shadow = c
            shadow.translateBy(x: L * 0.006, y: L * 0.014)
            shadow.fill(shape, with: .color(rgba(10, 6, 4, 0.35)))
            c.fill(shape, with: .radialGradient(Gradient(colors: [Color(hex: band.light), Color(hex: band.dark)]),
                                                center: light, startRadius: L * 0.05, endRadius: L * 1.25))
            // Liseré éclairé sur le bord dentelé.
            c.stroke(shape, with: .color(palette.edge.opacity(0.16 + kk * 0.015)), lineWidth: max(1, L * 0.006))
        }

        var texture = c
        texture.clip(to: path(outline(ax, ay, angle, L, ph, frill: 0.045)))
        // Stries qui rayonnent depuis la charnière.
        for i in 0..<22 {
            let f = -1.3 + 2.6 * Double(i) / 21 + (rand() - 0.5) * 0.05
            let dx = cos(f) * L * 1.1, dy = sin(f) * L * 1.1
            let end = CGPoint(x: ax + dx * ca - dy * sa, y: ay + dx * sa + dy * ca)
            var line = Path()
            line.move(to: CGPoint(x: ax, y: ay))
            line.addLine(to: end)
            texture.stroke(line, with: .color(palette.striation.opacity(0.16)), lineWidth: L * 0.008)
            var highlight = Path()
            highlight.move(to: CGPoint(x: ax + L * 0.008, y: ay))
            highlight.addLine(to: CGPoint(x: end.x + L * 0.01, y: end.y))
            texture.stroke(highlight, with: .color(rgba(255, 240, 220, 0.07)), lineWidth: L * 0.005)
        }
        func point(_ f: Double, _ r: Double) -> CGPoint {
            CGPoint(x: ax + cos(f) * r * ca - sin(f) * r * sa, y: ay + cos(f) * r * sa + sin(f) * r * ca)
        }
        // Traces d'algues vertes près du bord.
        for _ in 0..<3 {
            let p = point(-1 + rand() * 2, L * (0.6 + rand() * 0.3))
            if palette.algae {
                texture.fill(Path(CGRect(x: p.x - L * 0.25, y: p.y - L * 0.25, width: L * 0.5, height: L * 0.5)),
                             with: .radialGradient(Gradient(colors: [rgba(90, 140, 90, 0.32), rgba(90, 140, 90, 0)]),
                                                   center: p, startRadius: 0, endRadius: L * 0.22))
            }
        }
        // Petites taches claires et sombres.
        for _ in 0..<70 {
            let p = point(-1.35 + rand() * 2.7, L * sqrt(rand()) * 0.98)
            let color = rand() > 0.5 ? rgba(255, 245, 225, 0.06 + rand() * 0.1) : palette.speck.opacity(0.1 + rand() * 0.15)
            let radius = L * (0.004 + rand() * 0.01)
            texture.fill(Path(ellipseIn: CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2)), with: .color(color))
        }
        // Balanes : petits cônes beiges, plissés, ouverts d'une fente.
        for _ in 0..<3 {
            let p = point(-1.1 + rand() * 2.2, L * (0.45 + rand() * 0.45))
            let br = L * (0.016 + rand() * 0.014)
            let rotation = rand() * .pi
            guard palette.barnacles else { continue }
            var barnacle = texture
            barnacle.translateBy(x: p.x, y: p.y)
            barnacle.rotate(by: .radians(rotation))
            var cone = Path()
            for step in 0..<12 {
                let a = Double(step) / 12 * 2 * .pi
                let rr = br * (step % 2 == 1 ? 0.86 : 1)
                let q = CGPoint(x: cos(a) * rr, y: sin(a) * rr * 0.85)
                if step == 0 { cone.move(to: q) } else { cone.addLine(to: q) }
            }
            cone.closeSubpath()
            barnacle.fill(cone, with: .radialGradient(Gradient(colors: [rgba(225, 214, 192, 0.9), rgba(120, 108, 92, 0.85)]),
                                                      center: CGPoint(x: -br * 0.3, y: -br * 0.3), startRadius: br * 0.1, endRadius: br))
            var slit = Path()
            slit.move(to: CGPoint(x: -br * 0.35, y: 0))
            slit.addLine(to: CGPoint(x: br * 0.35, y: 0))
            barnacle.stroke(slit, with: .color(rgba(70, 58, 48, 0.6)), lineWidth: max(0.8, br * 0.18))
        }
        // Reflet de la lumière du dessus.
        texture.fill(Path(CGRect(x: ax - L * 1.5, y: ay - L * 1.5, width: L * 3, height: L * 3)),
                     with: .radialGradient(Gradient(colors: [palette.sheen.opacity(palette.sheenStrength), palette.sheen.opacity(0)]),
                                           center: light, startRadius: 0, endRadius: L * 0.7))
    }

    /// Intérieur nacré, irisé, avec des reflets qui tournent lentement (t en secondes).
    static func drawNacre(_ c: inout GraphicsContext, _ ax: Double, _ ay: Double, _ angle: Double, _ L: Double, _ ph: Phases, _ t: Double, _ palette: ShellPalette) {
        var nacre = c
        nacre.clip(to: path(outline(ax, ay, angle, L, ph, frill: 0)))
        let center = CGPoint(x: ax + cos(angle) * L * 0.5, y: ay + sin(angle) * L * 0.5)
        let square = Path(CGRect(x: center.x - L, y: center.y - L, width: L * 2, height: L * 2))
        nacre.fill(square, with: .radialGradient(
            Gradient(stops: [.init(color: Color(hex: palette.nacre[0]), location: 0),
                             .init(color: Color(hex: palette.nacre[1]), location: 0.5),
                             .init(color: Color(hex: palette.nacre[2]), location: 1)]),
            center: center, startRadius: L * 0.05, endRadius: L * 0.85))
        var iris = nacre
        iris.opacity = 0.32
        iris.fill(square, with: .conicGradient(Gradient(colors: palette.iris.map { Color(hex: $0) }),
                                               center: center, angle: .radians(t * 0.15 + ph.0)))
        for i in 0..<6 {
            let rx = L * (0.35 + Double(i) * 0.11), ry = L * (0.3 + Double(i) * 0.1)
            nacre.stroke(ellipseArc(ax, ay, rx, ry, angle, from: -1.2, to: 1.2), with: .color(.white.opacity(0.12)), lineWidth: L * 0.01)
        }
    }

    /// Chair de l'huître, autour de la perle (à mi-longueur de la valve).
    static func drawFlesh(_ c: inout GraphicsContext, _ ax: Double, _ ay: Double, _ angle: Double, _ L: Double, _ ph: Phases) {
        let rx = L * 0.34, ry = L * 0.37
        var flesh = c
        flesh.translateBy(x: ax + cos(angle) * L * 0.5, y: ay + sin(angle) * L * 0.5)
        flesh.rotate(by: .radians(angle))
        var body = Path()
        for i in 0...140 {
            let a = Double(i) / 140 * 2 * .pi
            let w = 1 + 0.022 * sin(a * 24 + ph.2) + 0.035 * sin(a * 5)
            let p = CGPoint(x: cos(a) * rx * w, y: sin(a) * ry * w)
            if i == 0 { body.move(to: p) } else { body.addLine(to: p) }
        }
        body.closeSubpath()
        flesh.fill(body, with: .radialGradient(
            Gradient(stops: [.init(color: Color(hex: "#f4e8d2"), location: 0), .init(color: Color(hex: "#d8c3a0"), location: 0.7),
                             .init(color: Color(hex: "#a88f6d"), location: 1)]),
            center: CGPoint(x: -rx * 0.1, y: -ry * 0.1), startRadius: rx * 0.1, endRadius: rx * 1.1))
        flesh.stroke(body, with: .color(rgba(98, 80, 64, 0.55)), lineWidth: L * 0.01)
        for k in 1..<4 {
            let kk = Double(k)
            flesh.stroke(ellipseArc(-rx * 0.1, 0, rx * (0.45 + kk * 0.14), ry * (0.5 + kk * 0.13), 0, from: -1.1, to: 1.1),
                         with: .color(rgba(120, 95, 70, 0.22)), lineWidth: L * 0.007)
        }
    }

    /// Arc d'ellipse de centre (x, y), tournée de `angle`, entre deux angles paramétriques.
    static func ellipseArc(_ x: Double, _ y: Double, _ rx: Double, _ ry: Double, _ angle: Double, from: Double, to: Double) -> Path {
        var arc = Path()
        let steps = 40
        for i in 0...steps {
            let t = from + (to - from) * Double(i) / Double(steps)
            let p = CGPoint(x: x + rx * cos(t) * cos(angle) - ry * sin(t) * sin(angle),
                            y: y + rx * cos(t) * sin(angle) + ry * sin(t) * cos(angle))
            if i == 0 { arc.move(to: p) } else { arc.addLine(to: p) }
        }
        return arc
    }
}

/// Couleurs d'une coquille d'huître (un skin). Les bandes vont de l'extérieur vers la charnière.
struct ShellPalette {
    struct Band { let light: String; let dark: String }
    var bands: [Band]
    /// Liseré des bords dentelés.
    var edge: Color
    var striation: Color
    var speck: Color
    var sheen: Color
    var sheenStrength: Double
    /// Nacre : centre, milieu, bord ; puis couleurs de l'irisation.
    var nacre: [String]
    var iris: [String]
    var algae: Bool
    var barnacles: Bool

    /// L'huître du lagon : les couleurs exactes de la webapp (src/art/shell.ts).
    static let lagoon = ShellPalette(
        bands: [.init(light: "#5a4a3c", dark: "#2a211b"), .init(light: "#7b6853", dark: "#3e3229"), .init(light: "#4a3f36", dark: "#221b17"),
                .init(light: "#988267", dark: "#4f4236"), .init(light: "#6a5a4b", dark: "#30271f"), .init(light: "#ad9878", dark: "#5d4e3e"),
                .init(light: "#5d5246", dark: "#2d261f")],
        edge: rgba(255, 238, 210, 1), striation: rgba(20, 12, 8, 1), speck: rgba(15, 8, 5, 1),
        sheen: rgba(255, 250, 235, 1), sheenStrength: 0.16,
        nacre: ["#fdfaff", "#e7ddf2", "#a99fbd"],
        iris: ["#ffd1e8", "#c9f2ff", "#fff2c4", "#d9ccff", "#c4ffe9", "#ffd1e8"],
        algae: true, barnacles: true
    )

    /// Première marée : sable mouillé et écume, liseré argent.
    static let firstTide = ShellPalette(
        bands: [.init(light: "#b9a37f", dark: "#6f604a"), .init(light: "#d8c7a4", dark: "#8d7c60"), .init(light: "#a8936f", dark: "#625440"),
                .init(light: "#e6d9bd", dark: "#a29175"), .init(light: "#c3ae89", dark: "#76664e"), .init(light: "#f2e8d2", dark: "#b3a386"),
                .init(light: "#b8a27e", dark: "#6d5e48")],
        edge: rgba(226, 236, 244, 1), striation: rgba(60, 50, 38, 1), speck: rgba(70, 58, 44, 1),
        sheen: rgba(240, 250, 255, 1), sheenStrength: 0.26,
        nacre: ["#ffffff", "#e3f1f6", "#a9c3cf"],
        iris: ["#d6f3ff", "#ffffff", "#e9e1ff", "#c9fff1", "#fff6dc", "#d6f3ff"],
        algae: false, barnacles: true
    )

    /// Huître d'or : or martelé, nacre champagne.
    static let gold = ShellPalette(
        bands: [.init(light: "#b8862b", dark: "#5a3d10"), .init(light: "#e2b650", dark: "#86601e"), .init(light: "#a87a24", dark: "#50370e"),
                .init(light: "#f2d27a", dark: "#957026"), .init(light: "#c7972f", dark: "#624510"), .init(light: "#ffe597", dark: "#a8842f"),
                .init(light: "#b88a2c", dark: "#573c0f")],
        edge: rgba(255, 242, 196, 1), striation: rgba(90, 58, 10, 1), speck: rgba(110, 72, 12, 1),
        sheen: rgba(255, 250, 225, 1), sheenStrength: 0.42,
        nacre: ["#fffaf0", "#f2e2bf", "#c9a96a"],
        iris: ["#fff1b8", "#ffd88a", "#fff8e6", "#f5d6a0", "#fffbe0", "#fff1b8"],
        algae: false, barnacles: false
    )
}

/// rgba() comme en CSS (composantes 0…255).
func rgba(_ r: Double, _ g: Double, _ b: Double, _ a: Double) -> Color {
    Color(red: r / 255, green: g / 255, blue: b / 255).opacity(a)
}
