import SwiftUI
import PearlCore

/// La Pêche : le lagon, l'huître, le geste. Remplit tout l'écran dans chaque pose (docs/duo-gadget.md §5).
struct FishingView: View {
    @Environment(GameModel.self) private var game
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var showMissions = false
    @State private var showSettings = false
    /// « Ma progression » (toucher l'anneau de niveau).
    @State private var showProgress = false
    /// La bulle sur le stock (première huître après le tutoriel) s'efface toute seule.
    @State private var stockTipExpired = false
    /// Taille de la scène, pour savoir si le doigt touche le poisson voleur.
    @State private var sceneSize = CGSize.zero

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
                    if let fish = thief(at: timeline.date, size: size, oyster: oyster, layout: layout) {
                        fish.draw(&context, pearl: oyster.pearl, pearlRadius: oyster.pearlRadius(layout.L), glow: oyster.glowColor)
                    }
                }
            }
            .ignoresSafeArea()
            .onGeometryChange(for: CGSize.self) { $0.size } action: { sceneSize = $0 }
            // Outil de test (`-SimulatedFold`) : un pli au milieu de l'écran, comme l'écran intérieur du Duo.
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width in
                if HingeInput.simulatedFold { game.foldChanged(x: width / 2) }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if case .theft = game.stage { tryToCatch(at: value.location) } else { game.drag(translation: value.translation.height) }
                    }
                    .onEnded { _ in game.endDrag() }
            )
            .accessibilityElement()
            .accessibilityLabel("Huître fermée")
            .accessibilityHint("Glisse le doigt vers le haut pour l'ouvrir doucement.")
            .accessibilityAction(named: "Ouvrir l'huître") { game.openForAccessibility() }
            .accessibilityAction(named: "Attraper le poisson") { game.catchFish() }

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
                ResourceBar(showMissions: $showMissions, showSettings: $showSettings, showProgress: $showProgress)
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
                        .besideFold(game.foldX)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }

            if case .theft = game.stage {
                VStack {
                    CoachBubble(text: String(localized: "Un poisson ! Touche-le vite pour récupérer ta perle"))
                        .padding(.horizontal, 24)
                        .padding(.top, 70)
                    Spacer()
                }
                .besideFold(game.foldX)
                .allowsHitTesting(false)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            if case .stolen(let reveal) = game.stage {
                Color(hex: 0x02141A).opacity(0.3).ignoresSafeArea()
                    .transition(.opacity)
                    .allowsHitTesting(false)
                StolenView(reveal: reveal)
                    .besideFold(game.foldX)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
                    .onTapGesture { withAnimation(.snappy) { game.nextOyster() } }
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

            // Montée de niveau : au moment calme suivant (huître posée, hors tutoriel).
            if let levelUp = game.levelUpToShow {
                Color(hex: 0x02141A).opacity(0.45).ignoresSafeArea()
                    .transition(.opacity)
                LevelUpView(levelUp: levelUp)
                    .besideFold(game.foldX)
                    .transition(reduceMotion ? .opacity : .scale(scale: 0.5).combined(with: .opacity))
            }

            if showProgress {
                Color(hex: 0x02141A).opacity(0.35).ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture { showProgress = false }
                    .accessibilityHidden(true)
                ProgressPanel(close: { showProgress = false })
                    .besideFold(game.foldX)
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(.spring(duration: 0.45, bounce: 0.35), value: game.stage)
        .animation(.spring(duration: 0.5, bounce: 0.3), value: game.levelUpToShow)
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.4, bounce: 0.1), value: showProgress)
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
        .task(id: game.step) {
            stockTipExpired = false
            guard game.step == game.catalog.tutorialPearls.count else { return }
            try? await Task.sleep(for: .milliseconds(Int(game.tuning.coachTipMs)))
            stockTipExpired = true
        }
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
        // Marée basse : le panneau prend la place, la bulle passerait dessous.
        guard game.stage == .playing, !game.cracked, !game.isTideOut(at: Date()) else { return nil }
        if stockTipExpired && game.step == game.catalog.tutorialPearls.count { return nil }
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

    /// Le poisson voleur, pendant qu'il emporte la perle.
    private func thief(at date: Date, size: CGSize, oyster: OysterArt, layout: OysterArt.Layout) -> ThiefFishArt? {
        guard let elapsed = game.theftElapsedMs(at: date) else { return nil }
        let fish = game.fishThief
        return ThiefFishArt(elapsedMs: elapsed, arriveMs: fish.arriveMs, fleeMs: fish.fleeMs, target: layout.pearlCenter, L: layout.L,
                            size: size, fromLeft: game.shapeSeed % 2 == 0, time: date.timeIntervalSinceReferenceDate)
    }

    /// Le doigt touche-t-il le poisson ? (Le Core décide s'il est encore temps.)
    private func tryToCatch(at point: CGPoint) {
        let date = Date()
        let oyster = art(at: date)
        let layout = OysterArt.layout(size: sceneSize, look: oyster.look, pose: oyster.pose)
        guard let fish = thief(at: date, size: sceneSize, oyster: oyster, layout: layout) else { return }
        let center = fish.position(at: fish.elapsedMs)
        if hypot(point.x - center.x, point.y - center.y) <= fish.length * 0.5 + layout.L * game.fishThief.hitRadius {
            withAnimation(.spring(duration: 0.45, bounce: 0.35)) { game.catchFish() }
        }
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
            pose: pose,
            pearlTaken: game.pearlTaken(at: date)
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
