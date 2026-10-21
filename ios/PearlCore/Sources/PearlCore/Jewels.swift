// Les bijoux des écrins (lot 1.4), miroir de src/core/jewels.ts : raretés, tirage avec garantie ★, types, modèles,
// métaux, tailles de pierre, variantes rares. Les tables sont lues dans catalog.json (`npm run ios:export`).
// Un bijou garde sa structure (rareté, type, modèle, métal…) ; son nom et son texte se composent dans la langue de l'app.

public struct JewelRarity: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public internal(set) var label: String
    /// 0 (toc) à 5 (légende).
    public let tier: Int
    /// Symbole affiché : —, ◆ … ★★.
    public let rarity: String
    public let probability: Double
    public let glow: String?
    public let metal: String
    public let metalName: String
    public let gem: String?
    public let carats: [Double]?
    /// Valeur [min, max], avant carats, type et modèle.
    public let value: [Double]
    public internal(set) var flavor: String
}

/// Un bijou en toc : l'humour du jeu.
public struct TocVariant: Codable, Sendable, Equatable {
    public internal(set) var name: String
    public let metal: String
    public let gem: String
    public let metalName: String
    public let candy: Bool
    public internal(set) var flavor: String
}

public struct MetalOption: Codable, Sendable, Equatable {
    public let color: String
    public let name: String
    public let weight: Double
}

public struct GemWords: Codable, Sendable, Equatable {
    public let one: String
    public let with: String
    public let of: String
}

public struct GemCutInfo: Codable, Sendable, Equatable {
    public internal(set) var label: String
    public let value: Double
}

/// Variante rare révélée par un éclat parfait (Aurore, Nuit, Givre).
public struct JewelVariant: Codable, Sendable, Identifiable, Equatable {
    public struct Frame: Codable, Sendable, Equatable {
        public let colors: [String]
        public let dark: Bool
    }
    public let id: String
    public internal(set) var label: String
    public let metal: String
    public let metalName: String
    public let gem: String
    public let glow: String
    public let frame: Frame
    public internal(set) var flavor: String
}

public struct JewelCatalog: Codable, Sendable {
    public internal(set) var rarities: [JewelRarity]
    public internal(set) var tocVariants: [TocVariant]
    public internal(set) var legendName: String
    public internal(set) var types: [String: String]
    /// Les six types d'un écrin complet (le diadème est à part).
    public let mainTypes: [String]
    let typeMultipliers: [String: Double]
    public internal(set) var cuts: [String: GemCutInfo]
    let styles: [String: Double]
    let metalOptions: [String: [MetalOption]]
    let cutWeights: [String: [Weighted]]
    let typeWeights: [String: [Weighted]]
    let styleWeights: [String: [String: [Weighted]]]
    let diademMinTier: Int
    let diademWeight: Double
    let forcedCuts: [String: String]
    var gemWords: [String: GemWords]
    var names: [String: [String: String]]
    public internal(set) var variants: [JewelVariant]
    /// Noms des métaux dans la langue de l'app, par nom français (nil en français).
    var metalLabels: [String: String]?
}

/// Un bijou tiré : tout ce qu'il faut pour le dessiner, le nommer et l'estimer.
public struct Jewel: Codable, Sendable, Equatable {
    public let rarityId: String
    public let type: String
    public let style: String
    /// Couleur du métal, et son nom français (traduit à l'affichage).
    public let metal: String
    public let metalName: String
    public let gem: String?
    /// Pierre « bonbon » (toc) plutôt que taillée.
    public let candy: Bool
    /// Rang de perles (bijoux « Perles »).
    public let pearls: Bool
    public let carats: Double
    /// Valeur de base, avant l'éclat parfait.
    public let value: Double
    public let cut: String?
    /// Bijou en toc : lequel (nom et texte).
    public let toc: Int?
}

public struct JewelDrawState: Codable, Sendable, Equatable {
    /// Écrins d'affilée sans bijou ★ ou mieux.
    public var sinceStarOrBetter: Int

    public static let initial = JewelDrawState(sinceStarOrBetter: 0)
}

