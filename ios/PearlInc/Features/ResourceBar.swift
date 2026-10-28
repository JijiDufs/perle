import SwiftUI
import PearlCore

/// Barre du haut : niveau, huîtres (avec le minuteur de recharge), poussière d'or, missions du jour, réglages.
struct ResourceBar: View {
    @Environment(GameModel.self) private var game
    @Binding var showMissions: Bool
    @Binding var showSettings: Bool
    @Binding var showProgress: Bool

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            HStack(spacing: 6) {
                if !game.inTutorial { LevelRing { showProgress = true } }
                // Pendant le tutoriel, les huîtres sont offertes : les compteurs arrivent après.
                if !game.inTutorial { counters(at: timeline.date) }

                Spacer(minLength: 0)

                if !game.inTutorial {
                    Button { showMissions = true } label: {
                        Chip {
                            Image(systemName: "checklist")
                            if game.player.missions?.hasReward == true || game.canClaimDaily {
                                Circle().fill(Palette.gold).frame(width: 8, height: 8)
                            }
                        }
                    }
                    .accessibilityLabel("Missions du jour")
                }

                Button { showSettings = true } label: {
                    Chip { Image(systemName: "gearshape.fill") }
                }
                .accessibilityLabel("Réglages")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .animation(.easeInOut(duration: 0.4), value: game.inTutorial)
        }
    }

    @ViewBuilder
    private func counters(at date: Date) -> some View {
        Chip {
            Image(systemName: "drop.fill").foregroundStyle(Lagoon.surface)
            Text("\(game.oystersAvailable(at: date))").monospacedDigit()
            if let next = game.nextOysterIn(at: date) {
                Text(GameText.countdown(next)).font(.caption.monospacedDigit()).foregroundStyle(.white.opacity(0.65))
            }
        }
        // À sa largeur, sur une ligne : « 1,345 » et le minuteur passaient à la ligne quand la barre était pleine.
        .fixedSize()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(game.oystersAvailable(at: date)) huîtres")

        Chip {
            Text("✦").foregroundStyle(Palette.gold)
            // Abrégé au-delà de 10 000 (« 12K ») : la barre tient sur la largeur d'un iPhone, minuteur compris.
            Text(game.player.dust < 10_000 ? game.player.dust.formatted() : game.player.dust.formatted(.number.notation(.compactName)))
                .monospacedDigit()
        }
        .fixedSize()
        .phaseAnimator([1.0, 1.2, 1.0], trigger: game.dustBump) { content, scale in
            content.scaleEffect(scale)
        }
        .accessibilityLabel("\(game.player.dust) poussière d’or")
    }
}

private struct Chip<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        HStack(spacing: 6) { content }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .glass(Capsule())
    }
}
