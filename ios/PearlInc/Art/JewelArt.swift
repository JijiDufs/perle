import Foundation
import PearlCore

/// Dessin procédural des bijoux, porté de src/art/jewel.ts (repris du prototype Duo).
/// L'échelle `s` vaut 1 pour un bijou d'environ 440 pt de large.
enum JewelArt {
    typealias Point = (Double, Double)

    /// Ce qu'il faut pour dessiner un bijou : sa structure, et ses couleurs (celles de la variante rare, s'il y en a une).
    struct Look {
        let jewel: Jewel
        let metal: String
        let gem: String?

        init(_ jewel: Jewel, variant: String?, catalog: Catalog) {
            let look = catalog.jewelLook(jewel, variant: variant)
            self.jewel = jewel
            metal = look.metal
            gem = look.gem
        }
    }

    static func goldGradient(_ c: Canvas2D, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double) -> Gradient2D {
        let g = c.createLinearGradient(x0, y0, x1, y1)
        for (color, at) in [("#8a6420", 0.0), ("#f5d77e", 0.3), ("#b8862b", 0.5), ("#ffe9a8", 0.72), ("#8a6420", 1.0)] { g.addColorStop(at, color) }
        return g
    }

    private static func metalGradient(_ c: Canvas2D, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: String) -> Gradient2D {
        let g = c.createLinearGradient(x0, y0, x1, y1)
        g.addColorStop(0, shadeColor(col, 0.4))
        g.addColorStop(0.3, tintColor(col, 0.6))
        g.addColorStop(0.55, col)
        g.addColorStop(0.8, shadeColor(col, 0.3))
        g.addColorStop(1, tintColor(col, 0.35))
        return g
    }

    private static func polygon(_ c: Canvas2D, _ points: [Point]) {
        c.beginPath()
        for (i, p) in points.enumerated() { if i == 0 { c.moveTo(p.0, p.1) } else { c.lineTo(p.0, p.1) } }
        c.closePath()
    }

