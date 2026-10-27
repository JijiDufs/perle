import CoreMotion
import Foundation
import Observation

/// L'inclinaison du téléphone (gyroscope), pour faire jouer les cartes dans la lumière sans les toucher.
/// Le repos suit doucement la façon dont on tient le téléphone : seul le mouvement compte, et une carte tenue
/// immobile revient à plat. Les capteurs ne tournent que tant qu'une carte est à l'écran.
@MainActor @Observable
final class DeviceTilt {
    static let shared = DeviceTilt()

    /// -1…1 sur chaque axe (x : gauche / droite, y : haut / bas), dans le sens où la carte doit pencher pour
    /// rester à plat dans la pièce ; nil = pas de capteur, ou aucune carte à l'écran.
    private(set) var tilt: CGPoint?

    /// Basculement (en g) qui penche la carte à fond, ≈ 20°.
    private static let fullTilt = 0.35
    /// Part de l'écart que le repos rattrape à chaque mesure (à 60 Hz, ≈ 1,5 s pour revenir à plat).
    private static let restFollow = 0.012

    private let manager = CMMotionManager()
    private var users = 0
    private var rest: CMAcceleration?

    func start() {
        users += 1
        guard users == 1, manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1 / 60
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let gravity = motion?.gravity else { return }
            MainActor.assumeIsolated { self?.update(gravity) }
        }
    }

    func stop() {
        users = max(0, users - 1)
        guard users == 0 else { return }
        manager.stopDeviceMotionUpdates()
        rest = nil
        tilt = nil
    }

    private func update(_ g: CMAcceleration) {
        var r = rest ?? g
        r.x += (g.x - r.x) * Self.restFollow
        r.y += (g.y - r.y) * Self.restFollow
        r.z += (g.z - r.z) * Self.restFollow
        rest = r
        // Gauche / droite : la gravité glisse sur l'axe x. Haut / bas : elle tourne dans le plan y-z autour du repos,
        // quelle que soit la façon dont on tient le téléphone (debout, penché, à plat).
        let side = g.x - r.x
        let pitch = ((g.y - r.y) * r.z - (g.z - r.z) * r.y) / max(0.2, hypot(r.y, r.z))
        tilt = CGPoint(x: clamp(-side / Self.fullTilt), y: clamp(-pitch / Self.fullTilt))
    }

    private func clamp(_ value: Double) -> Double { min(1, max(-1, value)) }
}
