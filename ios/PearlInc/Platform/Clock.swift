import Foundation

/// L'heure du téléphone, pour le Core (qui reçoit le temps en paramètre, invariant 4).
enum Clock {
    /// Maintenant, en millisecondes.
    static var nowMs: Double { Date().timeIntervalSince1970 * 1000 }

    /// Jour local « AAAA-MM-JJ » : les missions changent à minuit, heure du téléphone.
    static func dayKey(_ date: Date = Date()) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    /// Temps avant minuit (heure locale), en secondes.
    static func secondsUntilMidnight(_ date: Date = Date()) -> TimeInterval {
        let midnight = Calendar.current.startOfDay(for: date).addingTimeInterval(86_400)
        return Calendar.current.startOfDay(for: midnight).timeIntervalSince(date)
    }
}
