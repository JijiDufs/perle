import SwiftUI
import PearlCore

/// La collection, comme dans le prototype de pearl-inc.app : les huit perles en cases (toucher une perle
/// trouvée montre sa plus belle carte), le trésor, le comptoir (revente des doublons), les trouvailles,
/// les dernières perles et les probabilités. Nombre pair de colonnes, pour se couper proprement au pli du Duo.
struct CollectionView: View {
    @Environment(GameModel.self) private var game
    @State private var confirmSellAll = false
    @State private var shown: PearlCard?
    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 22) {
                    header

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(findable) { pearl in
                            let count = game.player.count(of: pearl.id)
                            Button {
                                if let best = best(pearl.id) { withAnimation(.snappy) { shown = best } }
                            } label: {
                                PearlCell(pearl: pearl, count: count)
                            }
                            .buttonStyle(.plain)
                            .disabled(count == 0)
                        }
                    }

                    counter

                    if !game.player.findCards.isEmpty {
                        section("Trouvailles")
                        GlassList {
                            ForEach(game.player.findCards.reversed()) { card in
                                let find = game.catalog.find(card.findId)
                                HStack {
                                    FindThumb(find: find, size: 30)
                                    Text(find.name)
                                    Spacer()
                                    Text(GameText.serial(card.serial)).font(.caption.monospaced()).foregroundStyle(.white.opacity(0.6))
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }

                    if !game.player.pearlCards.isEmpty {
                        section("Mes perles", note: "Appui long sur une perle en double pour la revendre.")
                        GlassList {
                            ForEach(game.player.pearlCards.suffix(40).reversed()) { card in
                                PearlRow(card: card) { withAnimation(.snappy) { shown = card } }
                            }
                        }
                    }

                    section("Probabilités", note: "Chaque huître est un tirage. Les chances ne changent jamais, ni avec un skin ni avec un achat.")
                    GlassList { OddsList().padding(.vertical, 8) }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
            .statusBarFade()
            .background(LagoonBackground(dim: 0.82))

            if let shown {
                Color.black.opacity(0.6).ignoresSafeArea()
                    .onTapGesture { withAnimation(.snappy) { self.shown = nil } }
                    .transition(.opacity)
                VStack(spacing: 18) {
                    PearlCardView(content: .pearl(shown), width: 300)
                        .cardTilt()
                    Button("Fermer") { withAnimation(.snappy) { self.shown = nil } }
                        .buttonStyle(GlassButtonStyle())
                        .frame(maxWidth: 200)
                }
                .transition(.scale(scale: 0.4).combined(with: .opacity))
            }
        }
        .confirmationDialog("Revendre les doublons ?", isPresented: $confirmSellAll, titleVisibility: .visible) {
            Button("Revendre \(sellable.count) perles pour \(sellableDust) ✦") { game.sellAllDuplicates() }
        } message: {
            Text("On garde la plus belle de chaque sorte et toutes les perles à marque rare.")
        }
    }

    // MARK: - En-tête et comptoir

    private var header: some View {
        VStack(spacing: 6) {
            Text("Ma collection").font(.system(size: 34, weight: .bold)).tracking(-0.8)
            Text("\(discovered) / \(findable.count) perles trouvées").font(.headline).opacity(0.9)
            Text("Trésor : \(treasure) · \(game.player.pearlCards.count) perles")
                .font(.subheadline).opacity(0.65)
        }
        .shadow(color: .black.opacity(0.3), radius: 6)
        .padding(.top, 16)
    }

    private var counter: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Comptoir").font(.title3.weight(.bold))
                Spacer()
                Text("✦ \(game.player.dust)").font(.headline.monospacedDigit()).foregroundStyle(Palette.gold)
            }
            Text("Revends tes doublons contre de la poussière d’or. On garde toujours un exemplaire de chaque sorte.")
                .font(.footnote).opacity(0.75)
            Button {
                confirmSellAll = true
            } label: {
                if sellable.isEmpty {
                    Text("Aucun doublon à revendre")
                } else {
                    Text("Revendre \(sellable.count) doublons · + \(sellableDust) ✦")
                }
            }
            .buttonStyle(PearlButtonStyle())
            .disabled(sellable.isEmpty)
        }
        .padding(18)
        .glassPanel(shade: 0.25)
    }

    private func section(_ title: LocalizedStringKey, note: LocalizedStringKey? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).lagoonTitle()
            if let note { Text(note).font(.footnote).foregroundStyle(.white.opacity(0.7)) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Les perles à trouver (l'huître vide ne donne pas de carte).
    private var findable: [PearlType] { game.catalog.pearls.filter { $0.glow != nil } }
    private var discovered: Int { findable.filter { game.player.count(of: $0.id) > 0 }.count }
    private var treasure: Int { Int(game.player.pearlCards.reduce(0) { $0 + $1.value }) }
    private var sellable: [PearlCard] { game.player.sellableDuplicates() }
    private var sellableDust: Int { sellable.reduce(0) { $0 + game.catalog.sellDust($1.pearlId) } }

    /// La plus belle carte d'une sorte de perle.
    private func best(_ pearlId: String) -> PearlCard? {
        game.player.pearlCards.filter { $0.pearlId == pearlId }.max { $0.value < $1.value }
    }
}

/// Une case de l'encyclopédie, comme dans le prototype : la perle et son halo, ou un « ? ».
private struct PearlCell: View {
    @Environment(GameModel.self) private var game
    let pearl: PearlType
    let count: Int

    private static let cyan = rgba(174, 244, 255, 1)

    var body: some View {
        let known = count > 0
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        VStack(spacing: 0) {
            ZStack {
                if known && pearl.glow != nil {
                    PearlThumb(look: PearlLook(pearl, traits: nil, catalog: game.catalog), glow: pearl.glow, size: pearl.id == "giant" ? 46 : 36)
                } else if known {
                    Circle().strokeBorder(.white.opacity(0.35), style: StrokeStyle(lineWidth: 2, dash: [5, 5])).frame(width: 52, height: 52)
                } else {
                    Text("?").font(.system(size: 50, weight: .semibold)).foregroundStyle(.white.opacity(0.22))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 104)
            HStack(alignment: .firstTextBaseline) {
                Text(known ? pearl.name : "???").font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(known ? 0.95 : 0.4)).lineLimit(1).minimumScaleFactor(0.75)
                Spacer(minLength: 4)
                Text(known ? "×\(count)" : pearl.rarity).font(.subheadline.weight(.semibold)).foregroundStyle(Self.cyan.opacity(0.85))
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
        .background(shape.fill(.white.opacity(known ? 0.1 : 0.04)))
        .overlay(shape.strokeBorder(known ? Self.cyan.opacity(0.4) : .white.opacity(0.1), lineWidth: 1))
        .contentShape(shape)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText(known: known))
    }

    private func accessibilityText(known: Bool) -> String {
        let name = pearl.name, rarity = pearl.rarity
        return known ? String(localized: "\(name), \(count) exemplaires") : String(localized: "Perle pas encore trouvée, \(rarity)")
    }
}

private struct PearlRow: View {
    @Environment(GameModel.self) private var game
    let card: PearlCard
    let open: () -> Void

    var body: some View {
        let pearl = game.catalog.pearl(card.pearlId)
        let isDuplicate = game.player.count(of: card.pearlId) > 1
        Button(action: open) {
            HStack {
                PearlThumb(look: PearlLook(pearl, traits: card.traits, catalog: game.catalog), glow: pearl.glow, size: 12)
                VStack(alignment: .leading, spacing: 2) {
                    Text(GameText.pearlName(pearl.name, cracked: card.cracked))
                    Text("\(pearl.rarity) · lustre \(card.lustre.rawValue)").font(.caption).foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                Text("\(Int(card.value))").font(.headline.monospacedDigit()).foregroundStyle(Palette.gold)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            if isDuplicate {
                Button("Revendre · + \(game.catalog.sellDust(card.pearlId)) ✦", systemImage: "sparkles") { game.sell(card) }
            } else {
                Text("Ta seule \(pearl.name.lowercased()) : on la garde.")
            }
        }
    }
}

/// Les probabilités de chaque perle (et des trouvailles), toujours affichées (docs/duo-gadget.md §5, règle 3.1.1).
struct OddsList: View {
    @Environment(GameModel.self) private var game

    var body: some View {
        VStack(spacing: 10) {
            ForEach(game.catalog.pearls) { pearl in
                row(Text(verbatim: "\(pearl.name)  \(pearl.rarity)"), pearl.probability)
            }
            row(Text("Trouvaille, à la place de la perle"), game.catalog.findProbability)
            row(Text("Poisson voleur, sur une perle ◆"), game.economy.fishThief.chance)
            Text("Il emporte la perle qu’on vient de trouver : touche-le pendant qu’il s’enfuit pour la récupérer.")
                .font(.caption).foregroundStyle(.white.opacity(0.65)).frame(maxWidth: .infinity, alignment: .leading)
            Text("Garantie : une perle dorée ou plus rare au plus tard à la \(game.tuning.pityThreshold + 1)ᵉ huître.")
                .font(.caption).foregroundStyle(.white.opacity(0.65)).frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func row(_ label: Text, _ probability: Double) -> some View {
        HStack {
            label.font(.subheadline)
            Spacer()
            Text(probability.formatted(.percent.precision(.fractionLength(0...2))))
                .font(.subheadline.monospacedDigit()).foregroundStyle(.white.opacity(0.85))
        }
    }
}

/// Une liste de lignes dans un seul panneau de verre.
struct GlassList<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .glassPanel(cornerRadius: 20, shade: 0.25)
    }
}
