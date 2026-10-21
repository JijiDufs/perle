// Moteur d'ouverture d'un écrin, miroir de src/core/glint.ts (cahier §7) : même ouverture que l'huître
// (résistance, pop, révélation), sans fêlure, plus l'angle d'éclat caché. Tenir le geste immobile sur cet angle
// assez longtemps donne un éclat parfait. Le pouce (ou la charnière) immobile n'envoie plus de mesures :
// `tick` doit être appelé régulièrement pour faire avancer le temps.

public enum GlintEvent: Equatable, Sendable {
    case pop
    case perfect
    case reveal(perfect: Bool)

    /// Nom de l'événement, comme en TypeScript.
    public var type: String {
        switch self {
        case .pop: "pop"
        case .perfect: "perfect"
        case .reveal: "reveal"
        }
    }
}

public final class GlintEngine {
    /// Proximité de l'angle d'éclat, 0 (loin) à 1 (dessus) : pilote le scintillement.
    public private(set) var closeness = 0.0
    /// Temps (ms) déjà tenu sur l'angle d'éclat.
    public private(set) var holdMs = 0.0
    public private(set) var perfect = false
    public let sweetAngle: Double

    private let tuning: Tuning
    private let opening: OpeningEngine
    private var lastSampleTime = -Double.infinity
    private var lastTickTime: Double?

    public init(tuning: Tuning, sweetAngle: Double) {
        self.tuning = tuning
        self.sweetAngle = sweetAngle
        opening = OpeningEngine(tuning: tuning, crackProtected: true)
    }

    public var phase: OpeningPhase { opening.phase }
    public var angle: Double { opening.angle }

    /// Vitesse en °/s, ramenée à 0 si aucune mesure récente (geste immobile).
    public func velocity(at time: Double) -> Double {
        time - lastSampleTime > tuning.velocityWindowMs ? 0 : opening.velocity
    }

    /// Progression de l'éclat parfait, 0 à 1.
    public var holdProgress: Double {
        perfect ? 1 : min(1, holdMs / tuning.glintHoldMs)
    }

    @discardableResult
    public func push(_ sample: OpeningSample) -> [GlintEvent] {
        lastSampleTime = sample.time
        var events: [GlintEvent] = []
        for event in opening.push(sample) {
            switch event {
            case .pop: events.append(.pop)
            case .reveal: events.append(.reveal(perfect: perfect))
            case .crack: break
            }
        }
        events += tick(sample.time)
        return events
    }

    /// Fait avancer le temps (même sans mouvement).
    @discardableResult
    public func tick(_ time: Double) -> [GlintEvent] {
        let dt = lastTickTime.map { max(0, time - $0) } ?? 0
        lastTickTime = time
        let t = tuning
        let isOpening = phase == .opening
        let gap = abs(angle - sweetAngle)
        closeness = isOpening ? max(0, 1 - gap / t.glintSparkleRange) : 0
        if perfect || !isOpening { return [] }

        let still = abs(velocity(at: time)) < t.glintMaxVelocity
        if gap < t.glintTolerance && still { holdMs += dt } else { holdMs = max(0, holdMs - dt * 2) }

        if holdMs >= t.glintHoldMs {
            perfect = true
            return [.perfect]
        }
        return []
    }

    public func release() {
        opening.release()
    }
}
