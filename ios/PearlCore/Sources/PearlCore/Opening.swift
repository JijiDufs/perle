// Moteur d'ouverture d'une huître et note de lustre, miroir de src/core/opening.ts et lustre.ts.
// Toute source de geste (pouce, charnière du Duo) produit des OpeningSample (AGENTS.md, invariant 2).

/// Une mesure du geste, quelle que soit sa source.
public struct OpeningSample: Codable, Sendable, Equatable {
    /// Angle d'ouverture en degrés, 0 (fermée) à 180.
    public var angle: Double
    /// Instant de la mesure en millisecondes.
    public var time: Double

    public init(angle: Double, time: Double) {
        self.angle = angle
        self.time = time
    }
}

public enum OpeningPhase: String, Sendable {
    case closed, resisting, opening, revealed
}

public enum Lustre: String, Codable, Sendable {
    case S, A, B, C
}

public enum OpeningEvent: Equatable, Sendable {
    case pop
    case crack
    case reveal(lustre: Lustre, cracked: Bool)

    /// Nom de l'événement, comme en TypeScript.
    public var type: String {
        switch self {
        case .pop: "pop"
        case .crack: "crack"
        case .reveal: "reveal"
        }
    }
}

/// Note la régularité de l'ouverture (coefficient de variation des vitesses).
public func gradeLustre(_ velocities: [Double], _ tuning: Tuning) -> Lustre {
    if velocities.count < tuning.lustreMinSamples { return .C }
    let mean = velocities.reduce(0, +) / Double(velocities.count)
    if mean <= 0 { return .C }
    let variance = velocities.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(velocities.count)
    let variation = variance.squareRoot() / mean
    if variation <= tuning.lustreMaxVariationS { return .S }
    if variation <= tuning.lustreMaxVariationA { return .A }
    if variation <= tuning.lustreMaxVariationB { return .B }
    return .C
}

/// closed → resisting → opening → revealed. Reçoit des mesures d'angle, calcule la vitesse,
/// et décide du pop, de la fêlure et de la révélation.
public final class OpeningEngine {
    public private(set) var phase: OpeningPhase = .closed
    public private(set) var angle: Double = 0
    /// Vitesse lissée en °/s (positive = ouverture).
    public private(set) var velocity: Double = 0
    public private(set) var cracked = false
    public private(set) var lustre: Lustre?

    private let tuning: Tuning
    /// Désactive la fêlure (première huître du tutoriel).
    private let crackProtected: Bool
    private var window: [OpeningSample] = []
    private var openingVelocities: [Double] = []

    public init(tuning: Tuning, crackProtected: Bool = false) {
        self.tuning = tuning
        self.crackProtected = crackProtected
    }

    public var inFragileZone: Bool {
        angle >= tuning.fragileMinAngle && angle <= tuning.fragileMaxAngle
    }

    @discardableResult
    public func push(_ sample: OpeningSample) -> [OpeningEvent] {
        if phase == .revealed { return [] }
        var events: [OpeningEvent] = []
        let t = tuning

        // Une fois ouverte, la coquille ne redescend pas sous l'angle du pop.
        let raw = phase == .opening ? max(sample.angle, t.popAngle) : sample.angle
        angle = min(max(raw, 0), 180)
        updateVelocity(OpeningSample(angle: angle, time: sample.time))

        if phase == .closed && angle > 0 { phase = .resisting }

        if phase == .resisting && angle >= t.popAngle {
            phase = .opening
            events.append(.pop)
            // La vitesse de la résistance ne compte pas pour le lustre.
            window = [OpeningSample(angle: angle, time: sample.time)]
            velocity = 0
            return events
        }

        if phase == .opening {
            // Le lustre juge la régularité dans la zone fragile, là où elle compte.
            if window.count >= 2 && inFragileZone { openingVelocities.append(velocity) }

            if !crackProtected && !cracked && inFragileZone && velocity > t.maxSafeVelocity {
                cracked = true
                events.append(.crack)
            }

            if angle >= t.revealAngle {
                phase = .revealed
                let grade = gradeLustre(openingVelocities, t)
                lustre = grade
                events.append(.reveal(lustre: grade, cracked: cracked))
            }
        }
        return events
    }

    /// Le doigt quitte l'écran. Pendant la résistance, la coquille se referme.
    public func release() {
        if phase == .resisting {
            phase = .closed
            angle = 0
        }
        velocity = 0
        window = []
    }

    private func updateVelocity(_ sample: OpeningSample) {
        window.append(sample)
        let cutoff = sample.time - tuning.velocityWindowMs
        while window.count > 2 && window[0].time < cutoff { window.removeFirst() }
        let first = window[0]
        let dt = (sample.time - first.time) / 1000
        velocity = dt > 0 ? (sample.angle - first.angle) / dt : 0
    }
}
