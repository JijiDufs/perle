import SwiftUI

/// iPhone Duo, téléphone ouvert : le joueur choisit d'ouvrir ses huîtres avec la charnière ou au pouce.
/// Rien de bloquant : les deux gestes marchent pendant que les boutons sont là, et le premier geste vaut choix.
/// `tip` : la relance d'après le tutoriel pour qui a choisi le pouce (une seule fois).
struct DuoPlayChoice: View {
    @Environment(GameModel.self) private var game
    let tip: Bool

    var body: some View {
        VStack(spacing: 10) {
            if tip {
                caption(Text("Ton iPhone Duo peut ouvrir l’huître avec sa charnière."))
            } else if game.step > 0 {
                // Pendant la toute première huître, la bulle du tutoriel pose déjà la question.
                caption(Text("Comment veux-tu jouer ?"))
            }
            Button { withAnimation(.snappy) { game.chooseDuoPlay(hinge: true) } } label: {
                if tip { Text("Essayer la charnière") } else { Text("Jouer avec la charnière") }
            }
            .buttonStyle(PearlButtonStyle())
            Button { withAnimation(.snappy) { tip ? game.endDuoTip() : game.chooseDuoPlay(hinge: false) } } label: {
                if tip { Text("Non merci") } else { Text("Rester ouvert, jouer au pouce") }
            }
            .buttonStyle(GlassButtonStyle())
        }
        .padding(game.foldX == nil ? 16 : 10)
        .glassPanel()
        // À côté du pli, la moitié d'écran est étroite : le texte des boutons passe à la ligne.
        .environment(\.buttonLabelWraps, game.foldX != nil)
    }

    private func caption(_ text: Text) -> some View {
        text.font(.subheadline.weight(.semibold))
            .multilineTextAlignment(.center)
            .foregroundStyle(.white)
            .fixedSize(horizontal: false, vertical: true)
    }
}