    /// Contour d'une taille de pierre, dans un repère unité (rayon 1).
    private static func cutShape(_ cut: String) -> [Point] {
        switch cut {
        case "ovale":
            return (0..<14).map { i in let a = Double(i) / 14 * 2 * .pi - .pi / 2; return (cos(a) * 0.76, sin(a)) }
        case "poire":
            let half: [Point] = [(0, -1), (0.36, -0.56), (0.6, -0.08), (0.66, 0.32), (0.52, 0.7), (0.24, 0.92)]
            return half + [(0, 0.97)] + half.dropFirst().reversed().map { (-$0.0, $0.1) }
        case "coussin":
            return (0..<16).map { i in
                let a = Double(i) / 16 * 2 * .pi + .pi / 16
                let k = 0.92 / pow(pow(abs(cos(a)), 4) + pow(abs(sin(a)), 4), 0.25)
                return (cos(a) * k, sin(a) * k)
            }
        case "emeraude":
            return [(-0.55, -1), (0.55, -1), (0.84, -0.7), (0.84, 0.7), (0.55, 1), (-0.55, 1), (-0.84, 0.7), (-0.84, -0.7)]
        case "princesse":
            return [(-0.78, -0.84), (0.78, -0.84), (0.84, -0.78), (0.84, 0.78), (0.78, 0.84), (-0.78, 0.84), (-0.84, 0.78), (-0.84, -0.78)]
        case "coeur":
            return (0..<18).map { i in
                let t = Double(i) / 18 * 2 * .pi
                return (pow(sin(t), 3) * 0.98, -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t)) / 16 + 0.08)
            }
        case "marquise":
            let right: [Point] = (0..<7).map { i in let t = Double(i) / 6; return (sin(.pi * t) * 0.5, -1 + 2 * t) }
            return right + right.dropFirst().dropLast().reversed().map { (-$0.0, $0.1) }
        default:
            return (0..<16).map { i in let a = Double(i) / 16 * 2 * .pi; return (cos(a), sin(a)) }
        }
    }

    private static func gemOutline(_ x: Double, _ y: Double, _ r: Double, _ cut: String?) -> [Point] {
        if let cut { return cutShape(cut).map { (x + $0.0 * r, y + $0.1 * r) } }
        return (0..<8).map { i in let a = Double(i) / 8 * 2 * .pi + .pi / 8; return (x + cos(a) * r, y + sin(a) * r) }
    }

    /// Pierre facettée dans sa taille, ou « bonbon » pour le toc.
    static func drawGem(_ c: Canvas2D, _ x: Double, _ y: Double, _ r: Double, _ col: String, candy: Bool = false, cut: String? = nil) {
        c.save()
        defer { c.restore() }
        if candy {
            let g = c.createRadialGradient(x - r * 0.3, y - r * 0.35, r * 0.1, x, y, r)
            g.addColorStop(0, tintColor(col, 0.65))
            g.addColorStop(0.5, col)
            g.addColorStop(1, shadeColor(col, 0.35))
            c.fillStyle = g
            c.beginPath()
            c.arc(x, y, r, 0, .pi * 2)
            c.fill()
            c.globalAlpha = 0.75
            c.fillStyle = "#fff"
            c.beginPath()
            c.ellipse(x - r * 0.35, y - r * 0.42, r * 0.3, r * 0.15, -0.6, 0, .pi * 2)
            c.fill()
            return
        }
        let outer = gemOutline(x, y, r, cut)
        let table = gemOutline(x, y, r * 0.53, cut)
        let n = outer.count
        let g = c.createRadialGradient(x - r * 0.2, y - r * 0.2, r * 0.1, x, y, r * 1.05)
        g.addColorStop(0, tintColor(col, 0.4))
        g.addColorStop(0.6, col)
        g.addColorStop(1, shadeColor(col, 0.45))
        polygon(c, outer)
        c.fillStyle = g
        c.fill()
        for i in 0..<n {
            polygon(c, [outer[i], outer[(i + 1) % n], table[(i + 1) % n], table[i]])
            c.fillStyle = i % 3 == 0 ? "rgba(255,255,255,.28)" : i % 2 == 1 ? "rgba(255,255,255,.1)" : "rgba(0,0,0,.18)"
            c.fill()
        }
        // Lignes de taille au cœur : un reflet net même sur les petites cartes.
        c.strokeStyle = "rgba(255,255,255,.24)"
        c.lineWidth = r * 0.03
        for i in stride(from: 0, to: n, by: 2) {
            c.beginPath()
            c.moveTo(outer[i].0, outer[i].1)
            c.lineTo(table[i].0, table[i].1)
            c.stroke()
        }
        polygon(c, table)
        c.globalAlpha = 0.7
        c.fillStyle = tintColor(col, 0.45)
        c.fill()
        c.globalAlpha = 1
        let rgb = CSSColor(col)
        if rgb.r + rgb.g + rgb.b > 620 {
            // Feux irisés des pierres claires (diamant, strass) ; un dégradé linéaire remplace le dégradé conique du web.
            let k = c.createLinearGradient(x - r, y - r, x + r, y + r)
            for (i, color) in ["#ff9ad5", "#9af0ff", "#fff59a", "#b9a6ff", "#ff9ad5"].enumerated() { k.addColorStop(Double(i) / 4, color) }
            polygon(c, outer)
            c.globalAlpha = 0.32
            c.fillStyle = k
            c.fill()
            c.globalAlpha = 1
        }
        c.beginPath()
        c.moveTo(x - r * 0.45, y - r * 0.5)
        c.lineTo(x - r * 0.1, y - r * 0.62)
        c.lineTo(x - r * 0.3, y - r * 0.25)
        c.closePath()
        c.fillStyle = "rgba(255,255,255,.85)"
        c.fill()
    }

    private static func pearlDot(_ c: Canvas2D, _ x: Double, _ y: Double, _ r: Double, _ color: String = "#f2ece4") {
        let g = c.createRadialGradient(x - r * 0.35, y - r * 0.4, r * 0.05, x, y, r)
        g.addColorStop(0, "#ffffff")
        g.addColorStop(0.45, color)
        g.addColorStop(1, shadeColor(color, 0.35))
        c.fillStyle = g
        c.beginPath()
        c.arc(x, y, r, 0, .pi * 2)
        c.fill()
    }

    private static func prongs(_ c: Canvas2D, _ x: Double, _ y: Double, _ r: Double, _ col: String, _ s: Double, _ cut: String?) {
        let finish = metalGradient(c, x - r, y - r, x + r, y + r, col)
        if let cut, cut != "rond" {
            // Le serti épouse la taille : liseré tout autour, une griffe à chaque extrémité.
            let outline = gemOutline(x, y, r * 1.1, cut)
            polygon(c, outline)
            c.strokeStyle = finish
            c.lineWidth = max(r * 0.05, 3 * s)
            c.stroke()
            let top = outline.min { $0.1 < $1.1 }!, bottom = outline.max { $0.1 < $1.1 }!
            let left = outline.min { $0.0 < $1.0 }!, right = outline.max { $0.0 < $1.0 }!
            c.fillStyle = finish
            for p in [top, bottom, left, right] {
                c.beginPath()
                c.arc(p.0, p.1, max(r * 0.1, 4.5 * s), 0, .pi * 2)
                c.fill()
            }
            return
        }
        c.strokeStyle = finish
        c.lineWidth = max(r * 0.05, 3 * s)
        c.beginPath()
        c.arc(x, y, r * 1.08, 0, .pi * 2)
        c.stroke()
        c.fillStyle = finish
        for k in [0.25, 0.75, 1.25, 1.75] {
            let a = k * .pi
            c.beginPath()
            c.arc(x + cos(a) * r * 1.08, y + sin(a) * r * 1.08, max(r * 0.1, 4.5 * s), 0, .pi * 2)
            c.fill()
        }
    }

    private static func curve(_ p0: Point, _ ctrl: Point, _ p2: Point) -> (Double) -> Point {
        { t in
            ((1 - t) * (1 - t) * p0.0 + 2 * (1 - t) * t * ctrl.0 + t * t * p2.0,
             (1 - t) * (1 - t) * p0.1 + 2 * (1 - t) * t * ctrl.1 + t * t * p2.1)
        }
    }

    private static func roundedRect(_ c: Canvas2D, _ x: Double, _ y: Double, _ w: Double, _ h: Double, _ r: Double) {
        c.beginPath()
        c.moveTo(x + r, y)
        c.arcTo(x + w, y, x + w, y + h, r)
        c.arcTo(x + w, y + h, x, y + h, r)
        c.arcTo(x, y + h, x, y, r)
        c.arcTo(x, y, x + w, y, r)
        c.closePath()
    }

    /// Coquille Saint-Jacques : éventail côtelé, deux oreilles à la base (pendentif, gravure de chevalière).
    private static func scallop(_ c: Canvas2D, _ x: Double, _ y: Double, _ size: Double, fill: (any Paint)?, line: String, lw: Double) {
        let base: Point = (x, y + size * 0.55)
        let ribs = 9.0
        func edge(_ k: Double) -> Point {
            let a = Double.pi * (1.12 + (k / ribs) * 0.76)
            return (base.0 + cos(a) * size * 1.15, base.1 + sin(a) * size * 1.15)
        }
        c.beginPath()
        c.moveTo(base.0 - size * 0.32, base.1 + size * 0.1)
        c.lineTo(base.0 - size * 0.3, base.1 - size * 0.12)
        let e0 = edge(0)
        c.lineTo(e0.0, e0.1)
        for k in 1...Int(ribs) {
            let q = edge(Double(k) - 0.5), e = edge(Double(k))
            c.quadraticCurveTo(base.0 + (q.0 - base.0) * 1.08, base.1 + (q.1 - base.1) * 1.08, e.0, e.1)
        }
        c.lineTo(base.0 + size * 0.3, base.1 - size * 0.12)
        c.lineTo(base.0 + size * 0.32, base.1 + size * 0.1)
        c.closePath()
        if let fill {
            c.fillStyle = fill
            c.fill()
        }
        c.strokeStyle = line
        c.lineWidth = lw
        c.stroke()
        for k in 0...Int(ribs) {
            let p = edge(Double(k))
            c.beginPath()
            c.moveTo(base.0, base.1 - size * 0.05)
            c.lineTo(base.0 + (p.0 - base.0) * 0.9, base.1 + (p.1 - base.1) * 0.9)
            c.stroke()
        }
    }

    /// Où placer le bijou dans un carré, en fraction de la hauteur, pour qu'il y paraisse centré.
    static func yOffset(_ jewel: Jewel) -> Double {
        switch jewel.type {
        case "collier": 0.62
        case "pendentif": 0.77
        case "diademe": 0.52
        case "boucles": jewel.style == "puces" ? 0.68 : 0.56
        case "broche": jewel.style == "fleur" ? 0.44 : jewel.style == "libellule" ? 0.47 : 0.5
        default: 0.5
        }
    }

    static func draw(_ c: Canvas2D, _ x: Double, _ y: Double, _ s: Double, _ look: Look) {
        c.save()
        defer { c.restore() }
        c.lineCap = "round"
        let jewel = look.jewel
        let style = jewel.style
        let toc = jewel.rarityId == "toc"
        let metalColor = look.metal
        let gemColor = look.gem
        func metal(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double) -> Gradient2D { metalGradient(c, x0, y0, x1, y1, metalColor) }
        func gemRadius(_ base: Double, _ maxValue: Double) -> Double { (base + min(maxValue, (jewel.carats == 0 ? 1 : jewel.carats) * 6)) * s }
        /// La pierre principale, dans sa taille, sertie de griffes.
        func mainGem(_ gx: Double, _ gy: Double, _ r: Double) {
            guard let gemColor else { return }
            if !toc { prongs(c, gx, gy, r, metalColor, s, jewel.cut) }
            drawGem(c, gx, gy, r, gemColor, candy: jewel.candy, cut: jewel.cut)
        }
        /// Petites pierres d'accompagnement (pavé), toujours rondes.
        func accent(_ gx: Double, _ gy: Double, _ r: Double, _ color: String? = nil) {
            drawGem(c, gx, gy, r, color ?? gemColor ?? "#f2fbff", cut: "rond")
        }
        func accent(_ p: Point, _ r: Double) { accent(p.0, p.1, r) }
        /// Serti clos : un liseré de métal tout autour de la pierre (pendentifs).
        func bezel(_ gx: Double, _ gy: Double, _ r: Double) {
            guard let gemColor else { return }
            polygon(c, gemOutline(gx, gy, r * 1.14, jewel.cut))
            c.fillStyle = metal(gx - r, gy - r, gx + r, gy + r)
            c.fill()
            drawGem(c, gx, gy, r, gemColor, cut: jewel.cut)
        }
        /// Petit dôme de métal, à la place d'une pierre.
        func dome(_ gx: Double, _ gy: Double, _ r: Double) {
            let g = c.createRadialGradient(gx - r * 0.35, gy - r * 0.4, r * 0.05, gx, gy, r)
            g.addColorStop(0, tintColor(metalColor, 0.75))
            g.addColorStop(0.5, metalColor)
            g.addColorStop(1, shadeColor(metalColor, 0.4))
            c.fillStyle = g
            c.beginPath()
            c.arc(gx, gy, r, 0, 2 * .pi)
            c.fill()
        }
        let tau = 2 * Double.pi

        switch jewel.type {
        case "bague":
            let R = 64 * s
            let cy = y + 12 * s
            let lw = (toc ? 18 : style == "jonc" ? 24 : style == "chevaliere" ? 16 : gemColor != nil ? 13 : 20) * s
            c.fillStyle = "rgba(0,0,0,.55)"
            c.beginPath()
            c.ellipse(x, cy + R * 0.92, R * 1.4, 10 * s, 0, 0, tau)
            c.fill()
            c.lineWidth = lw
            c.strokeStyle = metal(x - R, cy - R, x + R, cy + R)
            c.beginPath()
            c.arc(x, cy, R, .pi * 0.8, .pi * 2.2)
            c.stroke()
            c.lineWidth = lw * 0.25
            c.strokeStyle = "rgba(255,255,255,.55)"
            c.beginPath()
            c.arc(x, cy, R + lw * 0.12, .pi * 1.15, .pi * 1.45)
            c.stroke()
            let top = cy - R
            if style == "jonc" {
                c.lineWidth = 1.6 * s
                c.strokeStyle = "rgba(0,0,0,.28)"
                c.beginPath()
                c.arc(x, cy, R, .pi * 0.85, .pi * 2.15)
                c.stroke()
            } else if style == "chevaliere" {
                let pw = 46 * s, ph = 34 * s, py = top - 4 * s
                c.beginPath()
                c.ellipse(x, py + 6 * s, pw, ph, 0, 0, tau)
                c.fillStyle = shadeColor(metalColor, 0.45)
                c.fill()
                c.beginPath()
                c.ellipse(x, py, pw, ph, 0, 0, tau)
                c.fillStyle = metal(x - pw, py - ph, x + pw, py + ph)
                c.fill()
                c.lineWidth = 2 * s
                c.strokeStyle = "rgba(255,255,255,.5)"
                c.beginPath()
                c.ellipse(x, py, pw * 0.84, ph * 0.8, 0, .pi * 1.05, .pi * 1.7)
                c.stroke()
                scallop(c, x, py - 4 * s, 20 * s, fill: nil, line: "rgba(40,25,5,.4)", lw: 1.6 * s)
            } else if style == "trilogie" {
                let r0 = gemRadius(14, 18), r1 = r0 * 0.66, gy = top - r0 * 0.7
                for side in [-1.0, 1.0] { mainGem(x + side * (r0 + r1 * 0.95), gy + r1 * 0.6, r1) }
                mainGem(x, gy, r0)
            } else if style == "cocktail" {
                let r0 = gemRadius(18, 22), gy = top - r0 * 0.8
                for k in 0..<16 {
                    let a = Double(k) / 16 * tau
                    accent(x + cos(a) * r0 * 1.42, gy + sin(a) * r0 * 1.42, 6.5 * s, "#f2fbff")
                }
                mainGem(x, gy, r0)
            } else if gemColor != nil {
                let r = toc ? 42 * s : jewel.rarityId == "fantaisie" ? 22 * s : gemRadius(18, 30)
                mainGem(x, top - r * 0.7, r)
            }

        case "collier":
            let sautoir = style == "sautoir"
            let q = curve((x - 210 * s, y - 190 * s), (x, y + 120 * s), (x + 210 * s, y - 190 * s))
            if jewel.pearls {
                if sautoir {
                    let q2 = curve((x - 200 * s, y - 190 * s), (x, y + 210 * s), (x + 200 * s, y - 190 * s))
                    for k in 0...42 { let p = q2(Double(k) / 42); pearlDot(c, p.0, p.1, 9 * s) }
                }
                for k in 0...34 { let p = q(Double(k) / 34); pearlDot(c, p.0, p.1, (sautoir ? 9.5 : 11) * s) }
            } else {
                c.strokeStyle = metal(x - 210 * s, y - 190 * s, x + 210 * s, y)
                c.lineWidth = (style == "chaine" ? 4 : 3) * s
                for k in 0...70 {
                    let p = q(Double(k) / 70)
                    c.beginPath()
                    c.ellipse(p.0, p.1, (style == "chaine" ? 6 : 5) * s, (style == "chaine" ? 3.6 : 3) * s, k % 2 == 1 ? 0.8 : -0.8, 0, tau)
                    c.stroke()
                }
                if style == "riviere" && gemColor != nil {
                    for k in stride(from: 5, through: 65, by: 3) {
                        let t = Double(k) / 70
                        accent(q(t), (5 + 5 * (1 - abs(t - 0.5) * 2)) * s)
                    }
                }
            }
            let (bx, by) = q(0.5)
            if jewel.pearls {
                if !sautoir { pearlDot(c, bx, by + 24 * s, 18 * s) }
            } else if gemColor != nil {
                c.strokeStyle = metal(bx - 10, by, bx + 10, by + 20)
                c.lineWidth = 3 * s
                c.beginPath()
                c.arc(bx, by + 8 * s, 7 * s, 0, tau)
                c.stroke()
                let r = style == "riviere" ? gemRadius(12, 16) : gemRadius(16, 26)
                mainGem(bx, by + 16 * s + r, r)
            } else {
                c.fillStyle = metal(bx - 24 * s, by, bx + 24 * s, by + 60 * s)
                c.beginPath()
                c.arc(bx, by + 34 * s, 24 * s, 0, tau)
                c.fill()
                c.strokeStyle = "rgba(255,255,255,.4)"
                c.lineWidth = 2 * s
                c.beginPath()
                c.arc(bx, by + 34 * s, 17 * s, 3.6, 5.2)
                c.stroke()
            }

        case "bracelet":
            let rx = 150 * s, ry = 58 * s
            if style == "jonc" {
                c.lineWidth = 20 * s
                c.strokeStyle = metal(x - rx, y - ry, x + rx, y + ry)
                c.beginPath()
                c.ellipse(x, y, rx, ry, 0, 0, tau)
                c.stroke()
                c.lineWidth = 4 * s
                c.strokeStyle = "rgba(255,255,255,.5)"
                c.beginPath()
                c.ellipse(x, y - 2 * s, rx, ry, 0, 3.5, 4.9)
                c.stroke()
                if gemColor != nil {
                    for k in [-2.0, -1, 1, 2] {
                        let a = Double.pi / 2 + k * 0.2
                        accent(x + cos(a) * rx, y + sin(a) * ry, 7 * s)
                    }
                    mainGem(x, y + ry, gemRadius(9, 8))
                }
            } else if style == "gourmette" {
                c.strokeStyle = metal(x - rx, y - ry, x + rx, y + ry)
                c.lineWidth = 7 * s
                for k in 0..<30 {
                    let a = Double(k) / 30 * tau
                    c.beginPath()
                    c.ellipse(x + cos(a) * rx, y + sin(a) * ry, 11 * s, 6.5 * s, a + (k % 2 == 1 ? 0.55 : -0.55), 0, tau)
                    c.stroke()
                }
                let pw = 74 * s, ph = 26 * s
                roundedRect(c, x - pw / 2, y + ry - ph / 2, pw, ph, 8 * s)
                c.fillStyle = metal(x - pw / 2, y + ry - ph / 2, x + pw / 2, y + ry + ph / 2)
                c.fill()
                c.lineWidth = 2 * s
                c.strokeStyle = "rgba(255,255,255,.55)"
                c.beginPath()
                c.moveTo(x - pw / 2 + 8 * s, y + ry - ph / 2 + 4 * s)
                c.lineTo(x + pw / 2 - 8 * s, y + ry - ph / 2 + 4 * s)
                c.stroke()
            } else {
                // Tennis (pierres) ou rang de perles.
                let n = jewel.pearls ? 30 : 44
                c.strokeStyle = metal(x - rx, y - ry, x + rx, y + ry)
                c.lineWidth = 3 * s
                for k in 0..<n {
                    let a = Double(k) / Double(n) * tau
                    let px = x + cos(a) * rx, py = y + sin(a) * ry
                    if jewel.pearls {
                        pearlDot(c, px, py, 13 * s)
                    } else {
                        c.beginPath()
                        c.ellipse(px, py, 6 * s, 4 * s, a, 0, tau)
                        c.stroke()
                        let dense = style == "tennis" || jewel.rarityId == "diamant"
                        if gemColor != nil && k % (dense ? 2 : 4) == 0 { accent(px, py, (dense ? 8 : 10) * s) }
                    }
                }
            }

        case "boucles":
            for side in [-1.0, 1.0] {
                let px = x + side * 95 * s
                let top = y - 110 * s
                if style == "puces" {
                    let cy = top + 40 * s
                    if jewel.pearls { pearlDot(c, px, cy, 26 * s) } else { mainGem(px, cy, gemRadius(16, 14)) }
                    continue
                }
                if style == "creoles" {
                    let hy = top + 72 * s, hr = 50 * s
                    c.lineWidth = 8 * s
                    c.strokeStyle = metal(px - hr, hy - hr, px + hr, hy + hr)
                    c.beginPath()
                    c.arc(px, hy, hr, 0, tau)
                    c.stroke()
                    c.lineWidth = 2 * s
                    c.strokeStyle = "rgba(255,255,255,.5)"
                    c.beginPath()
                    c.arc(px, hy, hr + 2 * s, .pi * 1.1, .pi * 1.45)
                    c.stroke()
                    if gemColor != nil {
                        for k in 0..<7 {
                            let a = Double.pi * (0.15 + Double(k) / 6 * 0.7)
                            accent(px + cos(a) * hr, hy + sin(a) * hr, 6 * s)
                        }
                    }
                    continue
                }
                // Pendants : crochet et pendeloque.
                c.strokeStyle = metal(px - 20 * s, top - 20 * s, px + 20 * s, top + 30 * s)
                c.lineWidth = 4 * s
                c.beginPath()
                c.arc(px, top, 16 * s, .pi, tau)
                c.lineTo(px + 16 * s, top + 6 * s)
                c.stroke()
                c.beginPath()
                c.moveTo(px, top)
                c.lineTo(px, top + 34 * s)
                c.stroke()
                if jewel.pearls {
                    pearlDot(c, px, top + 62 * s, 24 * s)
                } else if gemColor != nil {
                    let r = gemRadius(16, 14)
                    mainGem(px, top + 40 * s + r, r)
                } else {
                    c.lineWidth = 7 * s
                    c.strokeStyle = metal(px - 46 * s, top + 20 * s, px + 46 * s, top + 110 * s)
                    c.beginPath()
                    c.arc(px, top + 80 * s, 46 * s, 0, tau)
                    c.stroke()
                }
            }

        case "pendentif":
            let q = curve((x - 170 * s, y - 215 * s), (x, y + 10 * s), (x + 170 * s, y - 215 * s))
            c.strokeStyle = metal(x - 170 * s, y - 215 * s, x + 170 * s, y)
            c.lineWidth = 2 * s
            for k in 0...56 {
                let p = q(Double(k) / 56)
                c.beginPath()
                c.ellipse(p.0, p.1, 3.6 * s, 2.2 * s, k % 2 == 1 ? 0.8 : -0.8, 0, tau)
                c.stroke()
            }
            let (bx, by) = q(0.5)
            c.lineWidth = 3.5 * s
            c.beginPath()
            c.ellipse(bx, by + 8 * s, 5 * s, 8 * s, 0, 0, tau)
            c.stroke()
            let top = by + 16 * s
            if style == "medaille" {
                let r = 40 * s, cy = top + r
                c.beginPath()
                c.arc(bx + 2 * s, cy + 3 * s, r, 0, tau)
                c.fillStyle = "rgba(0,0,0,.35)"
                c.fill()
                c.beginPath()
                c.arc(bx, cy, r, 0, tau)
                c.fillStyle = metal(bx - r, cy - r, bx + r, cy + r)
                c.fill()
                c.lineWidth = 2.5 * s
                c.strokeStyle = "rgba(255,255,255,.5)"
                c.beginPath()
                c.arc(bx, cy, r * 0.84, 0, tau)
                c.stroke()
                let star: [Point] = (0..<16).map { i in
                    let a = Double(i) / 16 * tau - .pi / 2
                    let k = i % 2 == 1 ? 0.18 : i % 4 == 0 ? 0.62 : 0.4
                    return (bx + cos(a) * r * k, cy + sin(a) * r * k)
                }
                polygon(c, star)
                c.fillStyle = "rgba(255,255,255,.32)"
                c.fill()
                c.lineWidth = 1.2 * s
                c.strokeStyle = "rgba(0,0,0,.25)"
                c.stroke()
            } else if style == "coquillage" {
                scallop(c, bx, top + 40 * s, 44 * s, fill: metal(bx - 50 * s, top, bx + 50 * s, top + 90 * s), line: shadeColor(metalColor, 0.45), lw: 1.6 * s)
            } else if jewel.pearls {
                c.save()
                c.translate(bx, top + 32 * s)
                c.scale(1, 1.18)
                pearlDot(c, 0, 0, 24 * s)
                c.restore()
                c.beginPath()
                c.arc(bx, top + 6 * s, 8 * s, .pi, tau)
                c.fillStyle = metal(bx - 8 * s, top, bx + 8 * s, top + 8 * s)
                c.fill()
            } else if gemColor != nil {
                let r = gemRadius(20, 20)
                bezel(bx, top + r * 1.1, r)
            }

        case "broche":
            if style == "fleur" {
                c.strokeStyle = metal(x, y, x + 60 * s, y + 140 * s)
                c.lineWidth = 6 * s
                c.beginPath()
                c.moveTo(x + 8 * s, y + 30 * s)
                c.quadraticCurveTo(x + 40 * s, y + 90 * s, x + 18 * s, y + 140 * s)
                c.stroke()
                c.beginPath()
                c.moveTo(x + 30 * s, y + 82 * s)
                c.quadraticCurveTo(x + 92 * s, y + 58 * s, x + 104 * s, y + 100 * s)
                c.quadraticCurveTo(x + 62 * s, y + 114 * s, x + 30 * s, y + 82 * s)
                c.fillStyle = metal(x + 30 * s, y + 60 * s, x + 104 * s, y + 114 * s)
                c.fill()
                for k in 0..<5 {
                    let a = Double(k) / 5 * tau - .pi / 2
                    c.save()
                    c.translate(x + cos(a) * 42 * s, y + sin(a) * 42 * s)
                    c.rotate(a + .pi / 2)
                    c.beginPath()
                    c.ellipse(0, 0, 28 * s, 44 * s, 0, 0, tau)
                    c.fillStyle = metal(-28 * s, -44 * s, 28 * s, 44 * s)
                    c.fill()
                    c.lineWidth = 1.5 * s
                    c.strokeStyle = shadeColor(metalColor, 0.4)
                    c.stroke()
                    c.lineWidth = 2 * s
                    c.strokeStyle = "rgba(255,255,255,.5)"
                    c.beginPath()
                    c.ellipse(0, 0, 20 * s, 34 * s, 0, .pi * 1.1, .pi * 1.6)
                    c.stroke()
                    if gemColor != nil { for j in 0..<3 { accent(0, -22 * s + Double(j) * 15 * s, 4.5 * s) } }
                    c.restore()
                }
                if jewel.pearls { pearlDot(c, x, y, 22 * s) } else if gemColor != nil { mainGem(x, y, gemRadius(13, 12)) } else { dome(x, y, 18 * s) }
            } else if style == "libellule" {
                for side in [-1.0, 1.0] {
                    for (dy, len, rot) in [(-38.0, 128.0, -0.22), (-6.0, 108.0, 0.22)] {
                        let wx = x + side * (len / 2 + 6) * s, wy = y + dy * s
                        c.beginPath()
                        c.ellipse(wx, wy, (len / 2) * s, 21 * s, side * rot, 0, tau)
                        c.fillStyle = gemColor.map { color -> String in
                            let rgb = CSSColor(color)
                            return "rgba(\(rgb.r),\(rgb.g),\(rgb.b),0.27)"
                        } ?? "rgba(220,240,255,.28)"
                        c.fill()
                        c.lineWidth = 4 * s
                        c.strokeStyle = metal(wx - (len / 2) * s, wy - 21 * s, wx + (len / 2) * s, wy + 21 * s)
                        c.stroke()
                        c.lineWidth = 1.2 * s
                        c.strokeStyle = "rgba(255,255,255,.45)"
                        c.beginPath()
                        c.moveTo(x + side * 8 * s, wy)
                        c.lineTo(x + side * (len + 2) * s, wy + side * tan(rot) * len * s * 0.4)
                        c.stroke()
                    }
                }
                for k in 0..<8 {
                    let r = (9 - Double(k) * 0.65) * s
                    let by = y + (14 + Double(k) * 15) * s
                    if gemColor != nil { accent(x, by, r) } else { dome(x, by, r) }
                }
                if gemColor != nil { mainGem(x, y - 24 * s, gemRadius(11, 8)) } else { dome(x, y - 24 * s, 15 * s) }
                dome(x, y - 54 * s, 11 * s)
            } else {
                // Étoile de mer : cinq bras arrondis, picots ou petites pierres.
                let points: [Point] = (0..<10).map { i in
                    let a = Double(i) / 10 * tau - .pi / 2
                    let r = (i % 2 == 1 ? 44.0 : 104.0) * s
                    return (x + cos(a) * r, y + sin(a) * r)
                }
                polygon(c, points)
                c.lineJoin = "round"
                c.lineWidth = 16 * s
                c.strokeStyle = metal(x - 104 * s, y - 104 * s, x + 104 * s, y + 104 * s)
                c.stroke()
                c.fillStyle = metal(x - 104 * s, y - 104 * s, x + 104 * s, y + 104 * s)
                c.fill()
                for arm in 0..<5 {
                    let a = Double(arm) / 5 * tau - .pi / 2
                    for k in 1...4 {
                        let d = (18 + Double(k) * 18) * s
                        let px = x + cos(a) * d, py = y + sin(a) * d
                        if gemColor != nil { accent(px, py, (6 - Double(k) * 0.6) * s) } else { dome(px, py, (6 - Double(k) * 0.7) * s) }
                    }
                }
                if gemColor != nil { mainGem(x, y, gemRadius(12, 10)) } else { dome(x, y, 16 * s) }
            }

        default:
            // Diadème.
            let p0: Point = (x - 220 * s, y + 70 * s), p2: Point = (x + 220 * s, y + 70 * s)
            let q = curve(p0, (x, y - 20 * s), p2)
            c.lineWidth = 12 * s
            c.strokeStyle = metal(x - 220 * s, y, x + 220 * s, y + 70 * s)
            c.beginPath()
            c.moveTo(p0.0, p0.1)
            c.quadraticCurveTo(x, y - 20 * s, p2.0, p2.1)
            c.stroke()
            for i in -3...3 {
                let (bx, by) = q(Double(i + 3) / 6 * 0.8 + 0.1)
                let height = (95 - Double(abs(i)) * 20) * s
                c.lineWidth = 5 * s
                c.beginPath()
                c.moveTo(bx - 18 * s, by)
                c.lineTo(bx, by - height)
                c.lineTo(bx + 18 * s, by)
                c.stroke()
                drawGem(c, bx, by - height, (i == 0 ? 32 : 12) * s, i == 0 ? gemColor ?? "#f2fbff" : "#f2fbff", cut: i == 0 ? jewel.cut : "rond")
            }
            for k in 1..<20 { let p = q(Double(k) / 20); drawGem(c, p.0, p.1, 5 * s, "#f2fbff", cut: "rond") }
        }
    }

    /// Étoile de scintillement à quatre branches.
    static func drawStar(_ c: Canvas2D, _ x: Double, _ y: Double, _ r: Double, _ alpha: Double, _ col: String) {
        guard alpha > 0.02 else { return }
        c.save()
        defer { c.restore() }
        c.globalCompositeOperation = "lighter"
        c.globalAlpha = min(1, alpha)
        c.fillStyle = col
        c.beginPath()
        c.moveTo(x, y - r)
        c.lineTo(x + r * 0.13, y - r * 0.13)
        c.lineTo(x + r, y)
        c.lineTo(x + r * 0.13, y + r * 0.13)
        c.lineTo(x, y + r)
        c.lineTo(x - r * 0.13, y + r * 0.13)
        c.lineTo(x - r, y)
        c.lineTo(x - r * 0.13, y - r * 0.13)
        c.closePath()
        c.fill()
        c.fillStyle = "#fff"
        c.beginPath()
        c.arc(x, y, r * 0.12, 0, .pi * 2)
        c.fill()
    }

    /// Scintillements autour du bijou ; `tier` en ajoute, `alpha` règle l'intensité, `scale` la taille.
    static func drawSparkles(_ c: Canvas2D, _ x: Double, _ y: Double, tier: Int, glow: String, t: Double, alpha: Double, scale: Double = 1) {
        let n = 4 + tier * 3
        for i in 0..<n {
            let angle = Double(i) * 2.399
            let radius = (50 + Double((i * 73) % 170)) * scale
            let twinkle = 0.5 + 0.5 * sin(t * Double(3 + i % 3) + Double(i) * 1.7)
            drawStar(c, x + cos(angle) * radius, y + sin(angle) * radius * 0.75, ((12 + Double(tier) * 4) * twinkle + 6) * scale,
                     alpha * twinkle, i % 2 == 1 ? "#ffffff" : glow)
        }
    }
}
