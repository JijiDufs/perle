import Foundation
import PearlCore

/// Sauvegarde de la partie sur le téléphone, une par compte (deux comptes sur le même iPhone ne se mélangent pas).
/// L'huître en cours est sauvegardée avec sa perle : relancer l'app ne relance pas le tirage (AGENTS.md, invariant 5).
/// La copie sur le compte du joueur passe par `CloudSave`.
enum Storage {
    /// Clé de la 1.0 (une seule partie par iPhone) ; la partie qui s'y trouve est reprise par le premier compte connecté.
    private static let legacyKey = "pearlinc.player.v1"
    private static var defaults: UserDefaults { .standard }

    /// Où en est la copie sur le compte.
    struct SyncState: Codable {
        /// Date de la dernière sauvegarde sur le téléphone (ms).
        var savedAt: Double = 0
        /// Date de la version que le compte a aussi (nil : jamais synchronisée).
        var syncedSavedAt: Double?
        /// Révision du compte dont descend la partie du téléphone.
        var syncedRevision: Int?

        var changed: Bool { syncedSavedAt != savedAt }
    }

    private static func key(_ user: UUID?) -> String { user.map { "\(legacyKey).\($0.uuidString.lowercased())" } ?? legacyKey }

    static func load(_ user: UUID?) -> PlayerState? {
        if let user, defaults.data(forKey: key(user)) == nil, let legacy = defaults.data(forKey: legacyKey) {
            defaults.set(legacy, forKey: key(user))
            defaults.removeObject(forKey: legacyKey)
        }
        return defaults.data(forKey: key(user)).flatMap { try? JSONDecoder().decode(PlayerState.self, from: $0) }
    }

    /// Sauvegarde ; renvoie false si rien n'a changé (le jeu sauvegarde aussi chaque minute, sans rien de neuf).
    @discardableResult
    static func save(_ player: PlayerState, user: UUID?, savedAt: Double = Clock.nowMs) -> Bool {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        guard let data = try? encoder.encode(player), data != defaults.data(forKey: key(user)) else { return false }
        defaults.set(data, forKey: key(user))
        var sync = syncState(user)
        sync.savedAt = savedAt
        setSyncState(sync, user: user)
        return true
    }

    static func syncState(_ user: UUID?) -> SyncState {
        defaults.data(forKey: key(user) + ".sync").flatMap { try? JSONDecoder().decode(SyncState.self, from: $0) } ?? SyncState()
    }

    static func setSyncState(_ sync: SyncState, user: UUID?) {
        defaults.set(try? JSONEncoder().encode(sync), forKey: key(user) + ".sync")
    }

    /// La partie mise de côté après un conflit (celle qui avait le moins avancé), pour pouvoir la reprendre.
    static func setAside(_ user: UUID?) -> PlayerState? {
        defaults.data(forKey: key(user) + ".aside").flatMap { try? JSONDecoder().decode(PlayerState.self, from: $0) }
    }

    static func setSetAside(_ player: PlayerState?, user: UUID?) {
        defaults.set(player.flatMap { try? JSONEncoder().encode($0) }, forKey: key(user) + ".aside")
    }

    /// Suppression du compte : sa partie, sa copie mise de côté et son état de synchronisation.
    static func erase(_ user: UUID?) {
        for suffix in ["", ".sync", ".aside"] { defaults.removeObject(forKey: key(user) + suffix) }
    }
}
