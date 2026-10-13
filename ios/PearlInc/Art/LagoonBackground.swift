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

/// Fond : eau turquoise qui descend vers le sable, avec des rayons de lumière qui ondulent.
struct LagoonBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    stops: [
                        .init(color: Lagoon.surface, location: 0.00),
                        .init(color: Lagoon.shallow, location: 0.14),
                        .init(color: Lagoon.deep,    location: 0.42),
                        .init(color: Lagoon.abyss,   location: 0.62),
                        .init(color: Lagoon.deep,    location: 0.70),
                        .init(color: Lagoon.seagrass, location: 0.82),
                        .init(color: Lagoon.sand,    location: 0.94),
                        .init(color: Lagoon.wetSand, location: 1.00),
                    ],
                    startPoint: .top, endPoint: .bottom
                )

                TimelineView(.animation(paused: reduceMotion)) { context in
                    let t = context.date.timeIntervalSinceReferenceDate
                    Canvas { ctx, size in
                        drawRays(in: &ctx, size: size, time: reduceMotion ? 0 : t)
                    }
                }
                .blendMode(.plusLighter)
                .allowsHitTesting(false)

                // Vignette douce, comme sous l'eau.
                RadialGradient(
                    colors: [.clear, Color(hex: 0x00141E).opacity(0.45)],
                    center: .center,
                    startRadius: geo.size.width * 0.35,
                    endRadius: geo.size.height * 0.75
                )
            }
        }
        .ignoresSafeArea()
    }

    private func drawRays(in ctx: inout GraphicsContext, size: CGSize, time: Double) {
        let depth = size.height * 0.62
        for i in 0..<6 {
            let d = Double(i)
            let sway = sin(time * 0.25 + d * 1.9) * size.width * 0.04
            let x = size.width * (0.02 + d * 0.19) + sway
            let top = size.width * (0.035 + 0.02 * sin(d * 3.1))
            let spread = size.width * (0.12 + 0.05 * sin(d * 2.3))
            let slant = size.width * 0.16
            let alpha = 0.08 + 0.05 * sin(time * 0.6 + d * 2.1)

            var path = Path()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x + top, y: 0))
            path.addLine(to: CGPoint(x: x + top + slant + spread, y: depth))
            path.addLine(to: CGPoint(x: x + slant - spread * 0.2, y: depth))
            path.closeSubpath()

            ctx.fill(path, with: .linearGradient(
                Gradient(colors: [
                    Color(red: 1, green: 1, blue: 0.88).opacity(alpha),
                    Color(red: 0.86, green: 1, blue: 0.94).opacity(alpha * 0.45),
                    .clear,
                ]),
                startPoint: .zero, endPoint: CGPoint(x: 0, y: depth)
            ))
        }
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
