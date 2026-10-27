import SwiftUI
import PearlCore

/// La collection, comme dans le prototype de pearl-inc.app : les huit perles en cases (toucher une perle
/// ne montre que ses cartes, avec son carnet des variantes), le comptoir (revente des doublons), les cartes
/// triées, les albums de trouvailles et les probabilités. Toucher une carte l'agrandit.
/// Nombre pair de colonnes partout, pour se couper proprement au pli du Duo.
struct CollectionView: View {
    private enum Shelf: Hashable { case pearls, jewels, finds }

    @Environment(GameModel.self) private var game
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @AppStorage("collection.sort") private var sort: CardSort = .rarity
    @State private var shelf: Shelf = .pearls
    /// La sorte de perle touchée dans l'encyclopédie ; nil = toutes les cartes.
    @State private var filter: String?
    /// La rareté touchée dans l'encyclopédie des bijoux ; nil = tous.
    @State private var jewelFilter: String?
    @State private var shown: PearlCardView.Content?
    @State private var confirmSellAll = false

    var body: some View {
        ZStack {
            ScrollViewReader { scroll in
                ScrollView {
                    VStack(spacing: 22) {
                        header
                        if !game.player.findCards.isEmpty || !game.player.jewelCards.isEmpty {
                            Picker("Volet de la collection", selection: $shelf) {
                                Text("Perles").tag(Shelf.pearls)
                                if !game.player.jewelCards.isEmpty { Text("Bijoux").tag(Shelf.jewels) }
                                if !game.player.findCards.isEmpty { Text("Trouvailles").tag(Shelf.finds) }
                            }
                            .pickerStyle(.segmented)
                        }
                        if shelf == .finds && !game.player.findCards.isEmpty {
                            findAlbums
                        } else if shelf == .jewels && !game.player.jewelCards.isEmpty {
                            jewelShelf(scroll)
                        } else {
                            pearlShelf(scroll)
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
            }
            .statusBarFade()
            .background(LagoonBackground(dim: 0.82))

            if let shown { zoom(shown) }
        }
        .confirmationDialog("Revendre les doublons ?", isPresented: $confirmSellAll, titleVisibility: .visible) {
            Button("Revendre \(sellableCount) doublons pour \(sellableDust) ✦") { game.sellAllDuplicates() }
        } message: {
            Text("On garde la plus belle de chaque sorte, toutes les perles à marque rare et tous les bijoux à éclat parfait.")
        }
    }

    // MARK: - Perles

    @ViewBuilder
    private func pearlShelf(_ scroll: ScrollViewProxy) -> some View {
        LazyVGrid(columns: columns(2, spacing: 14), spacing: 14) {
            ForEach(findable) { pearl in
                let count = game.player.count(of: pearl.id)
                let selected = filter == pearl.id
                Button { toggleFilter(pearl.id, scroll) } label: {
                    PearlCell(pearl: pearl, count: count, selected: selected)
                }
                .buttonStyle(.plain)
                .disabled(count == 0)
                .accessibilityAddTraits(selected ? .isSelected : [])
                .accessibilityHint(selected ? Text("Touche pour revoir toutes les cartes") : Text("Touche pour ne voir que ses cartes"))
            }
        }

        counter

        if !game.player.pearlCards.isEmpty {
            VStack(spacing: 12) {
                section("Mes perles", note: "Appui long sur une perle en double pour la revendre.")
                Picker("Trier les cartes", selection: $sort) {
                    Text("Rareté").tag(CardSort.rarity)
                    Text("Récentes").tag(CardSort.recent)
                    Text("Valeur").tag(CardSort.value)
                }
                .pickerStyle(.segmented)
                if let filter {
                    filterBar(filter)
                    VariantNotebook(pearlId: filter)
                }
                GlassList {
                    LazyVStack(spacing: 0) {
                        ForEach(cards) { card in
                            PearlRow(card: card) { open(.pearl(card)) }
                        }
                    }
                }
            }
            .id(Self.cardsAnchor)
        }

        section("Probabilités", note: "Chaque huître est un tirage. Les chances ne changent jamais, ni avec un skin ni avec un achat.")
        GlassList { OddsList().padding(.vertical, 8) }
    }

    private static let cardsAnchor = "cards"

    /// Toucher une perle ne garde que ses cartes ; la retoucher les montre toutes.
    private func toggleFilter(_ pearlId: String, _ scroll: ScrollViewProxy) {
        game.audio.tap()
        withAnimation(.snappy) { filter = filter == pearlId ? nil : pearlId }
        guard filter != nil else { return }
        if reduceMotion { scroll.scrollTo(Self.cardsAnchor, anchor: .top) } else { withAnimation(.snappy) { scroll.scrollTo(Self.cardsAnchor, anchor: .top) } }
    }

    private func filterBar(_ pearlId: String) -> some View {
        let name = game.catalog.pearl(pearlId).name, shownCount = cards.count, total = game.player.pearlCards.count
        return HStack {
            Text("\(name) seulement · \(shownCount) sur \(total)").font(.subheadline.weight(.semibold))
            Spacer(minLength: 8)
            Button("Tout afficher") { withAnimation(.snappy) { filter = nil } }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Palette.gold)
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("Ma collection").font(.system(size: 34, weight: .bold)).tracking(-0.8)
            if shelf == .jewels && !game.player.jewelCards.isEmpty {
                let rarities = game.catalog.jewels.rarities
                Text("\(rarities.filter { game.player.count(ofJewel: $0.id) > 0 }.count) / \(rarities.count) raretés de bijoux").font(.headline).opacity(0.9)
                Text("\(game.player.jewelCards.count) bijoux").font(.subheadline).opacity(0.65)
            } else if shelf == .finds && !game.player.findCards.isEmpty {
                let found = game.catalog.finds.filter { game.player.count(ofFind: $0.id) > 0 }.count
                Text("\(found) / \(game.catalog.finds.count) trouvailles").font(.headline).opacity(0.9)
                Text("\(completeAlbums) albums complets").font(.subheadline).opacity(0.65)
            } else {
                Text("\(discovered) / \(findable.count) perles trouvées").font(.headline).opacity(0.9)
                Text("Trésor : \(treasure) · \(game.player.pearlCards.count) perles")
                    .font(.subheadline).opacity(0.65)
            }
        }
        .multilineTextAlignment(.center)
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
                if sellableCount == 0 {
                    Text("Aucun doublon à revendre")
                } else {
                    Text("Revendre \(sellableCount) doublons · + \(sellableDust) ✦")
                }
            }
            .buttonStyle(PearlButtonStyle())
            .disabled(sellableCount == 0)
            // Un écrin contre de la poussière d'or (jamais contre de l'argent réel) ; probabilités dans le volet Bijoux,
            // dans l'onglet Écrins et dans les réglages.
            Button { game.buyEcrin() } label: {
                Label("Acheter un écrin · \(game.ecrinPrice) ✦", systemImage: "gift.fill")
            }
            .buttonStyle(GlassButtonStyle())
            .disabled(game.player.dust < game.ecrinPrice)
        }
        .padding(18)
        .glassPanel(shade: 0.25)
    }

