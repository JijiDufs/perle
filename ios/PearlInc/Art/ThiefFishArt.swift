import SwiftUI

/// Le poisson voleur : il fond sur la perle depuis un bord de l'écran, la happe, puis file vers l'autre bord
/// en ondulant, la perle dans la bouche, avec un sillage de bulles. Dessiné par code, comme le lagon.
/// Aucune règle ici : la scène reçoit le temps écoulé et les durées du Core (`FishThief`).
struct ThiefFishArt {
    /// Temps écoulé depuis le début du vol (ms).
    var elapsedMs: Double
    var arriveMs: Double
    var fleeMs: Double
    /// Le centre de la perle dans l'huître, et la taille de l'huître (L).
    var target: CGPoint
    var L: Double
    var size: CGSize
    /// Il arrive par la gauche (et s'enfuit à droite), ou l'inverse.
    var fromLeft: Bool
    var time: Double

    /// Longueur du poisson.
    var length: Double { L * 0.46 }

    /// Le poisson est encore à l'écran.
    var isVisible: Bool { elapsedMs >= 0 && elapsedMs <= arriveMs + fleeMs }

    /// Où est le centre du poisson à un instant donné (ms).
    func position(at ms: Double) -> CGPoint {
        let w = Double(size.width), h = Double(size.height)
        let side = fromLeft ? 1.0 : -1.0
        // La bouche se pose sur la perle : le centre est une demi-longueur en arrière.
        let grab = CGPoint(x: target.x - side * length * 0.48, y: target.y)
        if ms < arriveMs {
            // Arrivée en plongeant depuis le haut, puis à l'horizontale sur la perle, en ralentissant pour mordre.
            let u = 1 - pow(1 - max(0, ms / arriveMs), 3)
            let start = CGPoint(x: fromLeft ? -length : w + length, y: target.y - L * 0.7)
            let c1 = CGPoint(x: start.x + side * L * 0.4, y: start.y)
            let c2 = CGPoint(x: grab.x - side * L * 0.45, y: grab.y)
            return bezier(start, c1, c2, grab, u)
        }
        // Fuite : hésite un instant (il nargue), puis accélère vers l'autre bord en ondulant.
        let v = min(1, (ms - arriveMs) / fleeMs)
        let p = 0.45 * v + 0.55 * v * v * v
        let exit = CGPoint(x: fromLeft ? w + length * 1.2 : -length * 1.2, y: max(h * 0.2, target.y - L * 1.3))
        let wobble = sin(v * .pi * 5) * L * 0.14 * (1 - v * 0.4)
        return CGPoint(x: grab.x + (exit.x - grab.x) * p, y: grab.y + (exit.y - grab.y) * p + wobble)
    }

    /// Le poisson tient la perle dans la bouche.
    var carrying: Bool { elapsedMs >= arriveMs }

    func draw(_ c: inout GraphicsContext, pearl: PearlLook?, pearlRadius: Double, glow: String?) {
        guard isVisible else { return }
        let here = position(at: elapsedMs)
        let ahead = position(at: elapsedMs + 24)
        // Il garde le dos en haut : le nez ne pique ni ne se cabre de plus de 30°.
        let raw = atan2(ahead.y - here.y, ahead.x - here.x)
        let level = cos(raw) < 0 ? Double.pi : 0
        let heading = level + min(0.52, max(-0.52, remainder(raw - level, 2 * .pi)))

        // Sillage de bulles pendant la fuite.
        if carrying {
            for k in 1...7 {
                let past = elapsedMs - Double(k) * 70
                guard past > arriveMs else { break }
                let p = position(at: past)
                let r = length * (0.025 + 0.012 * Double(k % 3))
                let drift = CGPoint(x: p.x + sin(time * 3 + Double(k)) * 3, y: p.y - Double(k) * 2.5)
                c.stroke(Path(ellipseIn: CGRect(x: drift.x - r, y: drift.y - r, width: r * 2, height: r * 2)),
                         with: .color(.white.opacity(0.55 - Double(k) * 0.06)), lineWidth: 1.2)
            }
        }
        // Gros plouf d'eau au moment où il mord.
        let bite = (elapsedMs - arriveMs) / 220
        if bite > 0 && bite < 1 {
            let r = L * (0.15 + bite * 0.35)
            c.stroke(Path(ellipseIn: CGRect(x: target.x - r, y: target.y - r * 0.7, width: r * 2, height: r * 1.4)),
                     with: .color(.white.opacity(0.6 * (1 - bite))), lineWidth: 3 * (1 - bite) + 1)
        }

        let flap = sin(time * (carrying ? 22 : 14)) * (carrying ? 0.4 : 0.25)
        Self.drawFish(&c, at: here, length: length, heading: heading, flap: flap, time: time,
                      carrying: carrying ? pearl : nil, pearlRadius: pearlRadius, glow: glow)
    }

