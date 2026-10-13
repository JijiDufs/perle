import CoreGraphics
import SwiftUI

/// Le lagon, porté de src/art/lagoon.ts (le prototype de pearl-inc.app) : eau turquoise traversée de soleil,
/// récif au loin, fond de sable où dansent les reflets (caustiques), algues, poissons, bulles et plancton.
/// Tout est dessiné par code et déterministe (le décor est le même d'une fois sur l'autre).
/// Aucune règle de jeu ici.
struct LagoonArt {
    /// Ce que le décor doit savoir du sujet (l'huître) : où il est posé, et sa taille.
    struct Focus {
        var x: Double
        var y: Double
        var size: Double
    }

    var time: Double
    var focus: Focus
    /// Ombre douce du sujet sur le sable.
    var shadow = true

    private static let tau = Double.pi * 2

    /// Le décor, sous le sujet.
    func draw(_ c: inout GraphicsContext, size: CGSize) {
        let w = Double(size.width), h = Double(size.height)
        let horizon = min(h * 0.8, max(h * 0.2, (focus.y - focus.size * 0.32).rounded()))
        drawBase(&c, w, h, horizon)
        drawSurface(&c, w, horizon, time)
        drawRays(&c, w, h, horizon, time)
        drawCaustics(&c, w, h, horizon, time)
        drawSeaweed(&c, w, h, horizon, time)
        drawFish(&c, w, horizon, time)
        drawParticles(&c, w, h, horizon, time)
        if shadow {
            // Ombre douce de l'huître sur le sable.
            let cy = focus.y + focus.size * 0.62
            var s = c
            s.translateBy(x: 0, y: cy)
            s.scaleBy(x: 1, y: 0.42)
            s.translateBy(x: 0, y: -cy)
            s.fill(Path(CGRect(x: focus.x - focus.size * 1.1, y: focus.y - focus.size * 0.6, width: focus.size * 2.2, height: focus.size * 2.6)),
                   with: .radialGradient(Gradient(colors: [rgba(0, 30, 35, 0.42), rgba(0, 30, 35, 0)]),
                                         center: CGPoint(x: focus.x, y: cy), startRadius: 0, endRadius: focus.size * 1.05))
        }
    }

    /// Par-dessus le sujet : vignette, comme vu à travers un masque de plongée.
    func drawOverlay(_ c: inout GraphicsContext, size: CGSize) {
        let w = Double(size.width), h = Double(size.height)
        c.fill(Path(CGRect(origin: .zero, size: size)), with: .radialGradient(
            Gradient(colors: [rgba(0, 20, 30, 0), rgba(0, 20, 30, 0.55)]),
            center: CGPoint(x: w / 2, y: h / 2), startRadius: min(w, h) * 0.35, endRadius: max(w, h) * 0.8))
    }

    // MARK: - Le fixe : eau, récif, sable

    /// Hasard déterministe (même générateur que la webapp).
    private static func seeded(_ seed: Int64) -> () -> Double {
        var s = seed
        return {
            s = (s * 16807) % 2_147_483_647
            return Double(s) / 2_147_483_647
        }
    }

