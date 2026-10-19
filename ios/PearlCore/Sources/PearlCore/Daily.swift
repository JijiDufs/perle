// Calendrier de connexion (cahier §15), miroir de src/core/daily.ts : une case par jour où l'on vient
// (7 cases, puis on recommence), et une série de jours consécutifs qu'un « joker » protège d'un jour
// d'absence, une fois par semaine. Les montants de l'app sont dans src/core/appEconomy.ts (APP_CALENDAR).
// Les jours sont des chaînes « AAAA-MM-JJ », heure locale du téléphone (comme les missions).

public struct CalendarReward: Codable, Sendable, Equatable {
    public let oysters: Int
    public let dust: Int
}

public struct LoginState: Codable, Sendable, Equatable {
    /// Dernier jour récupéré, ou nil.
    public var lastClaimDay: String?
    /// Prochaine case du calendrier (0…6).
    public var calendarIndex: Int
    /// Jours consécutifs, et meilleure série.
    public var streak: Int
    public var bestStreak: Int
    /// Jour où le joker a servi pour la dernière fois.
    public var jokerUsedDay: String?

    public static let initial = LoginState(lastClaimDay: nil, calendarIndex: 0, streak: 0, bestStreak: 0, jokerUsedDay: nil)

    /// Le joker est disponible s'il n'a pas servi dans les `jokerDays` derniers jours.
    public func jokerAvailable(day: String, jokerDays: Int) -> Bool {
        guard let used = jokerUsedDay else { return true }
        return daysBetween(used, day) >= jokerDays
    }

    /// Jours avant que le joker revienne (0 : disponible).
    public func jokerBackIn(day: String, jokerDays: Int) -> Int {
        guard let used = jokerUsedDay else { return 0 }
        return max(0, jokerDays - daysBetween(used, day))
    }

    /// Série prévue si l'on récupère ce jour-là (pour l'afficher avant), et si le joker y passe.
    public func streakIfClaimed(day: String, jokerDays: Int) -> (streak: Int, jokerUsed: Bool) {
        guard let last = lastClaimDay else { return (1, false) }
        let gap = daysBetween(last, day)
        if gap <= 0 { return (streak, false) }
        if gap == 1 { return (streak + 1, false) }
        // Un seul jour manqué et le joker est libre : la série continue.
        if gap == 2 && jokerAvailable(day: day, jokerDays: jokerDays) { return (streak + 1, true) }
        return (1, false)
    }

    /// Enregistre la case du jour : série, joker, case suivante.
    public mutating func claim(day: String, calendarLength: Int, jokerDays: Int) {
        let (newStreak, jokerUsed) = streakIfClaimed(day: day, jokerDays: jokerDays)
        lastClaimDay = day
        calendarIndex = (calendarIndex + 1) % calendarLength
        streak = newStreak
        bestStreak = max(bestStreak, newStreak)
        if jokerUsed { jokerUsedDay = day }
    }
}

/// Nombre de jours entre deux dates « AAAA-MM-JJ » (b - a), sans fuseau ni heure d'été.
public func daysBetween(_ a: String, _ b: String) -> Int {
    dayNumber(b) - dayNumber(a)
}

/// Jours depuis le 1er janvier 1970 (calendrier grégorien), pour une date « AAAA-MM-JJ ».
private func dayNumber(_ day: String) -> Int {
    let parts = day.split(separator: "-").compactMap { Int($0) }
    guard parts.count == 3 else { return 0 }
    // Algorithme « days from civil » (Howard Hinnant).
    let y = parts[1] <= 2 ? parts[0] - 1 : parts[0]
    let era = (y >= 0 ? y : y - 399) / 400
    let yoe = y - era * 400
    let mp = (parts[1] + 9) % 12
    let doy = (153 * mp + 2) / 5 + parts[2] - 1
    let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
    return era * 146_097 + doe - 719_468
}
