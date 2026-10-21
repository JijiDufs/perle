import Foundation

/// Le salon du joaillier, décor des écrins, porté de src/art/salon.ts : mur prune tendu de soie, lumières floues
/// au loin, table de velours bordeaux, faisceau chaud qui tombe sur l'écrin et poussières dorées qui y dansent.
/// (Le grain du velours de la webapp n'est pas repris : il serait redessiné à chaque image.)
struct SalonArt {
    /// L'écrin posé sur la table : son centre, et la taille de sa base.
    struct Focus {
        let x, y, w, h: Double
    }

    let time: Double
    let focus: Focus

    private struct Light { let x, y, r: Double; let hue: String; let phase: Double }
    private struct Mote { let x, y, r, speed, phase: Double }

    private static func seeded(_ seed: Int) -> () -> Double {
        var s = seed
        return { s = (s * 16807) % 2_147_483_647; return Double(s) / 2_147_483_647 }
    }

    /// Le fond (mur, table, lumières, faisceau), sous l'écrin.
    func draw(_ c: Canvas2D, w: Double, h: Double) {
        let table = (focus.y - focus.h * 1.2).rounded()
        // Le mur : soie prune, plus sombre en haut, motif losangé très discret.
        let wall = c.createLinearGradient(0, 0, 0, table)
        wall.addColorStop(0, "#12080d")
        wall.addColorStop(0.7, "#2a1220")
        wall.addColorStop(1, "#3a1829")
        c.fillStyle = wall
        c.fillRect(0, 0, w, table + 1)
        c.strokeStyle = "rgba(232, 190, 90, 0.045)"
        c.lineWidth = 1
        let step = 34.0
        c.beginPath()
        for x in stride(from: -table, to: w + table, by: step) {
            c.moveTo(x, 0)
            c.lineTo(x + table, table)
            c.moveTo(x, 0)
            c.lineTo(x - table, table)
        }
        c.stroke()
        c.fillStyle = "rgba(232, 190, 90, 0.05)"
        c.beginPath()
        for y in stride(from: step / 2, to: table, by: step) {
            for x in stride(from: Int(y / step) % 2 == 1 ? step / 2 : 0, to: w, by: step) {
                c.moveTo(x + 1.4, y)
                c.arc(x, y, 1.4, 0, 2 * .pi)
            }
        }
        c.fill()
        // Plinthe sombre et fin filet doré au bas du mur.
        let skirting = c.createLinearGradient(0, table - 16, 0, table)
        skirting.addColorStop(0, "rgba(10, 3, 7, 0)")
        skirting.addColorStop(1, "rgba(10, 3, 7, 0.7)")
        c.fillStyle = skirting
        c.fillRect(0, table - 16, w, 16)
        c.fillStyle = "rgba(232, 190, 90, 0.45)"
        c.fillRect(0, table - 3, w, 1)

        // La table : velours bordeaux (plus sombre que les écrins, pour qu'ils ressortent dans le faisceau).
        let velvet = c.createLinearGradient(0, table, 0, h)
        velvet.addColorStop(0, "#3a0e1d")
        velvet.addColorStop(0.35, "#220710")
        velvet.addColorStop(1, "#0c0205")
        c.fillStyle = velvet
        c.fillRect(0, table, w, h - table)
        let sheenY = table + (h - table) * 0.15
        let sheen = c.createRadialGradient(w / 2, sheenY, 0, w / 2, sheenY, w * 0.9)
        sheen.addColorStop(0, "rgba(255, 170, 190, 0.12)")
        sheen.addColorStop(1, "rgba(255, 170, 190, 0)")
        c.fillStyle = sheen
        c.fillRect(0, table, w, h - table)
        let edge = c.createLinearGradient(0, table, 0, table + 18)
        edge.addColorStop(0, "rgba(8, 0, 4, 0.55)")
        edge.addColorStop(1, "rgba(8, 0, 4, 0)")
        c.fillStyle = edge
        c.fillRect(0, table, w, 18)

        drawLights(c, w: w, table: table)
        drawBeam(c)
    }

