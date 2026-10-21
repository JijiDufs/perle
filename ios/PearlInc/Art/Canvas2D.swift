import SwiftUI

/// Un petit équivalent du Canvas 2D du navigateur, au-dessus de GraphicsContext : les dessins de la webapp
/// (src/art) se portent presque ligne à ligne, avec le même rendu. Même sémantique que le navigateur :
/// la transformation s'applique aux points au moment où on construit le chemin, les dégradés et
/// l'épaisseur des traits suivent la transformation au moment où l'on remplit ou trace.
/// Seul ce dont les dessins portés ont besoin est implémenté.
final class Canvas2D {
    private struct State {
        var context: GraphicsContext
        var ctm: CGAffineTransform = .identity
        var fillStyle: any Paint = "#000"
        var strokeStyle: any Paint = "#000"
        var lineWidth = 1.0
        var lineCap = "butt"
        var lineJoin = "miter"
        var dash: [Double] = []
        var composite = "source-over"
        var alpha = 1.0
        var fontSize = 10.0
        var fontWeight = 400
        var serif = false
    }

    private var state: State
    private var stack: [State] = []
    private var path = Path()

    init(_ context: GraphicsContext) {
        state = State(context: context)
    }

    // MARK: - Styles

    var fillStyle: any Paint { get { state.fillStyle } set { state.fillStyle = newValue } }
    var strokeStyle: any Paint { get { state.strokeStyle } set { state.strokeStyle = newValue } }
    var lineWidth: Double { get { state.lineWidth } set { state.lineWidth = newValue } }
    var lineCap: String { get { state.lineCap } set { state.lineCap = newValue } }
    var lineJoin: String { get { state.lineJoin } set { state.lineJoin = newValue } }
    var globalCompositeOperation: String { get { state.composite } set { state.composite = newValue } }
    var globalAlpha: Double { get { state.alpha } set { state.alpha = newValue } }

    func setLineDash(_ segments: [Double]) { state.dash = segments }

    /// Police : taille (dans le repère courant), graisse, et famille (sans ou avec empattements).
    func setFont(size: Double, weight: Int, serif: Bool) {
        state.fontSize = size
        state.fontWeight = weight
        state.serif = serif
    }

    // MARK: - État et transformations

    func save() { stack.append(state) }

    func restore() { if let last = stack.popLast() { state = last } }

    func translate(_ x: Double, _ y: Double) { state.ctm = CGAffineTransform(translationX: x, y: y).concatenating(state.ctm) }
    func rotate(_ angle: Double) { state.ctm = CGAffineTransform(rotationAngle: angle).concatenating(state.ctm) }
    func scale(_ x: Double, _ y: Double) { state.ctm = CGAffineTransform(scaleX: x, y: y).concatenating(state.ctm) }
    func transform(_ a: Double, _ b: Double, _ c: Double, _ d: Double, _ e: Double, _ f: Double) {
        state.ctm = CGAffineTransform(a: a, b: b, c: c, d: d, tx: e, ty: f).concatenating(state.ctm)
    }

    // MARK: - Chemin (stocké dans le repère de l'écran)