    private func drawBase(_ c: inout GraphicsContext, _ w: Double, _ h: Double, _ horizon: Double) {
        let rand = Self.seeded(11)

        // L'eau : claire près de la surface, turquoise profond vers le fond.
        c.fill(Path(CGRect(x: 0, y: 0, width: w, height: horizon + 2)), with: .linearGradient(
            Gradient(stops: [.init(color: Color(hex: "#7fe3dc"), location: 0), .init(color: Color(hex: "#2fb7bd"), location: 0.18),
                             .init(color: Color(hex: "#11808c"), location: 0.62), .init(color: Color(hex: "#0b5f6c"), location: 1)]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: horizon)))

        // Le récif au loin, noyé dans la brume bleue.
        for (depth, hex) in [(0.16, "#0f6c78"), (0.07, "#0d6170")] {
            let color = Color(hex: hex)
            var reef = Path()
            reef.move(to: CGPoint(x: 0, y: horizon))
            var x = 0.0
            while x < w {
                let bump = 18 + rand() * 46
                let height = horizon * depth * (0.4 + rand() * 0.9)
                reef.addQuadCurve(to: CGPoint(x: x + bump, y: horizon - height * 0.25 * rand()),
                                  control: CGPoint(x: x + bump / 2, y: horizon - height))
                x += bump
            }
            reef.addLine(to: CGPoint(x: w, y: horizon + 4))
            reef.addLine(to: CGPoint(x: 0, y: horizon + 4))
            reef.closeSubpath()
            c.fill(reef, with: .color(color))
            // Quelques coraux en éventail sur la crête.
            for _ in 0..<4 {
                let fx = rand() * w
                let fy = horizon - horizon * depth * 0.6
                for b in -3...3 {
                    var fan = Path()
                    fan.move(to: CGPoint(x: fx, y: fy + 6))
                    fan.addQuadCurve(to: CGPoint(x: fx + Double(b) * 7, y: fy - 16 - rand() * 10), control: CGPoint(x: fx + Double(b) * 4, y: fy - 8))
                    c.stroke(fan, with: .color(color), lineWidth: 2)
                }
            }
        }

        // Le sable : brume turquoise à l'horizon, plus clair et chaud vers le bas.
        c.fill(Path(CGRect(x: 0, y: horizon, width: w, height: h - horizon)), with: .linearGradient(
            Gradient(stops: [.init(color: Color(hex: "#2c8f8e"), location: 0), .init(color: Color(hex: "#6fb3a0"), location: 0.18),
                             .init(color: Color(hex: "#c9c39a"), location: 0.55), .init(color: Color(hex: "#a8a07a"), location: 1)]),
            startPoint: CGPoint(x: 0, y: horizon), endPoint: CGPoint(x: 0, y: h)))

        // Rides du sable, plus serrées près de l'horizon (perspective).
        for i in 2..<26 {
            let k = Double(i) / 26
            let y = horizon + (h - horizon) * k * k + 4
            for (offset, color) in [(0.0, rgba(255, 250, 225, 0.06 + 0.1 * k)), (2.0, rgba(40, 70, 60, 0.05 + 0.08 * k))] {
                var ripple = Path()
                var x = -10.0
                while x <= w + 10 {
                    let p = CGPoint(x: x, y: y + offset + sin(x / (14 + 30 * k) + Double(i) * 1.3) * (1 + 3 * k))
                    if x == -10 { ripple.move(to: p) } else { ripple.addLine(to: p) }
                    x += 12
                }
                c.stroke(ripple, with: .color(color), lineWidth: 1.2)
            }
        }

        // Galets et petits coquillages semés.
        for _ in 0..<26 {
            let k = 0.15 + rand() * 0.85
            let y = horizon + (h - horizon) * k
            let x = rand() * w
            let r = (1.5 + rand() * 4) * (0.5 + k)
            let color = rand() > 0.5 ? rgba(120, 110, 90, 0.35 + k * 0.3) : rgba(240, 225, 200, 0.3 + k * 0.4)
            var pebble = c
            pebble.translateBy(x: x, y: y)
            pebble.rotate(by: .radians(rand()))
            pebble.fill(Path(ellipseIn: CGRect(x: -r * 1.4, y: -r * 0.8, width: r * 2.8, height: r * 1.6)), with: .color(color))
        }
        // Deux étoiles de mer.
        for (sx, sy, sr) in [(w * 0.12, horizon + (h - horizon) * 0.78, 13.0), (w * 0.88, horizon + (h - horizon) * 0.55, 9.0)] {
            var star = Path()
            for p in 0..<10 {
                let a = Double(p) / 10 * Self.tau - .pi / 2
                let r = p % 2 == 1 ? sr * 0.42 : sr
                let q = CGPoint(x: sx + cos(a) * r, y: sy + sin(a) * r * 0.6)
                if p == 0 { star.move(to: q) } else { star.addLine(to: q) }
            }
            star.closeSubpath()
            c.fill(star, with: .color(Color(hex: "#e07a52")))
        }

        // Brume à l'horizon : l'eau et le sable se fondent l'un dans l'autre.
        let hazeTop = horizon - horizon * 0.22
        let hazeBottom = horizon + (h - horizon) * 0.22
        c.fill(Path(CGRect(x: 0, y: hazeTop, width: w, height: hazeBottom - hazeTop)), with: .linearGradient(
            Gradient(stops: [.init(color: rgba(18, 120, 132, 0), location: 0), .init(color: rgba(24, 128, 138, 0.85), location: 0.5),
                             .init(color: rgba(40, 140, 140, 0), location: 1)]),
            startPoint: CGPoint(x: 0, y: hazeTop), endPoint: CGPoint(x: 0, y: hazeBottom)))
    }

