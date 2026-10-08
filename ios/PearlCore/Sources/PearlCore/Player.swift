// État du joueur de l'app iOS : huître en cours, cartes, numéros de série. Miroir réduit de
// src/core/player.ts (la poussière d'or, les skins et le stock viendront dans les passes suivantes).

/// Une carte de perle, créée à chaque huître ouverte.
public struct PearlCard: Codable, Sendable, Equatable, Identifiable {
    public let serial: Int
    public let pearlId: String
    public let sizeMm: Double
    public let value: Double
    public let lustre: Lustre
    public let cracked: Bool
    /// Date de révélation (ms).
    public let foundAt: Double
    public let traits: PearlTraits?
    public var id: Int { serial }
}

/// Une carte de trouvaille (easter egg).
public struct FindCard: Codable, Sendable, Equatable, Identifiable {
    public let serial: Int
    public let findId: String
    public let value: Double
    public let foundAt: Double
    public var id: Int { serial }
}

/// Ce que révèle une huître.
public enum Reveal: Sendable, Equatable {
    case pearl(PearlCard)
    case find(FindCard)
    case empty(serial: Int)
}

/// Valeur d'une perle : taille, traits, fêlure (÷ 2).
public func pearlValue(_ pearlId: String, sizeMm: Double, cracked: Bool, traits: PearlTraits?, catalog: Catalog = .shared) -> Double {
    let pearl = catalog.pearl(pearlId)
    if pearl.baseValue == 0 { return 0 }
    let sizeFactor = sizeMm / ((pearl.sizeMm[0] + pearl.sizeMm[1]) / 2)
    return jsRound(pearl.baseValue * sizeFactor * (traits.map { traitsValueFactor($0, catalog: catalog) } ?? 1) * (cracked ? 0.5 : 1))
}

public func traitsValueFactor(_ traits: PearlTraits, catalog: Catalog = .shared) -> Double {
    let shape = catalog.shapes[traits.shape]?.value ?? 1
    let overtone = catalog.overtones[traits.overtone]?.value ?? 1
    let mark = traits.mark.flatMap { catalog.marks[$0]?.value } ?? 1
    return shape * overtone * mark
}

public struct PlayerState: Codable, Sendable, Equatable {
    /// L'huître posée devant le joueur, tirée à l'avance et sauvegardée (invariant 5).
    public var oyster: Oyster
    public var drawState: DrawState
    public var nextSerial: Int
    public var pearlCards: [PearlCard]
    public var findCards: [FindCard]
    public var oystersOpened: Int

    /// Nouvelle partie : la première huître est déjà tirée.
    public static func new(_ rng: Rng, _ tuning: Tuning) -> PlayerState {
        let first = createOyster(.initial, rng, tuning)
        return PlayerState(oyster: first.oyster, drawState: first.drawState, nextSerial: 1, pearlCards: [], findCards: [], oystersOpened: 0)
    }

    /// L'huître en cours est ouverte : crée sa carte et tire la suivante.
    public mutating func reveal(lustre: Lustre, cracked: Bool, now: Double, rng: Rng, tuning: Tuning, catalog: Catalog = .shared) -> Reveal {
        let serial = nextSerial
        let opened = oyster
        let result: Reveal
        if let findId = opened.findId {
            let card = FindCard(serial: serial, findId: findId, value: catalog.find(findId).value, foundAt: now)
            findCards.append(card)
            result = .find(card)
        } else if opened.pearlId == "empty" {
            result = .empty(serial: serial)
        } else {
            let card = PearlCard(
                serial: serial, pearlId: opened.pearlId, sizeMm: opened.sizeMm,
                value: pearlValue(opened.pearlId, sizeMm: opened.sizeMm, cracked: cracked, traits: opened.traits, catalog: catalog),
                lustre: lustre, cracked: cracked, foundAt: now, traits: opened.traits
            )
            pearlCards.append(card)
            result = .pearl(card)
        }
        nextSerial += 1
        oystersOpened += 1
        let next = createOyster(drawState, rng, tuning, catalog: catalog)
        oyster = next.oyster
        drawState = next.drawState
        return result
    }

    /// Nombre de cartes possédées pour une sorte de perle (encyclopédie).
    public func count(of pearlId: String) -> Int {
        pearlCards.filter { $0.pearlId == pearlId }.count
    }
}

/// « N° 000042 ».
public func serialLabel(_ serial: Int) -> String {
    let digits = String(serial)
    return "N° " + String(repeating: "0", count: max(0, 6 - digits.count)) + digits
}
