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
    }
}
