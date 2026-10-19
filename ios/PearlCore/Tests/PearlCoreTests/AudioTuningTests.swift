// Réglages des sons : lus dans catalog.json, carillon gradué par rareté comme la webapp.
import Testing
@testable import PearlCore

private let audio = Catalog.shared.audio

@Test func leCarillonMonteAvecLaRarete() {
    #expect(audio.chimeNotes(audio.chime, level: 0) == [523, 659, 784])
    #expect(audio.chimeNotes(audio.chime, level: 3).count == 6)
    // L'huître vide n'a que deux notes, quel que soit le niveau.
    #expect(audio.chimeNotes(audio.emptyChime, level: 3) == [330, 262])
}

@Test func lesSonsRestentDansDesBornesRaisonnables() {
    #expect(audio.sampleRate > 0)
    #expect(!audio.chords.isEmpty && audio.chords.allSatisfy { !$0.isEmpty })
    #expect(audio.chordCrossfadeSeconds * 2 <= audio.chordSeconds)
    #expect(audio.sparkleGapMinSeconds <= audio.sparkleGapMaxSeconds)
    #expect((0...1).contains(audio.musicSuspenseDuck))
    #expect(!audio.wavePeriodsSeconds.isEmpty && audio.wavePeriodsSeconds.allSatisfy { $0 > 0 })
}
