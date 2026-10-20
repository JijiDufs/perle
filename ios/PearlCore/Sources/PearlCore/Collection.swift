// La collection : tri des cartes, carnet des variantes, albums de trouvailles.
// Miroir de src/core/collection.ts, pearlTraits.ts (shapesOf, overtonesOf) et finds.ts (albumProgress).

public enum CardSort: String, CaseIterable, Sendable {
    case rarity, recent, value
}

extension Catalog {
    /// Rang de rareté : 0 = la plus rare (probabilité la plus faible).
    public func rarityRank(_ pearlId: String) -> Int {
        let ranked = pearls.enumerated().sorted { ($0.element.probability, $0.offset) < ($1.element.probability, $1.offset) }
        return ranked.firstIndex { $0.element.id == pearlId } ?? pearls.count
    }

    /// Trie les cartes, comme `sortCards` :
    /// - rarity : la plus rare d'abord, puis la plus précieuse, puis la plus récente ;
    /// - recent : la plus récente d'abord ;
    /// - value : la plus précieuse d'abord, puis la plus rare, puis la plus récente.
    public func sortCards(_ cards: [PearlCard], _ sort: CardSort) -> [PearlCard] {
        let rank = Dictionary(uniqueKeysWithValues: pearls.map { ($0.id, rarityRank($0.id)) })
        return cards.sorted { a, b in
            let rarity = (rank[a.pearlId] ?? 0, rank[b.pearlId] ?? 0)
            switch sort {
            case .recent: return a.serial > b.serial
            case .value: return (-a.value, rarity.0, -a.serial) < (-b.value, rarity.1, -b.serial)
            case .rarity: return (rarity.0, -a.value, -a.serial) < (rarity.1, -b.value, -b.serial)
            }
        }
    }

    /// Les formes et les reflets qu'une perle peut avoir, et les marques rares (carnet des variantes), dans l'ordre du catalogue.
    public func shapes(of pearlId: String) -> [String] { shapeWeights[pearlId]?.map(\.id) ?? [] }
    public func overtones(of pearlId: String) -> [String] { overtoneWeights[pearlId]?.map(\.id) ?? [] }
    public var markIds: [String] { markWeights.map(\.id) }

    /// Les trouvailles d'un album, de la plus courante à la plus rare.
    public func finds(inAlbum albumId: String) -> [FindType] {
        finds.enumerated().filter { $0.element.album == albumId }
            .sorted { ($0.element.tier, $0.offset) < ($1.element.tier, $1.offset) }.map(\.element)
    }
}

extension PlayerState {
    /// Ce que le joueur a déjà trouvé pour une sorte de perle : formes, reflets, marques.
    public func foundTraits(of pearlId: String) -> (shapes: Set<String>, overtones: Set<String>, marks: Set<String>) {
        let traits = pearlCards.filter { $0.pearlId == pearlId }.compactMap(\.traits)
        return (Set(traits.map(\.shape)), Set(traits.map(\.overtone)), Set(traits.compactMap(\.mark)))
    }

    /// Nombre de cartes d'une trouvaille.
    public func count(ofFind findId: String) -> Int {
        findCards.filter { $0.findId == findId }.count
    }
}