/// L'écrin posé : bijou, angle d'éclat et variante tirés avant le geste et sauvegardés (invariant 5).
public struct PendingEcrin: Codable, Sendable, Equatable {
    public let jewel: Jewel
    public let sweetAngle: Double
    /// Variante obtenue SI l'éclat est parfait (tirée d'avance : relancer l'app ne la relance pas).
    public let variantIfPerfect: String?
}

/// Une carte de bijou, créée à chaque écrin ouvert.
public struct JewelCard: Codable, Sendable, Equatable, Identifiable {
    public let serial: Int
    public let jewel: Jewel
    /// Valeur finale (×1,5 sur un éclat parfait, ×2 avec une variante rare).
    public let value: Double
    public let perfect: Bool
    public let variant: String?
    public let foundAt: Double
    public var id: Int { serial }
}

extension Catalog {
    public func jewelRarity(_ id: String) -> JewelRarity {
        guard let rarity = jewels.rarities.first(where: { $0.id == id }) else { fatalError("Rareté de bijou inconnue : \(id)") }
        return rarity
    }

    public func jewelVariant(_ id: String) -> JewelVariant? {
        jewels.variants.first { $0.id == id }
    }

    /// Tire un bijou. Garantie : ★ ou mieux après `ecrinPityThreshold` écrins sans.
    public func rollJewel(_ state: JewelDrawState, _ rng: Rng) -> (jewel: Jewel, state: JewelDrawState) {
        let starOrBetter = { (rarity: JewelRarity) in rarity.tier >= 4 }
        let pool = state.sinceStarOrBetter >= tuning.ecrinPityThreshold ? jewels.rarities.filter(starOrBetter) : jewels.rarities
        let total = pool.reduce(0) { $0 + $1.probability }
        var roll = rng() * total
        var rarity = pool[pool.count - 1]
        for candidate in pool {
            roll -= candidate.probability
            if roll < 0 { rarity = candidate; break }
        }
        return (jewelOfRarity(rarity, rng), JewelDrawState(sinceStarOrBetter: starOrBetter(rarity) ? 0 : state.sinceStarOrBetter + 1))
    }

    /// Fabrique un bijou d'une rareté donnée (type, modèle, métal, taille, carats, valeur), comme `jewelOfRarity`.
    func jewelOfRarity(_ rarity: JewelRarity, _ rng: Rng) -> Jewel {
        let j = jewels
        func carats() -> Double {
            guard let range = rarity.carats else { return 0 }
            return jsRound((range[0] + rng() * (range[1] - range[0])) * 100) / 100
        }
        func estimate(_ type: String, _ style: String?, _ cut: String?, _ weight: Double) -> Double {
            let base = rarity.value[0] + rng() * (rarity.value[1] - rarity.value[0])
            let styleFactor = style.flatMap { j.styles[$0] } ?? 1
            let cutFactor = cut.flatMap { j.cuts[$0]?.value } ?? 1
            return roundJewelValue(base * (weight != 0 ? max(1, weight) : 1) * (j.typeMultipliers[type] ?? 1) * styleFactor * cutFactor)
        }

        if rarity.id == "toc" {
            let index = min(j.tocVariants.count - 1, Int((rng() * Double(j.tocVariants.count)).rounded(.down)))
            let toc = j.tocVariants[index]
            return Jewel(rarityId: rarity.id, type: "bague", style: "solitaire", metal: toc.metal, metalName: toc.metalName, gem: toc.gem,
                         candy: toc.candy, pearls: false, carats: 0, value: estimate("bague", nil, nil, 0), cut: nil, toc: index)
        }
        if rarity.id == "legende" {
            let weight = carats()
            return Jewel(rarityId: rarity.id, type: "diademe", style: "classique", metal: rarity.metal, metalName: rarity.metalName,
                         gem: rarity.gem, candy: false, pearls: false, carats: weight, value: estimate("diademe", nil, nil, weight), cut: "rond", toc: nil)
        }

        let ornament = ornamentOf(rarity)
        var typeWeights = j.typeWeights[ornament] ?? []
        if ornament == "gem" && rarity.tier >= j.diademMinTier { typeWeights.append(Weighted(id: "diademe", weight: j.diademWeight)) }
        let type = pickWeighted(typeWeights, rng)
        let style = pickWeighted(j.styleWeights[ornament]?[type] ?? [], rng)
        let options = j.metalOptions[rarity.id] ?? [MetalOption(color: rarity.metal, name: rarity.metalName, weight: 1)]
        let metal = options[Int(pickWeighted(options.enumerated().map { Weighted(id: String($0.offset), weight: $0.element.weight) }, rng)) ?? 0]
        let rolledCut = j.cutWeights[rarity.id].map { pickWeighted($0, rng) }
        let cut = rolledCut.map { j.forcedCuts[style] ?? $0 }
        let weight = carats()
        return Jewel(rarityId: rarity.id, type: type, style: style, metal: metal.color, metalName: metal.name, gem: rarity.gem,
                     candy: false, pearls: rarity.id == "perles", carats: weight, value: estimate(type, style, cut, weight), cut: cut, toc: nil)
    }

