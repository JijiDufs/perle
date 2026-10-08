import SwiftUI

/// L'huître vue de dessus, dessinée par code (aucune image) : la charnière est en haut,
/// le couvercle se soulève vers le haut de l'écran, la lumière filtre dans l'entrebâillement.
/// Aucune règle de jeu ici : on dessine l'état qu'on reçoit.
struct OysterArt {
    var angle: Double
    var pearlColor: Color?
    var glowColor: Color?
    var pearlRadiusRatio: Double
    var cracked: Bool
    var trembles: Bool
    var revealed: Bool
    var time: Double

    func draw(_ context: inout GraphicsContext, size: CGSize) {
        let width = min(size.width * 0.8, size.height * 0.62, 360)
        let height = width * 0.82
        var center = CGPoint(x: size.width / 2, y: size.height * 0.5)
        if trembles && angle == 0 && !revealed && time.truncatingRemainder(dividingBy: 2.4) < 0.45 {
            center.x += sin(time * 90) * 3
            center.y += cos(time * 70) * 2
        }
        let hingeY = center.y - height / 2
        let opening = smoothstep(1, 25, angle)

        // Ombre sur le sable
        context.fill(
            Path(ellipseIn: CGRect(x: center.x - width * 0.5, y: center.y + height * 0.32, width: width, height: height * 0.3)),
            with: .color(.black.opacity(0.22))
        )

        // Fond de la coquille et nacre
        let base = shellPath(center: center, width: width, height: height, seed: 1)
        context.fill(base, with: .linearGradient(Gradient(colors: [Palette.shellLight, Palette.shellDark]),
                                                  startPoint: CGPoint(x: center.x, y: hingeY), endPoint: CGPoint(x: center.x, y: hingeY + height)))
        let nacre = shellPath(center: CGPoint(x: center.x, y: center.y + height * 0.02), width: width * 0.86, height: height * 0.84, seed: 2, ruffle: 0.015)
        context.fill(nacre, with: .radialGradient(Gradient(colors: [Palette.nacreLight, Palette.nacreShade]),
                                                   center: center, startRadius: 0, endRadius: width * 0.5))

        // Chair et perle
        let pearlCenter = CGPoint(x: center.x, y: center.y + height * 0.08)
        let fleshRect = CGRect(x: pearlCenter.x - width * 0.26, y: pearlCenter.y - height * 0.22, width: width * 0.52, height: height * 0.44)
        context.fill(Path(ellipseIn: fleshRect), with: .color(Palette.flesh.opacity(0.85)))
        let radius = width * pearlRadiusRatio
        if let glowColor {
            let strength = revealed ? 1 : opening
            context.fill(
                Path(ellipseIn: CGRect(x: pearlCenter.x - radius * 5, y: pearlCenter.y - radius * 5, width: radius * 10, height: radius * 10)),
                with: .radialGradient(Gradient(colors: [glowColor.opacity(0.9 * strength), glowColor.opacity(0)]),
                                      center: pearlCenter, startRadius: radius * 0.6, endRadius: radius * 5)
            )
        }
        if let pearlColor {
            let rect = CGRect(x: pearlCenter.x - radius, y: pearlCenter.y - radius, width: radius * 2, height: radius * 2)
            context.fill(Path(ellipseIn: rect), with: .radialGradient(
                Gradient(colors: [.white, pearlColor, pearlColor.opacity(0.75)]),
                center: CGPoint(x: pearlCenter.x - radius * 0.35, y: pearlCenter.y - radius * 0.4), startRadius: 0, endRadius: radius * 1.4))
            if cracked {
                var crack = Path()
                crack.move(to: CGPoint(x: pearlCenter.x - radius * 0.6, y: pearlCenter.y - radius * 0.5))
                crack.addLine(to: CGPoint(x: pearlCenter.x - radius * 0.1, y: pearlCenter.y - radius * 0.05))
                crack.addLine(to: CGPoint(x: pearlCenter.x - radius * 0.25, y: pearlCenter.y + radius * 0.2))
                crack.addLine(to: CGPoint(x: pearlCenter.x + radius * 0.45, y: pearlCenter.y + radius * 0.6))
                context.stroke(crack, with: .color(.black.opacity(0.55)), lineWidth: max(1, radius * 0.08))
            }
        }

        // Pénombre de l'intérieur tant que la coquille est fermée
        let dim = revealed ? 0 : 1 - smoothstep(4, 140, angle)
        if dim > 0.001 { context.fill(nacre, with: .color(Color(hex: "#000608").opacity(dim * 0.94))) }

        // Couvercle : tourne autour de la charnière, vu de dessus (projection en cosinus)
        let radians = angle * .pi / 180
        let projection = cos(radians)
        var lid = context
        lid.translateBy(x: center.x, y: hingeY)
        lid.scaleBy(x: 1 + 0.06 * sin(radians), y: projection)
        lid.translateBy(x: -center.x, y: -hingeY)
        let lidPath = shellPath(center: center, width: width * 0.98, height: height * 0.98, seed: 3)
        if projection >= 0 {
            lid.fill(lidPath, with: .linearGradient(Gradient(colors: [Palette.shellDark, Palette.shellLight, Palette.shellDark]),
                                                     startPoint: CGPoint(x: center.x - width / 2, y: hingeY), endPoint: CGPoint(x: center.x + width / 2, y: hingeY + height)))
            drawRidges(&lid, center: center, width: width, height: height)
        } else {
            lid.fill(lidPath, with: .color(Palette.shellDark))
            let inner = shellPath(center: center, width: width * 0.86, height: height * 0.84, seed: 4, ruffle: 0.015)
            lid.fill(inner, with: .radialGradient(Gradient(colors: [Palette.nacreLight, Palette.nacreShade]),
                                                   center: center, startRadius: 0, endRadius: width * 0.5))
        }

        // Liseré de lumière dans l'entrebâillement
        if let glowColor, !revealed, opening > 0, projection > 0 {
            let edgeY = hingeY + height * projection
            context.fill(
                Path(ellipseIn: CGRect(x: center.x - width * 0.42, y: edgeY - height * 0.06, width: width * 0.84, height: height * 0.12)),
                with: .radialGradient(Gradient(colors: [glowColor.opacity(0.7 * opening), glowColor.opacity(0)]),
                                      center: CGPoint(x: center.x, y: edgeY), startRadius: 0, endRadius: width * 0.42)
            )
        }
    }

