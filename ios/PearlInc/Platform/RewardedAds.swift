import Foundation
import Observation

/// Pub récompensée. Pour l'instant une pub **simulée** (choix de Jules, 2026-10-13) : la régie publicitaire
/// (AdMob ou autre) se branchera ici seulement, sans toucher aux écrans ni au Core.
/// Ce que rapporte une pub et combien par jour : le Core (Economy.rewardedAdOysters / rewardedAdsPerDay).
@MainActor
@Observable
final class RewardedAds {
    /// Durée de la pub simulée, en secondes (une vraie pub dure de 15 à 30 s).
    static let simulatedSeconds = 5

    /// Une pub est à l'écran.
    private(set) var isShowing = false
    @ObservationIgnored private var completion: ((Bool) -> Void)?

    /// Montre une pub ; `completion(true)` si elle a été regardée jusqu'au bout.
    func show(completion: @escaping (Bool) -> Void) {
        guard !isShowing else { return }
        self.completion = completion
        isShowing = true
    }

    /// Fin de la pub (appelé par l'écran de la pub simulée).
    func finish(rewarded: Bool) {
        isShowing = false
        completion?(rewarded)
        completion = nil
    }
}