    private func point(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y).applying(state.ctm) }

    func beginPath() { path = Path() }
    func closePath() { path.closeSubpath() }
    func moveTo(_ x: Double, _ y: Double) { path.move(to: point(x, y)) }

    func lineTo(_ x: Double, _ y: Double) {
        if path.isEmpty { path.move(to: point(x, y)) } else { path.addLine(to: point(x, y)) }
    }

    func quadraticCurveTo(_ cx: Double, _ cy: Double, _ x: Double, _ y: Double) {
        if path.isEmpty { path.move(to: point(cx, cy)) }
        path.addQuadCurve(to: point(x, y), control: point(cx, cy))
    }

    func bezierCurveTo(_ c1x: Double, _ c1y: Double, _ c2x: Double, _ c2y: Double, _ x: Double, _ y: Double) {
        if path.isEmpty { path.move(to: point(c1x, c1y)) }
        path.addCurve(to: point(x, y), control1: point(c1x, c1y), control2: point(c2x, c2y))
    }

    func arc(_ x: Double, _ y: Double, _ r: Double, _ start: Double, _ end: Double, _ anticlockwise: Bool = false) {
        ellipse(x, y, r, r, 0, start, end, anticlockwise)
    }

    func ellipse(_ x: Double, _ y: Double, _ rx: Double, _ ry: Double, _ rotation: Double, _ start: Double, _ end: Double, _ anticlockwise: Bool = false) {
        // Comme le navigateur : un tour complet au plus.
        var end = end
        if !anticlockwise && end - start >= 2 * .pi { end = start + 2 * .pi }
        if anticlockwise && start - end >= 2 * .pi { end = start - 2 * .pi }
        let transform = CGAffineTransform(scaleX: rx, y: ry)
            .concatenating(CGAffineTransform(rotationAngle: rotation))
            .concatenating(CGAffineTransform(translationX: x, y: y))
            .concatenating(state.ctm)
        // Le navigateur relie le point courant au début de l'arc ; CoreGraphics aussi, sauf sur un chemin vide.
        let first = CGPoint(x: cos(start), y: sin(start)).applying(transform)
        if path.isEmpty { path.move(to: first) } else { path.addLine(to: first) }
        path.addArc(center: .zero, radius: 1, startAngle: .radians(start), endAngle: .radians(end), clockwise: anticlockwise, transform: transform)
    }

    func arcTo(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double, _ r: Double) {
        if path.isEmpty { path.move(to: point(x1, y1)) }
        path.addArc(tangent1End: CGPoint(x: x1, y: y1), tangent2End: CGPoint(x: x2, y: y2), radius: r, transform: state.ctm)
    }

    func rect(_ x: Double, _ y: Double, _ w: Double, _ h: Double) {
        path.addRect(CGRect(x: x, y: y, width: w, height: h), transform: state.ctm)
    }

    // MARK: - Dessin

    func fill(_ rule: String = "nonzero") { fill(path, eoFill: rule == "evenodd") }

    func fillRect(_ x: Double, _ y: Double, _ w: Double, _ h: Double) {
        fill(Path(CGRect(x: x, y: y, width: w, height: h)).applying(state.ctm), eoFill: false)
    }

    func stroke() {
        var g = drawingContext()
        let inverse = state.ctm.inverted()
        let style = StrokeStyle(lineWidth: state.lineWidth, lineCap: cap, lineJoin: join, dash: state.dash.map { CGFloat($0) })
        g.stroke(path.applying(inverse), with: state.strokeStyle.shading(), style: style)
    }

    func clip() { state.context.clip(to: path) }

    /// Texte centré en (x, y) dans le repère courant.
    func fillText(_ text: String, _ x: Double, _ y: Double) {
        var g = drawingContext()
        let weight: Font.Weight = switch state.fontWeight {
        case ..<500: .regular
        case ..<650: .semibold
        case ..<750: .bold
        case ..<850: .heavy
        default: .black
        }
        let color = (state.fillStyle as? String).map { CSSColor($0).color } ?? .black
        let label = Text(text).font(.system(size: state.fontSize, weight: weight, design: state.serif ? .serif : .default)).foregroundStyle(color)
        g.draw(label, at: CGPoint(x: x, y: y), anchor: .center)
    }

    // MARK: - Interne

    /// Contexte de dessin : repère courant, mode de fusion et transparence.
    private func drawingContext() -> GraphicsContext {
        var g = state.context
        g.concatenate(state.ctm)
        g.opacity *= state.alpha
        switch state.composite {
        case "lighter": g.blendMode = .plusLighter
        case "screen": g.blendMode = .screen
        case "multiply": g.blendMode = .multiply
        case "overlay": g.blendMode = .overlay
        default: break
        }
        return g
    }

    private var cap: CGLineCap { state.lineCap == "round" ? .round : state.lineCap == "square" ? .square : .butt }
    private var join: CGLineJoin { state.lineJoin == "round" ? .round : state.lineJoin == "bevel" ? .bevel : .miter }

    private func fill(_ devicePath: Path, eoFill: Bool) {
        var g = drawingContext()
        let local = devicePath.applying(state.ctm.inverted())
        if let gradient = state.fillStyle as? Gradient2D, case .radial(let x0, let y0, let r0, let x1, let y1, let r1) = gradient.kind,
           x0 != x1 || y0 != y1 {
            // Dégradé radial à deux centres (le reflet décentré qui donne le volume) : GraphicsContext n'en a pas,
            // on le reconstruit par des disques emboîtés, du cercle extérieur au cercle intérieur.
            g.clip(to: local, style: FillStyle(eoFill: eoFill))
            g.fill(local, with: .color(gradient.color(at: 1)), style: FillStyle(eoFill: eoFill))
            // Autant de disques que nécessaire à l'écran (les petites pierres des bijoux en ont des dizaines).
            let deviceRadius = max(r0, r1) * sqrt(abs(state.ctm.a * state.ctm.d - state.ctm.b * state.ctm.c))
            let steps = min(40, max(6, Int(deviceRadius / 2)))
            for i in stride(from: steps, through: 0, by: -1) {
                let t = Double(i) / Double(steps)
                let cx = x0 + (x1 - x0) * t, cy = y0 + (y1 - y0) * t, r = r0 + (r1 - r0) * t
                g.fill(Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)), with: .color(gradient.color(at: t)))
            }
            return
        }
        g.fill(local, with: state.fillStyle.shading(), style: FillStyle(eoFill: eoFill))
    }
}

// MARK: - Peintures : couleur CSS ou dégradé

protocol Paint {
    func shading() -> GraphicsContext.Shading
}

extension String: Paint {
    func shading() -> GraphicsContext.Shading { .color(CSSColor(self).color) }
}

final class Gradient2D: Paint {
    enum Kind {
        case linear(Double, Double, Double, Double)
        case radial(Double, Double, Double, Double, Double, Double)
    }