    // MARK: - Bijoux

    /// Les dix raretés de bijoux en cases (toucher une rareté ne garde que ses bijoux), les cartes triées, les probabilités.
    @ViewBuilder
    private func jewelShelf(_ scroll: ScrollViewProxy) -> some View {
        LazyVGrid(columns: columns(2, spacing: 14), spacing: 14) {
            ForEach(game.catalog.jewels.rarities) { rarity in
                let count = game.player.count(ofJewel: rarity.id)
                let selected = jewelFilter == rarity.id
                Button {
                    game.audio.tap()
                    withAnimation(.snappy) { jewelFilter = selected ? nil : rarity.id }
                    if !selected { withAnimation(reduceMotion ? nil : .snappy) { scroll.scrollTo(Self.cardsAnchor, anchor: .top) } }
                } label: {
                    JewelCell(rarity: rarity, best: bestJewel(rarity.id), count: count, selected: selected)
                }
                .buttonStyle(.plain)
                .disabled(count == 0)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }

        VStack(spacing: 12) {
            section("Mes bijoux", note: "Appui long sur un bijou en double pour le revendre.")
            Picker("Trier les cartes", selection: $sort) {
                Text("Rareté").tag(CardSort.rarity)
                Text("Récents").tag(CardSort.recent)
                Text("Valeur").tag(CardSort.value)
            }
            .pickerStyle(.segmented)
            if let jewelFilter {
                HStack {
                    Text("\(game.catalog.jewelRarity(jewelFilter).label) seulement · \(jewelCards.count) sur \(game.player.jewelCards.count)")
                        .font(.subheadline.weight(.semibold))
                    Spacer(minLength: 8)
                    Button("Tout afficher") { withAnimation(.snappy) { self.jewelFilter = nil } }
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Palette.gold)
                }
            }
            GlassList {
                LazyVStack(spacing: 0) {
                    ForEach(jewelCards) { card in
                        JewelRow(card: card) { open(.jewel(card)) }
                    }
                }
            }
        }
        .id(Self.cardsAnchor)

        section("Probabilités des écrins", note: "Chaque écrin est un tirage. Les chances ne changent jamais.")
        GlassList { EcrinOddsList().padding(.vertical, 8) }
    }

