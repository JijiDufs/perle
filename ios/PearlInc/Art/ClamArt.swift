import SwiftUI

/// Le bénitier (skin), vu de dessus comme l'huître et dans la même direction artistique (src/art/shell.ts,
/// prototype de pearl-inc.app) : un grand éventail crème à gros plis rayonnants, couverts d'écailles
/// relevées, au bord festonné. Ouvert : une coquille de porcelaine et le manteau bleu-vert irisé, tacheté,
/// sur lequel repose la perle. Le couvercle se soulève exactement comme celui de l'huître : le geste ne change pas.
///
/// Repère : charnière (ax, ay), valve dirigée selon `angle`, longueur L.
/// Les phases rendent chaque bénitier unique : nombre de plis, largeur, irrégularités.
enum ClamArt {
    /// Le bénitier est plus large que long : à longueur égale, il déborderait de l'écran.
    static let lengthFactor = 0.78
    /// Demi-ouverture de l'éventail (radians, dans le repère de la valve).
    private static let spread = 1.45
    /// Élargissement latéral par rapport à l'huître.
    private static let breadth = 1.3

    private static let mantleIris = ["#2ec4b6", "#3f7fe0", "#7a4fd0", "#1fa3a0", "#6fe0c8", "#2ec4b6"]

    /// Nombre de plis : 5 ou 6 selon le bénitier.
    private static func ribs(_ ph: ShellArt.Phases) -> Double { ph.2 > 3.15 ? 6 : 5 }

    /// Bord de la valve : éventail festonné par les plis.
    static func outline(_ ax: Double, _ ay: Double, _ angle: Double, _ L: Double, _ ph: ShellArt.Phases,
                        scallop: Double = 0.06) -> [CGPoint] {
        let steps = 160
        let n = ribs(ph)
        let ca = cos(angle), sa = sin(angle)
        return (0...steps).map { i in
            let u = Double(i) / Double(steps)
            let f = -spread + 2 * spread * u
            var r = L * pow(max(0, cos(f * 0.92)), 0.3) * (1 + 0.035 * sin(f * 2 + ph.0) + 0.02 * sin(f * 5 + ph.1))
            r *= 1 + scallop * cos(2 * .pi * (u * n - 0.5))
            r *= 1 + 0.01 * sin(f * 70 + ph.2)
            let x = cos(f) * r
            let y = sin(f) * r * breadth
            return CGPoint(x: ax + x * ca - y * sa, y: ay + x * sa + y * ca)
        }
    }

    /// Point de la valve à l'angle `f` (repère de la valve) et à la fraction `k` du bord.
    private static func point(_ ax: Double, _ ay: Double, _ angle: Double, _ L: Double, _ ph: ShellArt.Phases, f: Double, k: Double) -> CGPoint {
        let r = L * k * pow(max(0, cos(f * 0.92)), 0.3)
        let x = cos(f) * r, y = sin(f) * r * breadth
        return CGPoint(x: ax + x * cos(angle) - y * sin(angle), y: ay + x * sin(angle) + y * cos(angle))
    }

    /// Relief des plis : clair sur les crêtes, sombre dans les creux (dégradé conique depuis la charnière).
    private static func ribShading(_ ax: Double, _ ay: Double, _ angle: Double, _ ph: ShellArt.Phases, light: Double, dark: Double) -> GraphicsContext.Shading {
        let n = ribs(ph)
        let start = angle - .pi
        var stops: [Gradient.Stop] = []
        for i in 0...96 {
            let u = Double(i) / 96
            let f = -spread + 2 * spread * u
            // Angle à l'écran, en tenant compte de l'élargissement.
            let screen = angle + atan2(sin(f) * breadth, cos(f))
            let b = cos(2 * .pi * (u * n - 0.5))
            let color = b > 0 ? Color.white.opacity(light * pow(b, 1.5)) : rgba(70, 50, 25, dark * pow(-b, 1.2))
            let location = (screen - start) / (2 * .pi)
            stops.append(.init(color: color, location: min(1, max(0, location))))
        }
        return .conicGradient(Gradient(stops: stops), center: CGPoint(x: ax, y: ay), angle: .radians(start))
    }

    // MARK: - Extérieur

