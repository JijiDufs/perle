import SwiftUI

@main
struct PearlIncApp: App {
    @State private var game = GameModel()
    @StateObject private var auth = AuthViewModel()

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
            .preferredColorScheme(.dark)
        }
    }
}

/// Onglets du système : sur l'iPhone Duo, ils passent tout seuls sur le côté (docs/duo-gadget.md §5).
struct RootView: View {
    @Environment(GameModel.self) private var game
    @Environment(\.scenePhase) private var scenePhase
    @State private var showCalendar = false

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
        // Consentement RGPD (formulaire de Google si besoin), puis première pub récompensée,
        // puis le calendrier de connexion s'il y a une case à récupérer aujourd'hui.
        .task {
            game.audio.start()
            await game.ads.start()
            offerCalendar()
        }
        // « Tes huîtres sont revenues » : programmée en partant, retirée en revenant.
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                game.scheduleRefillNotification()
                game.audio.stop()
            }
            if phase == .active {
                game.audio.start()
                Notifications.cancel()
                game.refresh()
                // Au lancement, le formulaire de consentement de Google passe d'abord (la tâche ci-dessus) :
                // sinon il s'ouvrirait par-dessus le calendrier.
                if game.ads.consentAnswered { offerCalendar() }
            }
        }
        .sheet(isPresented: $showCalendar) { CalendarView() }
        // Déconnexion : retour à l'écran de connexion, sans musique.
        .onDisappear { game.audio.stop() }
    }

    private func offerCalendar() {
        #if DEBUG
        // Outil de test (`-ShowCalendar`) : ouvrir le calendrier à chaque lancement.
        if ProcessInfo.processInfo.arguments.contains("-ShowCalendar") { showCalendar = true; return }
        #endif
        guard game.shouldOfferCalendar else { return }
        game.calendarOffered()
        showCalendar = true
    }
}
