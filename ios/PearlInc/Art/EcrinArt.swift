import Foundation

/// L'écrin en 3D, porté de src/art/ecrin3d.ts : un écrin plat de joaillier en cuir, vu de trois quarts.
/// Base et couvercle sont des prismes aux coins à peine arrondis ; le couvercle s'ouvre comme un livre, sur sa
/// charnière arrière, avec le geste. Cuir lisse éclairé face par face, dorures sur le dessus, filet d'or sur la
/// tranche, fermoir à poussoir. (Le grain du cuir de la webapp n'est pas repris.)
enum EcrinArt {
    typealias V3 = (Double, Double, Double)
    typealias P2 = (Double, Double)

    /// Couleurs du cuir : bleu nuit, bordeaux, vert anglais, cognac (src/art/ecrin.ts).
    static let leathers = ["#1b2b5c", "#6a1426", "#16463a", "#7a4320"]

    // Proportions de l'étui (largeur = 1).
    private static let W = 1.0, D = 0.78, H = 0.11, T = 0.085, R = 0.045
    private static let pitch = 46 * Double.pi / 180
    private static let dist = 3.4
    /// Le couvercle s'ouvre jusqu'à ~115° quand le geste va jusqu'à 180°.
    private static let lidRatio = 0.64
    /// La caméra : de trois quarts (vu d'assez haut), ou de dessus comme l'huître sur le Duo (charnière à gauche,
    /// l'avant de l'écrin vers la droite de l'écran).
    private static func camera(top: Bool) -> (V3) -> V3 {
        if top { return { p in (p.2, p.0, p.1) } }
        let cosP = cos(pitch), sinP = sin(pitch)
        return { p in (p.0, p.1 * cosP - p.2 * sinP, p.1 * sinP + p.2 * cosP) }
    }

    private static func normalize(_ v: V3) -> V3 {
        let l = (v.0 * v.0 + v.1 * v.1 + v.2 * v.2).squareRoot()
        return (v.0 / l, v.1 / l, v.2 / l)
    }

    private static func dot(_ a: V3, _ b: V3) -> Double { a.0 * b.0 + a.1 * b.1 + a.2 * b.2 }

    // Lumière du salon : d'en haut, un peu de face et de la gauche ; demi-vecteur pour le reflet du cuir.
    private static let light = normalize((-0.4, 0.78, 0.48))
    private static let half = normalize((light.0, light.1, light.2 + 1))

    /// Contour de l'étui vu de dessus (plan xz), coins arrondis.
    private static func outline(_ inset: Double = 0) -> [(Double, Double)] {
        let w = W / 2 - inset, d = D / 2 - inset, r = max(0.008, R - inset * 0.5)
        let corners: [(Double, Double, Double)] = [(w - r, d - r, 0), (-(w - r), d - r, .pi / 2), (-(w - r), -(d - r), .pi), (w - r, -(d - r), 3 * .pi / 2)]
        return corners.flatMap { cx, cz, start in
            (0...5).map { i in let a = start + Double(i) / 5 * (.pi / 2); return (cx + cos(a) * r, cz + sin(a) * r) }
        }
    }

    private static let shape = outline()
    private static let tray = outline(0.05)

    /// Où se trouve le bijou à l'écran, l'échelle (pt par unité), et le bord avant du couvercle (d'où filtre la lumière).
    struct Anchors {
        let jewel: P2
        let scale: Double
        let lidEdge: P2
    }

    private static func rgbString(_ c: (Double, Double, Double)) -> String {
        "rgb(\(Int(c.0.rounded())),\(Int(c.1.rounded())),\(Int(c.2.rounded())))"
    }

    /// Cuir lisse : lumière diffuse + reflet satiné.
    private static func leatherShade(_ base: CSSColor, _ n: V3, boost: Double = 0) -> String {
        let diffuse = max(0, dot(n, light))
        let spec = pow(max(0, dot(n, half)), 22) * 0.4
        let k = 0.3 + 0.5 * diffuse + boost
        return rgbString((min(255, base.r * k + 255 * spec), min(255, base.g * k + 255 * spec), min(255, base.b * k + 255 * spec)))
    }

