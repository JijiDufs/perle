// État du joueur de l'app iOS : huître en cours, cartes, numéros de série, stock d'huîtres,
// poussière d'or, skins et missions du jour. Toutes les règles sont ici, pas dans les écrans.

/// Une carte de perle, créée à chaque huître ouverte.
public struct PearlCard: Codable, Sendable, Equatable, Identifiable {
    public let serial: Int
    public let pearlId: String
    public let sizeMm: Double
    public let value: Double
    public let lustre: Lustre
    public let cracked: Bool
    /// Date de révélation (ms).
    public let foundAt: Double
    public let traits: PearlTraits?
    /// Achetée avec la poussière d'or plutôt que pêchée.
    public var fromDust: Bool?
    public var id: Int { serial }
}

/// Une carte de trouvaille (easter egg).
public struct FindCard: Codable, Sendable, Equatable, Identifiable {
    public let serial: Int
    public let findId: String
    public let value: Double
    public let foundAt: Double
    public var id: Int { serial }
}

/// Ce que révèle une huître.
public enum Reveal: Sendable, Equatable {
    case pearl(PearlCard)
    case find(FindCard, dust: Int)
    case empty(serial: Int)
}

/// Valeur d'une perle : taille, traits, fêlure (÷ 2).
public func pearlValue(_ pearlId: String, sizeMm: Double, cracked: Bool, traits: PearlTraits?, catalog: Catalog = .shared) -> Double {
    let pearl = catalog.pearl(pearlId)
    if pearl.baseValue == 0 { return 0 }
    let sizeFactor = sizeMm / ((pearl.sizeMm[0] + pearl.sizeMm[1]) / 2)
    return jsRound(pearl.baseValue * sizeFactor * (traits.map { traitsValueFactor($0, catalog: catalog) } ?? 1) * (cracked ? 0.5 : 1))
}

public func traitsValueFactor(_ traits: PearlTraits, catalog: Catalog = .shared) -> Double {
    let shape = catalog.shapes[traits.shape]?.value ?? 1
    let overtone = catalog.overtones[traits.overtone]?.value ?? 1
    let mark = traits.mark.flatMap { catalog.marks[$0]?.value } ?? 1
    return shape * overtone * mark
}

public struct PlayerState: Codable, Sendable, Equatable {
    /// L'huître posée devant le joueur, tirée à l'avance et sauvegardée (invariant 5).
    public var oyster: Oyster
    public var drawState: DrawState
    public var nextSerial: Int
    public var pearlCards: [PearlCard]
    public var findCards: [FindCard]
    public var oystersOpened: Int
    public var dust: Int
    public var stock: StockState
    public var ownedSkins: [String]
    public var equippedSkin: String
    public var missions: DailyMissions?
    /// Huîtres ouvertes d'affilée sans fêlure.
    public var noCrackStreak: Int
    /// Pubs récompensées regardées aujourd'hui.
    public var adRewards: DailyCount?

    /// Nouvelle partie : stock plein, skin de départ, première huître déjà tirée.
    public static func new(_ rng: Rng, _ tuning: Tuning, now: Double, catalog: Catalog = .shared) -> PlayerState {
        let first = createOyster(.initial, rng, tuning, catalog: catalog)
        let starters = catalog.economy.skins.filter { $0.grant == "start" }.map(\.id)
        return PlayerState(
            oyster: first.oyster, drawState: first.drawState, nextSerial: 1, pearlCards: [], findCards: [], oystersOpened: 0,
            dust: 0, stock: StockState(count: tuning.oysterStockMax, lastRefillAt: now),
            ownedSkins: starters, equippedSkin: starters.first ?? "", missions: nil, noCrackStreak: 0, adRewards: nil
        )
    }

    // MARK: - Temps qui passe

    /// Recharge le stock et renouvelle les missions si le jour a changé (`day` : AAAA-MM-JJ, heure locale).
    public mutating func refresh(now: Double, day: String, tuning: Tuning, catalog: Catalog = .shared) {
        stock = refreshStock(stock, now: now, tuning)
        if missions?.day != day { missions = DailyMissions.forDay(day, economy: catalog.economy) }
    }

    public func oystersAvailable(now: Double, tuning: Tuning) -> Int {
        refreshStock(stock, now: now, tuning).count
    }

    // MARK: - Ouvrir

