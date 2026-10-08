// Économie de l'app : barèmes, missions, skins, produits. Lus dans catalog.json
// (source : src/core/appEconomy.ts). Docs : docs/duo-gadget.md §6 bis à §6 quater.

public struct AppSkin: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let description: String
    /// « oyster », « clam » (bénitier) ou « gold ».
    public let style: String
    /// Prix en poussière d'or ; nil = pas à vendre en poussière.
    public let dustPrice: Int?
    /// Produit de la boutique Apple ; nil = pas à vendre.
    public let productId: String?
    /// « start » (offert au départ), « signup » (réservé aux inscrits) ou nil.
    public let grant: String?
    public let shellLight: String
    public let shellDark: String
    public let nacreLight: String
    public let nacreShade: String
    public let rim: String?
}

public struct AppConsumable: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let oysters: Int
    public let dust: Int
}

public struct MissionTemplate: Codable, Sendable, Equatable {
    public let kind: MissionKind
    public let goals: [Int]
}

public enum MissionKind: String, Codable, Sendable {
    case open, lustreA, lustreS, rare, noCrack, sell, share
}

public struct Economy: Codable, Sendable {
    public let oysterDustPrice: Int
    public let goldCoinDust: Int
    public let missionsPerDay: Int
    public let missionRewardDust: Int
    public let missionBonusDust: Int
    public let boughtPearlLustre: Lustre
    public let sellDustByTier: [Int]
    public let missingPearlPriceByTier: [Int?]
    public let rareMissionTier: Int
    public let missions: [MissionTemplate]
    public let skins: [AppSkin]
    public let consumables: [AppConsumable]

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

    /// Prix d'une perle manquante ; nil si elle ne s'achète pas (★ et ★★).
    public func missingPearlPrice(_ pearlId: String) -> Int? {
        economy.missingPearlPriceByTier[tier(of: pearlId)]
    }
}
