// Écrins et bijoux (lot 1.4) : mêmes tirages et même moteur d'éclat que la webapp, sources (niveaux, poussière
// d'or), cartes, revente, succès, et parties d'avant la 1.4 qui reçoivent les écrins de leurs niveaux.
import Foundation
import Testing
@testable import PearlCore

private let catalog = Catalog.shared
private let tuning = catalog.tuning

private struct Parity: Decodable {
    struct WebJewel: Decodable {
        let rarityId, type, name, metal, metalName, flavor: String
        let gem: String?
        let candy, pearls: Bool
        let carats, value: Double
        let style: String?
        let cut: String?
    }
    struct Ecrin: Decodable {
        let jewel: WebJewel
        let sweetAngle: Double
        let variantIfPerfect: String?
        let sinceStarOrBetter: Int
    }
    struct Value: Decodable {
        let base: Double
        let perfect: Bool
        let variant: String?
        let value: Double
    }
    struct Sort: Decodable {
        let sort: String
        let serials: [Int]
    }
    struct Rank: Decodable {
        let rarityId: String
        let rank: Int
    }
    struct Glint: Decodable {
        struct Step: Decodable {
            let push: OpeningSample?
            let tick: Double?
        }
        let name: String
        let sweetAngle: Double
        let steps: [Step]
        let events: [[String]]
        let phase: String
        let perfect: Bool
        let holdMs: Double
        let closeness: Double
    }
    let ecrinSeed: UInt32
    let ecrins: [Ecrin]
    let jewelValues: [Value]
    let jewelSorts: [Sort]
    let jewelRarityRanks: [Rank]
    let glints: [Glint]
}

private func parity() throws -> Parity {
    let url = try #require(Bundle.module.url(forResource: "parity", withExtension: "json"))
    return try JSONDecoder().decode(Parity.self, from: Data(contentsOf: url))
}

@Test func memesEcrinsQueLaWebapp() throws {
    let expected = try parity()
    let rng = seededRng(expected.ecrinSeed)
    var draw = JewelDrawState.initial
    for (i, web) in expected.ecrins.enumerated() {
        let rolled = catalog.rollJewel(draw, rng)
        draw = rolled.state
        let jewel = rolled.jewel
        let sweet = catalog.rollSweetAngle(rng)
        let variant = catalog.rollRareVariant(rng)
        let w = web.jewel
        #expect(jewel.rarityId == w.rarityId && jewel.type == w.type && jewel.style == w.style, "écrin \(i)")
        #expect(jewel.metal == w.metal && jewel.metalName == w.metalName && jewel.gem == w.gem, "écrin \(i)")
        #expect(jewel.candy == w.candy && jewel.pearls == w.pearls && jewel.cut == w.cut, "écrin \(i)")
        #expect(jewel.carats == w.carats && jewel.value == w.value, "écrin \(i)")
        #expect(catalog.jewelName(jewel) == w.name && catalog.jewelFlavor(jewel) == w.flavor, "écrin \(i)")
        #expect(sweet == web.sweetAngle && variant == web.variantIfPerfect && draw.sinceStarOrBetter == web.sinceStarOrBetter, "écrin \(i)")
    }
}

@Test func memeValeurDeCarteQueLaWebapp() throws {
    let expected = try parity()
    for (i, web) in expected.jewelValues.enumerated() {
        let multiplier = web.variant != nil ? tuning.glintRareVariantMultiplier : web.perfect ? tuning.glintPerfectMultiplier : 1
        #expect(roundJewelValue(web.base * multiplier) == web.value, "carte \(i)")
    }
}