    private func ornamentOf(_ rarity: JewelRarity) -> String {
        rarity.id == "perles" ? "pearls" : rarity.gem != nil ? "gem" : "metal"
    }

    /// Angle d'éclat caché d'un écrin.
    public func rollSweetAngle(_ rng: Rng) -> Double {
        jsRound(tuning.glintMinAngle + rng() * (tuning.glintMaxAngle - tuning.glintMinAngle))
    }

    /// La variante qu'aurait l'écrin en cas d'éclat parfait (nil : pas de variante).
    public func rollRareVariant(_ rng: Rng) -> String? {
        if rng() >= tuning.glintRareVariantChance { return nil }
        let variants = jewels.variants
        return variants[min(variants.count - 1, Int((rng() * Double(variants.count)).rounded(.down)))].id
    }

    // MARK: - Ce qu'on affiche

    /// Nom du bijou dans la langue du catalogue, avec sa variante rare (« … · Aurore »).
    public func jewelName(_ jewel: Jewel, variant: String? = nil) -> String {
        let j = jewels
        let rarity = jewelRarity(jewel.rarityId)
        var name: String
        if let toc = jewel.toc {
            name = j.tocVariants[toc].name
        } else if jewel.rarityId == "legende" {
            name = j.legendName
        } else {
            let names = j.names[ornamentOf(rarity)] ?? [:]
            let words = j.gemWords[rarity.id]
            let template = names["\(jewel.style).\(jewel.type)"] ?? names[jewel.style] ?? j.types[jewel.type] ?? jewel.type
            name = template
                .replacingOccurrences(of: "{metal}", with: metalLabel(jewel.metalName).lowercased().replacingOccurrences(of: " 925", with: ""))
                .replacingOccurrences(of: "{one}", with: words?.one ?? "")
                .replacingOccurrences(of: "{with}", with: words?.with ?? "")
                .replacingOccurrences(of: "{of}", with: words?.of ?? "")
            name = name.prefix(1).uppercased() + name.dropFirst()
        }
        if let variant = variant.flatMap(jewelVariant) { name += " · \(variant.label)" }
        return name
    }

    /// Texte d'ambiance (celui de la variante rare, s'il y en a une).
    public func jewelFlavor(_ jewel: Jewel, variant: String? = nil) -> String {
        if let variant = variant.flatMap(jewelVariant) { return variant.flavor }
        if let toc = jewel.toc { return jewels.tocVariants[toc].flavor }
        return jewelRarity(jewel.rarityId).flavor
    }

    /// Le nom d'un métal dans la langue du catalogue.
    public func metalLabel(_ metalName: String) -> String {
        jewels.metalLabels?[metalName] ?? metalName
    }

    /// Couleurs du bijou transformé par sa variante rare : métal, pierre, et nom du métal.
    public func jewelLook(_ jewel: Jewel, variant: String?) -> (metal: String, gem: String?, metalName: String) {
        guard let variant = variant.flatMap(jewelVariant) else { return (jewel.metal, jewel.gem, jewel.metalName) }
        return (variant.metal, jewel.gem == nil ? nil : variant.gem, variant.metalName)
    }
}

/// Arrondit une valeur : à l'unité au-delà de 10, au centième en dessous (comme `roundValue`).
func roundJewelValue(_ value: Double) -> Double {
    value >= 10 ? jsRound(value) : jsRound(value * 100) / 100
}
