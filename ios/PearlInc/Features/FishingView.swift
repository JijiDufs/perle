import SwiftUI
import PearlCore

/// La Pêche : le lagon, l'huître, le geste. Remplit tout l'écran dans chaque pose (docs/duo-gadget.md §5).
struct FishingView: View {
    @Environment(GameModel.self) private var game
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var showMissions = false
    @State private var showSettings = false

    var body: some View {
        ZStack {
            // Le lagon et l'huître dans la même scène, comme dans le prototype : l'horizon et l'ombre suivent l'huître.
            TimelineView(.animation(paused: reduceMotion && game.stage == .playing)) { timeline in
                Canvas { context, size in
                    let oyster = art(at: timeline.date)
                    let layout = OysterArt.layout(size: size, look: oyster.look, pose: oyster.pose)
                    let lagoon = LagoonArt(time: reduceMotion ? 0 : oyster.time, focus: layout.focus)
                    lagoon.draw(&context, size: size)
                    oyster.draw(&context, size: size)
                    lagoon.drawOverlay(&context, size: size)
                    oyster.drawRevealEffects(&context, size: size)
                }
            }
            .ignoresSafeArea()
            // Outil de test (`-SimulatedFold`) : un pli au milieu de l'écran, comme l'écran intérieur du Duo.
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width in
                if HingeInput.simulatedFold { game.foldChanged(x: width / 2) }
            }
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

            // Premières minutes : la main fantôme montre le geste sur la toute première huître.
            if showsGhostHand {
                GeometryReader { proxy in
                    let layout = OysterArt.layout(size: proxy.size, look: SkinLook(skinId: game.player.equippedSkin))
                    GhostHand(travel: min(170, layout.L * 0.75))
                        .position(x: layout.hx, y: layout.hy + layout.L * 0.1)
                }
                .ignoresSafeArea()
                .transition(.opacity)
            }

            VStack(spacing: 14) {
                ResourceBar(showMissions: $showMissions, showSettings: $showSettings)
                    .padding(.horizontal)
                    .padding(.top, 8)
                VStack(spacing: 14) {
                    if let coach = coachText {
                        CoachBubble(text: coach)
                            .padding(.horizontal, 24)
                    }
                    Spacer()
                    StatusPill(text: statusText, warning: game.tooFast)
                        .padding(.bottom, 24)
                }
                .besideFold(game.foldX)
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
                    .besideFold(game.foldX)
                    .transition(.scale(scale: 0.3).combined(with: .opacity))
                    .onTapGesture { withAnimation(.snappy) { game.nextOyster() } }
            }
        }
        .animation(.spring(duration: 0.45, bounce: 0.35), value: game.stage)
        .animation(.easeInOut(duration: 0.3), value: coachText)
        .animation(.easeInOut(duration: 0.3), value: showsGhostHand)
        // Pendant le tutoriel, rien que l'huître : les onglets arrivent avec la première huître libre.
        .toolbar(game.inTutorial ? .hidden : .visible, for: .tabBar)
        .animation(.easeInOut(duration: 0.4), value: game.inTutorial)
        #if DEBUG
        // Outil de test : par-dessus la carte, pour essayer « refermer = huître suivante ».
        .overlay(alignment: .bottom) {
            if SimulatedHingeSlider.isEnabled {
                SimulatedHingeSlider { game.hingeChanged(degrees: $0) }
                    .padding(.horizontal, 24).padding(.bottom, 96)
            }
        }
        #endif
        // iPhone Duo : ouvrir le téléphone ouvre l'huître, le refermer passe à la suivante.
        .hingeInput({ game.hingeChanged(degrees: $0) }, fold: { if !HingeInput.simulatedFold { game.foldChanged(x: $0) } })
        .sheet(isPresented: $showMissions) { MissionsView() }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .onChange(of: scenePhase) { _, phase in if phase == .active { game.refresh() } }
        .task {
            // Recharge du stock et changement de jour, même si l'app reste ouverte.
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                game.refresh()
            }
        }
    }

    /// La bulle d'accompagnement des premières huîtres ; nil = rien à dire.
    private var coachText: String? {
        guard game.stage == .playing, !game.cracked else { return nil }
        return Coach.duringGesture(step: game.step, phase: game.phase, hinge: game.hasHinge, hingeArmed: game.hingeArmed, tuning: game.tuning)
    }

    private var showsGhostHand: Bool {
        game.step == 0 && game.stage == .playing && game.phase == .closed && game.angle == 0 && !game.hasHinge
    }

    /// Le message sous l'huître ; nil = rien à dire.
    private var statusText: String? {
        if game.stage != .playing { return nil }
        if game.cracked { return String(localized: "Fêlée…") }
        if game.tooFast { return String(localized: "Trop vite !") }
        if game.inFragileZone { return String(localized: "Zone fragile : doucement") }
        // La bulle d'accompagnement dit déjà quoi faire.
        if coachText != nil { return nil }
        if game.angle == 0 && game.isTideOut(at: Date()) { return nil }
        if game.angle == 0 {
            if game.hasHinge {
                return game.hingeArmed ? String(localized: "Ouvre le téléphone doucement") : String(localized: "Referme le téléphone, puis ouvre-le")
            }
            return String(localized: "Glisse vers le haut pour ouvrir")
        }
        return nil
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
            shapeSeed: game.shapeSeed,
            pose: pose
        )
    }

    /// Au pouce, l'huître est vue de dessus, charnière en haut. Sur l'iPhone Duo, elle est couchée comme
    /// sur pearl-inc.app : charnière au bord gauche de l'écran extérieur, puis sur le pli de l'écran intérieur.
    private var pose: OysterArt.Pose {
        guard game.hasHinge || game.foldX != nil else { return .thumb }
        if let x = game.foldX { return .fold(x: x) }
        return .cover
    }
}

private struct StatusPill: View {
    let text: String?
    let warning: Bool

    var body: some View {
        Text(text ?? " ")
            .font(.headline)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .glass(Capsule())
            .foregroundStyle(warning ? Color(hex: "#FF5A5F") : .white)
            .opacity(text == nil ? 0 : 1)
    }
}

extension View {
    /// Écran intérieur du Duo : rien sur le pli (docs/duo-gadget.md §5). La vue se centre sur la moitié
    /// droite, celle de la perle. `foldX` : abscisse du pli dans la fenêtre ; nil = toute la largeur.
    func besideFold(_ foldX: Double?) -> some View {
        modifier(BesideFold(foldX: foldX))
    }
}

private struct BesideFold: ViewModifier {
    let foldX: Double?

    func body(content: Content) -> some View {
        if let foldX {
            GeometryReader { proxy in
                let frame = proxy.frame(in: .global)
                let left = min(max(0, foldX - frame.minX), frame.width)
                content
                    .frame(width: max(0, frame.width - left))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            }
        } else {
            content
        }
    }
}
