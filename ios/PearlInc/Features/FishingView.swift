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
                RevealCardView(reveal: reveal)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
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

    private func art(time: Double) -> OysterArt {
        let oyster = game.player.oyster
        let look: PearlLook? = if let find = game.find { PearlLook(find: find) }
            else if oyster.pearlId == "empty" { nil }
            else { PearlLook(game.pearl, traits: oyster.traits, catalog: game.catalog) }
        return OysterArt(
            angle: game.stage == .playing ? game.angle : 180,
            pearl: look,
            glowColor: game.glowHex,
            sizeMm: oyster.sizeMm,
            isFind: game.find != nil,
            revealTier: game.revealTier,
            cracked: game.cracked,
            trembles: game.trembles && !reduceMotion,
            revealed: game.stage != .playing,
            time: time,
            look: SkinLook(skinId: game.player.equippedSkin),
            shapeSeed: game.player.nextSerial
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
