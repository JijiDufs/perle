import SwiftUI

@main
struct PearlIncApp: App {
    @State private var game = GameModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(game)
                .preferredColorScheme(.dark)
        }
    }
}

/// Onglets du système : sur l'iPhone Duo, ils passent tout seuls sur le côté (docs/duo-gadget.md §5).
struct RootView: View {
    var body: some View {
        TabView {
            Tab("Pêche", systemImage: "drop.fill") {
                FishingView()
            }
            Tab("Collection", systemImage: "square.grid.2x2.fill") {
                CollectionView()
            }
        }
        .tint(Palette.gold)
    }
}
