import SwiftUI
import PearlCore

/// Stock vide : « La marée remonte… », le compte à rebours, et une huître contre de la poussière d'or.
struct TideOutView: View {
    @Environment(GameModel.self) private var game
    let date: Date

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "water.waves").font(.system(size: 44)).foregroundStyle(.white.opacity(0.9))
            Text("La marée remonte…").font(.title2.weight(.bold))
            if let next = game.nextOysterIn(at: date) {
                Text("Prochaine huître dans \(Clock.countdown(next))").font(.headline.monospacedDigit()).foregroundStyle(.white.opacity(0.8))
            }
            Button {
                game.buyOyster()
            } label: {
                Text("Une huître pour \(game.economy.oysterDustPrice) ✦").frame(maxWidth: .infinity)
            }
            .buttonStyle(PearlButtonStyle())
            .disabled(game.player.dust < game.economy.oysterDustPrice)
            Text("Tu as \(game.player.dust) ✦. Revends tes perles en double dans la collection.")
                .font(.footnote).multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.7))
        }
        .padding(24)
        .frame(maxWidth: 320)
        .glassPanel(cornerRadius: 28, shade: 0.3)
        .foregroundStyle(.white)
        .padding(.horizontal, 24)
    }
}
