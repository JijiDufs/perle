import SwiftUI

/// Couleurs du lagon, reprises du prototype (src/art) et du site.
enum Lagoon {
    static let surface = Color(hex: 0x7FE3DC)
    static let shallow = Color(hex: 0x2FB7BD)
    static let deep    = Color(hex: 0x11808C)
    static let abyss   = Color(hex: 0x0B5F6C)
    static let seagrass = Color(hex: 0x6FB3A0)
    static let sand    = Color(hex: 0xC9C39A)
    static let wetSand = Color(hex: 0xA8A07A)
    static let pearl   = Color(hex: 0xF3F0EA)
    static let glow    = Color(hex: 0xFFF1D6)
}

/// Fond des écrans : le lagon du prototype (LagoonArt), animé. `dim` pose un voile d'eau profonde
/// (celui de la collection du prototype) pour les écrans pleins de texte.
struct LagoonBackground: View {
    var dim: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { context in
            let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let lagoon = LagoonArt(time: t, focus: .init(x: Double(size.width) / 2, y: Double(size.height) * 0.62,
                                                             size: Double(size.width) * 0.5), shadow: false)
                lagoon.draw(&ctx, size: size)
                lagoon.drawOverlay(&ctx, size: size)
                if dim > 0 { ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: 0x021218).opacity(dim))) }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// Icône de l'app : la perle qui luit dans le lagon (même dessin que le site).
struct PearlAppIcon: View {
    var size: CGFloat = 112

    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color(hex: 0x3CC4CC), location: 0),
                    .init(color: Color(hex: 0x0F6F7D), location: 0.5),
                    .init(color: Color(hex: 0x3F8F8A), location: 0.78),
                    .init(color: Color(hex: 0xD8C49B), location: 1),
                ],
                startPoint: .top, endPoint: .bottom
            )
            RadialGradient(colors: [Lagoon.glow.opacity(0.95), Lagoon.glow.opacity(0)],
                           center: UnitPoint(x: 0.5, y: 0.53), startRadius: 0, endRadius: size * 0.34)
            Circle()
                .fill(RadialGradient(
                    colors: [.white, Lagoon.pearl, Color(hex: 0x9C958D)],
                    center: UnitPoint(x: 0.36, y: 0.32), startRadius: 0, endRadius: size * 0.27))
                .frame(width: size * 0.35, height: size * 0.35)
                .offset(y: size * 0.033)
            Ellipse()
                .fill(.white.opacity(0.92))
                .frame(width: size * 0.1, height: size * 0.06)
                .rotationEffect(.degrees(-35))
                .offset(x: -size * 0.062, y: -size * 0.04)
            LinearGradient(colors: [.white.opacity(0.28), .clear], startPoint: .top, endPoint: .center)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.225, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
            .strokeBorder(.black.opacity(0.12), lineWidth: 0.8))
        .shadow(color: Color(hex: 0x0A3C46).opacity(0.3), radius: 18, y: 12)
        .accessibilityLabel("Icône de Pearl Inc.")
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
