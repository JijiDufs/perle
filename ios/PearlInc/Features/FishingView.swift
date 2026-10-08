import SwiftUI
import PearlCore

/// La Pêche : le lagon, l'huître, le geste. Remplit tout l'écran dans chaque pose (docs/duo-gadget.md §5).
struct FishingView: View {
    @Environment(GameModel.self) private var game
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LinearGradient(colors: [Palette.lagoonTop, Palette.lagoonMid, Palette.sand],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            TimelineView(.animation(paused: reduceMotion)) { timeline in
                Canvas { context, size in
                    art(time: timeline.date.timeIntervalSinceReferenceDate).draw(&context, size: size)
                }
            }
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { game.drag(translation: $0.translation.height) }
                    .onEnded { _ in game.endDrag() }
            )
            .accessibilityElement()
            .accessibilityLabel("Huître fermée")
            .accessibilityHint("Glisse le doigt vers le haut pour l'ouvrir doucement.")
            .accessibilityAction(named: "Ouvrir l'huître") { game.openForAccessibility() }

            VStack {
                Spacer()
                StatusPill(text: statusText, warning: game.tooFast)
                    .padding(.bottom, 24)
            }
            .allowsHitTesting(false)

            if case .card(let reveal) = game.stage {
                RevealCardView(reveal: reveal)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
                    .onTapGesture { withAnimation(.snappy) { game.nextOyster() } }
            }
        }
        .animation(.spring(duration: 0.45, bounce: 0.35), value: game.stage)
    }

    private var statusText: String {
        if game.stage != .playing { return " " }
        if game.cracked { return "Fêlée…" }
        if game.tooFast { return "Trop vite !" }
        if game.inFragileZone { return "Zone fragile : doucement" }
        if game.angle == 0 { return "Glisse vers le haut pour ouvrir" }
        return " "
    }

    private func art(time: Double) -> OysterArt {
        let pearl = game.pearl
        let isEmpty = pearl.id == "empty" && game.find == nil
        return OysterArt(
            angle: game.stage == .playing ? game.angle : 180,
            pearlColor: isEmpty ? nil : Color(hex: game.find?.glow ?? pearl.color),
            glowColor: game.glowHex.map { Color(hex: $0) },
            pearlRadiusRatio: 0.025 + max(game.player.oyster.sizeMm, 6) * 0.0028,
            cracked: game.cracked,
            trembles: game.trembles && !reduceMotion,
            revealed: game.stage != .playing,
            time: time
        )
    }
}

private struct StatusPill: View {
    let text: String
    let warning: Bool

    var body: some View {
        Text(text)
            .font(.headline)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .foregroundStyle(warning ? Color(hex: "#FF5A5F") : .white)
            .opacity(text == " " ? 0 : 1)
    }
}
