import SwiftUI
import PearlCore

/// Stock vide : « La marée remonte… », le compte à rebours, et de quoi continuer :
/// une pub récompensée, une huître contre de la poussière d'or, ou la boutique.
struct TideOutView: View {
    @Environment(GameModel.self) private var game
    @AppStorage(Notifications.settingKey) private var notify = false
    let date: Date
    /// Écran intérieur du Duo, à moitié ouvert : le panneau tient dans une moitié (rien sur le pli).
    private var compact: Bool { game.foldX != nil }

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
            Group {
                if compact { Text("Tu as \(game.player.dust) ✦") }
                else { Text("Tu as \(game.player.dust) ✦. Revends tes perles en double dans la collection, ou recharge tes huîtres dans la boutique.") }
            }
                .font(.footnote).multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.8))
            // Le bon moment pour proposer la notification : le joueur attend ses huîtres.
            if notify {
                Label("Je te préviens quand la marée est haute", systemImage: "bell.fill")
                    .font(.footnote.weight(.semibold)).foregroundStyle(.white.opacity(0.85))
            } else {
                Button {
                    Task { notify = await Notifications.enable() }
                } label: {
                    Label("Me prévenir quand elles reviennent", systemImage: "bell")
                }
                .buttonStyle(GlassButtonStyle(compact: true))
            }
        }
        .environment(\.buttonLabelWraps, compact)
        .padding(compact ? 14 : 20)
        .frame(maxWidth: 340)
        .glassPanel(cornerRadius: 28, shade: 0.35)
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.2), radius: 2)
        .padding(.horizontal, compact ? 8 : 16)
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
                // Moitié d'écran du Duo : libellé court.
                if game.foldX != nil {
                    Label("Pub · + \(game.economy.rewardedAdOysters) huîtres", systemImage: "play.rectangle.fill")
                } else {
                    Label("Regarder une pub · + \(game.economy.rewardedAdOysters) huîtres", systemImage: "play.rectangle.fill")
                }
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
