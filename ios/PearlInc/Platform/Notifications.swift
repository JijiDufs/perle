import Foundation
import UserNotifications

/// Une seule notification, désactivable : « Tes huîtres sont revenues », quand le stock est plein
/// (docs/duo-gadget.md §4). Programmée en quittant l'app, retirée en y revenant. Locale : aucun serveur.
@MainActor
enum Notifications {
    /// Réglage « Notifications » (Réglages du jeu), désactivé tant que le joueur ne l'a pas demandé.
    static let settingKey = "pearlinc.settings.notifications"
    private static let refillId = "pearlinc.refill"
    private static var center: UNUserNotificationCenter { .current() }

    static var isEnabled: Bool { UserDefaults.standard.bool(forKey: settingKey) }

    /// Demande l'autorisation à iOS ; le réglage suit la réponse.
    @discardableResult
    static func enable() async -> Bool {
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        UserDefaults.standard.set(granted, forKey: settingKey)
        return granted
    }

    static func disable() {
        UserDefaults.standard.set(false, forKey: settingKey)
        cancel()
    }

    /// iOS a refusé les notifications pour Pearl Inc. (il faut alors passer par les Réglages d'iOS).
    static func isDenied() async -> Bool {
        await center.notificationSettings().authorizationStatus == .denied
    }

    /// Programme la notification dans `seconds` secondes (nil : stock déjà plein, rien à annoncer).
    static func scheduleRefill(in seconds: TimeInterval?, stockMax: Int) {
        cancel()
        guard isEnabled, let seconds, seconds > 0 else { return }
        let content = UNMutableNotificationContent()
        content.title = String(localized: "La marée est haute")
        content.body = String(localized: "Tes huîtres sont revenues : \(stockMax) t’attendent sur le ponton.")
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        center.add(UNNotificationRequest(identifier: refillId, content: content, trigger: trigger))
    }

    static func cancel() {
        center.removePendingNotificationRequests(withIdentifiers: [refillId])
        center.removeDeliveredNotifications(withIdentifiers: [refillId])
    }
}
