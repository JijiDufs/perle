// Niveaux et réputation (lot 1.1) : gains, récompenses une seule fois, sauvegarde 1.0 rétroactive.
import Foundation
import Testing
@testable import PearlCore

private let catalog = Catalog.shared
private let tuning = catalog.tuning
private let levels = catalog.economy.levels

@Test func lesDixPremiersNiveauxVontPlusVite() {
    #expect(catalog.xpToNext(1) < Int(tuning.levelBaseXp + tuning.levelGrowthXp))
    for level in 1..<60 { #expect(catalog.xpToNext(level + 1) > catalog.xpToNext(level), "niveau \(level)") }
    #expect(catalog.levelProgress(reputation: 0) == LevelProgress(level: 1, into: 0, needed: catalog.xpToNext(1)))
    #expect(catalog.levelProgress(reputation: .max / 2).level == tuning.maxLevel)
}

@Test func rangsDuCahier() {
    #expect(catalog.rank(forLevel: 1).id == "pecheur")
    #expect(catalog.rank(forLevel: 4).id == "pecheur")
    #expect(catalog.rank(forLevel: 5).id == "perlier")
    #expect(catalog.rank(forLevel: 99).id == "maison")
    #expect(catalog.nextRank(after: 5)?.id == "artisan")
    #expect(catalog.nextRank(after: 50) == nil)
    #expect(Catalog.shared.localized("en").ranks.first?.title == "Fisher")
}

@Test func chaqueNiveauEstRecompenseUneSeuleFois() {
    var player = PlayerState.new(seededRng(1), tuning, now: 0)
    let stock = player.stock.count
    let toFive = (1..<5).reduce(0) { $0 + catalog.xpToNext($1) }
    player.gainReputation(toFive)
    // Niveaux 2 à 5 : des huîtres seulement au 5 (tous les `rewardOystersEvery` niveaux), qui est aussi un rang.
    let expectedOysters = (levels.rewardOystersEvery == 5 ? levels.rewardOysters : 0) + levels.rankRewardOysters
    let expectedDust = 4 * levels.rewardDust + levels.rankRewardDust
    #expect(player.rewardedLevel == 5)
    #expect(player.levelUp == LevelUp(from: 1, to: 5, oysters: expectedOysters, dust: expectedDust, retroactive: false))
    #expect(player.stock.count == stock + expectedOysters)
    #expect(player.dust == expectedDust)
    // Un peu plus sans changer de niveau : rien de plus ; la fête reste à faire.
    player.gainReputation(1)
    #expect(player.dust == expectedDust)
    player.acknowledgeLevelUp()
    #expect(player.levelUp == nil)
    // Un niveau de plus : une nouvelle fête, qui part du niveau 5.
    player.gainReputation(catalog.xpToNext(5))
    #expect(player.levelUp?.from == 5 && player.levelUp?.to == 6)
}

@Test func ouvrirMissionsEtCalendrierRapportentDeLaReputation() {
    let rng = seededRng(4)
    var player = PlayerState.new(rng, tuning, now: 0)
    // Première huître du tutoriel : la perle rosée, une découverte.
    let first = player.oyster.pearlId
    _ = player.reveal(lustre: .S, cracked: false, now: 0, rng: rng, tuning: tuning)
    #expect(player.reputation == catalog.reputationForPearl(first, lustre: .S, cracked: false, discovery: true)
        + achievementRewards(player).reputation)
    // Fini le tutoriel, puis le calendrier et une mission.
    while player.isInTutorial() { _ = player.reveal(lustre: .B, cracked: false, now: 0, rng: rng, tuning: tuning) }
    let before = player.reputation
    _ = player.claimDaily(day: "2026-10-21")
    #expect(player.reputation == before + levels.calendarReputation)
    player.refresh(now: 0, day: "2026-10-21", tuning: tuning)
    let index = player.missions!.missions.firstIndex { $0.kind == .open } ?? 0
    player.missions!.missions[index].progress = player.missions!.missions[index].goal
    _ = player.claimMission(at: index)
    #expect(player.reputation == before + levels.calendarReputation + levels.missionReputation)
}

@Test func uneSauvegarde10SeChargeSansRienPerdreEtDevientRetroactive() throws {
    let url = try #require(Bundle.module.url(forResource: "save-1.0", withExtension: "json"))
    let data = try Data(contentsOf: url)
    let raw = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    #expect(raw["reputation"] == nil, "c'est bien une sauvegarde d'avant les niveaux")
    let player = try JSONDecoder().decode(PlayerState.self, from: data)

    // Rien de perdu (hors récompenses de niveau, ajoutées) : cartes, huîtres ouvertes, missions, calendrier, skins.
    let rawStock = try #require(raw["stock"] as? [String: Any])
    #expect(player.pearlCards.count == (raw["pearlCards"] as? [Any])?.count)
    #expect(player.findCards.count == (raw["findCards"] as? [Any])?.count)
    #expect(player.oystersOpened == raw["oystersOpened"] as? Int)
    #expect(player.nextSerial == raw["nextSerial"] as? Int)
    #expect(player.missions != nil && player.login.lastClaimDay == "2026-10-21")
    #expect(player.ownedSkins == raw["ownedSkins"] as? [String])

    // Réputation d'après la collection, une seule fête « Tu es niveau N », récompenses données une fois.
    let expected = PlayerState.retroactiveReputation(pearlCards: player.pearlCards, findCards: player.findCards,
                                                     oystersOpened: player.oystersOpened, catalog: catalog)
    // Les succès déjà remplis (lot 1.3) ajoutent leur réputation et leurs récompenses.
    let achievements = player.achievements.map { catalog.reward(of: catalog.achievement($0)!) }
    #expect(player.reputation == expected + achievements.reduce(0) { $0 + $1.reputation } && expected > 0)
    let level = catalog.levelProgress(reputation: player.reputation).level
    #expect(level > 1)
    #expect(player.rewardedLevel == level)
    let up = try #require(player.levelUp)
    #expect(up.from == 1 && up.to == level && up.retroactive)
    let catchUp = player.achievementCatchUp
    #expect(player.stock.count == rawStock["count"] as! Int + up.oysters + (catchUp?.oysters ?? 0))
    #expect(player.dust == raw["dust"] as! Int + up.dust + (catchUp?.dust ?? 0))

    // Rechargée après la mise à jour : plus rien de rétroactif, rien de redonné.
    let again = try JSONDecoder().decode(PlayerState.self, from: JSONEncoder().encode(player))
    #expect(again == player)
}
