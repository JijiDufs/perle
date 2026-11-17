// La demande d'avis App Store : seulement après une belle prise, avec assez d'huîtres et de jours, pas trop souvent.
import Testing
@testable import PearlCore

private let rules = Catalog.shared.economy.review

@Test func avisApresUneBellePriseQuandLeJoueurEstInstalle() {
    #expect(rules.shouldAsk(happy: true, oystersOpened: rules.minOysters, daysPlayed: rules.minDays, daysSinceLastAsk: nil, askedThisVersion: false))
}

@Test func pasDAvisTropTotNiAuMauvaisMoment() {
    #expect(!rules.shouldAsk(happy: false, oystersOpened: 500, daysPlayed: 30, daysSinceLastAsk: nil, askedThisVersion: false))
    #expect(!rules.shouldAsk(happy: true, oystersOpened: rules.minOysters - 1, daysPlayed: 30, daysSinceLastAsk: nil, askedThisVersion: false))
    #expect(!rules.shouldAsk(happy: true, oystersOpened: 500, daysPlayed: rules.minDays - 1, daysSinceLastAsk: nil, askedThisVersion: false))
}

@Test func pasDeuxAvisRapprochesNiDeuxFoisPourLaMemeVersion() {
    #expect(!rules.shouldAsk(happy: true, oystersOpened: 500, daysPlayed: 30, daysSinceLastAsk: rules.minDaysBetween - 1, askedThisVersion: false))
    #expect(rules.shouldAsk(happy: true, oystersOpened: 500, daysPlayed: 30, daysSinceLastAsk: rules.minDaysBetween, askedThisVersion: false))
    #expect(!rules.shouldAsk(happy: true, oystersOpened: 500, daysPlayed: 30, daysSinceLastAsk: 400, askedThisVersion: true))
}