@Test func memeTriDesBijouxQueLaWebapp() throws {
    let expected = try parity()
    for rank in expected.jewelRarityRanks { #expect(catalog.jewelRarityRank(rank.rarityId) == rank.rank, "\(rank.rarityId)") }
    let rng = seededRng(expected.ecrinSeed)
    var draw = JewelDrawState.initial
    let cards: [JewelCard] = (0..<40).map { i in
        let rolled = catalog.rollJewel(draw, rng)
        draw = rolled.state
        _ = catalog.rollSweetAngle(rng)
        _ = catalog.rollRareVariant(rng)
        return JewelCard(serial: i + 1, jewel: rolled.jewel, value: expected.jewelValues[i].value, perfect: false, variant: nil, foundAt: 0)
    }
    for sort in expected.jewelSorts {
        let mine = catalog.sortJewelCards(cards, try #require(CardSort(rawValue: sort.sort)))
        #expect(mine.map(\.serial) == sort.serials, "\(sort.sort)")
    }
}

@Test func memeMoteurDEclatQueLaWebapp() throws {
    for web in try parity().glints {
        let engine = GlintEngine(tuning: tuning, sweetAngle: web.sweetAngle)
        for (i, step) in web.steps.enumerated() {
            let events = step.push.map { engine.push($0) } ?? engine.tick(step.tick ?? 0)
            #expect(events.map(\.type) == web.events[i], "\(web.name), étape \(i)")
        }
        if web.name.hasPrefix("relâché") { engine.release() }
        #expect(engine.phase.rawValue == web.phase && engine.perfect == web.perfect, "\(web.name)")
        #expect(abs(engine.holdMs - web.holdMs) < 1e-9 && abs(engine.closeness - web.closeness) < 1e-9, "\(web.name)")
    }
}

@Test func lesNomsDesBijouxExistentEnAnglais() {
    let english = catalog.localized("en")
    let rng = seededRng(3)
    var draw = JewelDrawState.initial
    for _ in 0..<2000 {
        let rolled = english.rollJewel(draw, rng)
        draw = rolled.state
        let name = english.jewelName(rolled.jewel, variant: "nuit")
        #expect(!name.contains("{") && name.first?.isUppercase == true && name.hasSuffix(" · Night"), "\(name)")
        #expect(english.metalLabel(rolled.jewel.metalName) != rolled.jewel.metalName || rolled.jewel.metalName == "Vermeil", "\(rolled.jewel.metalName)")
    }
    #expect(english.jewelRarity("toc").label == "Costume")
}

@Test func lesEcrinsViennentDesNiveauxEtDeLaPoussiere() {
    #expect(catalog.levelReward(2).ecrins == 0)
    #expect(catalog.levelReward(3).ecrins == 1)
    #expect(catalog.levelReward(5).ecrins == 1, "rang Perlier")
    #expect(catalog.levelReward(30).ecrins == 1)
    #expect(catalog.levelReward(20).ecrins == 1, "rang Joaillier")
    #expect(catalog.levelReward(15).ecrins == 1)

    var player = PlayerState.new(seededRng(1), tuning, now: 0)
    player.gainReputation((1..<5).reduce(0) { $0 + catalog.xpToNext($1) })
    #expect(player.ecrins == 2 && player.levelUp?.ecrins == 2)

    let price = catalog.economy.ecrins.dustPrice
    player.dust = price - 1
    let refused = player.buyEcrin()
    #expect(!refused)
    player.dust = price
    let bought = player.buyEcrin()
    #expect(bought && player.dust == 0 && player.ecrins == 3)
}

@Test func unEcrinEstTireAvantLeGesteEtDonneSaCarte() throws {
    let rng = seededRng(12)
    var player = PlayerState.new(rng, tuning, now: 0)
    player.ensureEcrin(rng: rng)
    #expect(player.currentEcrin == nil, "pas d'écrin à ouvrir")
    player.ecrins = 2
    player.ensureEcrin(rng: rng)
    let pending = try #require(player.currentEcrin)
    player.ensureEcrin(rng: rng)
    #expect(player.currentEcrin == pending && player.ecrins == 1, "le même écrin reste posé")
    // Sauvegardé : recharger ne relance pas le tirage.
    let reloaded = try JSONDecoder().decode(PlayerState.self, from: JSONEncoder().encode(player))
    #expect(reloaded.currentEcrin == pending)

    let reputation = player.reputation
    let serial = player.nextSerial
    let recorded = player.recordEcrin(perfect: true, now: 5)
    let card = try #require(recorded)
    #expect(card.serial == serial && card.perfect && player.currentEcrin == nil)
    let multiplier = card.variant != nil ? tuning.glintRareVariantMultiplier : tuning.glintPerfectMultiplier
    #expect(card.value == roundJewelValue(pending.jewel.value * multiplier))
    #expect(card.variant == pending.variantIfPerfect)
    #expect(player.stats.perfectGlints == 1)
    #expect(player.hasAchievement("premier-bijou") && player.hasAchievement("eclat-parfait"))
    #expect(player.reputation >= reputation + catalog.reputationForEcrin(perfect: true, discovery: true))
    let none = player.recordEcrin(perfect: false, now: 6)
    #expect(none == nil, "plus d'écrin posé")
}

@Test func onRevendLesBijouxEnDoubleSaufLesEclatsParfaits() {
    var player = PlayerState.new(seededRng(2), tuning, now: 0)
    let rng = seededRng(5)
    let jewel = catalog.jewelOfRarity(catalog.jewelRarity("or"), rng)
    player.jewelCards = [
        JewelCard(serial: 1, jewel: jewel, value: 500, perfect: false, variant: nil, foundAt: 0),
        JewelCard(serial: 2, jewel: jewel, value: 900, perfect: false, variant: nil, foundAt: 0),
        JewelCard(serial: 3, jewel: jewel, value: 400, perfect: true, variant: nil, foundAt: 0),
    ]
    #expect(player.sellableJewelDuplicates().map(\.serial) == [1])
    let dust = player.dust
    let gained = player.sellAllDuplicates()
    #expect(gained >= catalog.sellDust(jewel: "or"))
    #expect(player.jewelCards.map(\.serial) == [2, 3] && player.dust > dust)
    let soldPerfect = player.sellJewel(serial: 3)
    #expect(soldPerfect != nil)
    let soldLast = player.sellJewel(serial: 2)
    #expect(soldLast == nil, "jamais le dernier exemplaire")
}

@Test func uneSauvegarde10ReçoitLesEcrinsDeSesNiveauxDansSaFete() throws {
    let url = try #require(Bundle.module.url(forResource: "save-1.0", withExtension: "json"))
    let player = try JSONDecoder().decode(PlayerState.self, from: Data(contentsOf: url))
    let owed = (2...player.rewardedLevel).reduce(0) { $0 + catalog.levelReward($1).ecrins }
    #expect(owed > 0)
    #expect(player.ecrins == owed && player.levelUp?.ecrins == owed && player.ecrinCatchUp == nil)
    let again = try JSONDecoder().decode(PlayerState.self, from: JSONEncoder().encode(player))
    #expect(again == player, "rien de redonné au chargement suivant")
}

@Test func unePartie13ReçoitSesEcrinsUneSeuleFois() throws {
    // Une partie de la 1.3 : niveau 12 déjà fêté, statistiques sans éclats parfaits, pas d'écrins.
    var old = PlayerState.new(seededRng(9), tuning, now: 0)
    old.reputation = (1..<12).reduce(0) { $0 + catalog.xpToNext($1) }
    old.rewardedLevel = 12
    old.stats.sold = 4
    var raw = try #require(try JSONSerialization.jsonObject(with: JSONEncoder().encode(old)) as? [String: Any])
    for key in ["ecrins", "currentEcrin", "jewelDraw", "jewelCards", "ecrinCatchUp"] { raw[key] = nil }
    var stats = try #require(raw["stats"] as? [String: Any])
    stats["perfectGlints"] = nil
    stats["variants"] = nil
    raw["stats"] = stats
    let player = try JSONDecoder().decode(PlayerState.self, from: JSONSerialization.data(withJSONObject: raw))

    // Niveaux 3, 5 (rang), 6, 9, 10 (rang), 12.
    #expect(player.ecrins == 6 && player.ecrinCatchUp == 6 && player.levelUp == nil)
    #expect(player.stats.sold == 4 && player.stats.perfectGlints == 0)
    var seen = player
    seen.acknowledgeEcrinCatchUp()
    let again = try JSONDecoder().decode(PlayerState.self, from: JSONEncoder().encode(seen))
    #expect(again.ecrins == 6 && again.ecrinCatchUp == nil)

    // Une fête encore à faire : les écrins y sont annoncés, pas dans une deuxième fenêtre.
    old.levelUp = LevelUp(from: 11, to: 12, oysters: 5, dust: 5, ecrins: nil, retroactive: false)
    raw = try #require(try JSONSerialization.jsonObject(with: JSONEncoder().encode(old)) as? [String: Any])
    for key in ["ecrins", "currentEcrin", "jewelDraw", "jewelCards", "ecrinCatchUp"] { raw[key] = nil }
    let pending = try JSONDecoder().decode(PlayerState.self, from: JSONSerialization.data(withJSONObject: raw))
    #expect(pending.ecrins == 6 && pending.levelUp?.ecrins == 6 && pending.ecrinCatchUp == nil)
}

@Test func lesSuccesDesEcrinsComptentLesBijoux() {
    var player = PlayerState.new(seededRng(2), tuning, now: 0)
    let rng = seededRng(8)
    for (serial, rarity) in catalog.jewels.rarities.enumerated() {
        let jewel = catalog.jewelOfRarity(rarity, rng)
        player.jewelCards.append(JewelCard(serial: serial + 1, jewel: jewel, value: jewel.value, perfect: false, variant: nil, foundAt: 0))
    }
    let complete = catalog.achievement("ecrin-complet")!
    #expect(player.progress(of: complete) == (10, 10))
    #expect(player.progress(of: catalog.achievement("legende")!).done == 1)
    let types = Set(player.jewelCards.map(\.jewel.type)).intersection(catalog.jewels.mainTypes).count
    #expect(player.progress(of: catalog.achievement("types-bijoux")!).done == types)
}
