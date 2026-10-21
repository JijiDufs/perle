// Succès, titres et statistiques (lot 1.3) : mêmes avancements que la webapp, déblocage après chaque action,
// rattrapage des parties d'avant les succès, nouvelles missions.
import Foundation
import Testing
@testable import PearlCore

private let catalog = Catalog.shared
private let tuning = catalog.tuning

/// Cas de référence produits par tests/ios-export.test.ts (`achievementStates`).
private struct AchievementParity: Decodable {
    struct State: Decodable {
        struct Card: Decodable { let pearlId: String; let traits: PearlTraits? }
        struct Stats: Decodable { let emptyOysters: Int; let lustreS: Int; let bestCrackFreeStreak: Int; let sold: Int }
        let oystersOpened: Int
        let pearlCards: [Card]
        let findIds: [String]
        let stats: Stats
        let bestStreak: Int
        let progress: [String: [Int]]
    }
    let achievementStates: [State]
}

/// Ce qu'ont rapporté les succès obtenus (pour les tests qui comptent le stock, la poussière ou la réputation).
func achievementRewards(_ player: PlayerState) -> AchievementReward {
    let rewards = player.achievements.map { catalog.reward(of: catalog.achievement($0)!) }
    return AchievementReward(oysters: rewards.reduce(0) { $0 + $1.oysters }, dust: rewards.reduce(0) { $0 + $1.dust },
                             reputation: rewards.reduce(0) { $0 + $1.reputation })
}

private func card(_ pearlId: String, serial: Int, lustre: Lustre = .B, cracked: Bool = false, traits: PearlTraits? = nil) -> PearlCard {
    PearlCard(serial: serial, pearlId: pearlId, sizeMm: 8, value: 10, lustre: lustre, cracked: cracked, foundAt: 0, traits: traits)
}

@Test func memesAvancementsQueLaWebapp() throws {
    let url = try #require(Bundle.module.url(forResource: "parity", withExtension: "json"))
    let parity = try JSONDecoder().decode(AchievementParity.self, from: Data(contentsOf: url))
    #expect(parity.achievementStates.count >= 5)
    for state in parity.achievementStates {
        var player = PlayerState.new(seededRng(1), tuning, now: 0)
        player.oystersOpened = state.oystersOpened
        player.pearlCards = state.pearlCards.enumerated().map { card($1.pearlId, serial: $0, traits: $1.traits) }
        player.findCards = state.findIds.enumerated().map { FindCard(serial: 1000 + $0, findId: $1, value: 1, foundAt: 0) }
        player.stats.emptyOysters = state.stats.emptyOysters
        player.stats.lustreS = state.stats.lustreS
        player.stats.bestCrackFreeStreak = state.stats.bestCrackFreeStreak
        player.stats.sold = state.stats.sold
        player.login.bestStreak = state.bestStreak
        for (id, expected) in state.progress {
            let achievement = try #require(catalog.achievement(id))
            let (done, goal) = player.progress(of: achievement)
            #expect([done, goal] == expected, "\(id) après \(state.oystersOpened) huîtres")
        }
    }
}

@Test func lesSuccesTombentApresChaqueActionAvecLeurRecompense() {
    var player = PlayerState.new(seededRng(3), tuning, now: 0)
    let rng = seededRng(4)
    // La première huître du tutoriel est la perle rosée : « Première perle ».
    _ = player.reveal(lustre: .B, cracked: false, now: 0, rng: rng, tuning: tuning)
    #expect(player.achievements == ["premiere-perle"])
    #expect(player.unseenAchievements == ["premiere-perle"])
    let reward = catalog.reward(of: catalog.achievement("premiere-perle")!)
    let level = player.levelUp
    #expect(player.stock.count == tuning.oysterStockMax + reward.oysters + (level?.oysters ?? 0))
    #expect(player.dust == reward.dust + (level?.dust ?? 0))
    player.acknowledgeAchievement("premiere-perle")
    #expect(player.unseenAchievements.isEmpty)
    // Une seule fois.
    _ = player.reveal(lustre: .B, cracked: false, now: 0, rng: rng, tuning: tuning)
    #expect(player.achievements.filter { $0 == "premiere-perle" }.count == 1)
}

@Test func statistiquesCommeLaWebapp() {
    var player = PlayerState.new(seededRng(5), tuning, now: 0)
    let rng = seededRng(6)
    // Lustre S sans fêlure : compté ; fêlé : non, et la série repart de zéro.
    player.oyster = Oyster(pearlId: "white", sizeMm: 6, findId: nil, traits: nil)
    _ = player.reveal(lustre: .S, cracked: false, now: 0, rng: rng, tuning: tuning)
    player.oyster = Oyster(pearlId: "white", sizeMm: 6, findId: nil, traits: nil)
    _ = player.reveal(lustre: .S, cracked: true, now: 0, rng: rng, tuning: tuning)
    #expect(player.stats.lustreS == 1)
    #expect(player.noCrackStreak == 0 && player.stats.bestCrackFreeStreak == 1)
    // Une huître vide « fêlée » ne casse pas la série ; une trouvaille n'est pas une huître vide.
    player.oyster = Oyster(pearlId: "empty", sizeMm: 0, findId: nil, traits: nil)
    _ = player.reveal(lustre: .C, cracked: true, now: 0, rng: rng, tuning: tuning)
    player.oyster = Oyster(pearlId: "empty", sizeMm: 0, findId: "tong", traits: nil)
    _ = player.reveal(lustre: .C, cracked: false, now: 0, rng: rng, tuning: tuning)
    #expect(player.noCrackStreak == 2 && player.stats.emptyOysters == 1)
}