    /// Contour festonné d'une valve.
    private func shellPath(center: CGPoint, width: Double, height: Double, seed: Double, ruffle: Double = 0.04) -> Path {
        var path = Path()
        let steps = 96
        for step in 0...steps {
            let theta = Double(step) / Double(steps) * 2 * .pi
            let wave = 1 + ruffle * sin(theta * 14 + seed) + ruffle * 0.6 * sin(theta * 5 + seed * 2)
            // Plus étroite vers la charnière (en haut), plus large en bas.
            let taper = 1 - 0.18 * max(0, -sin(theta))
            let point = CGPoint(x: center.x + cos(theta) * width / 2 * wave * taper, y: center.y + sin(theta) * height / 2 * wave)
            if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }

    /// Stries de croissance sur le dessus du couvercle.
    private func drawRidges(_ context: inout GraphicsContext, center: CGPoint, width: Double, height: Double) {
        for ring in 1...5 {
            let k = Double(ring) / 6
            let ridge = shellPath(center: CGPoint(x: center.x, y: center.y - height * 0.5 * (1 - k) * 0.6),
                                  width: width * k, height: height * k, seed: Double(ring), ruffle: 0.05)
            context.stroke(ridge, with: .color(.black.opacity(0.18)), lineWidth: 1.2)
        }
    }
}
