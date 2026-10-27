// Économie de l'app : barèmes, missions, skins, produits. Lus dans catalog.json
// (source : src/core/appEconomy.ts). Docs : docs/duo-gadget.md §6 bis à §6 quater.

public struct AppSkin: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public internal(set) var name: String
    public internal(set) var description: String
    /// Silhouette : « oyster » ou « clam » (bénitier). Les couleurs vivent avec le dessin de l'app.
    public let style: String
    /// Prix en poussière d'or ; nil = pas à vendre en poussière.
    public let dustPrice: Int?
    /// Produit de la boutique Apple ; nil = pas à vendre.
    public let productId: String?
    /// « start » (offert au départ), « signup » (réservé aux inscrits) ou nil.
    public let grant: String?
}

public struct AppConsumable: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public internal(set) var name: String
    public let oysters: Int
    public let dust: Int
    /// Écrins à ouvrir (depuis le 2026-10-27).
    public let ecrins: Int
}

public struct MissionTemplate: Codable, Sendable, Equatable {
    public let kind: MissionKind
    public let goals: [Int]
}

public enum MissionKind: String, Codable, Sendable {
    case open, lustreA, lustreS, rare, noCrack, sell, share, find, fish
}

/// Le poisson voleur : il chipe parfois la perle juste après la révélation, quelle que soit sa rareté (src/core/appEconomy.ts).
public struct FishThief: Codable, Sendable, Equatable {
    /// Chance qu'une perle soit volée.
    public let chance: Double
    /// Poussière d'or quand on rattrape le poisson.
    public let catchBonusDust: Int
    /// Le poisson arrive sur la perle (ms), puis s'enfuit avec (ms) : le temps pour le toucher.
    public let arriveMs: Double
    public private(set) var fleeMs: Double
    /// Tolérance autour du poisson pour le toucher, en part de la taille de l'huître.
    public let hitRadius: Double
    /// Avec VoiceOver ou « Réduire les animations », la fuite dure ce nombre de fois plus longtemps (temps imposé).
    public let assistedFleeFactor: Double

    /// Le même poisson, qui fuit plus lentement (VoiceOver, « Réduire les animations »).
    public var assisted: FishThief {
        var slower = self
        slower.fleeMs *= assistedFleeFactor
        return slower
    }

    /// Le poisson peut encore être touché, `elapsedMs` après le début du vol.
    public func canCatch(elapsedMs: Double) -> Bool {
        elapsedMs >= 0 && elapsedMs <= arriveMs + fleeMs
    }
}

/// D'où viennent les écrins dans l'app (`APP_ECRINS`) : les huîtres ouvertes, les rangs, la poussière d'or, la boutique.
public struct EcrinEconomy: Codable, Sendable, Equatable {
    /// Un écrin toutes les `oysterEvery` huîtres ouvertes, et `rankEcrins` de plus à chaque rang.
    public let oysterEvery: Int
    public let rankEcrins: Int
    /// Un écrin acheté au comptoir.
    public let dustPrice: Int
}

public struct Economy: Codable, Sendable {
    public let oysterDustPrice: Int
    public let goldCoinDust: Int
    public let missionsPerDay: Int
    public let missionRewardDust: Int
    public let missionBonusDust: Int
    /// Pub récompensée : huîtres données par pub regardée, et nombre de pubs par jour.
    public let rewardedAdOysters: Int
    public let rewardedAdsPerDay: Int
    /// Calendrier de connexion : les 7 cases, et la fréquence du joker (jours).
    public let calendar: [CalendarReward]
    public let calendarJokerDays: Int
    public let sellDustByTier: [Int]
    public let rareMissionTier: Int
    public let missions: [MissionTemplate]
    public let fishThief: FishThief
    /// Niveaux : courbe accélérée au début, récompenses, réputation des missions et du calendrier.
    public let levels: LevelEconomy
    /// Succès de l'app et leurs récompenses.
    public internal(set) var achievements: [Achievement]
    public let achievementRewards: AchievementRewards
    public let ecrins: EcrinEconomy
    public internal(set) var skins: [AppSkin]
    public internal(set) var consumables: [AppConsumable]

    public func skin(_ id: String) -> AppSkin? { skins.first { $0.id == id } }
}

extension Catalog {
    /// Niveau de rareté d'une perle (0 = —, 5 = ★★), lu sur son symbole.
    public func tier(of pearlId: String) -> Int {
        raritySymbols.firstIndex(of: pearl(pearlId).rarity) ?? 0
    }

    /// Poussière d'or rapportée par la revente d'une perle de cette sorte.
    public func sellDust(_ pearlId: String) -> Int {
        economy.sellDustByTier[tier(of: pearlId)]
    }

    /// Poussière d'or rapportée par la revente d'un bijou de cette rareté (même barème que les perles).
    public func sellDust(jewel rarityId: String) -> Int {
        economy.sellDustByTier[jewelRarity(rarityId).tier]
    }
}