    private func bestJewel(_ rarityId: String) -> JewelCard? {
        game.player.jewelCards.filter { $0.jewel.rarityId == rarityId }.max { $0.value < $1.value }
    }

    private var jewelCards: [JewelCard] {
        let mine = jewelFilter.map { id in game.player.jewelCards.filter { $0.jewel.rarityId == id } } ?? game.player.jewelCards
        return game.catalog.sortJewelCards(mine, sort)
    }

    // MARK: - Trouvailles

    /// Les albums : les objets trouvés, et une case « ? » pour chaque objet encore caché (sans son nom).
    private var findAlbums: some View {
        ForEach(game.catalog.findAlbums) { album in
            let finds = game.catalog.finds(inAlbum: album.id)
            let found = finds.filter { game.player.count(ofFind: $0.id) > 0 }.count
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text(album.name).lagoonTitle()
                    Spacer(minLength: 8)
                    Text(verbatim: "\(found) / \(finds.count)").font(.headline.monospacedDigit()).opacity(0.85)
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
                Text(album.description).font(.footnote).foregroundStyle(.white.opacity(0.7))
                LazyVGrid(columns: columns(typeSize.isAccessibilitySize ? 2 : 4, spacing: 10), spacing: 10) {
                    ForEach(finds) { find in
                        let count = game.player.count(ofFind: find.id)
                        Button {
                            if let card = game.player.findCards.last(where: { $0.findId == find.id }) { open(.find(card, dust: 0)) }
                        } label: {
                            FindCell(find: find, count: count)
                        }
                        .buttonStyle(.plain)
                        .disabled(count == 0)
                    }
                }
            }
        }
    }

    private var completeAlbums: Int {
        game.catalog.findAlbums.filter { album in
            game.catalog.finds(inAlbum: album.id).allSatisfy { game.player.count(ofFind: $0.id) > 0 }
        }.count
    }

    // MARK: - Carte agrandie

    private func open(_ content: PearlCardView.Content) {
        game.audio.tap()
        withAnimation(.snappy) { shown = content }
    }

    private func close() {
        withAnimation(.snappy) { shown = nil }
    }

    /// La carte agrandie, qu'on fait jouer dans la lumière ; sur le Duo à moitié ouvert, à droite du pli.
    private func zoom(_ content: PearlCardView.Content) -> some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
                .onTapGesture { close() }
                .accessibilityHidden(true)
            GeometryReader { proxy in
                VStack(spacing: 18) {
                    PearlCardView(content: content, width: min(300, proxy.size.width - 48, (proxy.size.height - 160) * 63 / 88))
                        .cardTilt()
                    // Moitié d'écran du Duo : les boutons l'un sous l'autre si la place manque.
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 12) { zoomButtons(content) }
                        VStack(spacing: 10) { zoomButtons(content) }
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
            .besideFold(game.foldX)
        }
        .transition(reduceMotion ? .opacity : .scale(scale: 0.4).combined(with: .opacity))
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape) { close() }
    }

    @ViewBuilder
    private func zoomButtons(_ content: PearlCardView.Content) -> some View {
        if let message = content.shareMessage(game.catalog) {
            ShareLink(item: message) {
                Label("Partager", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(GlassButtonStyle(compact: true))
            .fixedSize()
            .simultaneousGesture(TapGesture().onEnded { game.recordShare() })
        }
        Button("Fermer") { close() }
            .buttonStyle(GlassButtonStyle(compact: true))
            .fixedSize()
    }

    // MARK: - Outils

    private func columns(_ count: Int, spacing: CGFloat) -> [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing), count: count)
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
    private var sellableJewels: [JewelCard] { game.player.sellableJewelDuplicates() }
    private var sellableCount: Int { sellable.count + sellableJewels.count }
    private var sellableDust: Int {
        sellable.reduce(0) { $0 + game.catalog.sellDust($1.pearlId) } + sellableJewels.reduce(0) { $0 + game.catalog.sellDust(jewel: $1.jewel.rarityId) }
    }

    /// Les cartes montrées : la sorte touchée (ou toutes), dans l'ordre choisi.
    private var cards: [PearlCard] {
        let mine = filter.map { id in game.player.pearlCards.filter { $0.pearlId == id } } ?? game.player.pearlCards
        return game.catalog.sortCards(mine, sort)
    }
}

