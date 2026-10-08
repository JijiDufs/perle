import SwiftUI
import PearlCore

/// La collection : le comptoir (revente des doublons), l'encyclopédie des perles (nombre pair de colonnes,
/// pour se couper proprement au pli du Duo), puis les dernières cartes et les trouvailles.
struct CollectionView: View {
    @Environment(GameModel.self) private var game
    @State private var confirmSellAll = false
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    counter

                    Text("\(discovered) / \(findable.count) perles découvertes")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(findable) { pearl in
                            EncyclopediaCell(
                                pearl: pearl,
                                count: game.player.count(of: pearl.id),
                                price: game.catalog.missingPearlPrice(pearl.id),
                                dust: game.player.dust
                            ) { game.buyMissingPearl(pearl.id) }
                        }
                    }

                    if !game.player.findCards.isEmpty {
                        Text("Trouvailles").font(.title3.weight(.bold))
                        ForEach(game.player.findCards.reversed()) { card in
                            let find = game.catalog.find(card.findId)
                            HStack {
                                PearlDot(color: Color(hex: find.glow), glow: nil, size: 28)
                                Text(find.name)
                                Spacer()
                                Text(serialLabel(card.serial)).font(.caption.monospaced()).foregroundStyle(.white.opacity(0.5))
                            }
                        }
                    }

                    if !game.player.pearlCards.isEmpty {
                        Text("Mes perles").font(.title3.weight(.bold))
                        Text("Appui long sur une perle en double pour la revendre.").font(.footnote).foregroundStyle(.white.opacity(0.6))
                        ForEach(game.player.pearlCards.suffix(40).reversed()) { card in
                            PearlRow(card: card)
                        }
                    }
                }
                .padding()
            }
            .background(Palette.night.ignoresSafeArea())
            .navigationTitle("Collection")
            .confirmationDialog("Revendre les doublons ?", isPresented: $confirmSellAll, titleVisibility: .visible) {
                Button("Revendre \(sellable.count) perles pour \(sellableDust) ✦") { game.sellAllDuplicates() }
            } message: {
                Text("On garde la plus belle de chaque sorte et toutes les perles à marque rare.")
            }
        }
    }

    /// Le comptoir : poussière d'or et revente en lot.
    private var counter: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Comptoir").font(.title3.weight(.bold))
                Spacer()
                Text("✦ \(game.player.dust)").font(.headline.monospacedDigit()).foregroundStyle(Palette.gold)
            }
            Button {
                confirmSellAll = true
            } label: {
                Text(sellable.isEmpty ? "Aucun doublon à revendre" : "Revendre \(sellable.count) doublons · + \(sellableDust) ✦")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Palette.gold)
            .disabled(sellable.isEmpty)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white.opacity(0.06)))
    }

    private var findable: [PearlType] { game.catalog.pearls.filter { $0.id != "empty" } }
    private var discovered: Int { findable.filter { game.player.count(of: $0.id) > 0 }.count }
    private var sellable: [PearlCard] { game.player.sellableDuplicates() }
    private var sellableDust: Int { sellable.reduce(0) { $0 + game.catalog.sellDust($1.pearlId) } }
}

private struct PearlRow: View {
    @Environment(GameModel.self) private var game
    let card: PearlCard

    var body: some View {
        let pearl = game.catalog.pearl(card.pearlId)
        let isDuplicate = game.player.count(of: card.pearlId) > 1
        HStack {
            PearlDot(color: Color(hex: pearl.color), glow: nil, size: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(card.cracked ? "\(pearl.name) fêlée" : pearl.name)
                if card.fromDust == true { Text("Poussière d’or").font(.caption2).foregroundStyle(Palette.gold) }
            }
            Spacer()
            Text("\(card.lustre.rawValue) · \(Int(card.value))").foregroundStyle(Palette.gold)
        }
        .contentShape(Rectangle())
        .contextMenu {
            if isDuplicate {
                Button("Revendre · + \(game.catalog.sellDust(card.pearlId)) ✦", systemImage: "sparkles") { game.sell(card) }
            } else {
                Text("Ta seule \(pearl.name.lowercased()) : on la garde.")
            }
        }
    }
}

private struct EncyclopediaCell: View {
    let pearl: PearlType
    let count: Int
    /// Prix en poussière d'or si elle manque ; nil si elle ne s'achète pas (★).
    let price: Int?
    let dust: Int
    let buy: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            if count > 0 {
                PearlDot(color: Color(hex: pearl.color), glow: pearl.glow.map { Color(hex: $0) }, size: 46)
            } else {
                Circle().strokeBorder(.white.opacity(0.25), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4])).frame(width: 46, height: 46)
            }
            Text(count > 0 ? pearl.name : "???").font(.subheadline.weight(.semibold))
            Text(pearl.rarity + (count > 0 ? "  ×\(count)" : "")).font(.caption).foregroundStyle(Palette.gold)
            if count == 0, let price {
                Button("Acheter · \(price) ✦", action: buy)
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.bordered)
                    .tint(Palette.gold)
                    .disabled(dust < price)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white.opacity(0.06)))
    }
}