    /// L'huître en cours est ouverte : consomme une huître du stock, crée sa carte,
    /// fait avancer les missions et tire la suivante.
    public mutating func reveal(lustre: Lustre, cracked: Bool, now: Double, rng: Rng, tuning: Tuning, catalog: Catalog = .shared) -> Reveal {
        if let consumed = consumeOyster(stock, now: now, tuning) { stock = consumed }
        let serial = nextSerial
        let opened = oyster
        let result: Reveal
        if let findId = opened.findId {
            let find = catalog.find(findId)
            let card = FindCard(serial: serial, findId: findId, value: find.value, foundAt: now)
            findCards.append(card)
            let bonus = find.effect == "dust" ? catalog.economy.goldCoinDust : 0
            dust += bonus
            result = .find(card, dust: bonus)
        } else if opened.pearlId == "empty" {
            result = .empty(serial: serial)
        } else {
            let card = PearlCard(
                serial: serial, pearlId: opened.pearlId, sizeMm: opened.sizeMm,
                value: pearlValue(opened.pearlId, sizeMm: opened.sizeMm, cracked: cracked, traits: opened.traits, catalog: catalog),
                lustre: lustre, cracked: cracked, foundAt: now, traits: opened.traits
            )
            pearlCards.append(card)
            result = .pearl(card)
        }
        nextSerial += 1
        oystersOpened += 1
        noCrackStreak = cracked ? 0 : noCrackStreak + 1

        missions?.advance(.open)
        if opened.findId == nil && opened.pearlId != "empty" {
            if lustre == .S || lustre == .A { missions?.advance(.lustreA) }
            if lustre == .S { missions?.advance(.lustreS) }
            if catalog.tier(of: opened.pearlId) >= catalog.economy.rareMissionTier { missions?.advance(.rare) }
        }
        missions?.reachStreak(.noCrack, noCrackStreak)

        let next = createOyster(drawState, rng, tuning, catalog: catalog)
        oyster = next.oyster
        drawState = next.drawState
        return result
    }

    // MARK: - Collection et comptoir

    /// Nombre de cartes possédées pour une sorte de perle (encyclopédie).
    public func count(of pearlId: String) -> Int {
        pearlCards.filter { $0.pearlId == pearlId }.count
    }

    /// Les doublons qu'on peut revendre d'un coup : on garde le plus bel exemplaire de chaque sorte
    /// et toutes les perles à marque rare.
    public func sellableDuplicates() -> [PearlCard] {
        var kept = Set<Int>()
        for pearlId in Set(pearlCards.map(\.pearlId)) {
            let best = pearlCards.filter { $0.pearlId == pearlId }
                .max { ($0.value, -$0.serial) < ($1.value, -$1.serial) }
            if let best { kept.insert(best.serial) }
        }
        return pearlCards.filter { !kept.contains($0.serial) && $0.traits?.mark == nil }
    }

    /// Revend une perle. Jamais le dernier exemplaire d'une sorte. Renvoie la poussière gagnée.
    public mutating func sell(serial: Int, catalog: Catalog = .shared) -> Int? {
        guard let card = pearlCards.first(where: { $0.serial == serial }), count(of: card.pearlId) > 1 else { return nil }
        pearlCards.removeAll { $0.serial == serial }
        let gained = catalog.sellDust(card.pearlId)
        dust += gained
        missions?.advance(.sell)
        return gained
    }

    /// Revend tous les doublons (voir `sellableDuplicates`). Renvoie la poussière gagnée.
    public mutating func sellAllDuplicates(catalog: Catalog = .shared) -> Int {
        let sold = sellableDuplicates()
        let gained = sold.reduce(0) { $0 + catalog.sellDust($1.pearlId) }
        let serials = Set(sold.map(\.serial))
        pearlCards.removeAll { serials.contains($0.serial) }
        dust += gained
        missions?.advance(.sell, by: sold.count)
        return gained
    }

    // MARK: - Dépenser la poussière d'or

    /// Une huître de plus, quand le stock est vide.
    public mutating func buyOyster(catalog: Catalog = .shared) -> Bool {
        let price = catalog.economy.oysterDustPrice
        guard dust >= price else { return false }
        dust -= price
        stock.count += 1
        return true
    }

    /// Un skin acheté avec la poussière d'or (s'il est à vendre en poussière).
    public mutating func buySkin(_ skinId: String, catalog: Catalog = .shared) -> Bool {
        guard !ownedSkins.contains(skinId), let price = catalog.economy.skin(skinId)?.dustPrice, dust >= price else { return false }
        dust -= price
        ownedSkins.append(skinId)
        return true
    }

