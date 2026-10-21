// Calendrier de connexion de l'app : une case par jour, jamais pendant le tutoriel.
import Foundation
import Testing
@testable import PearlCore

private let catalog = Catalog.shared
private let tuning = catalog.tuning

/// Une partie qui a fini le tutoriel.
private func playerAfterTutorial() -> PlayerState {
    let rng = seededRng(3)
    var player = PlayerState.new(rng, tuning, now: 0)
    while player.isInTutorial() { _ = player.reveal(lustre: .B, cracked: false, now: 0, rng: rng, tuning: tuning) }
    return player
}

@Test func joursEntreDeuxDates() {
    #expect(daysBetween("2026-10-19", "2026-10-20") == 1)
    #expect(daysBetween("2026-12-31", "2027-01-01") == 1)
    #expect(daysBetween("2028-02-28", "2028-03-01") == 2)
    #expect(daysBetween("2026-10-19", "2026-10-19") == 0)
}

@Test func pasDeCalendrierPendantLeTutoriel() {
    var player = PlayerState.new(seededRng(1), tuning, now: 0)
    #expect(!player.canClaimDaily(day: "2026-10-19"))
    #expect(player.claimDaily(day: "2026-10-19") == nil)
}

@Test func uneCaseParJour() {
    var player = playerAfterTutorial()
    // Sans compter ce que rapportent les niveaux et les succès que la case fait gagner.
    let bonus = { (oysters: (player.levelUp?.oysters ?? 0) + achievementRewards(player).oysters,
                   dust: (player.levelUp?.dust ?? 0) + achievementRewards(player).dust) }
    let stock = player.stock.count - bonus().oysters, dust = player.dust - bonus().dust
    let first = catalog.economy.calendar[0]
    #expect(player.claimDaily(day: "2026-10-19") == first)
    #expect(player.stock.count - bonus().oysters == stock + first.oysters)
    #expect(player.dust - bonus().dust == dust + first.dust)
    #expect(player.claimDaily(day: "2026-10-19") == nil)
    #expect(player.claimDaily(day: "2026-10-20") == catalog.economy.calendar[1])
    #expect(player.login.streak == 2)
}

@Test func leCalendrierRecommenceApresLaSeptiemeCase() throws {
    var player = playerAfterTutorial()
    let calendar = catalog.economy.calendar
    #expect(calendar.count == 7)
    for day in 1...calendar.count { _ = player.claimDaily(day: String(format: "2026-11-%02d", day)) }
    #expect(player.login.calendarIndex == 0)
    #expect(player.claimDaily(day: "2026-11-08") == calendar[0])
    #expect(player.login.streak == 8)
}

@Test func uneAncienneSauvegardeACalendrierVierge() throws {
    var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(playerAfterTutorial())) as! [String: Any]
    json.removeValue(forKey: "login")
    let loaded = try JSONDecoder().decode(PlayerState.self, from: JSONSerialization.data(withJSONObject: json))
    #expect(loaded.login == .initial)
}