@Test func revendreMissionsNiveauEtPoissonComptent() {
    var player = PlayerState.new(seededRng(7), tuning, now: 0)
    player.pearlCards = (0..<25).map { card("white", serial: $0) }
    _ = player.sell(serial: 0)
    #expect(player.stats.sold == 1)
    _ = player.sellAllDuplicates()
    #expect(player.stats.sold == 24 && player.hasAchievement("alchimiste"))

    player.missions = DailyMissions(day: "2026-10-21", missions: [
        Mission(kind: .find, goal: 1, progress: 1, claimed: false),
        Mission(kind: .fish, goal: 1, progress: 0, claimed: false),
        Mission(kind: .open, goal: 1, progress: 1, claimed: false),
    ], bonusClaimed: false)
    _ = player.claimMission(at: 0)
    #expect(player.stats.missions == 1)

    // Le poisson rattrapé : la mission avance, le succès tombe ; une perle rendue à la relance ne compte pas.
    player.stolenCard = card("rose", serial: 99)
    _ = player.resolveTheft(caught: true)
    #expect(player.stats.fishCaught == 0)
    player.stolenCard = card("rose", serial: 100)
    #expect(player.catchThief() == catalog.economy.fishThief.catchBonusDust)
    #expect(player.stats.fishCaught == 1 && player.hasAchievement("poisson"))
    #expect(player.missions?.missions[1].isDone == true)

    // Niveau 5 par la réputation : le succès de niveau tombe à l'action suivante.
    player.gainReputation((1..<5).reduce(0) { $0 + catalog.xpToNext($1) })
    _ = player.claimMission(at: 2)
    #expect(player.hasAchievement("niveau-5"))
}

@Test func onNePorteQueLesTitresGagnes() {
    var player = PlayerState.new(seededRng(8), tuning, now: 0)
    player.wearTitle("cent-huitres")
    #expect(player.title == nil)
    player.oystersOpened = 100
    _ = player.claimDaily(day: "2026-10-21")
    #expect(player.earnedTitles().map(\.id) == ["cent-huitres"])
    player.wearTitle("cent-huitres")
    #expect(player.wornTitle() == "Pêcheur assidu")
    #expect(player.wornTitle(catalog: catalog.localized("en")) == "Dedicated fisher")
    player.wearTitle(nil)
    #expect(player.title == nil)
}

@Test func uneSauvegarde10ReçoitSesSuccesEnUneFenetre() throws {
    let url = try #require(Bundle.module.url(forResource: "save-1.0", withExtension: "json"))
    let player = try JSONDecoder().decode(PlayerState.self, from: Data(contentsOf: url))
    #expect(!player.achievements.isEmpty)
    #expect(player.unseenAchievements.isEmpty, "pas de bannière en rafale")
    let catchUp = try #require(player.achievementCatchUp)
    #expect(catchUp.count == player.achievements.count)
    let rewards = player.achievements.map { catalog.reward(of: catalog.achievement($0)!) }
    #expect(catchUp.oysters == rewards.reduce(0) { $0 + $1.oysters })
    #expect(catchUp.dust == rewards.reduce(0) { $0 + $1.dust })
    // Rechargée : rien de redonné.
    let again = try JSONDecoder().decode(PlayerState.self, from: JSONEncoder().encode(player))
    #expect(again == player)
}

@Test func unePartie12ReçoitSesSuccesSansRienPerdre() throws {
    // Une partie des lots 1.1 / 1.2 : réputation, mais pas encore de statistiques ni de succès.
    var old = PlayerState.new(seededRng(9), tuning, now: 0)
    old.oystersOpened = 120
    old.noCrackStreak = 12
    old.pearlCards = [card("white", serial: 1, lustre: .S), card("black", serial: 2), card("rose", serial: 3, lustre: .S, cracked: true)]
    old.reputation = 900
    old.rewardedLevel = catalog.levelProgress(reputation: 900).level
    old.login.bestStreak = 7
    var raw = try #require(try JSONSerialization.jsonObject(with: JSONEncoder().encode(old)) as? [String: Any])
    for key in ["stats", "achievements", "unseenAchievements", "achievementCatchUp", "title"] { raw[key] = nil }
    let player = try JSONDecoder().decode(PlayerState.self, from: JSONSerialization.data(withJSONObject: raw))

    #expect(player.pearlCards == old.pearlCards && player.oystersOpened == 120)
    #expect(player.stats.lustreS == 1 && player.stats.bestCrackFreeStreak == 12)
    for id in ["premiere-perle", "dix-huitres", "cent-huitres", "perle-noire", "lustre-s", "sans-felure-10", "serie-7"] {
        #expect(player.hasAchievement(id), "\(id)")
    }
    #expect(player.achievementCatchUp?.count == player.achievements.count)
    #expect(player.unseenAchievements.isEmpty)
    let rewards = player.achievements.map { catalog.reward(of: catalog.achievement($0)!) }
    #expect(player.reputation == 900 + rewards.reduce(0) { $0 + $1.reputation })
}

@Test func lesNouvellesMissionsSontTirees() {
    let days = ["11", "12"].flatMap { month in (1...28).map { "2026-\(month)-\(String(format: "%02d", $0))" } }
    let kinds = days.flatMap { DailyMissions.forDay($0, economy: catalog.economy).missions.map(\.kind) }
    #expect(kinds.contains(.find) && kinds.contains(.fish))
}
