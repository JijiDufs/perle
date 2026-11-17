import PearlCore
import StoreKit
import UIKit

/// Demande d'avis App Store : la fenêtre d'Apple, proposée quand `ReviewPrompt.shouldAsk` (PearlCore) le dit.
/// Ici seulement la mémoire (jours joués, dernière demande) et l'appel au système.
enum Reviews {
    private static let daysKey = "pearlinc.review.days", lastDayKey = "pearlinc.review.lastDay"
    private static let askedAtKey = "pearlinc.review.askedAt", askedVersionKey = "pearlinc.review.askedVersion"
    private static let msPerDay = 86_400_000.0

    /// Au lancement et au retour dans l'app : compte les jours différents où l'on a joué.
    static func noteDay(_ day: String) {
        let defaults = UserDefaults.standard
        guard defaults.string(forKey: lastDayKey) != day else { return }
        defaults.set(day, forKey: lastDayKey)
        defaults.set(defaults.integer(forKey: daysKey) + 1, forKey: daysKey)
    }

    /// Une carte vient d'être refermée. `happy` : une belle prise, au calme (voir `GameModel.nextOyster`).
    @MainActor static func cardClosed(happy: Bool, oystersOpened: Int, rules: ReviewPrompt, now: Double) {
        let defaults = UserDefaults.standard
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let askedAt = defaults.double(forKey: askedAtKey)
        guard rules.shouldAsk(happy: happy, oystersOpened: oystersOpened, daysPlayed: defaults.integer(forKey: daysKey),
                              daysSinceLastAsk: askedAt > 0 ? Int((now - askedAt) / msPerDay) : nil,
                              askedThisVersion: defaults.string(forKey: askedVersionKey) == version),
              let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
                  .first(where: { $0.activationState == .foregroundActive })
        else { return }
        defaults.set(now, forKey: askedAtKey)
        defaults.set(version, forKey: askedVersionKey)
        AppStore.requestReview(in: scene)
    }
}
