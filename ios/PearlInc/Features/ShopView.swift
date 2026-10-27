import SwiftUI
import PearlCore

/// La boutique (docs/duo-gadget.md §6 bis, §6 ter) : huîtres (pub récompensée, poussière d'or, achats intégrés),
/// poussière d'or, écrins, coquilles. Les prix en euros viennent de StoreKit ; les probabilités sont rappelées
/// avant tout achat d'huîtres ou d'écrins (règle 3.1.1 d'Apple).
struct ShopView: View {
    @Environment(GameModel.self) private var game
    @State private var showOdds = false
    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(spacing: 6) {
                    Text("Boutique").font(.system(size: 34, weight: .bold)).tracking(-0.8)
                    Text("✦ \(game.player.dust) de poussière d’or").font(.headline.monospacedDigit()).foregroundStyle(Palette.gold)
                }
                .frame(maxWidth: .infinity)
                .shadow(color: .black.opacity(0.3), radius: 6)
                .padding(.top, 16)

                Text("Huîtres").lagoonTitle()
                VStack(spacing: 14) {
                    TimelineView(.periodic(from: .now, by: 60)) { timeline in AdRewardButton(date: timeline.date) }
                    ForEach(game.economy.consumables.filter { $0.oysters > 0 }) { product in
                        ProductRow(title: product.name, detail: String(localized: "\(product.oysters) huîtres"), productId: product.id)
                    }
                    Button("Une huître · \(game.economy.oysterDustPrice) ✦") { game.buyOyster() }
                        .buttonStyle(GlassButtonStyle())
                        .disabled(game.player.dust < game.economy.oysterDustPrice)
                    DisclosureGroup(isExpanded: $showOdds) {
                        OddsList().padding(.top, 10)
                    } label: {
                        Text("Chaque huître est un tirage : voir les probabilités").font(.footnote.weight(.semibold))
                    }
                    .tint(.white)
                }
                .padding(18)
                .glassPanel(shade: 0.25)

                Text("Écrins").lagoonTitle()
                VStack(spacing: 14) {
                    ForEach(game.economy.consumables.filter { $0.ecrins > 0 }) { product in
                        ProductRow(title: product.name, detail: String(localized: "\(product.ecrins) écrins"), productId: product.id)
                    }
                    Button("Un écrin · \(game.ecrinPrice) ✦") { game.buyEcrin() }
                        .buttonStyle(GlassButtonStyle())
                        .disabled(game.player.dust < game.ecrinPrice)
                    // Chaque écrin est un tirage : les probabilités restent affichées à côté des boutons (règle 3.1.1).
                    Text("Chaque écrin est un tirage : ce qu’il peut contenir").font(.footnote.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    EcrinOddsList()
                }
                .padding(18)
                .glassPanel(shade: 0.25)

                Text("Poussière d’or").lagoonTitle()
                VStack(spacing: 12) {
                    ForEach(game.economy.consumables.filter { $0.dust > 0 }) { product in
                        ProductRow(title: product.name, detail: "\(product.dust) ✦", productId: product.id)
                    }
                }
                .padding(18)
                .glassPanel(shade: 0.25)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Coquilles").lagoonTitle()
                    Text("Purement cosmétiques : elles ne changent ni les perles ni les chances.")
                        .font(.footnote).foregroundStyle(.white.opacity(0.75))
                }
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(game.economy.skins) { skin in SkinCard(skin: skin) }
                }

                VStack(spacing: 8) {
                    Button("Restaurer les achats") { game.restorePurchases() }
                        .buttonStyle(GlassButtonStyle())
                    Text("Paiement par ton compte Apple. Les coquilles achetées se restaurent sur un nouveau téléphone ; les huîtres, les écrins et la poussière d’or restent dans ta partie.")
                        .font(.caption).multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.6))
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .statusBarFade()
        .background(LagoonBackground(dim: 0.82))
    }
}

/// Un produit de la boutique Apple : nom, ce qu'il donne, prix StoreKit.
private struct ProductRow: View {
    @Environment(GameModel.self) private var game
    let title: String
    let detail: String
    let productId: String

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body.weight(.semibold))
                Text(detail).font(.subheadline).foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            PriceButton(productId: productId)
        }
    }
}

/// Le bouton d'achat : le prix vient de StoreKit (jamais écrit en dur).
private struct PriceButton: View {
    @Environment(GameModel.self) private var game
    let productId: String

    var body: some View {
        let price = game.store.price(productId)
        Button {
            game.purchase(productId)
        } label: {
            if game.store.purchasing == productId {
                ProgressView().tint(Lagoon.abyss)
            } else if let price {
                Text(price)
            } else {
                Text("Indisponible")
            }
        }
        .buttonStyle(PearlButtonStyle(compact: true))
        .disabled(price == nil || game.store.purchasing != nil)
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
            TimelineView(.animation(paused: reduceMotion)) { timeline in
                Canvas { context, size in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    let look = SkinLook(skinId: skin.id)
                    let length = min(Double(size.width) * 0.42, Double(size.height) * 0.62)
                    let layout = OysterArt.layout(size: size, look: look, length: length)
                    let lagoon = LagoonArt(time: t, focus: .init(x: layout.hx, y: layout.hy, size: layout.L))
                    lagoon.draw(&context, size: size)
                    OysterArt(angle: 0, pearl: nil, glowColor: nil, sizeMm: 0, cracked: false, trembles: false, revealed: false,
                              time: t, look: look, length: length).draw(&context, size: size)
                    lagoon.drawOverlay(&context, size: size)
                }
            }
            .frame(height: 124)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .accessibilityHidden(true)

            Text(skin.name).font(.subheadline.weight(.bold))
            action(owned: owned, equipped: equipped)
        }
        .padding(10)
        .glassPanel(cornerRadius: 22, rim: equipped ? Palette.gold : nil, shade: 0.25)
    }

    @ViewBuilder private func action(owned: Bool, equipped: Bool) -> some View {
        if equipped {
            Label("Équipée", systemImage: "checkmark").font(.caption.weight(.semibold)).foregroundStyle(Palette.gold).frame(minHeight: 36)
        } else if owned {
            Button("Équiper") { game.equip(skin.id) }.buttonStyle(GlassButtonStyle(compact: true))
        } else if skin.dustPrice != nil || skin.productId != nil {
            VStack(spacing: 6) {
                if let productId = skin.productId { PriceButton(productId: productId) }
                if let price = skin.dustPrice {
                    Button("\(price) ✦") { game.buySkin(skin.id) }
                        .buttonStyle(GlassButtonStyle(compact: true))
                        .disabled(game.player.dust < price)
                }
            }
        } else if skin.grant == "signup" {
            Text("Réservée aux inscrits").font(.caption).foregroundStyle(.white.opacity(0.7)).frame(minHeight: 36)
        }
    }
}
