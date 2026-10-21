// Le contenu du jeu en anglais (src/core/catalogEnglish.ts, exporté dans catalog.json).
// Seuls les textes changent : identifiants, probabilités et valeurs restent ceux du catalogue.

public struct CatalogEnglish: Codable, Sendable {
    public struct NameFlavor: Codable, Sendable { public let name: String; public let flavor: String }
    public struct NameDescription: Codable, Sendable { public let name: String; public let description: String }
    public struct Mark: Codable, Sendable { public let label: String; public let description: String }
    public struct AchievementText: Codable, Sendable { public let name: String; public let description: String; public let title: String? }

    public let pearls: [String: NameFlavor]
    public let findAlbums: [String: NameDescription]
    public let finds: [String: NameFlavor]
    /// Même ordre que `Catalog.bottleMessages`.
    public let bottleMessages: [String]
    public let shapes: [String: String]
    public let overtones: [String: String]
    public let marks: [String: Mark]
    public let skins: [String: NameDescription]
    public let consumables: [String: String]
    public let ranks: [String: String]
    public let achievements: [String: AchievementText]
    public let jewels: Jewels

    public struct Jewels: Codable, Sendable {
        public struct LabelFlavor: Codable, Sendable { public let label: String; public let flavor: String }
        public let rarities: [String: LabelFlavor]
        /// Même ordre que `JewelCatalog.tocVariants`.
        public let tocVariants: [NameFlavor]
        public let legendName: String
        public let metals: [String: String]
        public let types: [String: String]
        public let cuts: [String: String]
        public let gemWords: [String: GemWords]
        public let names: [String: [String: String]]
        public let variants: [String: LabelFlavor]
    }
}

extension Catalog {
    /// Le catalogue dans la langue de l'app : « en » pour l'anglais, le français sinon.
    /// Un texte sans traduction garde son français.
    public func localized(_ language: String) -> Catalog {
        guard language == "en", let english else { return self }
        var catalog = self
        catalog.pearls = pearls.map { pearl in
            var pearl = pearl
            if let text = english.pearls[pearl.id] { pearl.name = text.name; pearl.flavor = text.flavor }
            return pearl
        }
        catalog.findAlbums = findAlbums.map { album in
            var album = album
            if let text = english.findAlbums[album.id] { album.name = text.name; album.description = text.description }
            return album
        }
        catalog.finds = finds.map { find in
            var find = find
            if let text = english.finds[find.id] { find.name = text.name; find.flavor = text.flavor }
            return find
        }
        if english.bottleMessages.count == bottleMessages.count { catalog.bottleMessages = english.bottleMessages }
        catalog.shapes = shapes.mapValuesWithKeys { id, trait in
            var trait = trait
            if let label = english.shapes[id] { trait.label = label }
            return trait
        }
        catalog.overtones = overtones.mapValuesWithKeys { id, trait in
            var trait = trait
            if let label = english.overtones[id] { trait.label = label }
            return trait
        }
        catalog.marks = marks.mapValuesWithKeys { id, trait in
            var trait = trait
            if let text = english.marks[id] { trait.label = text.label; trait.description = text.description }
            return trait
        }
        catalog.economy.skins = economy.skins.map { skin in
            var skin = skin
            if let text = english.skins[skin.id] { skin.name = text.name; skin.description = text.description }
            return skin
        }
        catalog.economy.consumables = economy.consumables.map { product in
            var product = product
            if let name = english.consumables[product.id] { product.name = name }
            return product
        }
        catalog.economy.achievements = economy.achievements.map { achievement in
            var achievement = achievement
            if let text = english.achievements[achievement.id] {
                achievement.name = text.name
                achievement.description = text.description
                if achievement.title != nil, let title = text.title { achievement.title = title }
            }
            return achievement
        }
        var jewels = self.jewels
        let en = english.jewels
        jewels.rarities = jewels.rarities.map { rarity in
            var rarity = rarity
            if let text = en.rarities[rarity.id] { rarity.label = text.label; rarity.flavor = text.flavor }
            return rarity
        }
        if en.tocVariants.count == jewels.tocVariants.count {
            jewels.tocVariants = zip(jewels.tocVariants, en.tocVariants).map { toc, text in
                var toc = toc
                toc.name = text.name
                toc.flavor = text.flavor
                return toc
            }
        }
        jewels.legendName = en.legendName
        jewels.metalLabels = en.metals
        jewels.types = jewels.types.mapValuesWithKeys { id, label in en.types[id] ?? label }
        jewels.cuts = jewels.cuts.mapValuesWithKeys { id, cut in
            var cut = cut
            if let label = en.cuts[id] { cut.label = label }
            return cut
        }
        jewels.gemWords = en.gemWords
        jewels.names = en.names
        jewels.variants = jewels.variants.map { variant in
            var variant = variant
            if let text = en.variants[variant.id] { variant.label = text.label; variant.flavor = text.flavor }
            return variant
        }
        catalog.jewels = jewels
        catalog.ranks = ranks.map { rank in
            var rank = rank
            if let title = english.ranks[rank.id] { rank.title = title }
            return rank
        }
        return catalog
    }
}

private extension Dictionary {
    func mapValuesWithKeys(_ transform: (Key, Value) -> Value) -> [Key: Value] {
        Dictionary(uniqueKeysWithValues: map { ($0.key, transform($0.key, $0.value)) })
    }
}
