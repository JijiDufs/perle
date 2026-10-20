// Règles de l'économie de l'app : stock, comptoir, poussière d'or, skins, missions.
import Testing
@testable import PearlCore

private let catalog = Catalog.shared
private let tuning = catalog.tuning
private let minute = 60_000.0

/// Une carte de perle pour les tests.
private func card(_ serial: Int, _ pearlId: String, value: Double = 10, mark: String? = nil) -> PearlCard {
    PearlCard(serial: serial, pearlId: pearlId, sizeMm: 6, value: value, lustre: .B, cracked: false, foundAt: 0,
              traits: mark.map { PearlTraits(shape: "ronde", overtone: "argente", mark: $0, seed: 0.5) })
}

private func newPlayer() -> PlayerState {
    var player = PlayerState.new(seededRng(1), tuning, now: 0)
    player.refresh(now: 0, day: "2026-10-08", tuning: tuning)
    return player
}

@Test func nouvellePartie() {
    let player = newPlayer()
    #expect(player.stock.count == tuning.oysterStockMax)
    #expect(player.ownedSkins == ["lagon"])
    #expect(player.equippedSkin == "lagon")
    #expect(player.dust == 0)
    #expect(player.missions?.missions.count == catalog.economy.missionsPerDay)
}

@Test func leStockSeVideEtRevient() {
    var stock = StockState(count: 1, lastRefillAt: 0)
    stock = consumeOyster(stock, now: 0, tuning)!
    #expect(stock.count == 0)
    #expect(consumeOyster(stock, now: 0, tuning) == nil)
    let interval = tuning.oysterRechargeMinutes * minute
    #expect(refreshStock(stock, now: interval * 2.5, tuning).count == 2)
    #expect(nextRefillIn(stock, now: interval * 0.25, tuning) == interval * 0.75)
}

@Test func leStockEstPleinAuBoutDuCompteARebours() {
    let interval = tuning.oysterRechargeMinutes * minute
    let stock = StockState(count: tuning.oysterStockMax - 3, lastRefillAt: 0)
    #expect(fullStockIn(stock, now: interval * 0.5, tuning) == interval * 2.5)
    #expect(refreshStock(stock, now: interval * 3, tuning).count == tuning.oysterStockMax)
    #expect(fullStockIn(stock, now: interval * 3, tuning) == nil)
    #expect(fullStockIn(StockState(count: tuning.oysterStockMax + 2, lastRefillAt: 0), now: 0, tuning) == nil)
}

@Test func lesHuitresAcheteesDepassentLeMaximum() {
    var player = newPlayer()
    player.grant(catalog.economy.consumables.first { $0.oysters == 10 }!)
    #expect(player.stock.count == tuning.oysterStockMax + 10)
    #expect(refreshStock(player.stock, now: 999 * minute, tuning).count == tuning.oysterStockMax + 10)
}

@Test func ouvrirConsommeUneHuitre() {
    var player = newPlayer()
    let rng = seededRng(2)
    // Les huîtres du tutoriel sont offertes ; les suivantes coûtent une huître du stock.
    // (Sans compter les huîtres gagnées en montant de niveau.)
    let levelOysters = { player.levelUp?.oysters ?? 0 }
    for _ in catalog.tutorialPearls { _ = player.reveal(lustre: .B, cracked: false, now: 0, rng: rng, tuning: tuning) }
    #expect(player.stock.count - levelOysters() == tuning.oysterStockMax)
    _ = player.reveal(lustre: .B, cracked: false, now: 0, rng: rng, tuning: tuning)
    #expect(player.stock.count - levelOysters() == tuning.oysterStockMax - 1)
}

@Test func onNeRevendJamaisLeDernierExemplaire() {
    var player = newPlayer()
    player.pearlCards = [card(1, "white")]
    let result1 = player.sell(serial: 1)
    #expect(result1 == nil)
    player.pearlCards.append(card(2, "white"))
    let result2 = player.sell(serial: 2)
    #expect(result2 == catalog.sellDust("white"))
    #expect(player.pearlCards.count == 1)
}