/// Une case de l'encyclopédie, comme dans le prototype : la perle et son halo, ou un « ? ».
private struct PearlCell: View {
    @Environment(GameModel.self) private var game
    @Environment(\.dynamicTypeSize) private var typeSize
    let pearl: PearlType
    let count: Int
    var selected = false

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
            // Très grand texte : le nom au-dessus du nombre, pour ne pas le couper.
            let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2)) : AnyLayout(HStackLayout(alignment: .firstTextBaseline))
            layout {
                Text(known ? pearl.name : "???").font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(known ? 0.95 : 0.4)).lineLimit(2).minimumScaleFactor(0.75)
                Spacer(minLength: 4)
                Text(known ? "×\(count)" : pearl.rarity).font(.subheadline.weight(.semibold)).foregroundStyle(collectionCyan.opacity(0.85))
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
        .collectionCell(known: known, selected: selected)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText(known: known))
    }

    private func accessibilityText(known: Bool) -> String {
        let name = pearl.name, rarity = pearl.rarity
        return known ? String(localized: "\(name), \(count) exemplaires") : String(localized: "Perle pas encore trouvée, \(rarity)")
    }
}

/// Une case d'album : l'objet en relief, ou un « ? » avec sa rareté (on ne révèle pas son nom).
private struct FindCell: View {
    @Environment(GameModel.self) private var game
    let find: FindType
    let count: Int

