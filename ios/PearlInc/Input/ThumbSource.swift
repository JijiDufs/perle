import QuartzCore
import PearlCore

/// Source de geste « pouce vers le haut » (iPhone classique), miroir de src/input/thumb.ts.
/// La distance s'accumule d'un appui à l'autre : on peut reprendre une ouverture entamée.
/// La charnière du Duo sera une autre source, qui produit les mêmes OpeningSample.
@MainActor
final class ThumbSource {
    /// Durée (ms) de l'ouverture automatique de fin de course, comme dans la webapp.
    private static let autoOpenMs = 240.0

    private(set) var distance = 0.0
    private var floor = 0.0
    private var startDistance: Double?
    private var autoOpenTask: Task<Void, Never>?

    var onSample: (OpeningSample, Double) -> Void = { _, _ in }
    var onRelease: () -> Void = {}

    static var now: Double { CACurrentMediaTime() * 1000 }

    /// Le doigt bouge : `translation` en pt, négative vers le haut.
    func drag(translation: Double, tuning: Tuning) {
        autoOpenTask?.cancel()
        if startDistance == nil { startDistance = distance }
        distance = max(floor, (startDistance ?? 0) - translation)
        onSample(OpeningSample(angle: thumbDistanceToAngle(distance, tuning), time: Self.now), distance)
    }

    /// Le doigt quitte l'écran. Au-delà de `autoOpenFrom`, le couvercle finit seul.
    func end(tuning: Tuning, autoOpenFrom: Double?) {
        startDistance = nil
        let angle = thumbDistanceToAngle(distance, tuning)
        if let threshold = autoOpenFrom, angle >= threshold, angle < 180 { autoOpen(tuning) } else { onRelease() }
    }

    /// Après le pop, le pouce ne peut plus refermer la coquille sous l'angle du pop.
    func lockAfterPop(tuning: Tuning) {
        floor = tuning.resistanceDistance
        distance = max(distance, floor)
    }

    /// Nouvelle huître, ou coquille refermée pendant la résistance.
    func reset() {
        autoOpenTask?.cancel()
        distance = 0
        floor = 0
        startDistance = nil
    }

    /// Ouverture lente et régulière, pour VoiceOver (« Ouvrir l'huître »).
    func openSlowly(tuning: Tuning, durationMs: Double) {
        animate(to: thumbFullDistance(tuning), durationMs: durationMs, eased: false, tuning: tuning)
    }

    private func autoOpen(_ tuning: Tuning) {
        animate(to: thumbFullDistance(tuning), durationMs: Self.autoOpenMs, eased: true, tuning: tuning)
    }

    private func animate(to target: Double, durationMs: Double, eased: Bool, tuning: Tuning) {
        autoOpenTask?.cancel()
        let from = distance
        let start = Self.now
        autoOpenTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let progress = min(1, (Self.now - start) / durationMs)
                let curve = eased ? 1 - pow(1 - progress, 3) : progress
                self.distance = from + (target - from) * curve
                self.onSample(OpeningSample(angle: thumbDistanceToAngle(self.distance, tuning), time: Self.now), self.distance)
                if progress >= 1 { self.onRelease(); return }
                try? await Task.sleep(for: .milliseconds(16))
            }
        }
    }
}