    /// Un skin reçu autrement (achat Apple, lien des inscrits).
    public mutating func grantSkin(_ skinId: String) {
        if !ownedSkins.contains(skinId) { ownedSkins.append(skinId) }
    }

    public mutating func equip(_ skinId: String) -> Bool {
        guard ownedSkins.contains(skinId) else { return false }
        equippedSkin = skinId
        return true
    }

    /// Un achat consommable de la boutique Apple (huîtres et / ou poussière d'or).
    public mutating func grant(_ product: AppConsumable) {
        stock.count += product.oysters
        dust += product.dust
    }

    // MARK: - Pub récompensée

    /// Pubs récompensées qu'il reste à regarder aujourd'hui (`day` : AAAA-MM-JJ, heure locale).
    public func adRewardsLeft(day: String, catalog: Catalog = .shared) -> Int {
        let watched = adRewards?.day == day ? adRewards?.count ?? 0 : 0
        return max(0, catalog.economy.rewardedAdsPerDay - watched)
    }

    /// Une pub regardée jusqu'au bout : des huîtres en plus (au-delà du maximum si besoin).
    /// nil si la limite du jour est atteinte.
    public mutating func claimAdReward(day: String, catalog: Catalog = .shared) -> Int? {
        guard adRewardsLeft(day: day, catalog: catalog) > 0 else { return nil }
        let watched = adRewards?.day == day ? adRewards?.count ?? 0 : 0
        adRewards = DailyCount(day: day, count: watched + 1)
        stock.count += catalog.economy.rewardedAdOysters
        return catalog.economy.rewardedAdOysters
    }

    // MARK: - Missions

    public mutating func recordShare() {
        missions?.advance(.share)
    }

    /// Récupère la récompense d'une mission terminée ; le bonus arrive avec la dernière des trois.
    public mutating func claimMission(at index: Int, catalog: Catalog = .shared) -> Int? {
        guard var daily = missions, daily.missions.indices.contains(index),
              daily.missions[index].isDone, !daily.missions[index].claimed else { return nil }
        daily.missions[index].claimed = true
        var gained = catalog.economy.missionRewardDust
        if !daily.bonusClaimed && daily.missions.allSatisfy(\.claimed) {
            daily.bonusClaimed = true
            gained += catalog.economy.missionBonusDust
        }
        missions = daily
        dust += gained
        return gained
    }
}

extension PlayerState {
    private enum CodingKeys: String, CodingKey {
        case oyster, drawState, nextSerial, pearlCards, findCards, oystersOpened
        case dust, stock, ownedSkins, equippedSkin, missions, noCrackStreak, adRewards
    }

    /// Les anciennes sauvegardes (sans poussière, stock ni skins) se chargent avec des valeurs de départ.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        oyster = try container.decode(Oyster.self, forKey: .oyster)
        drawState = try container.decode(DrawState.self, forKey: .drawState)
        nextSerial = try container.decode(Int.self, forKey: .nextSerial)
        pearlCards = try container.decode([PearlCard].self, forKey: .pearlCards)
        findCards = try container.decode([FindCard].self, forKey: .findCards)
        oystersOpened = try container.decode(Int.self, forKey: .oystersOpened)
        dust = try container.decodeIfPresent(Int.self, forKey: .dust) ?? 0
        let tuning = Catalog.shared.tuning
        stock = try container.decodeIfPresent(StockState.self, forKey: .stock) ?? StockState(count: tuning.oysterStockMax, lastRefillAt: 0)
        let starters = Catalog.shared.economy.skins.filter { $0.grant == "start" }.map(\.id)
        ownedSkins = try container.decodeIfPresent([String].self, forKey: .ownedSkins) ?? starters
        equippedSkin = try container.decodeIfPresent(String.self, forKey: .equippedSkin) ?? (starters.first ?? "")
        missions = try container.decodeIfPresent(DailyMissions.self, forKey: .missions)
        noCrackStreak = try container.decodeIfPresent(Int.self, forKey: .noCrackStreak) ?? 0
        adRewards = try container.decodeIfPresent(DailyCount.self, forKey: .adRewards)
    }
}

/// Un compteur qui repart de zéro chaque jour.
public struct DailyCount: Codable, Sendable, Equatable {
    public let day: String
    public let count: Int

    public init(day: String, count: Int) {
        self.day = day
        self.count = count
    }
}

/// « N° 000042 ».
public func serialLabel(_ serial: Int) -> String {
    let digits = String(serial)
    return "N° " + String(repeating: "0", count: max(0, 6 - digits.count)) + digits
}
