import SwiftUI
import PearlCore

/// Stock vide : « La marée remonte… », le compte à rebours, et de quoi continuer :
/// une pub récompensée, une huître contre de la poussière d'or, ou la boutique.
struct TideOutView: View {
    @Environment(GameModel.self) private var game
    let date: Date

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "water.waves").font(.system(size: 44)).foregroundStyle(.white.opacity(0.9))
            Text("La marée remonte…").font(.title2.weight(.bold))
            if let next = game.nextOysterIn(at: date) {
                Text("Prochaine huître dans \(GameText.countdown(next))").font(.headline.monospacedDigit()).foregroundStyle(.white.opacity(0.85))
            }
            AdRewardButton(date: date)
            Button {
                game.buyOyster()
            } label: {
                Text("Une huître pour \(game.economy.oysterDustPrice) ✦")
            }
            .buttonStyle(GlassButtonStyle())
            .disabled(game.player.dust < game.economy.oysterDustPrice)
            Text("Tu as \(game.player.dust) ✦. Revends tes perles en double dans la collection, ou recharge tes huîtres dans la boutique.")
                .font(.footnote).multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.8))
        }
        .padding(24)
        .frame(maxWidth: 340)
        .glassPanel(cornerRadius: 28, shade: 0.35)
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.2), radius: 2)
        .padding(.horizontal, 24)
    }
}

/// « Regarder une pub · + 3 huîtres », avec ce qu'il reste aujourd'hui.
struct AdRewardButton: View {
    @Environment(GameModel.self) private var game
    let date: Date

    var body: some View {
        let left = game.adRewardsLeft(at: date)
        VStack(spacing: 4) {
            Button {
                game.watchAd()
            } label: {
                Label("Regarder une pub · + \(game.economy.rewardedAdOysters) huîtres", systemImage: "play.rectangle.fill")
            }
            .buttonStyle(PearlButtonStyle())
            .disabled(left == 0 || !game.ads.canShow)
            Group {
                if left == 0 {
                    Text("Plus de pub aujourd’hui : reviens demain")
                } else if game.ads.canShow {
                    Text("Encore \(left) aujourd’hui")
                } else {
                    Text("Pub en préparation…")
                }
            }
            .font(.caption).foregroundStyle(.white.opacity(0.75))
        }
    }
}
