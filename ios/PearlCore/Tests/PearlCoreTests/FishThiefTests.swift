// Le poisson voleur : il chipe parfois une perle, quelle que soit sa rareté, qu'on récupère en le touchant à temps.
import Foundation
import Testing
@testable import PearlCore

private let catalog = Catalog.shared
private let tuning = catalog.tuning
private let fish = catalog.economy.fishThief

/// Ouvre `count` huîtres (stock illimité) ; `onTheft` décide pour chaque vol.
private func open(_ count: Int, seed: UInt32 = 3, onTheft: (PearlCard) -> Bool? = { _ in false })
    -> (player: PlayerState, stolen: [PearlCard], during: [Int])
{
    let rng = seededRng(seed), thiefRng = seededRng(seed + 100)
    var player = PlayerState.new(rng, tuning, now: 0)
    player.stock.count = 10_000
    var stolen: [PearlCard] = [], during: [Int] = []
    for index in 0..<count {
        _ = player.reveal(lustre: .B, cracked: false, now: 0, rng: rng, thiefRng: thiefRng, tuning: tuning)
        if let card = player.stolenCard {
            stolen.append(card)
            during.append(index)
            #expect(!player.pearlCards.contains { $0.serial == card.serial }, "pas dans la collection tant qu'il fuit")
            if let caught = onTheft(card) { _ = player.resolveTheft(caught: caught) }
        }
    }
    return (player, stolen, during)
}

@Test func lePoissonResteRare() {
    let result = open(3000)
    #expect(!result.stolen.isEmpty)
    #expect(result.stolen.allSatisfy { $0.pearlId != "empty" })
    // Toutes raretés (choix de Jules, 2026-10-27), mais rare : environ une huître sur 40.
    let share = Double(result.stolen.count) / 3000
    #expect(share > 0.015 && share < 0.04, "\(share)")
}

@Test func jamaisPendantLeTutoriel() {
    let result = open(200)
    #expect(result.during.allSatisfy { $0 >= catalog.tutorialPearls.count })
}

@Test func lePoissonRattrapeRendLaPerleEtUnPeuDePoussiere() {
    var player = open(400, onTheft: { _ in nil }).player
    let stolen = PearlCard(serial: 9999, pearlId: "white", sizeMm: 6, value: 10, lustre: .B, cracked: false, foundAt: 0, traits: nil)
    _ = player.resolveTheft(caught: true)
    player.stolenCard = stolen
    let dustBefore = player.dust
    #expect(player.resolveTheft(caught: true) == fish.catchBonusDust)
    #expect(player.dust == dustBefore + fish.catchBonusDust)
    #expect(player.pearlCards.last == stolen)
    #expect(player.stolenCard == nil)
    #expect(player.resolveTheft(caught: true) == 0, "une seule fois")
}

@Test func lePoissonQuiFileEmporteLaPerle() {
    let result = open(600, onTheft: { _ in false })
    let serials = Set(result.player.pearlCards.map(\.serial))
    #expect(result.stolen.allSatisfy { !serials.contains($0.serial) })
    #expect(result.player.stolenCard == nil)
}

@Test func unVolEnSuspensEstRenduSansBonusALaRevelationSuivante() {
    // App fermée pendant la fuite : la perle revient, sans la poussière d'or du poisson rattrapé (audit P2-2).
    var player = open(400, onTheft: { _ in nil }).player
    _ = player.resolveTheft(caught: false)
    let stolen = PearlCard(serial: 9997, pearlId: "white", sizeMm: 6, value: 10, lustre: .B, cracked: false, foundAt: 0, traits: nil)
    player.stolenCard = stolen
    // Comme si la perle avait toujours été dans la collection.
    var twin = player
    twin.pearlCards.append(stolen)
    twin.stolenCard = nil
    _ = player.reveal(lustre: .B, cracked: false, now: 0, rng: seededRng(4), tuning: tuning)
    _ = twin.reveal(lustre: .B, cracked: false, now: 0, rng: seededRng(4), tuning: tuning)
    #expect(player.pearlCards.contains(stolen))
    #expect(player == twin, "pas de bonus du poisson")
}

@Test func lePoissonFuitPlusLentementAvecVoiceOver() {
    #expect(fish.assisted.fleeMs == fish.fleeMs * fish.assistedFleeFactor)
    #expect(fish.assisted.canCatch(elapsedMs: fish.arriveMs + fish.fleeMs + 1))
}

@Test func leVolSeSauvegarde() throws {
    var player = PlayerState.new(seededRng(1), tuning, now: 0)
    player.stolenCard = PearlCard(serial: 5, pearlId: "rose", sizeMm: 7, value: 18, lustre: .A, cracked: false, foundAt: 0, traits: nil)
    let data = try JSONEncoder().encode(player)
    #expect(try JSONDecoder().decode(PlayerState.self, from: data).stolenCard == player.stolenCard)
}

@Test func laFenetreDuPoisson() {
    #expect(fish.canCatch(elapsedMs: 0))
    #expect(fish.canCatch(elapsedMs: fish.arriveMs + fish.fleeMs))
    #expect(!fish.canCatch(elapsedMs: fish.arriveMs + fish.fleeMs + 1))
}
