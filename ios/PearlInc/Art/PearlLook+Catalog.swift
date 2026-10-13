import PearlCore

extension PearlLook {
    /// La perle d'une huître ou d'une carte, avec ses traits.
    init(_ pearl: PearlType, traits: PearlTraits?, catalog: Catalog) {
        self.init(id: pearl.id, color: pearl.color, glow: pearl.glow, shape: traits?.shape, overtone: traits?.overtone,
                  overtoneColor: traits.flatMap { catalog.overtones[$0.overtone]?.color }, mark: traits?.mark, seed: traits?.seed ?? 0.5)
    }

}