    // MARK: - Ce qui bouge

    /// Le dessous de la surface, qui ondule tout en haut.
    private func drawSurface(_ c: inout GraphicsContext, _ w: Double, _ horizon: Double, _ t: Double) {
        let top = horizon * 0.14
        var light = c
        light.blendMode = .plusLighter
        for i in 0..<3 {
            let ii = Double(i)
            var line = Path()
            var x = -10.0
            while x <= w + 10 {
                let p = CGPoint(x: x, y: top * (0.25 + ii * 0.3) + sin(x / 38 + t * (0.9 + ii * 0.3) + ii) * 3 + sin(x / 13 - t * 1.7) * 1.2)
                if x == -10 { line.move(to: p) } else { line.addLine(to: p) }
                x += 10
            }
            light.stroke(line, with: .color(rgba(230, 255, 250, 0.1 - ii * 0.025)), lineWidth: 2)
        }
    }

    /// Rayons de soleil qui descendent en biais et ondulent doucement.
    private func drawRays(_ c: inout GraphicsContext, _ w: Double, _ h: Double, _ horizon: Double, _ t: Double) {
        let bottom = horizon + (h - horizon) * 0.45
        var light = c
        light.blendMode = .plusLighter
        for i in 0..<6 {
            let ii = Double(i)
            let x0 = w * (0.02 + ii * 0.19) + sin(t * 0.25 + ii * 1.9) * w * 0.04
            let top = w * (0.035 + 0.02 * sin(ii * 3.1))
            let spread = w * (0.12 + 0.05 * sin(ii * 2.3))
            let skew = w * 0.16
            let alpha = 0.08 + 0.05 * sin(t * 0.6 + ii * 2.1)
            var ray = Path()
            ray.move(to: CGPoint(x: x0, y: 0))
            ray.addLine(to: CGPoint(x: x0 + top, y: 0))
            ray.addLine(to: CGPoint(x: x0 + top + skew + spread, y: bottom))
            ray.addLine(to: CGPoint(x: x0 + skew - spread * 0.2, y: bottom))
            ray.closeSubpath()
            light.fill(ray, with: .linearGradient(
                Gradient(stops: [.init(color: rgba(255, 255, 225, alpha), location: 0), .init(color: rgba(220, 255, 240, alpha * 0.45), location: 0.6),
                                 .init(color: rgba(220, 255, 240, 0), location: 1)]),
                startPoint: .zero, endPoint: CGPoint(x: 0, y: bottom)))
        }
    }

    /// Reflets de lumière sur le sable : deux nappes de caustiques qui glissent l'une sur l'autre.
    private func drawCaustics(_ c: inout GraphicsContext, _ w: Double, _ h: Double, _ horizon: Double, _ t: Double) {
        guard let sheetImage = CausticTile.sheet else { return }
        let tile = Double(CausticTile.size)
        let sheetW = tile * Double(CausticTile.columns), sheetH = tile * Double(CausticTile.rows)
        let resolved = c.resolve(sheetImage)
        // Plus discrètes à l'horizon, dans la brume : le sable est découpé en bandes d'intensité croissante
        // (0 → 0,6 sur le premier quart, puis → 1).
        let bands: [(Double, Double, Double)] = [(0, 0.1, 0.12), (0.1, 0.2, 0.36), (0.2, 0.35, 0.62), (0.35, 0.6, 0.78), (0.6, 1, 0.95)]
        for (k0, k1, fade) in bands {
            let strip = CGRect(x: 0, y: horizon + (h - horizon) * k0, width: w, height: (h - horizon) * (k1 - k0) + 0.5)
            for (speed, dir, scale, alpha) in [(6.0, 1.0, 1.0, 0.75), (5.0, -1.0, 1.3, 0.55)] {
                // Comme la webapp : la nappe est calculée à mi-résolution puis étirée sur le sable.
                let sx = scale * 0.55, sy = scale * 0.3
                // Le décalage ne compte qu'à un motif près : on le ramène sur un motif, sinon les très grandes
                // coordonnées (le temps est compté depuis 2001) font perdre toute précision au dessin.
                let dx = (t * speed * dir).truncatingRemainder(dividingBy: tile * sx)
                let dy = (t * speed * 0.6).truncatingRemainder(dividingBy: tile * sy)
                var sheet = c
                sheet.blendMode = .plusLighter
                sheet.opacity = 0.32 * alpha * fade
                sheet.clip(to: Path(strip))
                sheet.translateBy(x: 0, y: horizon)
                sheet.scaleBy(x: 2, y: 2)
                sheet.translateBy(x: dx, y: dy)
                sheet.scaleBy(x: sx, y: sy)
                // Zone visible dans le repère du motif, recouverte par des copies de la planche (le plus souvent une seule).
                let x0 = ((-dx / sx) / tile).rounded(.down) * tile, x1 = (w / 2 - dx) / sx
                let y0 = ((-dy / sy) / tile).rounded(.down) * tile, y1 = ((h - horizon) / 2 - dy) / sy
                var y = y0
                while y < y1 {
                    var x = x0
                    while x < x1 {
                        sheet.draw(resolved, in: CGRect(x: x, y: y, width: sheetW, height: sheetH))
                        x += sheetW
                    }
                    y += sheetH
                }
            }
        }
    }

