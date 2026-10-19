import SwiftUI
import PearlCore

/// Barre du haut : huîtres (avec le minuteur de recharge), poussière d'or, missions du jour, réglages.
struct ResourceBar: View {
    @Environment(GameModel.self) private var game
    @Binding var showMissions: Bool
    @Binding var showSettings: Bool

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            HStack(spacing: 10) {
                Chip {
                    Image(systemName: "drop.fill").foregroundStyle(Lagoon.surface)
                    Text("\(game.oystersAvailable(at: timeline.date))").monospacedDigit()
                    if let next = game.nextOysterIn(at: timeline.date) {
                        Text(GameText.countdown(next)).font(.caption.monospacedDigit()).foregroundStyle(.white.opacity(0.65))
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(game.oystersAvailable(at: timeline.date)) huîtres")

                Chip {
                    Text("✦").foregroundStyle(Palette.gold)
                    Text("\(game.player.dust)").monospacedDigit()
                }
                .phaseAnimator([1.0, 1.2, 1.0], trigger: game.dustBump) { content, scale in
                    content.scaleEffect(scale)
                }
                .accessibilityLabel("\(game.player.dust) poussière d’or")

                Spacer()

                Button { showMissions = true } label: {
                    Chip {
                        Image(systemName: "checklist")
                        if game.player.missions?.hasReward == true {
                            Circle().fill(Palette.gold).frame(width: 8, height: 8)
                        }
                    }
                }
                .accessibilityLabel("Missions du jour")

                Button { showSettings = true } label: {
                    Chip { Image(systemName: "gearshape.fill") }
                }
                .accessibilityLabel("Réglages")
            }
            .font(.headline)
            .foregroundStyle(.white)
        }
    }
}

private struct Chip<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        HStack(spacing: 6) { content }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .glass(Capsule())
    }
}