    let kind: Kind
    private var stops: [(Double, CSSColor)] = []

    init(_ kind: Kind) { self.kind = kind }

    func addColorStop(_ offset: Double, _ color: String) {
        stops.append((offset, CSSColor(color)))
        stops.sort { $0.0 < $1.0 }
    }

    /// Couleur à la position t (0…1), comme le navigateur (couleurs interpolées, bords prolongés).
    func color(at t: Double) -> Color {
        guard let first = stops.first, let last = stops.last else { return .clear }
        if t <= first.0 { return first.1.color }
        if t >= last.0 { return last.1.color }
        for k in 1..<stops.count where t <= stops[k].0 {
            let (a, ca) = stops[k - 1], (b, cb) = stops[k]
            return ca.mix(cb, b > a ? (t - a) / (b - a) : 0).color
        }
        return last.1.color
    }

    func shading() -> GraphicsContext.Shading {
        let gradient = Gradient(stops: stops.map { .init(color: $0.1.color, location: $0.0) })
        switch kind {
        case .linear(let x0, let y0, let x1, let y1):
            return .linearGradient(gradient, startPoint: CGPoint(x: x0, y: y0), endPoint: CGPoint(x: x1, y: y1))
        case .radial(_, _, let r0, let x1, let y1, let r1):
            return .radialGradient(gradient, center: CGPoint(x: x1, y: y1), startRadius: r0, endRadius: r1)
        }
    }
}

extension Canvas2D {
    func createLinearGradient(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double) -> Gradient2D {
        Gradient2D(.linear(x0, y0, x1, y1))
    }

    func createRadialGradient(_ x0: Double, _ y0: Double, _ r0: Double, _ x1: Double, _ y1: Double, _ r1: Double) -> Gradient2D {
        Gradient2D(.radial(x0, y0, r0, x1, y1, r1))
    }
}

/// Couleur CSS : « #rgb », « #rrggbb », « rgb(…) », « rgba(…) ».
struct CSSColor {
    var r = 0.0, g = 0.0, b = 0.0, a = 1.0

    init(r: Double, g: Double, b: Double, a: Double) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    init(_ css: String) {
        let text = css.trimmingCharacters(in: .whitespaces).lowercased()
        if text.hasPrefix("#") {
            var hex = String(text.dropFirst())
            if hex.count == 3 { hex = hex.map { "\($0)\($0)" }.joined() }
            let value = UInt32(hex, radix: 16) ?? 0
            r = Double((value >> 16) & 0xFF)
            g = Double((value >> 8) & 0xFF)
            b = Double(value & 0xFF)
        } else if let open = text.firstIndex(of: "("), let close = text.lastIndex(of: ")") {
            let parts = text[text.index(after: open)..<close].split(separator: ",").map { Double($0.trimmingCharacters(in: .whitespaces)) ?? 0 }
            if parts.count >= 3 { (r, g, b) = (parts[0], parts[1], parts[2]) }
            if parts.count >= 4 { a = parts[3] }
        }
    }

    var color: Color { Color(.sRGB, red: r / 255, green: g / 255, blue: b / 255, opacity: a) }

    func mix(_ other: CSSColor, _ t: Double) -> CSSColor {
        CSSColor(r: r + (other.r - r) * t, g: g + (other.g - g) * t, b: b + (other.b - b) * t, a: a + (other.a - a) * t)
    }
}

/// Éclaircit (k = 0 : identique, 1 : blanc) ou assombrit une couleur, comme src/art/color.ts.
func tintColor(_ hex: String, _ k: Double) -> String {
    let c = CSSColor(hex)
    return "rgb(\((c.r + (255 - c.r) * k).rounded()),\((c.g + (255 - c.g) * k).rounded()),\((c.b + (255 - c.b) * k).rounded()))"
}

func shadeColor(_ hex: String, _ k: Double) -> String {
    let c = CSSColor(hex)
    return "rgb(\((c.r * (1 - k)).rounded()),\((c.g * (1 - k)).rounded()),\((c.b * (1 - k)).rounded()))"
}

/// Halo lumineux, comme drawGlow de src/art/pearl.ts.
func drawGlow(_ c: Canvas2D, _ x: Double, _ y: Double, _ rad: Double, _ color: String?, _ alpha: Double, _ additive: Bool = true) {
    guard let color, alpha > 0.001 else { return }
    let base = CSSColor(color)
    func rgba(_ a: Double) -> String { "rgba(\(base.r),\(base.g),\(base.b),\(a))" }
    c.save()
    c.globalCompositeOperation = additive ? "lighter" : "screen"
    let g = c.createRadialGradient(x, y, 0, x, y, rad)
    g.addColorStop(0, rgba(alpha))
    g.addColorStop(0.4, rgba(alpha * 0.35))
    g.addColorStop(1, rgba(0))
    c.fillStyle = g
    c.fillRect(x - rad, y - rad, rad * 2, rad * 2)
    c.restore()
}
