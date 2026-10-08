import SwiftUI

/// Ce qu'il faut savoir d'une perle pour la dessiner (sans dépendre du moteur).
struct PearlLook {
    var id: String
    var color: String
    /// nil : huître vide, une petite tache.
    var glow: String?
    var shape: String?
    var overtone: String?
    var overtoneColor: String?
    var mark: String?
    var seed: Double = 0.5
}

/// Dessin procédural des perles et de leur halo, porté de src/art/pearl.ts.
enum PearlArt {
    private static let rainbow = ["#ff8aa8", "#ffd88a", "#a8ffb0", "#8ad8ff", "#c8a0ff", "#ff8aa8"]

    static func draw(_ c: inout GraphicsContext, _ x: Double, _ y: Double, _ rad: Double, _ pearl: PearlLook, cracked: Bool) {
        guard pearl.glow != nil else {
            // Huître vide : une petite tache, rien de plus.
            let r = rad * 0.13
            c.fill(Path(ellipseIn: CGRect(x: x + rad * 0.4 - r, y: y + rad * 0.2 - r, width: r * 2, height: r * 2)), with: .color(rgba(110, 92, 74, 0.7)))
            return
        }
        if pearl.mark == "jumelle" {
            // La jumelle : une seconde perle, un peu plus petite, soudée derrière la première.
            var twin = pearl
            twin.mark = nil
            var behind = twin
            behind.seed = (pearl.seed + 0.37).truncatingRemainder(dividingBy: 1)
            paint(&c, x + rad * 0.52, y - rad * 0.2, rad * 0.7, behind, cracked: false)
            paint(&c, x - rad * 0.2, y + rad * 0.08, rad * 0.88, twin, cracked: cracked)
            return
        }
        paint(&c, x, y, rad, pearl, cracked: cracked)
    }

    /// Halo lumineux. `additive` brille fort sur fond sombre ; false sur la nacre (éclaire sans brûler).
    static func glow(_ c: inout GraphicsContext, _ x: Double, _ y: Double, _ rad: Double, _ hex: String?, _ alpha: Double, additive: Bool = true) {
        guard let hex, alpha > 0.001, rad > 0 else { return }
        var layer = c
        layer.blendMode = additive ? .plusLighter : .screen
        let color = Color(hex: hex)
        layer.fill(Path(CGRect(x: x - rad, y: y - rad, width: rad * 2, height: rad * 2)), with: .radialGradient(
            Gradient(stops: [.init(color: color.opacity(alpha), location: 0), .init(color: color.opacity(alpha * 0.35), location: 0.4),
                             .init(color: color.opacity(0), location: 1)]),
            center: CGPoint(x: x, y: y), startRadius: 0, endRadius: rad))
    }

