// La sauvegarde sur le compte : quelle partie garder quand le téléphone et le compte diffèrent.
import Testing
@testable import PearlCore

private func version(_ oysters: Int, at savedAt: Double = 1_000) -> SaveVersion {
    SaveVersion(oystersOpened: oysters, savedAt: savedAt)
}

@Test func compteVideRecoitLaPartieDuTelephone() {
    #expect(cloudSaveDecision(local: version(12), localChanged: true, syncedRevision: nil, remote: nil) == .upload(setAsideRemote: false))
}

@Test func compteInchangeEnvoieSeulementSiLeTelephoneAJoue() {
    let remote = (version: version(10), revision: 4)
    #expect(cloudSaveDecision(local: version(12), localChanged: true, syncedRevision: 4, remote: remote) == .upload(setAsideRemote: false))
    #expect(cloudSaveDecision(local: version(10), localChanged: false, syncedRevision: 4, remote: remote) == .upToDate)
}

@Test func partieJoueeSurUnAutreIphoneRevientSansRienMettreDeCote() {
    let remote = (version: version(40), revision: 9)
    #expect(cloudSaveDecision(local: version(10), localChanged: false, syncedRevision: 4, remote: remote) == .download(setAsideLocal: false))
}

@Test func nouvelIphoneRecupereLaPartieDuCompte() {
    // Partie neuve créée au lancement, avant la réponse du compte : rien à mettre de côté.
    let remote = (version: version(40), revision: 9)
    #expect(cloudSaveDecision(local: version(0, at: 5_000), localChanged: true, syncedRevision: nil, remote: remote) == .download(setAsideLocal: false))
}

@Test func partieDeLa10QuiSeConnecteGardeLaPlusAvancee() {
    // Le compte avait déjà une partie (un autre iPhone) : la plus avancée gagne, l'autre est mise de côté.
    let remote = (version: version(15), revision: 2)
    #expect(cloudSaveDecision(local: version(80), localChanged: true, syncedRevision: nil, remote: remote) == .upload(setAsideRemote: true))
    #expect(cloudSaveDecision(local: version(5), localChanged: true, syncedRevision: nil, remote: remote) == .download(setAsideLocal: true))
}

@Test func deuxIphoneJouesTourATourGardentLaPlusAvanceePuisLaPlusRecente() {
    let remote = (version: version(30, at: 2_000), revision: 7)
    #expect(cloudSaveDecision(local: version(31, at: 1_000), localChanged: true, syncedRevision: 5, remote: remote) == .upload(setAsideRemote: true))
    #expect(cloudSaveDecision(local: version(30, at: 1_000), localChanged: true, syncedRevision: 5, remote: remote) == .download(setAsideLocal: true))
    #expect(cloudSaveDecision(local: version(30, at: 3_000), localChanged: true, syncedRevision: 5, remote: remote) == .upload(setAsideRemote: true))
}