    /// Le poisson lui-même (orange à rayures bleu nuit, nageoires, œil malicieux), tête vers `heading`.
    /// `carrying` : la perle qu'il tient dans la bouche.
    static func drawFish(_ c: inout GraphicsContext, at center: CGPoint, length: Double, heading: Double, flap: Double, time: Double,
                         carrying pearl: PearlLook? = nil, pearlRadius: Double = 0, glow: String? = nil) {
        var g = c
        g.translateBy(x: center.x, y: center.y)
        // Toujours le dos en haut : on retourne le poisson quand il nage vers la gauche.
        let left = cos(heading) < 0
        g.rotate(by: .radians(left ? heading - .pi : heading))
        if left { g.scaleBy(x: -1, y: 1) }
        g.scaleBy(x: length, y: length)

        // Ombre douce sous lui.
        g.fill(Path(ellipseIn: CGRect(x: -0.45, y: 0.22, width: 0.9, height: 0.14)), with: .color(.black.opacity(0.12)))

        // Queue fourchue qui bat.
        var tail = Path()
        tail.move(to: CGPoint(x: -0.36, y: 0))
        tail.addQuadCurve(to: CGPoint(x: -0.62, y: -0.24 + flap * 0.25), control: CGPoint(x: -0.5, y: -0.06))
        tail.addQuadCurve(to: CGPoint(x: -0.54, y: 0.02 + flap * 0.1), control: CGPoint(x: -0.56, y: -0.08))
        tail.addQuadCurve(to: CGPoint(x: -0.62, y: 0.24 + flap * 0.25), control: CGPoint(x: -0.56, y: 0.12))
        tail.addQuadCurve(to: CGPoint(x: -0.36, y: 0), control: CGPoint(x: -0.5, y: 0.06))
        g.fill(tail, with: .linearGradient(Gradient(colors: [Color(hex: "#ff8a2a"), Color(hex: "#ffcf4a")]),
                                           startPoint: CGPoint(x: -0.36, y: 0), endPoint: CGPoint(x: -0.62, y: 0)))

        // Nageoire du dos et du ventre.
        var dorsal = Path()
        dorsal.move(to: CGPoint(x: -0.2, y: -0.17))
        dorsal.addQuadCurve(to: CGPoint(x: 0.18, y: -0.19), control: CGPoint(x: -0.06, y: -0.42 + flap * 0.05))
        dorsal.closeSubpath()
        g.fill(dorsal, with: .color(Color(hex: "#f2711c")))
        var ventral = Path()
        ventral.move(to: CGPoint(x: -0.08, y: 0.17))
        ventral.addQuadCurve(to: CGPoint(x: 0.12, y: 0.18), control: CGPoint(x: -0.02, y: 0.34 - flap * 0.05))
        ventral.closeSubpath()
        g.fill(ventral, with: .color(Color(hex: "#f2711c")))

        // Corps en goutte, dégradé chaud.
        var body = Path()
        body.move(to: CGPoint(x: 0.5, y: 0.02))
        body.addCurve(to: CGPoint(x: -0.38, y: 0), control1: CGPoint(x: 0.42, y: -0.3), control2: CGPoint(x: -0.2, y: -0.24))
        body.addCurve(to: CGPoint(x: 0.5, y: 0.02), control1: CGPoint(x: -0.2, y: 0.24), control2: CGPoint(x: 0.42, y: 0.3))
        body.closeSubpath()
        g.fill(body, with: .linearGradient(Gradient(colors: [Color(hex: "#ffb347"), Color(hex: "#ff7a1a"), Color(hex: "#ffd36b")]),
                                           startPoint: CGPoint(x: 0, y: -0.25), endPoint: CGPoint(x: 0, y: 0.25)))
        // Deux rayures bleu nuit cerclées de blanc.
        var stripes = g
        stripes.clip(to: body)
        for x in [0.16, -0.14] {
            var band = Path()
            band.move(to: CGPoint(x: x + 0.04, y: -0.3))
            band.addQuadCurve(to: CGPoint(x: x + 0.04, y: 0.3), control: CGPoint(x: x - 0.06, y: 0))
            stripes.stroke(band, with: .color(.white.opacity(0.95)), lineWidth: 0.11)
            stripes.stroke(band, with: .color(Color(hex: "#1b2f6b")), lineWidth: 0.06)
        }
        // Reflet sur le dos.
        stripes.fill(Path(ellipseIn: CGRect(x: -0.18, y: -0.2, width: 0.5, height: 0.12)), with: .color(.white.opacity(0.22)))
        g.stroke(body, with: .color(Color(hex: "#b44a0a").opacity(0.55)), lineWidth: 0.012)

        // Nageoire de côté qui rame.
        var pectoral = Path()
        pectoral.move(to: CGPoint(x: 0.08, y: 0.05))
        pectoral.addQuadCurve(to: CGPoint(x: -0.06, y: 0.16 + flap * 0.12), control: CGPoint(x: -0.04, y: 0.02))
        pectoral.addQuadCurve(to: CGPoint(x: 0.08, y: 0.05), control: CGPoint(x: 0.04, y: 0.14))
        g.fill(pectoral, with: .color(Color(hex: "#ffe08a").opacity(0.9)))

        // Œil malicieux, sourcil froncé.
        g.fill(Path(ellipseIn: CGRect(x: 0.24, y: -0.12, width: 0.13, height: 0.13)), with: .color(.white))
        g.fill(Path(ellipseIn: CGRect(x: 0.29, y: -0.09, width: 0.07, height: 0.07)), with: .color(Color(hex: "#101820")))
        g.fill(Path(ellipseIn: CGRect(x: 0.31, y: -0.085, width: 0.025, height: 0.025)), with: .color(.white))
        var brow = Path()
        brow.move(to: CGPoint(x: 0.23, y: -0.17))
        brow.addLine(to: CGPoint(x: 0.37, y: -0.13))
        g.stroke(brow, with: .color(Color(hex: "#5a2206")), style: StrokeStyle(lineWidth: 0.025, lineCap: .round))

        // Bouche.
        var lip = Path()
        lip.move(to: CGPoint(x: 0.44, y: 0.0))
        lip.addQuadCurve(to: CGPoint(x: 0.5, y: 0.07), control: CGPoint(x: 0.52, y: 0.02))
        g.stroke(lip, with: .color(Color(hex: "#b44a0a")), style: StrokeStyle(lineWidth: 0.022, lineCap: .round))

        // La perle dans la bouche, qui brille encore (dessinée à l'échelle de l'écran, comme dans l'huître).
        if let pearl {
            let local = CGPoint(x: (0.5 * length + pearlRadius * 0.6) * (left ? -1 : 1), y: 0.04 * length)
            let turn = left ? heading - .pi : heading
            let mouth = CGPoint(x: center.x + local.x * cos(turn) - local.y * sin(turn), y: center.y + local.x * sin(turn) + local.y * cos(turn))
            // Son halo par-dessus, comme dans l'huître : c'est lui qui lui donne sa couleur.
            PearlArt.draw(&c, mouth.x, mouth.y, pearlRadius, pearl, cracked: false)
            PearlArt.glow(&c, mouth.x, mouth.y, pearlRadius * 3.2, glow, 0.75 + 0.2 * sin(time * 8), additive: false)
        }
    }

    private func bezier(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint, _ d: CGPoint, _ t: Double) -> CGPoint {
        let u = 1 - t
        let (k0, k1, k2, k3) = (u * u * u, 3 * u * u * t, 3 * u * t * t, t * t * t)
        return CGPoint(x: k0 * a.x + k1 * b.x + k2 * c.x + k3 * d.x, y: k0 * a.y + k1 * b.y + k2 * c.y + k3 * d.y)
    }
}