    var body: some View {
        let known = count > 0
        let rarity = game.catalog.raritySymbols[find.tier]
        VStack(spacing: 4) {
            ZStack {
                if known {
                    FindThumb(find: find, size: 48)
                } else {
                    Text("?").font(.system(size: 34, weight: .semibold)).foregroundStyle(.white.opacity(0.22))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            Text(known ? find.name : "???").font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(known ? 0.95 : 0.4))
                .lineLimit(2, reservesSpace: true).minimumScaleFactor(0.7).multilineTextAlignment(.center)
            Text(known ? "×\(count)" : rarity).font(.caption2.weight(.semibold)).foregroundStyle(collectionCyan.opacity(0.85))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 10)
        .frame(maxHeight: .infinity, alignment: .top)
        .collectionCell(known: known, cornerRadius: 16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(known ? String(localized: "\(find.name), \(count) exemplaires") : String(localized: "Trouvaille pas encore trouvée, \(rarity)"))
    }
}

/// Le carnet des variantes d'une sorte de perle : formes, reflets et marques rares, celles déjà trouvées en clair.
private struct VariantNotebook: View {
    @Environment(GameModel.self) private var game
    let pearlId: String

    var body: some View {
        let found = game.player.foundTraits(of: pearlId)
        VStack(alignment: .leading, spacing: 14) {
            Text("Carnet des variantes").font(.headline).accessibilityAddTraits(.isHeader)
            group("Formes", ids: game.catalog.shapes(of: pearlId), found: found.shapes, traits: game.catalog.shapes)
            group("Reflets", ids: game.catalog.overtones(of: pearlId), found: found.overtones, traits: game.catalog.overtones)
            group("Marques rares", ids: game.catalog.markIds, found: found.marks, traits: game.catalog.marks)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(cornerRadius: 20, shade: 0.25)
    }

    private func group(_ title: LocalizedStringKey, ids: [String], found: Set<String>, traits: [String: Trait]) -> some View {
        let foundCount = ids.filter(found.contains).count
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.subheadline.weight(.semibold))
                Spacer()
                Text(verbatim: "\(foundCount) / \(ids.count)").font(.subheadline.monospacedDigit()).opacity(0.8)
            }
            .accessibilityElement(children: .combine)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(ids, id: \.self) { id in
                    if let trait = traits[id] { chip(trait, found: found.contains(id)) }
                }
            }
        }
    }

    private func chip(_ trait: Trait, found: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        // Les reflets sont écrits pour « reflet rose » : majuscule en tête de case.
        let label = trait.label.prefix(1).uppercased() + trait.label.dropFirst()
        return HStack(spacing: 6) {
            if let color = trait.color {
                Circle().fill(Color(hex: color)).frame(width: 10, height: 10)
                    .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 0.5))
            }
            Text(label).font(.footnote.weight(found ? .semibold : .regular)).lineLimit(2).minimumScaleFactor(0.8)
            Spacer(minLength: 0)
            if found { Image(systemName: "checkmark").font(.caption2.weight(.bold)).foregroundStyle(collectionCyan) }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(shape.fill(.white.opacity(found ? 0.14 : 0.04)))
        .overlay(shape.strokeBorder(found ? collectionCyan.opacity(0.45) : .white.opacity(0.1), lineWidth: 1))
        .opacity(found ? 1 : 0.6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(found ? String(localized: "\(label), dans ta collection") : String(localized: "\(label), pas encore dans ta collection"))
    }
}

/// Liseré des cases de la collection, comme le prototype.
private let collectionCyan = rgba(174, 244, 255, 1)

private extension View {
    func collectionCell(known: Bool, selected: Bool = false, cornerRadius: CGFloat = 20) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return background(shape.fill(.white.opacity(selected ? 0.18 : known ? 0.1 : 0.04)))
            .overlay(shape.strokeBorder(selected ? Palette.gold : known ? collectionCyan.opacity(0.4) : .white.opacity(0.1), lineWidth: selected ? 2 : 1))
            .contentShape(shape)
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

/// Une case de l'encyclopédie des bijoux : le plus beau de cette rareté, ou un « ? ».
private struct JewelCell: View {
    @Environment(GameModel.self) private var game
    let rarity: JewelRarity
    let best: JewelCard?
    let count: Int
    var selected = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if let best {
                    JewelThumb(card: best, size: 92)
                } else {
                    Text("?").font(.system(size: 50, weight: .semibold)).foregroundStyle(.white.opacity(0.22))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 104)
            HStack(alignment: .firstTextBaseline) {
                Text(count > 0 ? rarity.label : "???").font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(count > 0 ? 0.95 : 0.4)).lineLimit(2).minimumScaleFactor(0.75)
                Spacer(minLength: 4)
                Text(count > 0 ? "×\(count)" : rarity.rarity).font(.subheadline.weight(.semibold)).foregroundStyle(collectionCyan.opacity(0.85))
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
        .collectionCell(known: count > 0, selected: selected)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(count > 0 ? String(localized: "\(rarity.label), \(count) exemplaires") : String(localized: "Bijou pas encore trouvé, \(rarity.rarity)"))
    }
}

