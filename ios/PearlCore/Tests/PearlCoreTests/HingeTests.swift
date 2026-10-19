// La charnière du Duo : quand elle pilote l'huître, quand elle passe à la suivante.
import Testing
@testable import PearlCore

private let tuning = Catalog.shared.tuning

@Test func telephoneDejaOuvertNOuvrePasLHuitre() {
    var hinge = HingeTracker(tuning: tuning)
    #expect(hinge.update(degrees: 170) == .none)
    #expect(hinge.update(degrees: 120) == .none)
    #expect(!hinge.armed)
}

@Test func refermerPuisOuvrirPiloteLHuitre() {
    var hinge = HingeTracker(tuning: tuning)
    #expect(hinge.update(degrees: 170) == .none)
    #expect(hinge.update(degrees: 2) == .closed)
    #expect(hinge.update(degrees: 0) == .none)
    #expect(hinge.update(degrees: 30) == .sample(30))
    #expect(hinge.update(degrees: 200) == .sample(180))
}

@Test func refermerSignaleUneSeuleFois() {
    var hinge = HingeTracker(tuning: tuning)
    #expect(hinge.update(degrees: 0) == .closed)
    #expect(hinge.update(degrees: tuning.hingeClosedAngle) == .none)
    #expect(hinge.update(degrees: 90) == .sample(90))
    #expect(hinge.update(degrees: 1) == .closed)
}

@Test func carteToucheeTelephoneOuvertDemandeDeRefermer() {
    var hinge = HingeTracker(tuning: tuning)
    _ = hinge.update(degrees: 0)
    _ = hinge.update(degrees: 175)
    hinge.disarmIfOpen()
    #expect(hinge.update(degrees: 170) == .none)
    #expect(hinge.update(degrees: 0) == .closed)
    #expect(hinge.update(degrees: 40) == .sample(40))
}

@Test func carteToucheeTelephoneFermeResteArme() {
    var hinge = HingeTracker(tuning: tuning)
    _ = hinge.update(degrees: 0)
    hinge.disarmIfOpen()
    #expect(hinge.update(degrees: 25) == .sample(25))
}

/// Une ouverture lente du téléphone donne une perle sans fêlure, comme au pouce.
@Test func ouvertureLenteDuTelephoneSansFelure() {
    var hinge = HingeTracker(tuning: tuning)
    let engine = OpeningEngine(tuning: tuning)
    _ = hinge.update(degrees: 0)
    var revealed = false
    for step in 1...90 {
        if case .sample(let angle) = hinge.update(degrees: Double(step) * 2) {
            for event in engine.push(OpeningSample(angle: angle, time: Double(step) * 20)) {
                if case .reveal(_, let cracked) = event { revealed = true; #expect(!cracked) }
            }
        }
    }
    #expect(revealed)
}
