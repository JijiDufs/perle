// Le catalogue en anglais : les textes changent, jamais les règles.
import Testing
@testable import PearlCore

private let french = Catalog.shared
private let english = Catalog.shared.localized("en")

@Test func catalogueAnglaisTraduitLesTextes() {
    #expect(english.pearl("cursed").name == "Cursed pearl")
    #expect(english.find("aileron").flavor == "You’re going to need a bigger boat.")
    #expect(english.shapes["ronde"]?.label == "Round")
    #expect(english.marks["coeur"]?.label == "Heart")
    #expect(english.economy.skin("benitier")?.name == "Giant clam")
    #expect(english.economy.consumables.first { $0.id == "app.pearlinc.oysters.10" }?.name == "High tide")
}

@Test func catalogueAnglaisGardeLesRegles() {
    #expect(english.pearls.map(\.id) == french.pearls.map(\.id))
    #expect(english.pearls.map(\.probability) == french.pearls.map(\.probability))
    #expect(english.finds.map(\.value) == french.finds.map(\.value))
    #expect(english.shapes.mapValues(\.value) == french.shapes.mapValues(\.value))
    #expect(english.economy.skins.map(\.dustPrice) == french.economy.skins.map(\.dustPrice))
}

@Test func toutLeCatalogueATraduction() {
    for pearl in english.pearls { #expect(pearl.name != french.pearl(pearl.id).name || pearl.id == "baroque") }
    for find in english.finds { #expect(find.name != french.find(find.id).name) }
}

@Test func lesAutresLanguesGardentLeFrancais() {
    #expect(Catalog.shared.localized("fr").pearl("white").name == "Perle blanche")
    #expect(Catalog.shared.localized("de").pearl("white").name == "Perle blanche")
}