    /// Par-dessus l'écrin : poussières dans la lumière, vignette.
    func drawOverlay(_ c: Canvas2D, w: Double, h: Double) {
        let rand = Self.seeded(9)
        for _ in 0..<50 { _ = rand() } // les lumières prennent les 50 premiers tirages
        c.save()
        c.globalCompositeOperation = "lighter"
        let bottom = focus.y + focus.h
        for _ in 0..<30 {
            let m = Mote(x: rand(), y: rand(), r: 0.6 + rand() * 1.6, speed: 4 + rand() * 9, phase: rand() * 2 * .pi)
            let y = ((m.y * bottom - time * m.speed).truncatingRemainder(dividingBy: bottom) + bottom).truncatingRemainder(dividingBy: bottom)
            let halfWidth = focus.w * (0.18 + 0.77 * y / bottom)
            let x = focus.x + (m.x * 2 - 1) * halfWidth + sin(time * 0.5 + m.phase) * 6
            let twinkle = 0.25 + 0.75 * max(0, sin(time * 1.6 + m.phase * 3))
            c.fillStyle = "rgba(255, 230, 170, \(0.55 * twinkle))"
            c.beginPath()
            c.arc(x, y, m.r, 0, 2 * .pi)
            c.fill()
        }
        c.restore()
        let g = c.createRadialGradient(w / 2, h * 0.5, min(w, h) * 0.3, w / 2, h * 0.5, max(w, h) * 0.75)
        g.addColorStop(0, "rgba(6, 0, 3, 0)")
        g.addColorStop(1, "rgba(6, 0, 3, 0.7)")
        c.fillStyle = g
        c.fillRect(0, 0, w, h)
    }

    /// Lumières floues au loin (bokeh), qui respirent.
    private func drawLights(_ c: Canvas2D, w: Double, table: Double) {
        let rand = Self.seeded(9)
        let hues = ["#ffd27a", "#ffb3c6", "#fff1d6", "#ffc56b"]
        c.save()
        c.globalCompositeOperation = "lighter"
        for _ in 0..<10 {
            let light = Light(x: rand() * w, y: table * (0.15 + rand() * 0.75), r: 10 + rand() * 26,
                              hue: hues[min(hues.count - 1, Int(rand() * Double(hues.count)))], phase: rand() * 2 * .pi)
            let alpha = 0.06 + 0.05 * sin(time * 0.7 + light.phase)
            let x = light.x + sin(time * 0.08 + light.phase) * 6
            let base = CSSColor(light.hue)
            func rgba(_ a: Double) -> String { "rgba(\(base.r),\(base.g),\(base.b),\(max(0, a)))" }
            let g = c.createRadialGradient(x, light.y, light.r * 0.55, x, light.y, light.r)
            g.addColorStop(0, rgba(alpha))
            g.addColorStop(0.8, rgba(alpha * 0.8))
            g.addColorStop(1, rgba(0))
            c.fillStyle = g
            c.beginPath()
            c.arc(x, light.y, light.r, 0, 2 * .pi)
            c.fill()
        }
        c.restore()
    }

    /// Le faisceau chaud qui tombe d'en haut sur l'écrin.
    private func drawBeam(_ c: Canvas2D) {
        let breathe = 0.9 + 0.1 * sin(time * 0.8)
        c.save()
        c.globalCompositeOperation = "lighter"
        let g = c.createLinearGradient(0, 0, 0, focus.y + focus.h)
        g.addColorStop(0, "rgba(255, 220, 160, \(0.02 * breathe))")
        g.addColorStop(1, "rgba(255, 220, 160, \(0.09 * breathe))")
        c.fillStyle = g
        c.beginPath()
        c.moveTo(focus.x - focus.w * 0.18, 0)
        c.lineTo(focus.x + focus.w * 0.18, 0)
        c.lineTo(focus.x + focus.w * 0.95, focus.y + focus.h * 1.1)
        c.lineTo(focus.x - focus.w * 0.95, focus.y + focus.h * 1.1)
        c.closePath()
        c.fill()
        // Flaque de lumière sur le velours.
        let cy = focus.y + focus.h * 0.5
        let pool = c.createRadialGradient(focus.x, cy, 0, focus.x, cy, focus.w * 1.1)
        pool.addColorStop(0, "rgba(255, 190, 150, \(0.3 * breathe))")
        pool.addColorStop(1, "rgba(255, 190, 150, 0)")
        c.fillStyle = pool
        c.translate(0, cy)
        c.scale(1, 0.62)
        c.translate(0, -cy)
        c.fillRect(focus.x - focus.w * 1.2, focus.y - focus.h * 1.5, focus.w * 2.4, focus.h * 4)
        c.restore()
    }
}
