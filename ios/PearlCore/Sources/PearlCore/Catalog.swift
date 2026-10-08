// Les perles, les trouvailles et les traits, lus dans catalog.json : la source de vérité reste
// le TypeScript (src/core/catalog.ts, finds.ts, pearlTraits.ts), exporté par `npm run ios:export`.
import Foundation

public struct PearlType: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let name: String
    /// Symbole de rareté du cahier : —, ◆, ◆◆, ◆◆◆, ★, ★★.
    public let rarity: String
    public let probability: Double
    public let color: String
    /// Couleur de la lumière qui filtre à l'ouverture ; nil = huître vide, reste noire.
    public let glow: String?
    public let shape: String
    public let flavor: String
    public let baseValue: Double
    public let sizeMm: [Double]
    public let trembles: Bool
    public let goldenOrBetter: Bool
    public let revealTier: Int
}

public struct FindAlbum: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let description: String
}

/// Une trouvaille (easter egg) : un objet à la place de la perle.
public struct FindType: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let album: String
    public let name: String
    /// 1 (◆) à 5 (★★), comme les perles.
    public let tier: Int
    public let flavor: String
    public let value: Double
    public let glow: String
    /// « dust », « ecrin » ou « message ».
    public let effect: String?
}

public struct Trait: Codable, Sendable, Equatable {
    public let label: String
    /// Facteur appliqué à la valeur de la perle.
    public let value: Double
    public let color: String?
    public let weight: Double?
    public let description: String?
}

/// Un poids de tirage ; l'ordre des listes compte.
public struct Weighted: Codable, Sendable, Equatable {
    public let id: String
    public let weight: Double
}

public struct Catalog: Codable, Sendable {
    public let tuning: Tuning
    public let pearls: [PearlType]
    public let findProbability: Double
    public let findTierWeights: [Weighted]
    public let findAlbums: [FindAlbum]
    public let finds: [FindType]
    public let bottleMessages: [String]
    public let shapes: [String: Trait]
    public let overtones: [String: Trait]
    public let marks: [String: Trait]
    public let shapeWeights: [String: [Weighted]]
    public let overtoneWeights: [String: [Weighted]]
    public let markWeights: [Weighted]
    public let raritySymbols: [String]
    public let economy: Economy

    /// Le catalogue livré avec l'app.
    public static let shared: Catalog = {
        guard let url = Bundle.module.url(forResource: "catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let catalog = try? JSONDecoder().decode(Catalog.self, from: data)
        else { fatalError("catalog.json illisible : relancer npm run ios:export") }
        return catalog
    }()

    public func pearl(_ id: String) -> PearlType {
        guard let pearl = pearls.first(where: { $0.id == id }) else { fatalError("Perle inconnue : \(id)") }
        return pearl
    }

    public func find(_ id: String) -> FindType {
        guard let find = finds.first(where: { $0.id == id }) else { fatalError("Trouvaille inconnue : \(id)") }
        return find
    }

    /// Chance d'une trouvaille parmi toutes les trouvailles (0…1).
    func findShare(_ find: FindType) -> Double {
        let weightOf = { (tier: Int) in findTierWeights.first(where: { $0.id == String(tier) })?.weight ?? 0 }
        let total = finds.reduce(0) { $0 + weightOf($1.tier) }
        return weightOf(find.tier) / total
    }
}

/// Tire une clé au prorata de son poids, dans l'ordre de la liste (comme `pickWeighted` en TypeScript).
func pickWeighted(_ weights: [Weighted], _ rng: Rng) -> String {
    let total = weights.reduce(0) { $0 + $1.weight }
    var roll = rng() * total
    for entry in weights {
        roll -= entry.weight
        if roll < 0 { return entry.id }
    }
    return weights[weights.count - 1].id
}