    static func drawExterior(_ c: inout GraphicsContext, _ ax: Double, _ ay: Double, _ angle: Double, _ L: Double, _ ph: ShellArt.Phases) {
        let shape = ShellArt.path(outline(ax, ay, angle, L, ph))
        let light = CGPoint(x: ax - L * 0.3, y: ay + L * 0.2)

        var shadow = c
        shadow.translateBy(x: L * 0.01, y: L * 0.025)
        shadow.fill(shape, with: .color(rgba(10, 20, 20, 0.35)))

        c.fill(shape, with: .radialGradient(
            Gradient(stops: [.init(color: Color(hex: "#fdf7ea"), location: 0), .init(color: Color(hex: "#e3d4b4"), location: 0.55),
                             .init(color: Color(hex: "#a89270"), location: 1)]),
            center: light, startRadius: L * 0.05, endRadius: L * 1.35))

        var inside = c
        inside.clip(to: shape)
        inside.fill(Path(CGRect(x: ax - L * 2, y: ay - L * 2, width: L * 4, height: L * 4)),
                    with: ribShading(ax, ay, angle, ph, light: 0.4, dark: 0.38))

        // Lignes de croissance : le feston se répète en plus petit vers la charnière.
        for k in 1...6 {
            let kk = Double(k)
            let band = ShellArt.path(outline(ax, ay, angle, L * (1 - kk * 0.13), ph, scallop: 0.06 * (1 - kk * 0.1)))
            inside.stroke(band, with: .color(rgba(110, 85, 50, 0.22)), lineWidth: max(1, L * 0.007))
            var lit = inside
            lit.translateBy(x: -L * 0.004, y: -L * 0.006)
            lit.stroke(band, with: .color(rgba(255, 252, 240, 0.25)), lineWidth: max(0.8, L * 0.004))
        }

        // Écailles relevées sur la crête des plis, de plus en plus grandes vers le bord.
        let n = ribs(ph)
        for i in 0..<Int(n) {
            let u = (Double(i) + 0.5) / n
            let f = -spread + 2 * spread * u
            let screen = angle + atan2(sin(f) * breadth, cos(f))
            for (j, k) in [0.42, 0.56, 0.69, 0.81, 0.92].enumerated() {
                let p = point(ax, ay, angle, L, ph, f: f, k: k)
                let size = L * (0.045 + Double(j) * 0.012) * (0.85 + 0.15 * sin(ph.1 + Double(i)))
                var scale = c
                scale.translateBy(x: p.x, y: p.y)
                scale.rotate(by: .radians(screen))
                // Une écaille : une lamelle en croissant, ombre côté bord, reflet côté charnière.
                var lamella = Path()
                lamella.move(to: CGPoint(x: 0, y: -size))
                lamella.addQuadCurve(to: CGPoint(x: 0, y: size), control: CGPoint(x: size * 1.1, y: 0))
                lamella.addQuadCurve(to: CGPoint(x: 0, y: -size), control: CGPoint(x: size * 0.35, y: 0))
                var under = scale
                under.translateBy(x: size * 0.18, y: 0)
                under.fill(lamella, with: .color(rgba(60, 40, 20, 0.35)))
                scale.fill(lamella, with: .linearGradient(Gradient(colors: [Color(hex: "#fffaf0"), Color(hex: "#d8c7a2")]),
                                                          startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: size, y: 0)))
                scale.stroke(lamella, with: .color(rgba(255, 255, 250, 0.55)), lineWidth: max(0.6, L * 0.003))
            }
        }

