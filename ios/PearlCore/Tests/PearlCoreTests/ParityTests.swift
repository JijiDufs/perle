// Le moteur Swift doit donner exactement les mêmes résultats que le moteur TypeScript.
// Les cas de référence (parity.json) sont produits par tests/ios-export.test.ts.
import Foundation
import Testing
@testable import PearlCore

private struct Parity: Decodable {
    struct ExpectedOyster: Decodable {
        let pearlId: String
        let sizeMm: Double
        let findId: String?
        let traits: PearlTraits?
        let sinceGoldenOrBetter: Int
    }
    struct Opening: Decodable {
        let name: String
        let crackProtected: Bool
        let samples: [OpeningSample]
        let events: [[String]]
        let phase: String
        let cracked: Bool
        let lustre: Lustre?
    }
    struct ThumbAngle: Decodable {
        let distance: Double
        let angle: Double
    }
    let rngSeed: UInt32
    let rngValues: [Double]
    let oysterSeed: UInt32
    let oysters: [ExpectedOyster]
    let openings: [Opening]
    let thumbAngles: [ThumbAngle]
    struct Value: Decodable {
        let pearlId: String
        let sizeMm: Double
        let cracked: Bool
        let traits: PearlTraits?
        let value: Double
    }
    let values: [Value]
}

private let parity: Parity = {
    let url = Bundle.module.url(forResource: "parity", withExtension: "json")!
    return try! JSONDecoder().decode(Parity.self, from: Data(contentsOf: url))
}()

private let tuning = Catalog.shared.tuning

@Test func generateurAGraine() {
    let rng = seededRng(parity.rngSeed)
    #expect(parity.rngValues.map { _ in rng() } == parity.rngValues)
}

@Test func catalogueComplet() {
    let catalog = Catalog.shared
    #expect(catalog.pearls.count == 8)
    #expect(abs(catalog.pearls.reduce(0) { $0 + $1.probability } + catalog.findProbability - 1) < 1e-9)
    #expect(catalog.finds.count == 25)
}

@Test func memesHuitresQueLeWeb() {
    let rng = seededRng(parity.oysterSeed)
    var state = DrawState.initial
    for (index, expected) in parity.oysters.enumerated() {
        let result = createOyster(state, rng, tuning)
        state = result.drawState
        let oyster = result.oyster
        #expect(oyster.pearlId == expected.pearlId, "huître \(index)")
        #expect(oyster.sizeMm == expected.sizeMm, "huître \(index)")
        #expect(oyster.findId == expected.findId, "huître \(index)")
        #expect(oyster.traits == expected.traits, "huître \(index)")
        #expect(state.sinceGoldenOrBetter == expected.sinceGoldenOrBetter, "huître \(index)")
    }
}

@Test func memesOuverturesQueLeWeb() {
    for opening in parity.openings {
        let engine = OpeningEngine(tuning: tuning, crackProtected: opening.crackProtected)
        let events = opening.samples.map { engine.push($0).map(\.type) }
        #expect(events == opening.events, "\(opening.name)")
        #expect(engine.phase.rawValue == opening.phase, "\(opening.name)")
        #expect(engine.cracked == opening.cracked, "\(opening.name)")
        #expect(engine.lustre == opening.lustre, "\(opening.name)")
    }
}

@Test func memeGesteDuPouceQueLeWeb() {
    for expected in parity.thumbAngles {
        #expect(thumbDistanceToAngle(expected.distance, tuning) == expected.angle, "distance \(expected.distance)")
    }
}

@Test func memesValeursQueLeWeb() {
    for expected in parity.values {
        #expect(pearlValue(expected.pearlId, sizeMm: expected.sizeMm, cracked: expected.cracked, traits: expected.traits) == expected.value)
    }
}

@Test func ouvrirCreeLaCarteEtTireLaSuivante() {
    let rng = seededRng(7)
    var player = PlayerState.new(rng, tuning)
    let first = player.oyster
    let reveal = player.reveal(lustre: .A, cracked: false, now: 0, rng: rng, tuning: tuning)
    #expect(player.nextSerial == 2)
    #expect(player.oystersOpened == 1)
    switch reveal {
    case .pearl(let card): #expect(card.pearlId == first.pearlId && card.serial == 1)
    case .find(let card): #expect(card.findId == first.findId)
    case .empty: #expect(first.pearlId == "empty")
    }
}

@Test func relacherPendantLaResistanceReferme() {
    let engine = OpeningEngine(tuning: tuning)
    engine.push(OpeningSample(angle: 5, time: 0))
    #expect(engine.phase == .resisting)
    engine.release()
    #expect(engine.phase == .closed)
    #expect(engine.angle == 0)
}
