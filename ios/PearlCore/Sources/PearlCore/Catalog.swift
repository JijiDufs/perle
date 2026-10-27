// Les perles, les trouvailles et les traits, lus dans catalog.json : la source de vérité reste
// le TypeScript (src/core/catalog.ts, finds.ts, pearlTraits.ts), exporté par `npm run ios:export`.
import Foundation

public struct PearlType: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public internal(set) var name: String
    /// Symbole de rareté du cahier : —, ◆, ◆◆, ◆◆◆, ★, ★★.
    public let rarity: String
    public let probability: Double
    public let color: String
    /// Couleur de la lumière qui filtre à l'ouverture ; nil = huître vide, reste noire.
    public let glow: String?
    public let shape: String
    public internal(set) var flavor: String
    public let baseValue: Double
    public let sizeMm: [Double]
    public let trembles: Bool
    public let goldenOrBetter: Bool
    public let revealTier: Int
}

public struct FindAlbum: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public internal(set) var name: String
    public internal(set) var description: String
}

/// Une trouvaille (easter egg) : un objet à la place de la perle.
public struct FindType: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let album: String
    public internal(set) var name: String
    /// 1 (◆) à 5 (★★), comme les perles.
    public let tier: Int
    public internal(set) var flavor: String
    public let value: Double
    public let glow: String
    /// « dust », « ecrin » ou « message ».
    public let effect: String?
}

public struct Trait: Codable, Sendable, Equatable {
    public internal(set) var label: String
    /// Facteur appliqué à la valeur de la perle.
    public let value: Double
    public let color: String?
    public let weight: Double?
    public internal(set) var description: String?
}

/// Un poids de tirage ; l'ordre des listes compte.
public struct Weighted: Codable, Sendable, Equatable {
    public let id: String
    public let weight: Double
}

public struct Catalog: Codable, Sendable {
    public let tuning: Tuning
    /// Musique et effets sonores de l'app (src/tuning.ts, `APP_AUDIO`).
    public let audio: AudioTuning
    public internal(set) var pearls: [PearlType]
    public let findProbability: Double
    public let findTierWeights: [Weighted]
    public internal(set) var findAlbums: [FindAlbum]
    public internal(set) var finds: [FindType]
    public internal(set) var bottleMessages: [String]
    public internal(set) var shapes: [String: Trait]
    public internal(set) var overtones: [String: Trait]
    public internal(set) var marks: [String: Trait]
    public let shapeWeights: [String: [Weighted]]
    public let overtoneWeights: [String: [Weighted]]
    public let markWeights: [Weighted]
    public let raritySymbols: [String]
    /// Les premières huîtres, écrites à l'avance (src/core/tutorial.ts) ; voir Tutorial.swift.
    public let tutorialPearls: [String]
    /// Rangs de prestige (src/core/levels.ts), du Pêcheur à la Maison de haute joaillerie.
    public internal(set) var ranks: [Rank]
    public internal(set) var economy: Economy
    /// Textes anglais du contenu (src/core/catalogEnglish.ts) ; voir `localized(_:)`.
    public let english: CatalogEnglish?

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

    /// Chance qu'une huître cache une trouvaille de cette rareté (probabilités affichées).
    public func findChance(tier: Int) -> Double {
        findProbability * finds.filter { $0.tier == tier }.reduce(0) { $0 + findShare($1) }
    }

    /// Chance qu'une perle porte cette marque rare (probabilités affichées).
    public func markChance(_ markId: String, tuning: Tuning) -> Double {
        let total = markWeights.reduce(0) { $0 + $1.weight }
        return tuning.pearlMarkChance * (markWeights.first { $0.id == markId }?.weight ?? 0) / total
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