@Test func toutRevendreGardeLeMeilleurEtLesMarques() {
    var player = newPlayer()
    player.pearlCards = [card(1, "white", value: 8), card(2, "white", value: 12), card(3, "white", value: 9, mark: "coeur"),
                         card(4, "black", value: 60), card(5, "black", value: 50), card(6, "rose")]
    let gained = player.sellAllDuplicates()
    #expect(Set(player.pearlCards.map(\.serial)) == [2, 3, 4, 6])
    #expect(gained == catalog.sellDust("white") + catalog.sellDust("black"))
}

@Test func laPoussiereAchete() {
    var player = newPlayer()
    player.dust = catalog.economy.oysterDustPrice
    let before = player.stock.count
    let result3 = player.buyOyster()
    #expect(result3)
    #expect(player.stock.count == before + 1)
    #expect(player.dust == 0)
    let result4 = player.buyOyster()
    #expect(!result4)
}

@Test func lesPubsDonnentDesHuitresTroisFoisParJour() {
    var player = newPlayer()
    let economy = catalog.economy
    let before = player.stock.count
    for _ in 0..<economy.rewardedAdsPerDay {
        let gained = player.claimAdReward(day: "2026-10-13")
        #expect(gained == economy.rewardedAdOysters)
    }
    #expect(player.stock.count == before + economy.rewardedAdOysters * economy.rewardedAdsPerDay)
    #expect(player.adRewardsLeft(day: "2026-10-13") == 0)
    #expect(player.claimAdReward(day: "2026-10-13") == nil)
    // Le lendemain, le compteur repart.
    #expect(player.adRewardsLeft(day: "2026-10-14") == economy.rewardedAdsPerDay)
}

@Test func skins() {
    var player = newPlayer()
    let result8 = player.buySkin("benitier")
    #expect(!result8)
    let result9 = player.equip("benitier")
    #expect(!result9)
    player.dust = 2000
    let result10 = player.buySkin("benitier")
    #expect(result10)
    #expect(player.dust == 0)
    let result11 = player.equip("benitier")
    #expect(result11)
    player.dust = 1_000_000
    let result12 = player.buySkin("or")
    #expect(!result12)
    player.grantSkin("or")
    let result13 = player.equip("or")
    #expect(result13)
}

@Test func lesMissionsSontLesMemesPourUnJour() {
    let economy = catalog.economy
    #expect(DailyMissions.forDay("2026-10-08", economy: economy) == DailyMissions.forDay("2026-10-08", economy: economy))
    let kinds = DailyMissions.forDay("2026-10-08", economy: economy).missions.map(\.kind)
    #expect(Set(kinds).count == kinds.count)
}

@Test func missionsEtBonus() {
    var player = newPlayer()
    player.missions = DailyMissions(day: "2026-10-08", missions: [
        Mission(kind: .open, goal: 2, progress: 0, claimed: false),
        Mission(kind: .sell, goal: 1, progress: 0, claimed: false),
        Mission(kind: .share, goal: 1, progress: 0, claimed: false),
    ], bonusClaimed: false)
    let rng = seededRng(3)
    _ = player.reveal(lustre: .C, cracked: false, now: 0, rng: rng, tuning: tuning)
    let result14 = player.claimMission(at: 0)
    #expect(result14 == nil)
    _ = player.reveal(lustre: .C, cracked: false, now: 0, rng: rng, tuning: tuning)
    let result15 = player.claimMission(at: 0)
    #expect(result15 == catalog.economy.missionRewardDust)
    let result16 = player.claimMission(at: 0)
    #expect(result16 == nil)
    player.recordShare()
    let result17 = player.claimMission(at: 2)
    #expect(result17 == catalog.economy.missionRewardDust)
    player.pearlCards = [card(90, "white"), card(91, "white")]
    _ = player.sell(serial: 91)
    let result18 = player.claimMission(at: 1)
    #expect(result18 == catalog.economy.missionRewardDust + catalog.economy.missionBonusDust)
}

@Test func lesMissionsChangentAvecLeJour() {
    var player = newPlayer()
    player.refresh(now: 0, day: "2026-10-09", tuning: tuning)
    #expect(player.missions?.day == "2026-10-09")
}
