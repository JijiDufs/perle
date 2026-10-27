// Niveaux, réputation et rangs (miroir de src/core/levels.ts, lot 1.1 de docs/ios-feuille-de-route.md).
// Gains de réputation : src/tuning.ts ; courbe accélérée des premiers niveaux et récompenses de l'app :
// `APP_LEVELS` (src/core/appEconomy.ts). Le niveau se déduit de la réputation ; chaque niveau n'est
// récompensé qu'une fois (`rewardedLevel`).
import Foundation

/// Un rang de prestige (Pêcheur, Perlier…), atteint à un niveau.
public struct Rank: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public internal(set) var title: String
    public let level: Int
}

/// Niveaux de l'app : départ accéléré, récompenses en économie lente, réputation des missions et du calendrier.
public struct LevelEconomy: Codable, Sendable, Equatable {
    public struct FastStart: Codable, Sendable, Equatable {
        /// À partir de ce niveau, la courbe est celle de la webapp.
        public let levels: Int
        /// Part de la réputation habituelle demandée au niveau 1.
        public let factor: Double
    }
    public let fastStart: FastStart
    public let rewardDust: Int
    /// Des huîtres seulement tous les `rewardOystersEvery` niveaux (à chaque niveau, elles faisaient boule de neige).
    public let rewardOysters: Int
    public let rewardOystersEvery: Int
    public let rankRewardOysters: Int
    public let rankRewardDust: Int
    public let missionReputation: Int
    public let calendarReputation: Int
}

public struct LevelProgress: Sendable, Equatable {
    public let level: Int
    /// Réputation acquise dans le niveau en cours.
    public let into: Int
    /// Réputation nécessaire pour le niveau suivant (0 au niveau maximum).
    public let needed: Int
}

/// Ce que rapporte un niveau atteint.
public struct LevelReward: Sendable, Equatable {
    public let oysters: Int
    public let dust: Int
    /// Écrins : un à chaque nouveau rang (`APP_ECRINS` ; les autres viennent des huîtres ouvertes).
    public let ecrins: Int
    /// Rang atteint à ce niveau, s'il y en a un.
    public let rank: Rank?
}

/// Une montée de niveau à fêter (une seule fenêtre, même si plusieurs niveaux ont été franchis).
public struct LevelUp: Codable, Sendable, Equatable {
    /// Niveau avant, niveau atteint.
    public let from: Int
    public internal(set) var to: Int
    /// Récompenses de tous les niveaux franchis (déjà données).
    public internal(set) var oysters: Int
    public internal(set) var dust: Int
    /// Écrins gagnés (absent des fêtes sauvegardées avant la 1.4).
    public internal(set) var ecrins: Int?
    /// Partie de la 1.0 : réputation calculée d'après la collection (« Tu es niveau N »).
    public internal(set) var retroactive: Bool
}

extension Catalog {
    /// Réputation pour passer du niveau `level` au suivant (même calcul que `xpToNext` en TypeScript).
    public func xpToNext(_ level: Int) -> Int {
        let fast = economy.levels.fastStart
        let factor = level < fast.levels
            ? fast.factor + (1 - fast.factor) * Double(level - 1) / Double(fast.levels - 1)
            : 1
        let base = tuning.levelBaseXp + tuning.levelGrowthXp * pow(Double(level), tuning.levelGrowthPower)
        return Int(jsRound(base * factor))
    }

    public func levelProgress(reputation: Int) -> LevelProgress {
        var level = 1
        var rest = max(0, reputation)
        while level < tuning.maxLevel && rest >= xpToNext(level) {
            rest -= xpToNext(level)
            level += 1
        }
        let atMax = level >= tuning.maxLevel
        return LevelProgress(level: level, into: atMax ? 0 : rest, needed: atMax ? 0 : xpToNext(level))
    }

    public func rank(forLevel level: Int) -> Rank {
        ranks.last { level >= $0.level } ?? ranks[0]
    }

    /// Prochain rang, ou nil au dernier.
    public func nextRank(after level: Int) -> Rank? {
        ranks.first { $0.level > level }
    }

