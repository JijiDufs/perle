// Premières minutes (cahier §15), miroir de src/core/tutorial.ts : les premières huîtres sont
// écrites à l'avance (perle rosée garantie, puis blanche, vide, baroque ; liste exportée du TypeScript).
// Elles sont offertes (le stock n'y touche pas) et comptent normalement pour la garantie « dorée ou mieux ».

extension Catalog {
    /// Perle imposée pour la n-ième huître (0 = la première), ou nil si le tirage est libre.
    public func scriptedPearl(oystersOpened: Int) -> String? {
        tutorialPearls.indices.contains(oystersOpened) ? tutorialPearls[oystersOpened] : nil
    }

    public func isInTutorial(oystersOpened: Int) -> Bool {
        oystersOpened < tutorialPearls.count
    }

    /// La toute première perle ne peut pas se fêler : la zone fragile s'apprend à partir de la 2e huître.
    public func isCrackProtected(oystersOpened: Int) -> Bool {
        oystersOpened == 0
    }
}

/// L'huître à poser quand `oystersOpened` huîtres ont déjà été ouvertes : écrite à l'avance
/// pendant le tutoriel, tirée au hasard ensuite.
public func nextOyster(oystersOpened: Int, _ drawState: DrawState, _ rng: Rng, _ tuning: Tuning, catalog: Catalog = .shared)
    -> (oyster: Oyster, drawState: DrawState)
{
    guard let scripted = catalog.scriptedPearl(oystersOpened: oystersOpened) else {
        return createOyster(drawState, rng, tuning, catalog: catalog)
    }
    let goldenOrBetter = catalog.pearl(scripted).goldenOrBetter
    return (oysterWith(scripted, rng, catalog: catalog),
            DrawState(sinceGoldenOrBetter: goldenOrBetter ? 0 : drawState.sinceGoldenOrBetter + 1))
}
