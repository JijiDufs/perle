// Missions du jour (docs/duo-gadget.md §6 quater) : trois petits objectifs, les mêmes pour tous,
// tirés avec une graine = le jour (heure locale du téléphone, fournie par l'app).

public struct Mission: Codable, Sendable, Equatable {
    public let kind: MissionKind
    public let goal: Int
    public var progress: Int
    public var claimed: Bool

    public var isDone: Bool { progress >= goal }
}

public struct DailyMissions: Codable, Sendable, Equatable {
    /// Jour local, AAAA-MM-JJ.
    public let day: String
    public var missions: [Mission]
    /// Bonus des trois missions déjà donné.
    public var bonusClaimed: Bool

    /// Les missions d'un jour : toujours les mêmes pour un jour donné.
    public static func forDay(_ day: String, economy: Economy) -> DailyMissions {
        let rng = seededRng(daySeed(day))
        var pool = economy.missions
        var missions: [Mission] = []
        for _ in 0..<min(economy.missionsPerDay, pool.count) {
            let template = pool.remove(at: Int(rng() * Double(pool.count)))
            let goal = template.goals[Int(rng() * Double(template.goals.count))]
            missions.append(Mission(kind: template.kind, goal: goal, progress: 0, claimed: false))
        }
        return DailyMissions(day: day, missions: missions, bonusClaimed: false)
    }

    /// Une mission avance (sans dépasser son objectif).
    mutating func advance(_ kind: MissionKind, by amount: Int = 1) {
        for index in missions.indices where missions[index].kind == kind {
            missions[index].progress = min(missions[index].goal, missions[index].progress + amount)
        }
    }

    /// Mission « d'affilée » : la meilleure série du jour compte.
    mutating func reachStreak(_ kind: MissionKind, _ streak: Int) {
        for index in missions.indices where missions[index].kind == kind {
            missions[index].progress = max(missions[index].progress, min(missions[index].goal, streak))
        }
    }

    /// La mission à mettre en avant à la Pêche : la plus avancée de celles pas encore récupérées (une terminée
    /// passe devant) ; nil quand toutes sont récupérées.
    public var nearest: Mission? {
        missions.filter { !$0.claimed }
            .max { Double($0.progress) / Double($0.goal) < Double($1.progress) / Double($1.goal) }
    }

    /// Une mission terminée attend sa récompense.
    public var hasReward: Bool {
        missions.contains { $0.isDone && !$0.claimed }
    }
}

/// « 2026-10-08 » → 20261008.
func daySeed(_ day: String) -> UInt32 {
    UInt32(day.filter(\.isNumber)) ?? 0
}