    private static func paint(_ c: inout GraphicsContext, _ x: Double, _ y: Double, _ rad: Double, _ pearl: PearlLook, cracked: Bool) {
        let rgb = tintedRGB(pearl)
        let color = rgbColor(rgb, 0)
        let cursed = pearl.id == "cursed"
        c.fill(Path(CGRect(x: x - rad * 2, y: y - rad * 2, width: rad * 4, height: rad * 4)), with: .radialGradient(
            Gradient(colors: [rgba(60, 40, 30, 0.45), rgba(60, 40, 30, 0)]),
            center: CGPoint(x: x + rad * 0.2, y: y + rad * 0.3), startRadius: rad * 0.2, endRadius: rad * 1.35))

        let shape = outline(x, y, rad, pearl)
        c.fill(shape, with: .radialGradient(
            Gradient(stops: [.init(color: .white, location: 0), .init(color: color, location: 0.24),
                             .init(color: rgbColor(rgb, cursed ? 0.28 : 0.65), location: 0.72),
                             .init(color: rgbColor(rgb, cursed ? 0.05 : 0.42), location: 1)]),
            center: CGPoint(x: x - rad * 0.22, y: y - rad * 0.26), startRadius: rad * 0.05, endRadius: rad * 1.2))

        // Nacre irisée : un voile de couleur glisse sur la surface sans masquer la teinte de la perle.
        var inside = c
        inside.clip(to: shape)
        let square = Path(CGRect(x: x - rad * 1.4, y: y - rad * 1.4, width: rad * 2.8, height: rad * 2.8))
        var sheen = inside
        sheen.opacity = pearl.overtone == "arc-en-ciel" ? 0.42 : cursed ? 0.32 : pearl.id == "black" ? 0.27 : 0.24
        sheen.fill(square, with: .conicGradient(Gradient(colors: irisColors(pearl).map { Color(hex: $0) }),
                                                center: CGPoint(x: x, y: y), angle: .radians(-0.72)))
        if ["golden", "giant", "cursed"].contains(pearl.id) {
            var ring = inside
            ring.opacity = cursed ? 0.38 : 0.26
            let stroke = Color(hex: cursed ? "#ff6c91" : pearl.id == "golden" ? "#fff0ad" : "#e8fbff")
            ring.stroke(ShellArt.ellipseArc(x, y, rad * 0.75, rad * 0.27, cursed ? -0.55 : -0.32, from: .pi * 0.1, to: .pi * 1.7),
                        with: .color(stroke), lineWidth: max(1, rad * 0.045))
        }
        if pearl.shape == "cerclee" {
            // Cerclée : des anneaux en creux tout autour.
            for k in [-0.42, -0.05, 0.32] {
                inside.stroke(ShellArt.ellipseArc(x, y + k * rad, rad * 1.02, rad * 0.16, 0, from: 0, to: .pi),
                              with: .color(rgba(40, 30, 30, 0.2)), lineWidth: rad * 0.055)
                inside.stroke(ShellArt.ellipseArc(x, y + k * rad - rad * 0.05, rad * 1.02, rad * 0.16, 0, from: 0.2, to: .pi - 0.2),
                              with: .color(rgba(255, 255, 255, 0.28)), lineWidth: rad * 0.025)
            }
        }
        inside.fill(Path(CGRect(x: x - rad, y: y - rad, width: rad * 2, height: rad * 2)), with: .linearGradient(
            Gradient(stops: [.init(color: .white.opacity(0), location: 0), .init(color: .white.opacity(0.18), location: 0.48),
                             .init(color: .white.opacity(0.03), location: 0.68), .init(color: .white.opacity(0), location: 1)]),
            startPoint: CGPoint(x: x - rad, y: y + rad * 0.55), endPoint: CGPoint(x: x + rad, y: y - rad * 0.65)))

        var rim = c
        rim.opacity = 0.35
        rim.stroke(shape, with: .color(Color(hex: pearl.glow ?? pearl.color)), lineWidth: rad * 0.08)

        // Reflets larges et petits éclats nets.
        c.fill(rotatedEllipse(x - rad * 0.35, y - rad * 0.42, rad * 0.22, rad * 0.13, -0.6), with: .color(.white.opacity(0.85)))
        c.fill(rotatedEllipse(x + rad * 0.45, y + rad * 0.28, rad * 0.1, rad * 0.035, -0.55),
               with: .color(cursed ? rgba(255, 92, 143, 0.62) : .white.opacity(0.34)))

        if pearl.mark == "lune" {
            // Lunaire : un croissant pâle sur la nacre.
            let mx = x + rad * 0.28, my = y + rad * 0.22, mr = rad * 0.26
            var crescent = Path()
            crescent.addArc(center: CGPoint(x: mx, y: my), radius: mr, startAngle: .radians(.pi * 0.5), endAngle: .radians(.pi * 1.5), clockwise: false)
            crescent.addArc(center: CGPoint(x: mx + mr * 0.38, y: my), radius: mr * 0.9, startAngle: .radians(.pi * 1.5), endAngle: .radians(.pi * 0.5), clockwise: true)
            crescent.closeSubpath()
            c.fill(crescent, with: .color(rgba(255, 250, 232, 0.62)))
        }
        if pearl.mark == "etoile" {
            // Étoilée : un reflet net en étoile à quatre branches.
            let sx = x - rad * 0.32, sy = y - rad * 0.38, sr = rad * 0.55
            var star = Path()
            star.move(to: CGPoint(x: sx, y: sy - sr))
            star.addQuadCurve(to: CGPoint(x: sx + sr, y: sy), control: CGPoint(x: sx, y: sy))
            star.addQuadCurve(to: CGPoint(x: sx, y: sy + sr), control: CGPoint(x: sx, y: sy))
            star.addQuadCurve(to: CGPoint(x: sx - sr, y: sy), control: CGPoint(x: sx, y: sy))
            star.addQuadCurve(to: CGPoint(x: sx, y: sy - sr), control: CGPoint(x: sx, y: sy))
            var bright = c
            bright.blendMode = .plusLighter
            bright.fill(star, with: .color(.white.opacity(0.95)))
        }
        if cracked {
            var crack = Path()
            crack.move(to: CGPoint(x: x - rad * 0.1, y: y - rad * 0.9))
            crack.addLine(to: CGPoint(x: x + rad * 0.12, y: y - rad * 0.3))
            crack.addLine(to: CGPoint(x: x - rad * 0.08, y: y + rad * 0.1))
            crack.addLine(to: CGPoint(x: x + rad * 0.2, y: y + rad * 0.7))
            crack.move(to: CGPoint(x: x + rad * 0.12, y: y - rad * 0.3))
            crack.addLine(to: CGPoint(x: x + rad * 0.55, y: y - rad * 0.15))
            c.stroke(crack, with: .color(rgba(40, 24, 20, 0.85)), lineWidth: max(1, rad * 0.045))
        }
    }