    /// Dessine l'écrin centré en (cx, cy), large de `width` ; `angle` : le geste (0…180°) ; `dim` : pénombre de
    /// l'intérieur (0…1) ; `sweep` : reflet sur le couvercle (0…1) ; `drawJewel` dessine le bijou couché sur le
    /// plateau (repère du plateau : 1 = largeur de l'écrin) ; `drawEffects` : lumière au-dessus du bijou (x, y, pt par unité).
    /// `top` (iPhone Duo) : vu de dessus, le couvercle tourne de l'angle donné (180° = ouvert à plat, à gauche de la
    /// charnière), le bijou est posé à l'endroit pour l'écran, et le satin du couvercle prend aussi la pénombre.
    @discardableResult
    static func draw(_ c: Canvas2D, cx: Double, cy: Double, width: Double, leather: String, angle: Double, dim: Double, sweep: Double?,
                     top: Bool = false, drawJewel: () -> Void, drawEffects: (Double, Double, Double) -> Void) -> Anchors {
        let scale = width * (dist - D / 2) * 0.98
        let alpha = min(180, max(0, angle)) * (top ? 1 : lidRatio) * .pi / 180
        let cosA = cos(alpha), sinA = sin(alpha)

        let toCam = camera(top: top)
        let topView = top
        let centre = toCam((0, H * 0.5, 0))
        func project(_ p: V3) -> P2 {
            let q = toCam(p)
            let depth = dist - q.2
            return (cx + scale * q.0 / depth, cy - scale * (q.1 - centre.1) / depth)
        }
        /// Une face est visible si elle regarde vers l'œil (depuis sa vraie position, pas « de très loin »).
        func facing(_ nCam: V3, _ pointWorld: V3) -> Bool {
            let q = toCam(pointWorld)
            return -q.0 * nCam.0 + (centre.1 - q.1) * nCam.1 + (dist - q.2) * nCam.2 > 0
        }
        // Couvercle : rotation autour de la charnière (y = H, z = -D/2).
        func lid(_ p: V3) -> V3 {
            let dy = p.1 - H, dz = p.2 + D / 2
            return (p.0, H + dy * cosA + dz * sinA, -D / 2 - dy * sinA + dz * cosA)
        }
        func lidN(_ n: V3) -> V3 { (n.0, n.1 * cosA + n.2 * sinA, -n.1 * sinA + n.2 * cosA) }

        let base = CSSColor(leather)
        func poly(_ points: [P2]) {
            c.beginPath()
            for (i, p) in points.enumerated() { if i == 0 { c.moveTo(p.0, p.1) } else { c.lineTo(p.0, p.1) } }
            c.closePath()
        }
        /// Dessine dans le plan d'une face (repère affine tangent à l'origine).
        func inPlane(_ origin: V3, _ ax: V3, _ az: V3, _ draw: () -> Void) {
            let e = 0.1
            func along(_ v: V3, _ k: Double) -> V3 { (origin.0 + v.0 * k, origin.1 + v.1 * k, origin.2 + v.2 * k) }
            let o = project(origin)
            let x1 = project(along(ax, e)), x0 = project(along(ax, -e))
            let z1 = project(along(az, e)), z0 = project(along(az, -e))
            c.save()
            c.transform((x1.0 - x0.0) / (2 * e), (x1.1 - x0.1) / (2 * e), (z1.0 - z0.0) / (2 * e), (z1.1 - z0.1) / (2 * e), o.0, o.1)
            draw()
            c.restore()
        }

        /// Tranches d'un prisme, seulement celles tournées vers nous, avec un filet d'or.
        func drawSides(_ y0: Double, _ y1: Double, _ transform: (V3) -> V3, _ rotateN: (V3) -> V3, filet: Double) {
            for i in shape.indices {
                let (x0, z0) = shape[i], (x1, z1) = shape[(i + 1) % shape.count]
                let nx = z1 - z0, nz = -(x1 - x0)
                let len = (nx * nx + nz * nz).squareRoot()
                let n = toCam(rotateN((nx / len, 0, nz / len)))
                guard facing(n, transform(((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2))) else { continue }
                poly([transform((x0, y0, z0)), transform((x1, y0, z1)), transform((x1, y1, z1)), transform((x0, y1, z0))].map(project))
                let color = leatherShade(base, n, boost: -0.12)
                c.fillStyle = color
                c.fill()
                c.strokeStyle = color
                c.lineWidth = 0.6
                c.stroke()
                let ya = filet - 0.005, yb = filet + 0.005
                poly([transform((x0, ya, z0)), transform((x1, ya, z1)), transform((x1, yb, z1)), transform((x0, yb, z0))].map(project))
                let g = 0.5 + 0.5 * max(0, dot(n, light))
                c.fillStyle = rgbString((236 * g, 192 * g, 98 * g))
                c.fill()
            }
        }

        func drawBase() {
            drawSides(0, H, { $0 }, { $0 }, filet: H * 0.45)
            // Fermoir à poussoir, au milieu de la tranche avant.
            inPlane((0, H * 0.82, D / 2 + 0.002), (1, 0, 0), (0, -1, 0)) {
                c.fillStyle = "rgba(0,0,0,.35)"
                c.fillRect(-0.045, 0.004, 0.092, 0.07)
                c.fillStyle = JewelArt.goldGradient(c, -0.045, 0, 0.045, 0.06)
                c.beginPath()
                c.moveTo(-0.045, 0)
                c.lineTo(0.045, 0)
                c.lineTo(0.045, 0.05)
                c.quadraticCurveTo(0.045, 0.064, 0.03, 0.064)
                c.lineTo(-0.03, 0.064)
                c.quadraticCurveTo(-0.045, 0.064, -0.045, 0.05)
                c.closePath()
                c.fill()
                c.fillStyle = "rgba(255, 248, 220, .55)"
                c.fillRect(-0.038, 0.006, 0.076, 0.008)
            }
            // Le dessus de la base : bord de cuir, puis plateau de velours sombre, légèrement en creux.
            poly(shape.map { project(($0.0, H, $0.1)) })
            c.fillStyle = leatherShade(base, toCam((0, 1, 0)), boost: -0.2)
            c.fill()
            poly(tray.map { project(($0.0, H - 0.006, $0.1)) })
            let (tx, ty) = project((0, H, 0))
            let pad = c.createRadialGradient(tx, ty - scale * 0.05, 0, tx, ty, scale * 0.4)
            pad.addColorStop(0, "#2b2f45")
            pad.addColorStop(1, "#0d0f1a")
            c.fillStyle = pad
            c.fill()
            c.strokeStyle = "rgba(0,0,0,.55)"
            c.lineWidth = max(1, scale * 0.004)
            c.stroke()
        }

        // Le bijou est couché au milieu du plateau, un peu vers l'avant.
        let jewelOrigin: V3 = (0, H - 0.004, 0.03)
        let jewelAt = project(jewelOrigin)
        let pxPerUnit = scale / (dist - toCam(jewelOrigin).2)

        func drawInterior() {
            // Le bijou reste dans le coin ouvert entre le bord de la base et le dessous du couvercle.
            let hull = convexHull(shape.map { project(($0.0, H, $0.1)) } + shape.map { project(lid(($0.0, H, $0.1))) })
            c.save()
            poly(hull)
            c.clip()
            // Vu de dessus, l'écrin est tourné d'un quart de tour : le bijou aussi, pour rester à l'endroit à l'écran.
            if top { inPlane(jewelOrigin, (0, 0, 1), (-1, 0, 0), drawJewel) } else { inPlane(jewelOrigin, (1, 0, 0), (0, 0, 1), drawJewel) }
            drawEffects(jewelAt.0, jewelAt.1, pxPerUnit)
            if dim > 0.001 {
                poly(shape.map { project(($0.0, H, $0.1)) })
                c.fillStyle = "rgba(0,0,0,\(dim * 0.92))"
                c.fill()
            }
            c.restore()
        }

        func drawLid() {
            drawSides(H, H + T, lid, lidN, filet: H + T * 0.5)
            let topN = toCam(lidN((0, 1, 0)))
            if facing(topN, lid((0, H + T, 0))) {
                let top = shape.map { project(lid(($0.0, H + T, $0.1))) }
                poly(top)
                c.fillStyle = leatherShade(base, topN)
                c.fill()
                // Le dessus est à peine rembourré : reflet doux, un peu décalé vers la lumière.
                let (hx, hy) = project(lid((-0.1, H + T, -0.08)))
                let sheen = c.createRadialGradient(hx, hy, 0, hx, hy, scale * 0.38)
                sheen.addColorStop(0, "rgba(255,255,255,.16)")
                sheen.addColorStop(1, "rgba(255,255,255,0)")
                c.fillStyle = sheen
                poly(top)
                c.fill()
                if let sweep {
                    let a = top[0], b = top[top.count / 2]
                    let g = c.createLinearGradient(b.0, b.1, a.0, a.1)
                    let at = { (v: Double) in min(1, max(0, v)) }
                    g.addColorStop(at(sweep - 0.1), "rgba(255,240,180,0)")
                    g.addColorStop(at(sweep), "rgba(255,240,180,.45)")
                    g.addColorStop(at(sweep + 0.1), "rgba(255,240,180,0)")
                    c.fillStyle = g
                    poly(top)
                    c.fill()
                }
                poly(top)
                c.strokeStyle = "rgba(255,255,255,.2)"
                c.lineWidth = max(1, scale * 0.003)
                c.stroke()

                // Dorures : double filet, fleurons d'angle, cartouche à la perle, « Pearl Inc. ».
                let origin = lid((0, H + T + 0.001, 0))
                let ax = lidN((1, 0, 0)), az = lidN((0, 0, 1))
                func at(_ u: Double, _ v: Double) -> P2 {
                    project((origin.0 + ax.0 * u + az.0 * v, origin.1 + ax.1 * u + az.1 * v, origin.2 + ax.2 * u + az.2 * v))
                }
                let unit = hypot(at(1, 0).0 - at(0, 0).0, at(1, 0).1 - at(0, 0).1)
                let g0 = at(-W / 2, -D / 2), g1 = at(W / 2, D / 2)
                let gold = JewelArt.goldGradient(c, g0.0, g0.1, g1.0, g1.1)
                c.strokeStyle = gold
                c.fillStyle = gold
                c.lineJoin = "round"
                c.lineCap = "round"
                func trace(_ points: [(Double, Double)], closed: Bool, _ lineWidth: Double) {
                    c.beginPath()
                    for (i, p) in points.enumerated() {
                        let q = at(p.0, p.1)
                        if i == 0 { c.moveTo(q.0, q.1) } else { c.lineTo(q.0, q.1) }
                    }
                    if closed { c.closePath() }
                    c.lineWidth = max(0.6, lineWidth * unit)
                    c.stroke()
                }
                func rect(_ inset: Double) -> [(Double, Double)] {
                    [(-W / 2 + inset, -D / 2 + inset), (W / 2 - inset, -D / 2 + inset), (W / 2 - inset, D / 2 - inset), (-W / 2 + inset, D / 2 - inset)]
                }
                trace(rect(0.045), closed: true, 0.008)
                trace(rect(0.065), closed: true, 0.004)
                func quad(_ p0: (Double, Double), _ p1: (Double, Double), _ p2: (Double, Double)) -> [(Double, Double)] {
                    (0...8).map { i in
                        let t = Double(i) / 8
                        return ((1 - t) * (1 - t) * p0.0 + 2 * (1 - t) * t * p1.0 + t * t * p2.0, (1 - t) * (1 - t) * p0.1 + 2 * (1 - t) * t * p1.1 + t * t * p2.1)
                    }
                }
                for (sx, sy) in [(1.0, 1.0), (-1.0, 1.0), (1.0, -1.0), (-1.0, -1.0)] {
                    let ox = sx * (-W / 2 + 0.08), oy = sy * (-D / 2 + 0.08), k = 0.07
                    func p(_ u: Double, _ v: Double) -> (Double, Double) { (ox + sx * u * k, oy + sy * v * k) }
                    trace(quad(p(0, 1), p(0, 0), p(1, 0)), closed: false, 0.006)
                    trace(quad(p(0.18, 0.75), p(0.35, 0.35), p(0.75, 0.18)), closed: false, 0.005)
                    let d = p(0.3, 0.3), dp = at(d.0, d.1)
                    c.beginPath()
                    c.arc(dp.0, dp.1, max(1, 0.007 * unit), 0, .pi * 2)
                    c.fill()
                }
                func ellipse(_ rx: Double, _ ry: Double) -> [(Double, Double)] {
                    (0..<40).map { i in let a = Double(i) / 40 * .pi * 2; return (cos(a) * rx, -0.03 + sin(a) * ry) }
                }
                trace(ellipse(0.085, 0.07), closed: true, 0.012)
                trace(ellipse(0.1, 0.085), closed: true, 0.004)
                inPlane(lid((0, H + T + 0.002, -0.03)), ax, az) {
                    let pearl = c.createRadialGradient(-0.016, -0.02, 0.003, 0, 0, 0.042)
                    pearl.addColorStop(0, "#ffffff")
                    pearl.addColorStop(0.45, "#f1e9dd")
                    pearl.addColorStop(1, "#a69a8a")
                    c.fillStyle = pearl
                    c.beginPath()
                    c.arc(0, 0, 0.042, 0, .pi * 2)
                    c.fill()
                }
                // Vu de dessus, l'écrin est tourné d'un quart de tour : le nom passe sous le cartouche et tourne avec.
                inPlane(lid(topView ? (-0.15, H + T + 0.002, -0.03) : (0, H + T + 0.002, 0.115)), ax, az) {
                    if topView { c.rotate(.pi / 2) }
                    c.scale(0.001, 0.001)
                    c.fillStyle = "#e8c46a"
                    c.setFont(size: 36, weight: 600, serif: false)
                    c.fillText("P E A R L   I N C .", 0, 0)
                }
            }
            // L'intérieur du couvercle : capitonnage de velours, avec le nom de la Maison en or.
            let innerN = toCam(lidN((0, -1, 0)))
            if facing(innerN, lid((0, H, 0))) {
                poly(shape.map { project(lid(($0.0, H, $0.1))) })
                c.fillStyle = leatherShade(base, innerN, boost: -0.15)
                c.fill()
                let lining = tray.map { project(lid(($0.0, H - 0.004, $0.1))) }
                poly(lining)
                let k = 0.55 + 0.45 * max(0, dot(innerN, light))
                let (lx, ly) = project(lid((0, H, 0)))
                let velvet = c.createRadialGradient(lx, ly, 0, lx, ly, scale * 0.42)
                velvet.addColorStop(0, rgbString((52 * k, 58 * k, 86 * k)))
                velvet.addColorStop(1, rgbString((16 * k, 18 * k, 30 * k)))
                c.fillStyle = velvet
                c.fill()
                // Capitons : coutures en losanges et petits boutons.
                let io = lid((0, H - 0.005, 0))
                let ix = lidN((1, 0, 0)), iz = lidN((0, 0, -1))
                func iat(_ u: Double, _ v: Double) -> P2 {
                    project((io.0 + ix.0 * u + iz.0 * v, io.1 + ix.1 * u + iz.1 * v, io.2 + ix.2 * u + iz.2 * v))
                }
                c.save()
                poly(lining)
                c.clip()
                c.strokeStyle = "rgba(0, 0, 0, 0.45)"
                c.lineWidth = max(0.8, scale * 0.0025)
                let step = 0.14
                for d in stride(from: -1.2, through: 1.2, by: step) {
                    c.beginPath()
                    let a0 = iat(d - 0.4, -0.4), a1 = iat(d + 0.4, 0.4), b0 = iat(d + 0.4, -0.4), b1 = iat(d - 0.4, 0.4)
                    c.moveTo(a0.0, a0.1)
                    c.lineTo(a1.0, a1.1)
                    c.moveTo(b0.0, b0.1)
                    c.lineTo(b1.0, b1.1)
                    c.stroke()
                }
                c.fillStyle = "rgba(255, 255, 255, 0.18)"
                for u in stride(from: -0.42, through: 0.42, by: step) {
                    for v in stride(from: -0.35, through: 0.35, by: step) {
                        let b = iat(u, v)
                        c.beginPath()
                        c.arc(b.0, b.1, max(0.8, scale * 0.003), 0, .pi * 2)
                        c.fill()
                    }
                }
                c.restore()
                // Le nom de la Maison, sur un petit écusson de satin.
                inPlane(lid((0, H - 0.006, 0.02)), ix, iz) {
                    if topView { c.rotate(.pi / 2) }
                    c.fillStyle = "rgba(245, 236, 218, 0.95)"
                    c.beginPath()
                    c.ellipse(0, 0, 0.17, 0.075, 0, 0, .pi * 2)
                    c.fill()
                    c.strokeStyle = JewelArt.goldGradient(c, -0.17, 0, 0.17, 0)
                    c.lineWidth = 0.006
                    c.stroke()
                    c.scale(0.001, 0.001)
                    c.fillStyle = "#b8862b"
                    c.setFont(size: 19, weight: 600, serif: false)
                    c.fillText("P E A R L   I N C .", 0, -20)
                    c.setFont(size: 32, weight: 400, serif: true)
                    c.fillText("Perles fines", 0, 20)
                }
                // Vu de dessus, le couvercle est déjà ouvert à plat : son intérieur reste dans l'ombre comme le plateau.
                if top && dim > 0.001 {
                    poly(shape.map { project(lid(($0.0, H, $0.1))) })
                    c.fillStyle = "rgba(0,0,0,\(dim * 0.92))"
                    c.fill()
                }
            }
        }

        // Ordre : tant qu'on voit le dessus du couvercle, il recouvre le bijou ; dès qu'on voit son satin, le bijou
        // est devant lui ; au-delà de la verticale, le couvercle passe derrière la base.
        if facing(toCam(lidN((0, 1, 0))), lid((0, H + T, 0))) {
            drawBase(); drawInterior(); drawLid()
        } else if alpha < .pi / 2 {
            drawBase(); drawLid(); drawInterior()
        } else {
            drawLid(); drawBase(); drawInterior()
        }
        return Anchors(jewel: jewelAt, scale: pxPerUnit, lidEdge: project(lid((0, H, D / 2))))
    }

    /// Ombre de l'étui sur la table, sous son empreinte (à dessiner avant l'étui).
    static func drawShadow(_ c: Canvas2D, cx: Double, cy: Double, width: Double, top: Bool = false) {
        let scale = width * (dist - D / 2) * 0.98
        let toCam = camera(top: top)
        let centre = toCam((0, H * 0.5, 0))
        func project(_ p: V3) -> P2 {
            let q = toCam(p)
            let depth = dist - q.2
            return (cx + scale * q.0 / depth, cy - scale * (q.1 - centre.1) / depth)
        }
        let pts = shape.map { project(($0.0 * 1.06, 0, $0.1 * 1.06 + 0.04)) }
        let xs = pts.map(\.0), ys = pts.map(\.1)
        let mx = (xs.min()! + xs.max()!) / 2, my = (ys.min()! + ys.max()!) / 2
        let rx = (xs.max()! - xs.min()!) / 2, ry = (ys.max()! - ys.min()!) / 2
        let g = c.createRadialGradient(0, 0, 0, 0, 0, 1)
        g.addColorStop(0, "rgba(8, 0, 4, 0.7)")
        g.addColorStop(0.7, "rgba(8, 0, 4, 0.4)")
        g.addColorStop(1, "rgba(8, 0, 4, 0)")
        c.save()
        c.translate(mx, my)
        c.scale(rx * 1.12, ry * 1.2)
        c.fillStyle = g
        c.beginPath()
        c.arc(0, 0, 1, 0, .pi * 2)
        c.fill()
        c.restore()
    }

    /// Enveloppe convexe de points (chaîne monotone).
    private static func convexHull(_ points: [P2]) -> [P2] {
        let pts = points.sorted { $0.0 != $1.0 ? $0.0 < $1.0 : $0.1 < $1.1 }
        func cross(_ o: P2, _ a: P2, _ b: P2) -> Double { (a.0 - o.0) * (b.1 - o.1) - (a.1 - o.1) * (b.0 - o.0) }
        var lower: [P2] = []
        for p in pts {
            while lower.count >= 2 && cross(lower[lower.count - 2], lower[lower.count - 1], p) <= 0 { lower.removeLast() }
            lower.append(p)
        }
        var upper: [P2] = []
        for p in pts.reversed() {
            while upper.count >= 2 && cross(upper[upper.count - 2], upper[upper.count - 1], p) <= 0 { upper.removeLast() }
            upper.append(p)
        }
        return Array(lower.dropLast()) + Array(upper.dropLast())
    }
}
