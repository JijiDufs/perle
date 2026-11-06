import SwiftUI

/// Le poisson voleur : il fond sur la perle depuis un bord de l'écran, la happe, puis file vers l'autre bord
/// en ondulant, la perle dans la bouche, avec un sillage de bulles. En photo (essai assets), animé par code.
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

    /// La photo du poisson et son rapport hauteur / largeur (`thief-fish.png`, à côté de ce fichier).
    nonisolated(unsafe) private static var photoCache: (Image, Double)??  // lu et écrit seulement en dessinant (fil principal)
    private static var photo: (Image, Double)? {
        if photoCache == nil {
            photoCache = .some(Bundle.main.url(forResource: "thief-fish", withExtension: "png")
                .flatMap { UIImage(contentsOfFile: $0.path) }.map { (Image(uiImage: $0), $0.size.height / $0.size.width) })
        }
        return photoCache ?? nil
    }

    /// Le poisson lui-même (la photo, ou rien si elle manque), tête vers `heading`.
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

        // Le poisson en photo (essai assets : Kling 3.0, détouré par la luminosité), le nez vers +x, la bouche au bord droit ;
        // il tangue un peu au rythme de la queue.
        if let (photo, aspect) = Self.photo {
            var fish = g
            fish.rotate(by: .radians(flap * 0.12))
            fish.draw(photo, in: CGRect(x: -0.5, y: -aspect / 2, width: 1, height: aspect))
        }

        // La perle dans la bouche, qui brille encore (dessinée à l'échelle de l'écran, comme dans l'huître).
        if let pearl {
            // Un peu plus petite que dans l'huître (la photo de la perle déborde de son rayon), au bout des lèvres.
            let pearlRadius = pearlRadius * 0.75
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
