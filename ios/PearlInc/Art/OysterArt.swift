import SwiftUI

/// L'huître vue de dessus, dessinée par code (aucune image) : la charnière est en haut,
/// le couvercle se soulève vers le haut de l'écran, la lumière filtre dans l'entrebâillement.
/// Le skin habille la coquille et la nacre, jamais la lumière de la perle.
/// Aucune règle de jeu ici : on dessine l'état qu'on reçoit.
struct OysterArt {
    /// Nombre de grands plis du bénitier.
    private static let clamFolds = 6

    var angle: Double
    var pearlColor: Color?
    var glowColor: Color?
    var pearlRadiusRatio: Double
    var cracked: Bool
    var trembles: Bool
    var revealed: Bool
    var time: Double
    var look: SkinLook = .lagoon
    /// Taille maximale de la coquille (pt).
    var maxWidth: Double = 360

    func draw(_ context: inout GraphicsContext, size: CGSize) {
        let scale = look.style == .clam ? 1.08 : 1
        let width = min(size.width * 0.8, size.height * 0.62, maxWidth) * scale
        let height = width * (look.style == .clam ? 0.74 : 0.82)
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
        let base = outline(center: center, width: width, height: height, seed: 1)
        context.fill(base, with: .linearGradient(Gradient(colors: [look.shellLight, look.shellDark]),
                                                  startPoint: CGPoint(x: center.x, y: hingeY), endPoint: CGPoint(x: center.x, y: hingeY + height)))
        if let rim = look.rim { context.stroke(base, with: .color(rim), lineWidth: 2) }
        let nacre = outline(center: CGPoint(x: center.x, y: center.y + height * 0.02), width: width * 0.86, height: height * 0.84, seed: 2, inner: true)
        drawInterior(&context, path: nacre, center: center, width: width, height: height)

        // Chair et perle
        let pearlCenter = CGPoint(x: center.x, y: center.y + height * 0.08)
        let fleshRect = CGRect(x: pearlCenter.x - width * 0.26, y: pearlCenter.y - height * 0.22, width: width * 0.52, height: height * 0.44)
        context.fill(Path(ellipseIn: fleshRect), with: .color(Palette.flesh.opacity(look.style == .clam ? 0.5 : 0.85)))
        let radius = width * pearlRadiusRatio / scale
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
        let lidPath = outline(center: center, width: width * 0.98, height: height * 0.98, seed: 3)
        if projection >= 0 {
            lid.fill(lidPath, with: .linearGradient(Gradient(colors: [look.shellDark, look.shellLight, look.shellDark]),
                                                     startPoint: CGPoint(x: center.x - width / 2, y: hingeY), endPoint: CGPoint(x: center.x + width / 2, y: hingeY + height)))
            drawLidRelief(&lid, path: lidPath, center: center, width: width, height: height)
        } else {
            lid.fill(lidPath, with: .color(look.shellDark))
            let inner = outline(center: center, width: width * 0.86, height: height * 0.84, seed: 4, inner: true)
            drawInterior(&lid, path: inner, center: center, width: width, height: height)
        }
        if let rim = look.rim { lid.stroke(lidPath, with: .color(rim), lineWidth: 2.5) }
        if look.style == .clam && projection > 0.2 {
            // Le bénitier ne ferme jamais tout à fait : son manteau bleu-vert ondule au bord.
            var mantle = lid
            mantle.clip(to: Path(CGRect(x: center.x - width, y: center.y + height * 0.05, width: width * 2, height: height)))
            mantle.stroke(lidPath, with: .linearGradient(Gradient(colors: [look.nacreLight, look.nacreShade, look.nacreLight]),
                                                         startPoint: CGPoint(x: center.x - width / 2, y: center.y), endPoint: CGPoint(x: center.x + width / 2, y: center.y)),
                          lineWidth: width * 0.03)
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

        if look.style == .gold && projection > 0 { drawSparkles(&context, center: center, width: width, height: height * projection) }
    }

    // MARK: - Silhouettes

    /// Contour d'une valve, selon le skin.
    private func outline(center: CGPoint, width: Double, height: Double, seed: Double, inner: Bool = false) -> Path {
        var path = Path()
        let steps = 120
        for step in 0...steps {
            let theta = Double(step) / Double(steps) * 2 * .pi
            let x: Double
            let y: Double
            switch look.style {
            case .clam:
                // Éventail : bord inférieur en grosses ondes (les côtes), charnière droite en haut.
                let lower = max(0, sin(theta))
                let wave = 1 + (inner ? 0.035 : 0.11) * lower * abs(sin(theta * Double(Self.clamFolds)))
                let taper = 1 - 0.32 * max(0, -sin(theta))
                x = cos(theta) * width / 2 * wave * taper
                y = sin(theta) * height / 2 * wave * (sin(theta) < 0 ? 0.62 : 1)
            case .oyster, .gold:
                let ruffle = inner ? 0.015 : 0.04
                let wave = 1 + ruffle * sin(theta * 14 + seed) + ruffle * 0.6 * sin(theta * 5 + seed * 2)
                // Plus étroite vers la charnière (en haut), plus large en bas.
                let taper = 1 - 0.18 * max(0, -sin(theta))
                x = cos(theta) * width / 2 * wave * taper
                y = sin(theta) * height / 2 * wave
            }
            let point = CGPoint(x: center.x + x, y: center.y + y)
            if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }

    // MARK: - Matières

    /// Intérieur : nacre, ou manteau tacheté du bénitier.
    private func drawInterior(_ context: inout GraphicsContext, path: Path, center: CGPoint, width: Double, height: Double) {
        context.fill(path, with: .radialGradient(Gradient(colors: [look.nacreLight, look.nacreShade]),
                                                 center: center, startRadius: 0, endRadius: width * 0.5))
        guard look.style == .clam else { return }
        var spots = context
        spots.clip(to: path)
        for index in 0..<46 {
            let a = Double(index) * 2.399
            let r = sqrt(Double(index) / 46) * width * 0.42
            let point = CGPoint(x: center.x + cos(a) * r, y: center.y + sin(a) * r * 0.8)
            let size = width * (0.012 + 0.01 * (Double(index % 3)))
            spots.fill(Path(ellipseIn: CGRect(x: point.x - size, y: point.y - size, width: size * 2, height: size * 2)),
                       with: .color(index % 4 == 0 ? Color(hex: "#3B5BDB").opacity(0.55) : Color(hex: "#C8FFF4").opacity(0.5)))
        }
    }

    /// Relief du dessus du couvercle : stries, côtes, ou martelage.
    private func drawLidRelief(_ context: inout GraphicsContext, path: Path, center: CGPoint, width: Double, height: Double) {
        var relief = context
        relief.clip(to: path)
        let hinge = CGPoint(x: center.x, y: center.y - height / 2)
        switch look.style {
        case .oyster:
            for ring in 1...5 {
                let k = Double(ring) / 6
                let ridge = outline(center: CGPoint(x: center.x, y: center.y - height * 0.5 * (1 - k) * 0.6),
                                    width: width * k, height: height * k, seed: Double(ring))
                relief.stroke(ridge, with: .color(.black.opacity(0.18)), lineWidth: 1.2)
            }
        case .clam:
            // Grands plis en éventail depuis la charnière : alternance ombre / lumière.
            let folds = Self.clamFolds
            for fold in 0..<folds {
                let from = .pi * (Double(fold) / Double(folds))
                let to = .pi * (Double(fold + 1) / Double(folds))
                var wedge = Path()
                wedge.move(to: hinge)
                wedge.addLine(to: CGPoint(x: hinge.x + cos(from) * width, y: hinge.y + sin(from) * height * 1.3))
                wedge.addLine(to: CGPoint(x: hinge.x + cos(to) * width, y: hinge.y + sin(to) * height * 1.3))
                wedge.closeSubpath()
                relief.fill(wedge, with: .linearGradient(
                    Gradient(colors: [.black.opacity(0.2), .white.opacity(0.28), .black.opacity(0.2)]),
                    startPoint: CGPoint(x: hinge.x + cos(from) * width * 0.6, y: hinge.y + sin(from) * height * 0.8),
                    endPoint: CGPoint(x: hinge.x + cos(to) * width * 0.6, y: hinge.y + sin(to) * height * 0.8)))
            }
            for ring in 1...4 {
                let k = Double(ring) / 5
                let ridge = outline(center: CGPoint(x: center.x, y: center.y - height * 0.5 * (1 - k) * 0.7),
                                    width: width * k, height: height * k, seed: Double(ring))
                relief.stroke(ridge, with: .color(.black.opacity(0.1)), lineWidth: 1)
            }
        case .gold:
            // Martelage : petites facettes claires et sombres.
            relief.fill(path, with: .linearGradient(
                Gradient(colors: [look.shellDark, look.shellLight, .white.opacity(0.9), look.shellLight, look.shellDark]),
                startPoint: CGPoint(x: center.x - width * 0.5, y: center.y - height * 0.5),
                endPoint: CGPoint(x: center.x + width * 0.5, y: center.y + height * 0.5)))
            relief.fill(path, with: .color(look.shellLight.opacity(0.35)))
            for index in 0..<160 {
                let a = Double(index) * 2.399
                let r = sqrt(Double(index) / 160) * width * 0.5
                let point = CGPoint(x: center.x + cos(a) * r, y: center.y + sin(a) * r * 0.82)
                let size = width * 0.014
                relief.fill(Path(ellipseIn: CGRect(x: point.x - size, y: point.y - size * 0.7, width: size * 2, height: size * 1.4)),
                            with: .color(index % 2 == 0 ? .white.opacity(0.16) : Color(hex: "#6B4A10").opacity(0.1)))
            }
            for ring in 1...4 {
                let k = Double(ring) / 5
                let ridge = outline(center: CGPoint(x: center.x, y: center.y - height * 0.5 * (1 - k) * 0.6),
                                    width: width * k, height: height * k, seed: Double(ring))
                relief.stroke(ridge, with: .color(Color(hex: "#7A5410").opacity(0.25)), lineWidth: 1)
            }
            relief.fill(Path(ellipseIn: CGRect(x: center.x - width * 0.35, y: center.y - height * 0.42, width: width * 0.4, height: height * 0.22)),
                        with: .radialGradient(Gradient(colors: [.white.opacity(0.45), .white.opacity(0)]),
                                              center: CGPoint(x: center.x - width * 0.15, y: center.y - height * 0.31), startRadius: 0, endRadius: width * 0.22))
        }
    }

    /// Éclats qui scintillent sur l'huître d'or.
    private func drawSparkles(_ context: inout GraphicsContext, center: CGPoint, width: Double, height: Double) {
        let spots: [(Double, Double, Double)] = [(-0.28, -0.3, 0), (0.22, -0.1, 1.3), (-0.05, 0.18, 2.1), (0.3, 0.25, 3.4)]
        for (dx, dy, phase) in spots {
            let twinkle = max(0, sin(time * 2.2 + phase))
            guard twinkle > 0.05 else { continue }
            let point = CGPoint(x: center.x + dx * width, y: center.y - height * 0.5 + (0.5 + dy) * height)
            let size = width * 0.035 * twinkle
            var star = Path()
            star.move(to: CGPoint(x: point.x - size, y: point.y))
            star.addLine(to: CGPoint(x: point.x + size, y: point.y))
            star.move(to: CGPoint(x: point.x, y: point.y - size))
            star.addLine(to: CGPoint(x: point.x, y: point.y + size))
            context.stroke(star, with: .color(.white.opacity(0.9 * twinkle)), lineWidth: 1.4)
            context.fill(Path(ellipseIn: CGRect(x: point.x - size * 0.35, y: point.y - size * 0.35, width: size * 0.7, height: size * 0.7)),
                         with: .color(.white.opacity(0.8 * twinkle)))
        }
    }
}
