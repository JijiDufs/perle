import Foundation
import PearlCore
import Supabase
import UIKit

/// La partie sauvegardée sur le compte du joueur (table `game_saves` de Supabase, une ligne par compte, protégée par RLS).
/// La sauvegarde du téléphone reste la référence (jeu hors ligne, lancement instantané) : chaque sauvegarde part
/// aussi vers le compte, regroupée (un envoi toutes les quelques secondes au plus), et une dernière fois quand
/// l'app passe en arrière-plan. Hors ligne, l'envoi est rejoué à la sauvegarde suivante ou au retour dans l'app.
/// Quelle partie garder quand les deux diffèrent : `cloudSaveDecision` (PearlCore).
@MainActor
@Observable
final class CloudSave {
    /// Une partie vient d'être mise de côté après un conflit : on le dit au joueur, qui peut la reprendre.
    struct SetAside: Identifiable, Equatable {
        let id = UUID()
        let keptOysters: Int
        let otherOysters: Int
    }

    private(set) var user: UUID?
    var setAside: SetAside?

    /// La partie du compte remplace celle du téléphone.
    @ObservationIgnored var onDownload: (PlayerState) -> Void = { _ in }

    /// Envois regroupés : pas plus d'un toutes les `uploadDelay` secondes.
    private static let uploadDelay: Duration = .seconds(5)
    @ObservationIgnored private var pending: Task<Void, Never>?
    @ObservationIgnored private var syncing = false
    /// La partie du compte a été lue depuis la connexion (ou depuis le dernier refus) : on peut envoyer.
    @ObservationIgnored private var checked = false
    /// Le compte a une partie que cette version de l'app ne sait pas lire (écrite par une version plus récente) :
    /// on n'y touche pas.
    @ObservationIgnored private var unreadable = false

    init(user: UUID?) { self.user = user }

    /// Le compte connecté au lancement (session gardée par Supabase sur le téléphone).
    static var signedInUser: UUID? { supabase.auth.currentSession?.user.id }

    /// Un autre compte se connecte (ou la déconnexion) : on repart de sa partie à lui.
    func switchUser(_ user: UUID?) {
        pending?.cancel()
        pending = nil
        self.user = user
        checked = false
        unreadable = false
        setAside = nil
    }

    func save(_ player: PlayerState) {
        guard Storage.save(player, user: user), pending == nil else { return }
        pending = Task {
            try? await Task.sleep(for: Self.uploadDelay)
            guard !Task.isCancelled else { return }
            pending = nil
            await sync()
        }
    }

    /// L'app passe en arrière-plan : on envoie tout de suite, avec le temps qu'iOS nous laisse.
    func flush() {
        pending?.cancel()
        pending = nil
        let task = UIApplication.shared.beginBackgroundTask(withName: "pearlinc.cloudsave")
        Task {
            await sync()
            UIApplication.shared.endBackgroundTask(task)
        }
    }

    /// Lit la partie du compte si besoin (et tranche un conflit), puis envoie celle du téléphone si elle a changé.
    func sync() async {
        guard let user, !syncing, !unreadable else { return }
        syncing = true
        defer { syncing = false }
        do {
            if !checked { try await check(user) }
            guard self.user == user, checked else { return }
            var sync = Storage.syncState(user)
            guard sync.changed, let player = Storage.load(user) else { return }
            let savedAt = sync.savedAt
            let expected = sync.syncedRevision ?? 0
            let revision = try await Task.detached { try await Self.send(player, expected: expected) }.value
            guard self.user == user else { return }
            sync = Storage.syncState(user)
            sync.syncedRevision = revision
            sync.syncedSavedAt = savedAt
            Storage.setSyncState(sync, user: user)
        } catch {
            // Hors ligne, ou un autre iPhone a envoyé entre-temps (`save_conflict`) : on relira le compte la prochaine fois.
            checked = false
        }
    }

    /// Reprendre la partie mise de côté ; celle qu'on quitte est mise de côté à son tour.
    func swapSetAside(current: PlayerState) {
        guard let other = Storage.setAside(user) else { return }
        Storage.setSetAside(current, user: user)
        setAside = nil
        onDownload(other)
        save(other)
    }

    // MARK: - Compte

    private struct RemoteSave: Decodable {
        let state: PlayerState
        let revision: Int
        let updatedAt: Date

        enum CodingKeys: String, CodingKey {
            case state, revision
            case updatedAt = "updated_at"
        }
    }

    private struct SaveParams: Encodable {
        let p_state: PlayerState
        let p_expected_revision: Int
    }

    private func check(_ user: UUID) async throws {
        let remote: RemoteSave?
        do {
            let rows: [RemoteSave] = try await supabase.from("game_saves")
                .select("state, revision, updated_at").eq("user_id", value: user).execute().value
            remote = rows.first
        } catch is DecodingError {
            unreadable = true
            return
        }
        guard self.user == user, let local = Storage.load(user) else { return }
        var sync = Storage.syncState(user)
        let decision = cloudSaveDecision(
            local: SaveVersion(oystersOpened: local.oystersOpened, savedAt: sync.savedAt),
            localChanged: sync.changed,
            syncedRevision: sync.syncedRevision,
            remote: remote.map { (SaveVersion(oystersOpened: $0.state.oystersOpened, savedAt: $0.updatedAt.timeIntervalSince1970 * 1000), $0.revision) })
        switch decision {
        case .upToDate:
            break
        case .upload(let setAsideRemote):
            // On écrasera la révision lue (et, si le compte est vide, on créera la ligne).
            if let remote, setAsideRemote {
                Storage.setSetAside(remote.state, user: user)
                setAside = SetAside(keptOysters: local.oystersOpened, otherOysters: remote.state.oystersOpened)
            }
            sync.syncedRevision = remote?.revision
            sync.syncedSavedAt = nil
            Storage.setSyncState(sync, user: user)
        case .download(let setAsideLocal):
            guard let remote else { break }
            if setAsideLocal {
                Storage.setSetAside(local, user: user)
                setAside = SetAside(keptOysters: remote.state.oystersOpened, otherOysters: local.oystersOpened)
            }
            let savedAt = remote.updatedAt.timeIntervalSince1970 * 1000
            Storage.save(remote.state, user: user, savedAt: savedAt)
            Storage.setSyncState(.init(savedAt: savedAt, syncedSavedAt: savedAt, syncedRevision: remote.revision), user: user)
            onDownload(remote.state)
        }
        checked = true
    }

    /// Envoie la partie ; renvoie la nouvelle révision. Refusé (`save_conflict`) si le compte a bougé depuis `expected`.
    private nonisolated static func send(_ player: PlayerState, expected: Int) async throws -> Int {
        try await supabase.rpc("save_game", params: SaveParams(p_state: player, p_expected_revision: expected)).execute().value
    }
}
