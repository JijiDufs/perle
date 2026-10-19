// Premières minutes : huîtres écrites à l'avance, offertes, première perle protégée.
import Foundation
import Testing
@testable import PearlCore

private let catalog = Catalog.shared
private let tuning = catalog.tuning

@Test func lesPremieresHuitresSontEcritesALAvance() {
    #expect(catalog.tutorialPearls == ["rose", "white", "empty", "baroque"])
    let rng = seededRng(11)
    var player = PlayerState.new(rng, tuning, now: 0)
    var revealed: [String] = []
    while player.isInTutorial() {
        #expect(player.oyster.findId == nil)
        #expect(player.oyster.traits?.mark == nil)
        revealed.append(player.oyster.pearlId)
        _ = player.reveal(lustre: .B, cracked: false, now: 0, rng: rng, tuning: tuning)
    }
    #expect(revealed == catalog.tutorialPearls)
    #expect(player.stock.count == tuning.oysterStockMax)
    #expect(player.pearlCards.map(\.pearlId) == ["rose", "white", "baroque"])
}

@Test func seuleLaPremiereEstProtegee() {
    #expect(catalog.isCrackProtected(oystersOpened: 0))
    #expect(!catalog.isCrackProtected(oystersOpened: 1))
    #expect(catalog.isInTutorial(oystersOpened: 3))
    #expect(!catalog.isInTutorial(oystersOpened: 4))
    #expect(catalog.scriptedPearl(oystersOpened: 4) == nil)
}

@Test func uneHuitreDejaPoseeNeChangePas() throws {
    // Invariant 5 : une ancienne sauvegarde garde son huître posée, même tirée avant le tutoriel.
    var player = PlayerState.new(seededRng(5), tuning, now: 0)
    player.oyster = Oyster(pearlId: "golden", sizeMm: 9, findId: nil, traits: nil)
    let data = try JSONEncoder().encode(player)
    let loaded = try JSONDecoder().decode(PlayerState.self, from: data)
    #expect(loaded.oyster.pearlId == "golden")
}
