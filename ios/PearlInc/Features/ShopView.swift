import SwiftUI
import PearlCore

/// La boutique : les skins d'huître (poussière d'or ou achat), et une huître contre de la poussière d'or.
/// Les achats intégrés d'Apple (StoreKit 2) arrivent dans une prochaine passe : leurs boutons sont désactivés.
struct ShopView: View {
    @Environment(GameModel.self) private var game
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("Coquilles").font(.title3.weight(.bold))
                        Spacer()
                        Text("✦ \(game.player.dust)").font(.headline.monospacedDigit()).foregroundStyle(Palette.gold)
                    }
                    Text("Purement cosmétiques : elles ne changent ni les perles ni les chances.")
                        .font(.footnote).foregroundStyle(.white.opacity(0.6))

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(game.economy.skins) { skin in
                            SkinCard(skin: skin)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Huîtres").font(.title3.weight(.bold))
                        Button {
                            game.buyOyster()
                        } label: {
                            Text("Une huître · \(game.economy.oysterDustPrice) ✦").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Palette.gold)
                        .disabled(game.player.dust < game.economy.oysterDustPrice)
                        ForEach(game.economy.consumables) { product in
                            HStack {
                                Text(product.name)
                                Spacer()
                                Text(product.oysters > 0 ? "\(product.oysters) huîtres" : "\(product.dust) ✦").foregroundStyle(.white.opacity(0.6))
                            }
                            .font(.subheadline)
                        }
                        Text("Achats intégrés : prochaine étape.").font(.footnote).foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding()
            }
            .background(Palette.night.ignoresSafeArea())
            .navigationTitle("Boutique")
        }
    }
}

private struct SkinCard: View {
    @Environment(GameModel.self) private var game
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let skin: AppSkin

    var body: some View {
        let owned = game.player.ownedSkins.contains(skin.id)
        let equipped = game.player.equippedSkin == skin.id
        VStack(spacing: 10) {
            TimelineView(.animation(paused: reduceMotion || skin.id != "or")) { timeline in
                Canvas { context, size in
                    OysterArt(angle: 0, pearl: nil, glowColor: nil, sizeMm: 0, cracked: false, trembles: false, revealed: false,
                              time: timeline.date.timeIntervalSinceReferenceDate, look: SkinLook(skinId: skin.id),
                              length: min(size.width * 0.42, size.height * 0.62)).draw(&context, size: size)
                }
            }
            .frame(height: 120)
            .background(LinearGradient(colors: [Palette.lagoonTop, Palette.lagoonMid, Palette.sand], startPoint: .top, endPoint: .bottom))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .accessibilityHidden(true)

            Text(skin.name).font(.subheadline.weight(.bold))
            action(owned: owned, equipped: equipped)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(equipped ? Palette.gold : .clear, lineWidth: 2))
        )
    }

    @ViewBuilder private func action(owned: Bool, equipped: Bool) -> some View {
        if equipped {
            Label("Équipée", systemImage: "checkmark").font(.caption.weight(.semibold)).foregroundStyle(Palette.gold)
        } else if owned {
            Button("Équiper") { game.equip(skin.id) }.buttonStyle(.bordered).tint(Palette.gold).font(.caption.weight(.semibold))
        } else if let price = skin.dustPrice {
            VStack(spacing: 4) {
                Button("\(price) ✦") { game.buySkin(skin.id) }
                    .buttonStyle(.borderedProminent).tint(Palette.gold).font(.caption.weight(.semibold))
                    .disabled(game.player.dust < price)
                if skin.productId != nil { Text("ou en achat (bientôt)").font(.caption2).foregroundStyle(.white.opacity(0.5)) }
            }
        } else if skin.grant == "signup" {
            Text("Réservée aux inscrits").font(.caption).foregroundStyle(.white.opacity(0.6))
        } else {
            Text("En achat (bientôt)").font(.caption).foregroundStyle(.white.opacity(0.6))
        }
    }
}
