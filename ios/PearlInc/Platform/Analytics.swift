import Foundation
import TelemetryDeck

/// Mesure d'usage, par **TelemetryDeck** (hébergé dans l'UE, sans donnée personnelle ni pistage ; AGENTS.md §6,
/// 2026-10-21). Seul fichier qui parle à l'outil : le reste de l'app appelle `Analytics.send`. Une dizaine
/// d'événements, pour vérifier les seuils de docs/duo-gadget.md §9 et recaler l'économie.
/// L'identifiant de l'app TelemetryDeck est lu dans Info.plist (`TelemetryDeckAppID`) : vide, rien n'est envoyé.
@MainActor
enum Analytics {
    enum Event: String {
        /// Une huître ouverte : sorte, rareté, lustre, fêlure, pouce ou charnière.
        case oyster = "Oyster.opened"
        /// Le poisson voleur : rattrapé ou non, rareté de la perle.
        case fish = "Fish.ended"
        case tideOut = "Tide.out"
        case ad = "Ad.rewarded"
        case purchase = "Purchase.completed"
        case mission = "Mission.claimed"
        case calendar = "Calendar.claimed"
        case level = "Level.reached"
    }

    private static let appID = Bundle.main.object(forInfoDictionaryKey: "TelemetryDeckAppID") as? String ?? ""
    private static var started = false

    /// Au lancement. Le début de séance est envoyé par TelemetryDeck lui-même (`TelemetryDeck.Session.started`).
    static func start() {
        guard !appID.isEmpty, !started else { return }
        started = true
        TelemetryDeck.initialize(config: TelemetryDeck.Config(appID: appID))
    }

    static func send(_ event: Event, _ parameters: [String: String] = [:]) {
        guard started else { return }
        TelemetryDeck.signal(event.rawValue, parameters: parameters)
    }
}
