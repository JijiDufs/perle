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
        TabView {
            Tab("Pêche", systemImage: "drop.fill") {
                FishingView()
            }
            Tab("Collection", systemImage: "square.grid.2x2.fill") {
                CollectionView()
            }
            Tab("Boutique", systemImage: "sparkles") {
                ShopView()
            }
        }
        .tint(Palette.gold)
        .fullScreenCover(isPresented: Binding(get: { game.ads.isShowing }, set: { if !$0 && game.ads.isShowing { game.ads.finish(rewarded: false) } })) {
            SimulatedAdView(ads: game.ads)
        }
        // Consentement RGPD (formulaire de Google si besoin), puis première pub récompensée,
        // puis le calendrier de connexion s'il y a une case à récupérer aujourd'hui.
        .task {
            await game.ads.start()
            offerCalendar()
        }
        // « Tes huîtres sont revenues » : programmée en partant, retirée en revenant.
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { game.scheduleRefillNotification() }
            if phase == .active {
                Notifications.cancel()
                game.refresh()
                offerCalendar()
            }
        }
        .sheet(isPresented: $showCalendar) { CalendarView() }
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
