// Carnet des variantes et albums de trouvailles (le tri est vérifié contre le TypeScript dans ParityTests).
import Testing
@testable import PearlCore

private let catalog = Catalog.shared

@Test func carnetDesVariantesDUnePerle() {
    var player = PlayerState.new(seededRng(3), catalog.tuning, now: 0)
    let traits = PearlTraits(shape: "goutte", overtone: "rose", mark: "lune", seed: 0.5)
    player.pearlCards = [
        PearlCard(serial: 1, pearlId: "rose", sizeMm: 7, value: 10, lustre: .A, cracked: false, foundAt: 0, traits: traits),
        PearlCard(serial: 2, pearlId: "white", sizeMm: 7, value: 5, lustre: .B, cracked: false, foundAt: 0,
                  traits: PearlTraits(shape: "ronde", overtone: "argente", mark: nil, seed: 0.5)),
    ]
    let found = player.foundTraits(of: "rose")
    #expect(found.shapes == ["goutte"] && found.overtones == ["rose"] && found.marks == ["lune"])
    #expect(player.foundTraits(of: "black").shapes.isEmpty)
    // Toutes les variantes possibles viennent du catalogue, et celles trouvées en font partie.
    #expect(catalog.shapes(of: "rose").contains("goutte"))
    #expect(catalog.overtones(of: "rose").contains("rose"))
    #expect(catalog.markIds == ["jumelle", "etoile", "lune", "coeur"])
    #expect(catalog.shapes(of: "baroque") == ["baroque"])
}

@Test func albumsDeTrouvailles() {
    let all = catalog.findAlbums.flatMap { catalog.finds(inAlbum: $0.id) }
    #expect(all.count == catalog.finds.count)
    for album in catalog.findAlbums {
        let tiers = catalog.finds(inAlbum: album.id).map(\.tier)
        #expect(tiers == tiers.sorted())
    }
    var player = PlayerState.new(seededRng(3), catalog.tuning, now: 0)
    let id = catalog.finds[0].id
    player.findCards = [FindCard(serial: 1, findId: id, value: 1, foundAt: 0), FindCard(serial: 2, findId: id, value: 1, foundAt: 0)]
    #expect(player.count(ofFind: id) == 2)
}
