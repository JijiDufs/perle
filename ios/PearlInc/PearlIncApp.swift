import SwiftUI

@main
struct PearlIncApp: App {
    @State private var game = GameModel()
    @StateObject private var auth = AuthViewModel()

    init() {
        Analytics.start()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                // Connexion d'abord (Apple, e-mail ou sans compte), puis le jeu.
                if auth.session != nil {
                    RootView()
                        .environment(game)
                        .environmentObject(auth)
                } else {
                    LoginView(auth: auth)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: auth.session != nil)
            // Chaque compte a sa partie (sur l'iPhone et sur le compte).
            .onChange(of: auth.session?.user.id) { _, user in game.useAccount(user) }
            .preferredColorScheme(.dark)
        }
    }
}

/// Onglets du système : sur l'iPhone Duo, ils passent tout seuls sur le côté (docs/duo-gadget.md §5).
struct RootView: View {
    @Environment(GameModel.self) private var game
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var game = game
        TabView(selection: $game.tab) {
            Tab("Pêche", systemImage: "drop.fill", value: GameModel.Tab.fishing) {
                FishingView()
            }
            // Apparaît avec le premier écrin (montée de niveau ou comptoir).
            if game.hasEcrins {
                Tab("Écrins", systemImage: "gift.fill", value: GameModel.Tab.ecrins) {
                    EcrinView()
                }
                .badge(game.ecrinsToOpen)
            }
            Tab("Collection", systemImage: "square.grid.2x2.fill", value: GameModel.Tab.collection) {
                CollectionView()
            }
            Tab("Boutique", systemImage: "sparkles", value: GameModel.Tab.shop) {
                ShopView()
            }
        }
        .tint(Palette.gold)
        #if DEBUG
        // Outil de test : par-dessus la carte, pour essayer « refermer = huître (ou écrin) suivant ».
        .overlay(alignment: .bottom) {
            if SimulatedHingeSlider.isEnabled {
                SimulatedHingeSlider { game.hingeChanged(degrees: $0) }
                    .padding(.horizontal, 24).padding(.bottom, 96)
            }
        }
        #endif
        // iPhone Duo : ouvrir le téléphone ouvre l'huître (ou l'écrin), le refermer passe au suivant.
        .hingeInput({ game.hingeChanged(degrees: $0) }, fold: { if !HingeInput.simulatedFold { game.foldChanged(x: $0) } })
        .fullScreenCover(isPresented: Binding(get: { game.ads.isShowing }, set: { if !$0 && game.ads.isShowing { game.ads.finish(rewarded: false) } })) {
            SimulatedAdView(ads: game.ads)
        }
        // Le calendrier de connexion s'il y a une case à récupérer aujourd'hui. Le formulaire de consentement de Google
        // attend la première pub (marée basse, boutique) : il ne coupe plus la première huître (audit P0-7).
        .task {
            game.audio.start()
            await game.cloud.sync()
            await game.checkSignupGift()
            await game.ads.startIfConsentKnown()
            offerCalendar()
        }
        // « Tes huîtres sont revenues » : programmée en partant, retirée en revenant.
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                game.cloud.flush()
                game.scheduleRefillNotification()
                game.audio.stop()
            }
            if phase == .active {
                game.audio.start()
                Notifications.cancel()
                game.refresh()
                offerCalendar()
                Task {
                    await game.cloud.sync()
                    await game.checkSignupGift()
                }
            }
        }
        .sheet(isPresented: Binding(get: { game.showingCalendar }, set: { game.showingCalendar = $0 })) { CalendarView() }
        // Pas pendant les premières minutes ni pendant une ouverture : au prochain moment calme.
        .alert("Merci d’avoir été là dès le début", isPresented: Binding(get: { game.signupThanks && game.stage == .playing && !game.inTutorial },
                                                                         set: { if !$0 { game.signupThanks = false } })) {
            Button("L’équiper") { if let skin = game.economy.skins.first(where: { $0.grant == "signup" }) { game.equip(skin.id) } }
            Button("OK", role: .cancel) {}
        } message: {
            Text("La coquille Première marée est à toi. Tu la retrouves dans la Boutique.")
        }
        .alert("Deux parties sur ce compte", isPresented: Binding(get: { game.cloud.setAside != nil }, set: { if !$0 { game.cloud.setAside = nil } }),
               presenting: game.cloud.setAside) { _ in
            Button("Garder celle-ci", role: .cancel) {}
            Button("Reprendre l’autre") { game.swapSetAside() }
        } message: { aside in
            Text("On a gardé la plus avancée, ou la plus récente à égalité (\(aside.keptOysters) huîtres ouvertes). L’autre (\(aside.otherOysters) huîtres) est mise de côté sur cet iPhone : tu peux la reprendre maintenant.")
        }
        // Déconnexion : retour à l'écran de connexion, sans musique.
        .onDisappear { game.audio.stop() }
    }

    private func offerCalendar() {
        #if DEBUG
        // Outil de test (`-ShowCalendar`) : ouvrir le calendrier à chaque lancement.
        if ProcessInfo.processInfo.arguments.contains("-ShowCalendar") { game.showingCalendar = true; return }
        #endif
        guard game.shouldOfferCalendar else { return }
        game.calendarOffered()
        game.showingCalendar = true
    }
}
