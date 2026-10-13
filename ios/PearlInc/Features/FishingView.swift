import SwiftUI
import PearlCore

/// La Pêche : le lagon, l'huître, le geste. Remplit tout l'écran dans chaque pose (docs/duo-gadget.md §5).
struct FishingView: View {
    @Environment(GameModel.self) private var game
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var showMissions = false

    var body: some View {
        ZStack {
            // Le lagon et l'huître dans la même scène, comme dans le prototype : l'horizon et l'ombre suivent l'huître.
            TimelineView(.animation(paused: reduceMotion && game.stage == .playing)) { timeline in
                Canvas { context, size in
                    let oyster = art(at: timeline.date)
                    let layout = OysterArt.layout(size: size, look: oyster.look)
                    let lagoon = LagoonArt(time: reduceMotion ? 0 : oyster.time, focus: .init(x: layout.hx, y: layout.hy, size: layout.L))
                    lagoon.draw(&context, size: size)
                    oyster.draw(&context, size: size)
                    lagoon.drawOverlay(&context, size: size)
                    oyster.drawRevealEffects(&context, size: size)
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
                ResourceBar(showMissions: $showMissions)
                    .padding(.horizontal)
                    .padding(.top, 8)
                Spacer()
                StatusPill(text: statusText, warning: game.tooFast)
                    .padding(.bottom, 24)
                    .allowsHitTesting(false)
            }

            TimelineView(.periodic(from: .now, by: 1)) { timeline in
                if game.isTideOut(at: timeline.date) {
                    TideOutView(date: timeline.date)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }

            if case .card(let reveal) = game.stage {
                Color(hex: 0x02141A).opacity(0.3).ignoresSafeArea()
                    .transition(.opacity)
                    .allowsHitTesting(false)
                RevealCardView(reveal: reveal)
                    .transition(.scale(scale: 0.3).combined(with: .opacity))
                    .onTapGesture { withAnimation(.snappy) { game.nextOyster() } }
            }
        }
        .animation(.spring(duration: 0.45, bounce: 0.35), value: game.stage)
        .sheet(isPresented: $showMissions) { MissionsView() }
        .onChange(of: scenePhase) { _, phase in if phase == .active { game.refresh() } }
        .task {
            // Recharge du stock et changement de jour, même si l'app reste ouverte.
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                game.refresh()
            }
        }
    }

    private var statusText: String {
        if game.stage != .playing { return " " }
        if game.cracked { return "Fêlée…" }
        if game.tooFast { return "Trop vite !" }
        if game.inFragileZone { return "Zone fragile : doucement" }
        if game.angle == 0 && game.isTideOut(at: Date()) { return " " }
        if game.angle == 0 { return "Glisse vers le haut pour ouvrir" }
        return " "
    }

    private func art(at date: Date) -> OysterArt {
        let oyster = game.current
        let look: PearlLook? = if game.find != nil || oyster.pearlId == "empty" { nil }
            else { PearlLook(game.pearl, traits: oyster.traits, catalog: game.catalog) }
        let progress = game.revealProgress(at: date)
        return OysterArt(
            angle: game.stage == .playing ? game.angle : progress.lidAngle,
            pearl: look,
            glowColor: game.glowHex,
            sizeMm: oyster.sizeMm,
            findId: game.find?.id,
            revealTier: game.revealTier,
            cracked: game.cracked,
            trembles: game.trembles && !reduceMotion,
            revealed: game.stage != .playing,
            suspense: progress.suspense,
            flash: progress.flash,
            time: date.timeIntervalSinceReferenceDate,
            look: SkinLook(skinId: game.player.equippedSkin),
            shapeSeed: game.shapeSeed
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
            .glass(Capsule())
            .foregroundStyle(warning ? Color(hex: "#FF5A5F") : .white)
            .opacity(text == " " ? 0 : 1)
    }
}
