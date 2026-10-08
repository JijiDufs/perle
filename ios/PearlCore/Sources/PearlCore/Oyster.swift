// Tirage et création d'une huître, miroir de src/core/draw.ts, oyster.ts et pearlTraits.ts.
// La perle est tirée à la création de l'huître (AGENTS.md, invariant 5).

/// Ce qui rend chaque perle unique : forme, reflet et, rarement, une marque.
public struct PearlTraits: Codable, Sendable, Equatable {
    public let shape: String
    public let overtone: String
    public let mark: String?
    /// 0…1 : petites irrégularités du dessin.
    public let seed: Double
}

/// Une huître fermée. Sa perle (ou sa trouvaille) est décidée dès sa création.
public struct Oyster: Codable, Sendable, Equatable {
    /// « empty » quand l'huître cache une trouvaille à la place d'une perle.
    public let pearlId: String
    /// Taille en mm, 0 pour une huître vide.
    public let sizeMm: Double
    public let findId: String?
    public let traits: PearlTraits?
}

public struct DrawState: Codable, Sendable, Equatable {
    /// Huîtres d'affilée sans perle dorée ou mieux.
    public var sinceGoldenOrBetter: Int
    public static let initial = DrawState(sinceGoldenOrBetter: 0)
}

public func isPityActive(_ state: DrawState, _ tuning: Tuning) -> Bool {
    state.sinceGoldenOrBetter >= tuning.pityThreshold
}

/// Tire le contenu d'une huître : une perle, ou parfois une trouvaille (perle = huître vide).
/// Sous garantie, le tirage se fait parmi les perles dorées ou mieux, sans trouvaille.
public func drawPearl(_ state: DrawState, _ rng: Rng, _ tuning: Tuning, catalog: Catalog = .shared)
    -> (pearl: PearlType, find: FindType?, state: DrawState)
{
    let pity = isPityActive(state, tuning)
    if !pity && rng() < catalog.findProbability {
        return (catalog.pearl("empty"), rollFind(rng, catalog: catalog), DrawState(sinceGoldenOrBetter: state.sinceGoldenOrBetter + 1))
    }
    let pool = pity ? catalog.pearls.filter(\.goldenOrBetter) : catalog.pearls
    let pearl = pickPearl(pool, rng)
    return (pearl, nil, DrawState(sinceGoldenOrBetter: pearl.goldenOrBetter ? 0 : state.sinceGoldenOrBetter + 1))
}

func pickPearl(_ pool: [PearlType], _ rng: Rng) -> PearlType {
    let total = pool.reduce(0) { $0 + $1.probability }
    var roll = rng() * total
    for pearl in pool {
        roll -= pearl.probability
        if roll < 0 { return pearl }
    }
    return pool[pool.count - 1]
}

/// Tire une trouvaille, au prorata des poids de rareté.
public func rollFind(_ rng: Rng, catalog: Catalog = .shared) -> FindType {
    var roll = rng()
    for find in catalog.finds {
        roll -= catalog.findShare(find)
        if roll < 0 { return find }
    }
    return catalog.finds[catalog.finds.count - 1]
}

public func createOyster(_ drawState: DrawState, _ rng: Rng, _ tuning: Tuning, catalog: Catalog = .shared)
    -> (oyster: Oyster, drawState: DrawState)
{
    let draw = drawPearl(drawState, rng, tuning, catalog: catalog)
    if let find = draw.find {
        return (Oyster(pearlId: "empty", sizeMm: 0, findId: find.id, traits: nil), draw.state)
    }
    return (oysterWith(draw.pearl.id, rng, markChance: tuning.pearlMarkChance, catalog: catalog), draw.state)
}

/// Huître contenant une perle donnée, de taille tirée dans sa plage, avec ses traits.
/// `markChance` : chance d'une marque rare (0 par défaut : tutoriel).
public func oysterWith(_ pearlId: String, _ rng: Rng, markChance: Double = 0, catalog: Catalog = .shared) -> Oyster {
    let range = catalog.pearl(pearlId).sizeMm
    let sizeMm = jsRound((range[0] + rng() * (range[1] - range[0])) * 10) / 10
    if pearlId == "empty" { return Oyster(pearlId: pearlId, sizeMm: sizeMm, findId: nil, traits: nil) }
    return Oyster(pearlId: pearlId, sizeMm: sizeMm, findId: nil, traits: rollTraits(pearlId, rng, markChance: markChance, catalog: catalog))
}

/// Tire les traits d'une perle.
public func rollTraits(_ pearlId: String, _ rng: Rng, markChance: Double, catalog: Catalog = .shared) -> PearlTraits {
    let shape = pickWeighted(catalog.shapeWeights[pearlId] ?? [], rng)
    let overtone = pickWeighted(catalog.overtoneWeights[pearlId] ?? [], rng)
    let mark = rng() < markChance ? pickWeighted(catalog.markWeights, rng) : nil
    return PearlTraits(shape: shape, overtone: overtone, mark: mark, seed: jsRound(rng() * 1000) / 1000)
}