private struct JewelRow: View {
    @Environment(GameModel.self) private var game
    let card: JewelCard
    let open: () -> Void

    var body: some View {
        let rarity = game.catalog.jewelRarity(card.jewel.rarityId)
        Button(action: open) {
            HStack {
                JewelThumb(card: card, size: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(game.catalog.jewelName(card.jewel, variant: card.variant)).lineLimit(2)
                    Group {
                        if card.perfect { Text("\(rarity.rarity) · éclat parfait") } else { Text(verbatim: rarity.rarity) }
                    }
                    .font(.caption).foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                Text(GameText.jewelValue(card.value)).font(.headline.monospacedDigit()).foregroundStyle(Palette.gold)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            if game.player.count(ofJewel: rarity.id) > 1 {
                Button("Revendre · + \(game.catalog.sellDust(jewel: rarity.id)) ✦", systemImage: "sparkles") { game.sellJewel(card) }
            } else {
                Text("Ton seul bijou \(rarity.label.lowercased()) : on le garde.")
            }
        }
    }
}

/// Un bijou dessiné avec sa lumière, pour les cases et les lignes de la collection.
struct JewelThumb: View {
    @Environment(GameModel.self) private var game
    let card: JewelCard
    var size: CGFloat = 40

    var body: some View {
        Canvas { c, canvasSize in
            let side = Double(canvasSize.width)
            let glow = card.variant.flatMap { game.catalog.jewelVariant($0)?.glow } ?? game.catalog.jewelRarity(card.jewel.rarityId).glow
            PearlArt.glow(&c, side / 2, side / 2, side * 0.5, glow, 0.45)
            JewelArt.draw(Canvas2D(c), side / 2, side * JewelArt.yOffset(card.jewel), side / 440,
                          JewelArt.Look(card.jewel, variant: card.variant, catalog: game.catalog))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Toutes les chances d'une huître, toujours affichées (docs/duo-gadget.md §5, règle 3.1.1) : perles, trouvailles par
/// rareté, marques rares, poisson voleur, garantie (avec ce qu'il reste au joueur).
struct OddsList: View {
    @Environment(GameModel.self) private var game

    var body: some View {
        let catalog = game.catalog
        VStack(spacing: 10) {
            ForEach(catalog.pearls) { pearl in
                row(Text(verbatim: "\(pearl.name)  \(pearl.rarity)"), pearl.probability)
            }
            ForEach(1..<catalog.raritySymbols.count, id: \.self) { tier in
                let chance = catalog.findChance(tier: tier)
                if chance > 0 { row(Text("Trouvaille \(catalog.raritySymbols[tier]), à la place de la perle"), chance) }
            }
            note(Text("Garantie : une perle dorée ou plus rare en \(game.tuning.pityThreshold + 1) huîtres au plus. Encore \(game.player.guaranteeIn(tuning: game.tuning))."))
            Divider().overlay(.white.opacity(0.2))
            ForEach(catalog.markWeights, id: \.id) { mark in
                row(Text("Marque « \(catalog.marks[mark.id]?.label ?? mark.id) », sur une perle"), catalog.markChance(mark.id, tuning: game.tuning))
            }
            note(Text("Une marque rare augmente la valeur de la perle, pas sa rareté."))
            row(Text("Poisson voleur, sur une perle"), game.economy.fishThief.chance)
            note(Text("Il emporte la perle qu’on vient de trouver, quelle que soit sa rareté : touche-le pendant qu’il s’enfuit pour la récupérer (+ \(game.economy.fishThief.catchBonusDust) ✦)."))
        }
    }

    private func note(_ text: Text) -> some View {
        text.font(.caption).foregroundStyle(.white.opacity(0.65)).frame(maxWidth: .infinity, alignment: .leading)
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