    /// Contour selon la forme : ronde, presque ronde, goutte, bouton, cerclée, baroque, ou en cœur.
    private static func outline(_ x: Double, _ y: Double, _ rad: Double, _ pearl: PearlLook) -> Path {
        var path = Path()
        if pearl.mark == "coeur" {
            for i in 0...64 {
                let t = Double(i) / 64 * 2 * .pi
                let p = CGPoint(x: x + pow(sin(t), 3) * rad * 1.08,
                                y: y - ((13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t)) / 16 - 0.12) * rad * 1.08)
                if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            path.closeSubpath()
            return path
        }
        let shape = pearl.shape ?? (pearl.id == "baroque" ? "baroque" : "ronde")
        if shape == "ronde" && pearl.id != "cursed" {
            return Path(ellipseIn: CGRect(x: x - rad, y: y - rad, width: rad * 2, height: rad * 2))
        }
        let seed = pearl.seed
        let tilt = (seed - 0.5) * 0.6
        let eerie: (Double) -> Double = { a in pearl.id == "cursed" ? 1 + 0.05 * sin(a * 7 + 0.7) : 1 }
        let (wide, tall, k): (Double, Double, (Double) -> Double) = switch shape {
        case "goutte": (0.9, 1.1, { a in 1 + 0.16 * sin(a) })
        case "bouton": (1.08, 0.88, { a in 1 - 0.1 * pow(max(0, sin(a)), 2) })
        case "cerclee": (1.02, 0.98, { a in 1 + 0.03 * sin(3 * a + seed * 6) })
        case "baroque": (1.06, 0.95, { a in 1 + 0.13 * sin(a * 3 + seed * 6.3) + 0.055 * sin(a * 7 + 2.1 + seed * 4) + 0.025 * cos(a * 11) })
        case "presque-ronde": (1.04, 0.97, { a in 1 + 0.02 * sin(2 * a + seed * 6) })
        default: (1, 1, { _ in 1 })
        }
        // La goutte et le bouton restent droits (pointe en haut, base à plat).
        let turn = shape == "goutte" || shape == "bouton" ? 0 : tilt
        for i in 0...64 {
            let a = Double(i) / 64 * 2 * .pi
            let r = k(a) * eerie(a)
            let p = CGPoint(x: x + cos(a + turn) * rad * wide * r, y: y + sin(a + turn) * rad * tall * r)
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }

    private static func irisColors(_ pearl: PearlLook) -> [String] {
        if pearl.overtone == "arc-en-ciel" { return rainbow }
        if let tone = pearl.overtoneColor { return [tone, "#ffffff", tone, pearl.color, tone] }
        return ["#6de2db", "#f3c8f1", "#fff4c8", "#b7e9ef", "#6de2db"]
    }

    /// Couleur de la perle teintée par son reflet (25 %), comme pearlTint en TypeScript.
    private static func tintedRGB(_ pearl: PearlLook) -> (Double, Double, Double) {
        let a = hexComponents(pearl.color)
        guard let tone = pearl.overtoneColor else { return a }
        let b = hexComponents(tone)
        return ((a.0 + (b.0 - a.0) * 0.25).rounded(), (a.1 + (b.1 - a.1) * 0.25).rounded(), (a.2 + (b.2 - a.2) * 0.25).rounded())
    }

    /// Couleur assombrie (k = 0 : identique, 1 : noir), comme shade() en TypeScript.
    private static func rgbColor(_ rgb: (Double, Double, Double), _ k: Double) -> Color {
        Color(red: rgb.0 * (1 - k) / 255, green: rgb.1 * (1 - k) / 255, blue: rgb.2 * (1 - k) / 255)
    }

    private static func rotatedEllipse(_ x: Double, _ y: Double, _ rx: Double, _ ry: Double, _ angle: Double) -> Path {
        var path = ShellArt.ellipseArc(x, y, rx, ry, angle, from: 0, to: 2 * .pi)
        path.closeSubpath()
        return path
    }
}

func hexComponents(_ hex: String) -> (Double, Double, Double) {
    let value = UInt32(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0
    return (Double((value >> 16) & 0xFF), Double((value >> 8) & 0xFF), Double(value & 0xFF))
}