    /// Algues sur les bords, qui ondulent avec le courant.
    private func drawSeaweed(_ c: inout GraphicsContext, _ w: Double, _ h: Double, _ horizon: Double, _ t: Double) {
        let strands: [(Double, Double, Double, String)] = [
            (w * 0.04, h * 0.42, 0, "#2f9a6a"), (w * 0.1, h * 0.3, 1.3, "#3fb37a"), (w * 0.93, h * 0.36, 2.1, "#2f9a6a"),
            (w * 0.985, h * 0.26, 0.7, "#46b985"), (w * 0.2, h * 0.14, 3.1, "#5ac08a"),
        ]
        let baseY = min(h, horizon + (h - horizon) * 0.95)
        let steps = 8
        for (x, height, phase, hex) in strands {
            var left: [CGPoint] = []
            var right: [CGPoint] = []
            var vein = Path()
            for s in 0...steps {
                let k = Double(s) / Double(steps)
                let px = x + sin(t * 1.1 + phase + k * 2.4) * 14 * k * k
                let py = baseY - height * k
                let width = 7 * (1 - k * 0.85)
                left.append(CGPoint(x: px - width, y: py))
                right.append(CGPoint(x: px + width, y: py))
                if s == 0 { vein.move(to: CGPoint(x: px, y: py)) } else { vein.addLine(to: CGPoint(x: px, y: py)) }
            }
            var blade = Path()
            blade.addLines(left + right.reversed())
            blade.closeSubpath()
            c.fill(blade, with: .color(Color(hex: hex).opacity(0.85)))
            c.stroke(vein, with: .color(Color(hex: "#d8ffd0").opacity(0.18)), lineWidth: 1)
        }
    }

    /// Un petit banc de poissons traverse au loin, de temps en temps.
    private func drawFish(_ c: inout GraphicsContext, _ w: Double, _ horizon: Double, _ t: Double) {
        let period = 22.0
        let cycle = t.truncatingRemainder(dividingBy: period)
        guard cycle <= 11 else { return }
        let pass = (t / period).rounded(.down)
        let fromLeft = Int(pass) % 2 == 0
        let k = cycle / 11
        let baseX = fromLeft ? -60 + k * (w + 120) : w + 60 - k * (w + 120)
        let baseY = horizon * (0.42 + 0.18 * sin(pass * 1.7))
        for i in 0..<6 {
            let ii = Double(i)
            let fx = baseX + (fromLeft ? -1 : 1) * Double(i % 3) * 16 + sin(t * 2 + ii) * 3
            let fy = baseY + Double(i / 3) * 12 + Double(i % 3) * 5 + sin(t * 3 + ii * 1.3) * 2
            var fish = c
            fish.translateBy(x: fx, y: fy)
            if !fromLeft { fish.scaleBy(x: -1, y: 1) }
            var body = Path(ellipseIn: CGRect(x: -7, y: -2.6, width: 14, height: 5.2))
            let flap = sin(t * 12 + ii) * 0.8
            body.move(to: CGPoint(x: -6, y: 0))
            body.addLine(to: CGPoint(x: -11, y: -3.2 + flap))
            body.addLine(to: CGPoint(x: -11, y: 3.2 + flap))
            body.closeSubpath()
            fish.fill(body, with: .color(rgba(8, 70, 80, 0.55)))
        }
    }

