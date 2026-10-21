// Succès et titres (miroir de src/core/achievements.ts, et des statistiques de src/core/progression.ts ; lot 1.3
// de docs/ios-feuille-de-route.md). La liste de l'app et ses récompenses en économie lente : `APP_ACHIEVEMENTS` et
// `APP_ACHIEVEMENT_REWARDS` (src/core/appEconomy.ts). Le Core met les statistiques et les succès à jour après chaque
// action ; l'écran montre une bannière par succès obtenu, au moment calme suivant.

public enum AchievementTier: String, Codable, Sendable {
    case bronze, argent, or
}

/// Ce que compte un succès (voir `AppAchievementMeasure` en TypeScript).
public enum AchievementMeasure: String, Codable, Sendable {
    case oysters, emptyOysters, pearlKinds, pearl, finds, find, album, mark, overtone, shapes
    case lustreS, crackFreeStreak, loginStreak, sold, missions, level, fishCaught
    case jewels, jewel, jewelRarities, jewelTypes, perfectGlints, variants
}

public struct Achievement: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public internal(set) var name: String
    public internal(set) var description: String
    public let tier: AchievementTier
    public let measure: AchievementMeasure
    /// La perle, trouvaille, album, marque ou reflet visé.
    public let target: String?
    public let goal: Int
    /// Caché tant qu'il n'est pas obtenu.
    public let secret: Bool?
    /// Titre que l'on peut porter une fois le succès obtenu.
    public internal(set) var title: String?
    /// Album de trouvailles complété : des huîtres en plus.
    public let album: Bool?
}

public struct AchievementReward: Codable, Sendable, Equatable {
    public let oysters: Int
    public let dust: Int
    public let reputation: Int

    public init(oysters: Int, dust: Int, reputation: Int) {
        self.oysters = oysters
        self.dust = dust
        self.reputation = reputation
    }
}

public struct AchievementRewards: Codable, Sendable, Equatable {
    public let bronze: AchievementReward
    public let argent: AchievementReward
    public let or: AchievementReward
    /// Huîtres en plus pour un album de trouvailles complété (la webapp donne un écrin).
    public let albumOysters: Int
}

/// Ce que comptent les succès et que la collection ne dit pas (statistiques de src/core/progression.ts).
public struct PlayerStats: Codable, Sendable, Equatable {
    /// Huîtres vides (pas les trouvailles).
    public var emptyOysters = 0
    /// Lustres S sur une perle non fêlée.
    public var lustreS = 0
    /// Meilleure série d'huîtres d'affilée sans fêlure.
    public var bestCrackFreeStreak = 0
    /// Doublons revendus au comptoir, missions du jour récupérées, poissons voleurs rattrapés.
    public var sold = 0
    public var missions = 0
    public var fishCaught = 0
    /// Éclats parfaits, et variantes rares révélées (écrins, 1.4).
    public var perfectGlints = 0
    public var variants = 0

    public init() {}

    private enum CodingKeys: String, CodingKey {
        case emptyOysters, lustreS, bestCrackFreeStreak, sold, missions, fishCaught, perfectGlints, variants
    }

    /// Les statistiques d'une version précédente se chargent avec 0 pour les nouvelles.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let count = { (key: CodingKeys) in try c.decodeIfPresent(Int.self, forKey: key) ?? 0 }
        emptyOysters = try count(.emptyOysters)
        lustreS = try count(.lustreS)
        bestCrackFreeStreak = try count(.bestCrackFreeStreak)
        sold = try count(.sold)
        missions = try count(.missions)
        fishCaught = try count(.fishCaught)
        perfectGlints = try count(.perfectGlints)
        variants = try count(.variants)
    }
}

/// Partie d'avant les succès : ceux déjà remplis au chargement, montrés en une seule fenêtre (récompenses déjà données).
public struct AchievementCatchUp: Codable, Sendable, Equatable {
    public internal(set) var count: Int
    public internal(set) var oysters: Int
    public internal(set) var dust: Int
}

extension Catalog {
    public func achievement(_ id: String) -> Achievement? {
        economy.achievements.first { $0.id == id }
    }

    /// Ce que rapporte un succès : selon son palier, et des huîtres en plus pour un album complété.
    public func reward(of achievement: Achievement) -> AchievementReward {
        let rewards = economy.achievementRewards
        let tier = switch achievement.tier {
        case .bronze: rewards.bronze
        case .argent: rewards.argent
        case .or: rewards.or
        }
        let album = achievement.album == true ? rewards.albumOysters : 0
        return AchievementReward(oysters: tier.oysters + album, dust: tier.dust, reputation: tier.reputation)
    }
}

