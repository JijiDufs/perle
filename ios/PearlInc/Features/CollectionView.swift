import SwiftUI
import PearlCore

/// La collection : encyclopédie des perles (nombre pair de colonnes, pour se couper proprement
/// au pli du Duo), puis les dernières cartes et les trouvailles.
struct CollectionView: View {
    @Environment(GameModel.self) private var game
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("\(discovered) / \(findable.count) perles découvertes")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(findable) { pearl in
                            EncyclopediaCell(pearl: pearl, count: game.player.count(of: pearl.id))
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
                        Text("Dernières perles").font(.title3.weight(.bold))
                        ForEach(game.player.pearlCards.suffix(20).reversed()) { card in
                            let pearl = game.catalog.pearl(card.pearlId)
                            HStack {
                                PearlDot(color: Color(hex: pearl.color), glow: nil, size: 28)
                                Text(card.cracked ? "\(pearl.name) fêlée" : pearl.name)
                                Spacer()
                                Text("\(card.lustre.rawValue) · \(Int(card.value))").foregroundStyle(Palette.gold)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Palette.night.ignoresSafeArea())
            .navigationTitle("Collection")
        }
    }

    private var findable: [PearlType] { game.catalog.pearls.filter { $0.id != "empty" } }
    private var discovered: Int { findable.filter { game.player.count(of: $0.id) > 0 }.count }
}

private struct EncyclopediaCell: View {
    let pearl: PearlType
    let count: Int

    var body: some View {
        VStack(spacing: 8) {
            if count > 0 {
                PearlDot(color: Color(hex: pearl.color), glow: pearl.glow.map { Color(hex: $0) }, size: 46)
            } else {
                Circle().strokeBorder(.white.opacity(0.25), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4])).frame(width: 46, height: 46)
            }
            Text(count > 0 ? pearl.name : "???").font(.subheadline.weight(.semibold))
            Text(pearl.rarity + (count > 0 ? "  ×\(count)" : "")).font(.caption).foregroundStyle(Palette.gold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white.opacity(0.06)))
    }
}
