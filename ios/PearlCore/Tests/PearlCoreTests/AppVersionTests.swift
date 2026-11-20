// La fenêtre « Mise à jour disponible » : seulement si l'App Store a une version plus récente.
import Testing
@testable import PearlCore

@Test func miseAJourSeulementSiLaVersionEnLigneEstPlusRecente() {
    #expect(isNewerVersion("1.2.1", than: "1.2"))
    #expect(isNewerVersion("1.10", than: "1.9"))
    #expect(isNewerVersion("2.0", than: "1.9.9"))
    #expect(!isNewerVersion("1.2", than: "1.2.0"))
    #expect(!isNewerVersion("1.2", than: "1.2.1"))
    #expect(!isNewerVersion("1.2.1", than: "1.2.1"))
}