    /// Récompense en arrivant au niveau `level` : de la poussière d'or, des huîtres de temps en temps, un bonus en
    /// changeant de rang.
    public func levelReward(_ level: Int) -> LevelReward {
        let rank = ranks.first { $0.level == level && $0.level > 1 }
        let levels = economy.levels
        let oysters = level % levels.rewardOystersEvery == 0 ? levels.rewardOysters : 0
        return LevelReward(oysters: oysters + (rank == nil ? 0 : levels.rankRewardOysters),
                           dust: levels.rewardDust + (rank == nil ? 0 : levels.rankRewardDust),
                           ecrins: rank == nil ? 0 : economy.ecrins.rankEcrins, rank: rank)
    }

    /// Réputation d'un écrin ouvert : éclat parfait, premier bijou de sa rareté.
    public func reputationForEcrin(perfect: Bool, discovery: Bool) -> Int {
        tuning.repEcrin + (perfect ? tuning.repPerfect : 0) + (discovery ? tuning.repDiscovery : 0)
    }

    /// Réputation d'une huître ouverte : sa rareté, le lustre S / A d'une perle non fêlée, une première perle de sa sorte.
    public func reputationForPearl(_ pearlId: String, lustre: Lustre, cracked: Bool, discovery: Bool) -> Int {
        if pearlId == "empty" { return tuning.repOyster }
        let bonus = cracked ? 0 : lustre == .S ? tuning.repLustreS : lustre == .A ? tuning.repLustreA : 0
        return tuning.repOyster + tuning.repPerTier * tier(of: pearlId) + bonus + (discovery ? tuning.repDiscovery : 0)
    }

    /// Réputation d'une trouvaille (elle ne se fêle pas, pas de lustre).
    public func reputationForFind(tier: Int, discovery: Bool) -> Int {
        tuning.repOyster + tuning.repPerTier * tier + (discovery ? tuning.repDiscovery : 0)
    }
}

extension PlayerState {
    /// Ajoute de la réputation et donne les récompenses des niveaux franchis (une seule fois par niveau).
    /// Les montées de niveau s'accumulent dans `levelUp` jusqu'à ce que l'écran les ait fêtées.
    public mutating func gainReputation(_ amount: Int, catalog: Catalog = .shared) {
        guard amount > 0 else { return }
        reputation += amount
        let level = catalog.levelProgress(reputation: reputation).level
        guard level > rewardedLevel else { return }
        var up = levelUp ?? LevelUp(from: rewardedLevel, to: rewardedLevel, oysters: 0, dust: 0, ecrins: 0, retroactive: false)
        for reached in (rewardedLevel + 1)...level {
            let reward = catalog.levelReward(reached)
            stock.count += reward.oysters
            dust += reward.dust
            ecrins += reward.ecrins
            up.oysters += reward.oysters
            up.dust += reward.dust
            up.ecrins = (up.ecrins ?? 0) + reward.ecrins
        }
        up.to = level
        rewardedLevel = level
        levelUp = up
    }

    /// La montée de niveau a été fêtée.
    public mutating func acknowledgeLevelUp() {
        levelUp = nil
    }

    /// Réputation d'une partie de la 1.0, d'après ce qu'elle contient : chaque carte comme si elle venait d'être
    /// pêchée, une découverte par sorte de perle et de trouvaille, et la réputation de base pour les huîtres
    /// qui n'ont plus de carte (vides, revendues, volées). Les missions et le calendrier passés ne comptent pas.
    static func retroactiveReputation(pearlCards: [PearlCard], findCards: [FindCard], oystersOpened: Int, catalog: Catalog) -> Int {
        let pearls = pearlCards.reduce(0) { $0 + catalog.reputationForPearl($1.pearlId, lustre: $1.lustre, cracked: $1.cracked, discovery: false) }
        let finds = findCards.reduce(0) { $0 + catalog.reputationForFind(tier: catalog.find($1.findId).tier, discovery: false) }
        let discoveries = Set(pearlCards.map(\.pearlId)).count + Set(findCards.map(\.findId)).count
        let withoutCard = max(0, oystersOpened - pearlCards.count - findCards.count)
        return pearls + finds + discoveries * catalog.tuning.repDiscovery + withoutCard * catalog.tuning.repOyster
    }
}
