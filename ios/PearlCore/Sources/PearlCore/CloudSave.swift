// Sauvegarde de la partie sur le compte du joueur : que faire quand la partie du téléphone et celle du compte
// diffèrent (nouvel iPhone, partie de la 1.0 qui se connecte, deux iPhone joués tour à tour).
// Chaque envoi au compte porte une révision : si le compte n'a pas bougé depuis la dernière révision connue
// du téléphone, il n'y a pas de conflit. Sinon, on garde la partie la plus avancée (huîtres ouvertes, puis la
// plus récente) et l'autre est mise de côté sur le téléphone, jamais perdue en silence.

/// Une version de la partie, pour comparer.
public struct SaveVersion: Equatable, Sendable {
    public var oystersOpened: Int
    /// Date de la sauvegarde (ms).
    public var savedAt: Double

    public init(oystersOpened: Int, savedAt: Double) {
        self.oystersOpened = oystersOpened
        self.savedAt = savedAt
    }
}

public enum CloudSaveDecision: Equatable, Sendable {
    /// Le compte a déjà cette partie.
    case upToDate
    /// Garder la partie du téléphone et l'envoyer ; `setAsideRemote` : celle du compte avait avancé aussi, on la met de côté.
    case upload(setAsideRemote: Bool)
    /// Prendre la partie du compte ; `setAsideLocal` : celle du téléphone avait avancé aussi, on la met de côté.
    case download(setAsideLocal: Bool)
}

/// - Parameters:
///   - local: la partie du téléphone.
///   - localChanged: elle a changé depuis la dernière révision envoyée ou reçue.
///   - syncedRevision: la révision du compte dont elle descend (nil : jamais synchronisée sur ce téléphone).
///   - remote: la partie du compte et sa révision (nil : le compte n'a pas encore de partie).
public func cloudSaveDecision(local: SaveVersion, localChanged: Bool, syncedRevision: Int?,
                              remote: (version: SaveVersion, revision: Int)?) -> CloudSaveDecision {
    guard let remote else { return .upload(setAsideRemote: false) }
    if syncedRevision == remote.revision { return localChanged ? .upload(setAsideRemote: false) : .upToDate }
    // Seul le compte a avancé (partie jouée sur un autre iPhone) : rien à perdre ici.
    if syncedRevision != nil && !localChanged { return .download(setAsideLocal: false) }
    // Les deux ont avancé, ou ce téléphone ne s'est jamais synchronisé : la plus avancée gagne.
    let localWins = (local.oystersOpened, local.savedAt) >= (remote.version.oystersOpened, remote.version.savedAt)
    // Une partie sans huître ouverte (partie neuve d'un iPhone tout juste installé) ne se met pas de côté.
    return localWins
        ? .upload(setAsideRemote: remote.version.oystersOpened > 0)
        : .download(setAsideLocal: local.oystersOpened > 0)
}
