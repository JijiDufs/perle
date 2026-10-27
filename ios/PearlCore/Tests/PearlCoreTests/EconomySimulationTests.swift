// Simulation de l'économie (docs/audit-app-ios.md, annexe A) : des joueurs types jouent 30 jours avec le vrai moteur
// (huîtres, revente, missions, calendrier, pubs, niveaux, succès, poisson). Elle garde l'équilibre voulu en
// AGENTS.md §6 (2026-10-21) : pas d'huîtres en cascade, des perles à chasser pendant des semaines, un bénitier
// qui se mérite. Les chiffres s'affichent avec `swift test --filter EconomySimulation`.
import Foundation
import Testing
@testable import PearlCore

private let catalog = Catalog.shared
private let tuning = catalog.tuning
private let hour = 3_600_000.0
/// 2026-11-01 à minuit (UTC+1).
private let firstDay = 1_793_487_600_000.0

struct PlayerProfile: Sendable {
    let name: String
    /// Heures des séances, chaque jour.
    let sessionHours: [Double]
    /// Pubs regardées quand la marée est basse.
    let adsPerDay: Int
    /// Lustre S, A, B (le reste : C) et fêlure.
    let lustreS: Double, lustreA: Double, lustreB: Double, crack: Double
    /// Chance de rattraper le poisson voleur.
    let fishCatch: Double
    let shares: Bool
}

let lightPlayer = PlayerProfile(name: "Léger", sessionHours: [9, 21], adsPerDay: 0,
                                lustreS: 0.10, lustreA: 0.30, lustreB: 0.35, crack: 0.15, fishCatch: 0.5, shares: false)
let regularPlayer = PlayerProfile(name: "Régulier", sessionHours: [8, 13, 20], adsPerDay: 3,
                                  lustreS: 0.20, lustreA: 0.35, lustreB: 0.30, crack: 0.08, fishCatch: 0.7, shares: true)
let heavyPlayer = PlayerProfile(name: "Gros", sessionHours: [7, 9, 11, 13, 15, 17, 19, 21, 23], adsPerDay: 3,
                                lustreS: 0.30, lustreA: 0.35, lustreB: 0.25, crack: 0.05, fishCatch: 0.8, shares: true)

struct SimulationResult {
    var firstSession: [Int] = []
    var dayAllKinds: [Int] = []
    var dayBenitier: [Int] = []
    var oystersPerDay = 0.0
    var dustPerDay = 0.0
    var levelDay30 = 0.0

    /// Médiane des jours (31 = pas dans les 30 jours).
    static func median(_ days: [Int]) -> Int { days.sorted()[days.count / 2] }
}

private func dayKey(_ day: Int) -> String {
    String(format: "2026-%02d-%02d", day < 30 ? 11 : 12, day < 30 ? day + 1 : day - 29)
}

/// Une partie neuve jouée 30 jours : chaque séance récupère le calendrier, ouvre tout le stock (pub quand il est
/// vide), revend les doublons et récupère les missions. Le joueur épargne sa poussière d'or.
func simulate(_ profile: PlayerProfile, runs: Int) -> SimulationResult {
    var result = SimulationResult()
    var oysters = 0, dust = 0, levels = 0
    for run in 0..<runs {
        let seed = UInt32(1000 + run)
        let rng = seededRng(seed), thief = seededRng(seed + 8000), play = seededRng(seed + 4000)
        var player = PlayerState.new(rng, tuning, now: firstDay + profile.sessionHours[0] * hour)
        var allKinds = 31, benitier = 31
        for day in 0..<30 {
            let key = dayKey(day)
            var adsLeft = profile.adsPerDay
            for time in profile.sessionHours {
                var now = firstDay + Double(day) * 24 * hour + time * hour
                player.refresh(now: now, day: key, tuning: tuning)
                let dustBefore = player.dust
                _ = player.claimDaily(day: key)
                var opened = 0
                while true {
                    let tutorial = player.isInTutorial()
                    if !tutorial && player.oystersAvailable(now: now, tuning: tuning) == 0 {
                        if adsLeft > 0, player.claimAdReward(day: key) != nil { adsLeft -= 1; continue }
                        break
                    }
                    let draw = play()
                    let lustre: Lustre = draw < profile.lustreS ? .S : draw < profile.lustreS + profile.lustreA ? .A
                        : draw < profile.lustreS + profile.lustreA + profile.lustreB ? .B : .C
                    let cracked = !tutorial && play() < profile.crack
                    _ = player.reveal(lustre: lustre, cracked: cracked, now: now, rng: rng, thiefRng: thief, tuning: tuning)
                    if player.stolenCard != nil {
                        if play() < profile.fishCatch { _ = player.catchThief() } else { _ = player.resolveTheft(caught: false) }
                    }
                    opened += 1
                    now += 20_000
                }
                if day == 0 && time == profile.sessionHours[0] { result.firstSession.append(opened) }
                oysters += opened
                if profile.shares { player.recordShare() }
                _ = player.sellAllDuplicates()
                for index in player.missions?.missions.indices ?? 0..<0 { _ = player.claimMission(at: index) }
                player.acknowledgeLevelUp()
                dust += player.dust - dustBefore
            }
            if allKinds == 31 && Set(player.pearlCards.map(\.pearlId)).count >= 7 { allKinds = day + 1 }
            if benitier == 31 && player.dust >= catalog.economy.skin("benitier")!.dustPrice! { benitier = day + 1 }
        }
        result.dayAllKinds.append(allKinds)
        result.dayBenitier.append(benitier)
        levels += catalog.levelProgress(reputation: player.reputation).level
    }
    result.oystersPerDay = Double(oysters) / Double(runs * 30)
    result.dustPerDay = Double(dust) / Double(runs * 30)
    result.levelDay30 = Double(levels) / Double(runs)
    return result
}

@Test func lEconomieResteLente() {
    var regular = SimulationResult(), light = SimulationResult()
    for profile in [lightPlayer, regularPlayer, heavyPlayer] {
        let result = simulate(profile, runs: 40)
        print(String(format: "%@ : 1re séance %d huîtres (max) · %.0f huîtres et %.0f ✦ par jour · niveau %.1f à J30 · 7 perles J%d · bénitier J%d",
                     profile.name, result.firstSession.max()!, result.oystersPerDay, result.dustPerDay, result.levelDay30,
                     SimulationResult.median(result.dayAllKinds), SimulationResult.median(result.dayBenitier)))
        #expect(result.firstSession.max()! <= 40, "\(profile.name) : première séance trop longue")
        if profile.name == regularPlayer.name { regular = result }
        if profile.name == lightPlayer.name { light = result }
    }
    // Probabilités inchangées (partagées avec la webapp) : la maudite (0,3 %) fixe le rythme de la collection.
    #expect(SimulationResult.median(regular.dayAllKinds) >= 5, "7 perles trop vite")
    #expect(SimulationResult.median(light.dayAllKinds) <= 21, "collection décourageante")
    #expect(SimulationResult.median(regular.dayBenitier) >= 19, "bénitier trop vite")
}