        // Bord festonné éclairé, et reflet de la lumière du dessus.
        c.stroke(shape, with: .color(rgba(255, 250, 235, 0.45)), lineWidth: max(1, L * 0.008))
        inside.fill(Path(CGRect(x: ax - L * 2, y: ay - L * 2, width: L * 4, height: L * 4)),
                    with: .radialGradient(Gradient(colors: [rgba(255, 252, 240, 0.3), rgba(255, 252, 240, 0)]),
                                          center: light, startRadius: 0, endRadius: L * 0.75))
    }

    // MARK: - Intérieur

    /// L'intérieur, là où l'ombre tombe tant que le bénitier est fermé.
    static func interiorPath(_ ax: Double, _ ay: Double, _ angle: Double, _ L: Double, _ ph: ShellArt.Phases) -> Path {
        ShellArt.path(outline(ax, ay, angle, L * 0.92, ph, scallop: 0.05))
    }

    /// Porcelaine de la valve ; `mantle` : le manteau irisé (valve du bas seulement).
    static func drawInterior(_ c: inout GraphicsContext, _ ax: Double, _ ay: Double, _ angle: Double, _ L: Double, _ ph: ShellArt.Phases,
                             _ t: Double, mantle: Bool) {
        let porcelain = interiorPath(ax, ay, angle, L, ph)
        let center = CGPoint(x: ax + cos(angle) * L * 0.5, y: ay + sin(angle) * L * 0.5)
        let square = Path(CGRect(x: center.x - L * 1.5, y: center.y - L * 1.5, width: L * 3, height: L * 3))
        var inside = c
        inside.clip(to: porcelain)
        inside.fill(square, with: .radialGradient(
            Gradient(stops: [.init(color: .white, location: 0), .init(color: Color(hex: "#f3eee4"), location: 0.6),
                             .init(color: Color(hex: "#c9bea8"), location: 1)]),
            center: center, startRadius: L * 0.05, endRadius: L * 0.95))
        inside.fill(square, with: ribShading(ax, ay, angle, ph, light: 0.35, dark: 0.18))
        guard mantle else { return }

        // Le manteau : chair bleu-vert irisée qui respire doucement, au bord frisé.
        let frill = ShellArt.path(outline(ax, ay, angle, L * 0.8, ph, scallop: 0.07).enumerated().map { i, p in
            let wave = 1 + 0.025 * sin(Double(i) * 0.9 + t * 0.8)
            return CGPoint(x: ax + (p.x - ax) * wave, y: ay + (p.y - ay) * wave)
        })
        var flesh = c
        flesh.clip(to: frill)
        flesh.fill(square, with: .radialGradient(
            Gradient(stops: [.init(color: Color(hex: "#39d6c2"), location: 0), .init(color: Color(hex: "#1c8fb0"), location: 0.45),
                             .init(color: Color(hex: "#2a4da0"), location: 0.78), .init(color: Color(hex: "#3a2366"), location: 1)]),
            center: center, startRadius: L * 0.04, endRadius: L * 0.7))
        var iris = flesh
        iris.opacity = 0.32
        iris.fill(square, with: .conicGradient(Gradient(colors: mantleIris.map { Color(hex: $0) }),
                                               center: center, angle: .radians(t * 0.2 + ph.0)))
        // Rayures ondulées et « yeux » clairs, comme sur un vrai bénitier.
        let n = ribs(ph)
        for i in 0..<Int(n * 2) {
            let u = (Double(i) + 0.5) / (n * 2)
            let f = -spread + 2 * spread * u
            var stripe = Path()
            for s in 0...20 {
                let k = 0.15 + 0.62 * Double(s) / 20
                let p = point(ax, ay, angle, L, ph, f: f + 0.05 * sin(Double(s) * 1.4 + Double(i)), k: k)
                if s == 0 { stripe.move(to: p) } else { stripe.addLine(to: p) }
            }
            flesh.stroke(stripe, with: .color(rgba(170, 255, 240, 0.22)), lineWidth: max(1, L * 0.012))
        }
        var seed = (ph.0 * 1000).rounded(.down) + 7
        func rand() -> Double {
            seed = (seed * 16807).truncatingRemainder(dividingBy: 2_147_483_647)
            return seed / 2_147_483_647
        }
        for _ in 0..<46 {
            let p = point(ax, ay, angle, L, ph, f: -spread * 0.95 + rand() * spread * 1.9, k: 0.2 + 0.58 * sqrt(rand()))
            let r = L * (0.008 + rand() * 0.012)
            flesh.fill(Path(ellipseIn: CGRect(x: p.x - r * 1.6, y: p.y - r * 1.6, width: r * 3.2, height: r * 3.2)), with: .color(rgba(10, 30, 70, 0.35)))
            flesh.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)), with: .color(rgba(200, 255, 245, 0.75)))
        }
        // Bord du manteau, plus clair.
        c.stroke(frill, with: .color(rgba(140, 240, 225, 0.55)), lineWidth: max(1, L * 0.012))
    }
}