extension PlayerState {
    /// Avancement d'un succès (fait, objectif), comme `progress` en TypeScript.
    public func progress(of achievement: Achievement, catalog: Catalog = .shared) -> (done: Int, goal: Int) {
        let traits = pearlCards.compactMap(\.traits)
        let target = achievement.target
        let done = switch achievement.measure {
        case .oysters: oystersOpened
        case .emptyOysters: stats.emptyOysters
        case .pearlKinds: Set(pearlCards.map(\.pearlId)).count
        case .pearl: pearlCards.contains { $0.pearlId == target } ? 1 : 0
        case .finds: findCards.count
        case .find: findCards.contains { $0.findId == target } ? 1 : 0
        case .album: Set(findCards.map(\.findId)).filter { catalog.find($0).album == target }.count
        case .mark: traits.contains { $0.mark == target } ? 1 : 0
        case .overtone: traits.contains { $0.overtone == target } ? 1 : 0
        case .shapes: Set(traits.map(\.shape)).count
        case .lustreS: stats.lustreS
        case .crackFreeStreak: stats.bestCrackFreeStreak
        case .loginStreak: login.bestStreak
        case .sold: stats.sold
        case .missions: stats.missions
        case .level: catalog.levelProgress(reputation: reputation).level
        case .fishCaught: stats.fishCaught
        case .jewels: jewelCards.count
        case .jewel: jewelCards.contains { $0.jewel.rarityId == target } ? 1 : 0
        case .jewelRarities: Set(jewelCards.map(\.jewel.rarityId)).count
        case .jewelTypes: Set(jewelCards.map(\.jewel.type)).intersection(catalog.jewels.mainTypes).count
        case .perfectGlints: stats.perfectGlints
        case .variants: stats.variants
        }
        return (min(done, achievement.goal), achievement.goal)
    }

    public func hasAchievement(_ id: String) -> Bool {
        achievements.contains(id)
    }

    /// Donne les succès nouvellement remplis, avec leurs récompenses (huîtres au-delà du maximum si besoin).
    /// Ils attendent leur bannière dans `unseenAchievements` ; en rattrapage (partie d'avant les succès), ils sont
    /// comptés dans `achievementCatchUp`, sans bannière. On recommence tant qu'il en tombe : la réputation d'un
    /// succès peut faire monter de niveau, et remplir un succès de niveau.
    mutating func unlockAchievements(catchUp: Bool = false, catalog: Catalog = .shared) {
        var unlocked = true
        while unlocked {
            unlocked = false
            for achievement in catalog.economy.achievements where !hasAchievement(achievement.id) {
                let (done, goal) = progress(of: achievement, catalog: catalog)
                guard done >= goal else { continue }
                unlocked = true
                achievements.append(achievement.id)
                let reward = catalog.reward(of: achievement)
                stock.count += reward.oysters
                dust += reward.dust
                if catchUp {
                    var notice = achievementCatchUp ?? AchievementCatchUp(count: 0, oysters: 0, dust: 0)
                    notice.count += 1
                    notice.oysters += reward.oysters
                    notice.dust += reward.dust
                    achievementCatchUp = notice
                } else {
                    unseenAchievements.append(achievement.id)
                }
                gainReputation(reward.reputation, catalog: catalog)
            }
        }
    }

    /// La bannière du succès a été montrée.
    public mutating func acknowledgeAchievement(_ id: String) {
        unseenAchievements.removeAll { $0 == id }
    }

    /// La fenêtre de rattrapage a été montrée.
    public mutating func acknowledgeAchievementCatchUp() {
        achievementCatchUp = nil
    }

    /// Les succès obtenus qui donnent un titre, dans l'ordre de la liste.
    public func earnedTitles(catalog: Catalog = .shared) -> [Achievement] {
        catalog.economy.achievements.filter { $0.title != nil && hasAchievement($0.id) }
    }

    /// Le titre porté (gardé par l'identifiant de son succès : il suit la langue de l'app).
    public func wornTitle(catalog: Catalog = .shared) -> String? {
        title.flatMap { catalog.achievement($0)?.title }
    }

    /// Porte le titre d'un succès obtenu (nil : aucun). Sans effet si le titre n'est pas gagné.
    public mutating func wearTitle(_ achievementId: String?, catalog: Catalog = .shared) {
        if let achievementId, !earnedTitles(catalog: catalog).contains(where: { $0.id == achievementId }) { return }
        title = achievementId
    }

    /// Statistiques d'une partie d'avant les succès, d'après ce qu'elle contient : les lustres S des perles gardées,
    /// la série sans fêlure en cours. Le reste (huîtres vides, reventes, missions) n'était pas compté et repart de 0.
    static func retroactiveStats(pearlCards: [PearlCard], noCrackStreak: Int) -> PlayerStats {
        var stats = PlayerStats()
        stats.lustreS = pearlCards.filter { $0.lustre == .S && !$0.cracked }.count
        stats.bestCrackFreeStreak = noCrackStreak
        return stats
    }
}