    /// Bulles qui montent du sable, plancton qui flotte dans la lumière.
    private func drawParticles(_ c: inout GraphicsContext, _ w: Double, _ h: Double, _ horizon: Double, _ t: Double) {
        let rand = Self.seeded(5)
        // Même ordre de tirage que la webapp : 14 bulles, puis 34 grains de plancton.
        let bubbles = (0..<14).map { _ in (x: rand() * w, y: horizon + rand() * (h - horizon), r: 1.5 + rand() * 3.5, speed: 18 + rand() * 30, phase: rand() * Self.tau) }
        let motes = (0..<34).map { _ in (x: rand() * w, y: rand() * h, r: 0.6 + rand() * 1.4, drift: 4 + rand() * 10, phase: rand() * Self.tau) }
        func mod(_ a: Double, _ b: Double) -> Double { (a.truncatingRemainder(dividingBy: b) + b).truncatingRemainder(dividingBy: b) }
        for m in motes {
            let x = mod(m.x + sin(t * 0.3 + m.phase) * m.drift + t * 3, w)
            let y = mod(m.y - t * m.drift * 0.6, h)
            c.fill(Path(ellipseIn: CGRect(x: x - m.r, y: y - m.r, width: m.r * 2, height: m.r * 2)),
                   with: .color(rgba(235, 255, 245, 0.25 + 0.25 * sin(t + m.phase))))
        }
        let travel = h - horizon * 0.2
        for b in bubbles {
            let y = horizon + (h - horizon) * 0.9 - mod(t * b.speed + b.phase * 100, travel)
            let x = b.x + sin(t * 2 + b.phase) * 4
            let fade = min(1, max(0, y / (horizon * 0.5)))
            c.stroke(Path(ellipseIn: CGRect(x: x - b.r, y: y - b.r, width: b.r * 2, height: b.r * 2)),
                     with: .color(rgba(240, 255, 255, 0.55 * fade)), lineWidth: 1)
            let hr = b.r * 0.3
            c.fill(Path(ellipseIn: CGRect(x: x - b.r * 0.35 - hr, y: y - b.r * 0.35 - hr, width: hr * 2, height: hr * 2)),
                   with: .color(rgba(255, 255, 255, 0.6 * fade)))
        }
    }
}

/// Motif de caustiques qui se répète sans couture : un réseau de lignes lumineuses ondulées,
/// comme la lumière qui traverse les vagues et se pose sur le sable. Calculé une seule fois, puis
/// recopié en planche (colonnes × rangées) pour couvrir l'écran en quelques dessins.
private enum CausticTile {
    static let size = 192
    static let columns = 4
    static let rows = 6

    static let sheet: Image? = {
        let k = Double.pi * 2 / Double(size)
        var tile = [UInt8](repeating: 0, count: size * size * 4)
        for y in 0..<size {
            for x in 0..<size {
                let fx = Double(x), fy = Double(y)
                let a = sin(fx * k * 3 + 1.7 * sin(fy * k * 2)) + sin(fy * k * 3 + 1.9 * sin(fx * k * 2 + 1))
                let b = sin((fx + fy) * k * 2 + 1.3 * sin((fx - fy) * k))
                let line = pow(max(0, 1 - abs(a) * 1.6), 3) + 0.6 * pow(max(0, 1 - abs(b) * 2.2), 4)
                let alpha = min(1, line * 200 / 255)
                let i = (y * size + x) * 4
                // Couleur prémultipliée (220, 255, 245).
                tile[i] = UInt8(220 * alpha)
                tile[i + 1] = UInt8(255 * alpha)
                tile[i + 2] = UInt8(245 * alpha)
                tile[i + 3] = UInt8(255 * alpha)
            }
        }
        let width = size * columns, height = size * rows
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        for y in 0..<height {
            let source = (y % size) * size * 4
            for column in 0..<columns {
                let target = (y * width + column * size) * 4
                pixels.replaceSubrange(target..<(target + size * 4), with: tile[source..<(source + size * 4)])
            }
        }
        guard let provider = CGDataProvider(data: Data(pixels) as CFData),
              let cg = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
                               space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                               provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
        else { return nil }
        return Image(decorative: cg, scale: 1)
    }()
}
