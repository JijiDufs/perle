import Foundation
import PearlCore

/// Sauvegarde de la partie sur le téléphone. L'huître en cours est sauvegardée avec sa perle :
/// relancer l'app ne relance pas le tirage (AGENTS.md, invariant 5).
enum Storage {
    private static let key = "pearlinc.player.v1"

    static func load() -> PlayerState? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(PlayerState.self, from: data)
    }

    static func save(_ player: PlayerState) {
        guard let data = try? JSONEncoder().encode(player) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
