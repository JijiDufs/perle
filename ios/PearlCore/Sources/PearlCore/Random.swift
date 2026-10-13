// Générateurs aléatoires, miroir de src/core/rng.ts. Le hasard est toujours passé en paramètre
// (AGENTS.md, invariant 4) : graine fixe dans les tests.

/// Générateur aléatoire : renvoie un nombre dans [0, 1).
public typealias Rng = () -> Double

/// Générateur à graine (mulberry32), reproductible : mêmes valeurs que `seededRng` en TypeScript.
public func seededRng(_ seed: UInt32) -> Rng {
    var state = seed
    return {
        state = state &+ 0x6D2B_79F5
        var t = state
        t = (t ^ (t >> 15)) &* (t | 1)
        t ^= t &+ ((t ^ (t >> 7)) &* (t | 61))
        return Double(t ^ (t >> 14)) / 4_294_967_296
    }
}

/// Générateur du système, pour le jeu.
public func systemRng() -> Rng {
    { Double.random(in: 0..<1) }
}

/// Arrondi de JavaScript (`Math.round`) : au plus proche, la moitié vers le haut.
func jsRound(_ value: Double) -> Double {
    (value + 0.5).rounded(.down)
}
