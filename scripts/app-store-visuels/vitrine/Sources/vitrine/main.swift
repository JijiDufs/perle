// Partie « vitrine » des visuels App Store, passée par le vrai moteur (PearlCore) pour être cohérente :
// lit sur l'entrée la partie écrite par seed.py (sans statistiques ni succès), la charge comme une ancienne
// sauvegarde (statistiques et succès remplis par le Core), monte jusqu'au niveau voulu, ajoute des bijoux
// tirés par le moteur des écrins et l'écrin posé, puis efface les fenêtres en attente (rien ne s'affiche
// au lancement). Écrit la partie sur la sortie.
// usage: vitrine <niveau> <écrins à ouvrir> <rareté de l'écrin posé|-> <angle d'éclat> <variante|-> <titre|->
import Foundation
import PearlCore

let args = CommandLine.arguments
let level = Int(args[1])!, ecrins = Int(args[2])!, ecrinRarity = args[3], sweet = Double(args[4])!, variant = args[5], title = args[6]
let catalog = Catalog.shared
let input = FileHandle.standardInput.readDataToEndOfFile()
// Poussière et stock voulus, sans les récompenses du rattrapage (données au chargement).
let raw = try JSONSerialization.jsonObject(with: input) as! [String: Any]
var player = try JSONDecoder().decode(PlayerState.self, from: input)

while catalog.levelProgress(reputation: player.reputation).level < level { player.gainReputation(25) }

// Bijoux tirés par le moteur : le premier de chaque rareté (graine fixe), comme un joueur qui en a ouvert une vingtaine.
let rng = seededRng(2026)
var draw = JewelDrawState.initial
var byRarity: [String: [Jewel]] = [:]
for _ in 0..<5000 { let r = catalog.rollJewel(draw, rng); draw = r.state; byRarity[r.jewel.rarityId, default: []].append(r.jewel) }
/// Comme roundJewelValue du Core (interne) : à l'unité au-delà de 10, au centième en dessous.
func rounded(_ v: Double) -> Double { v >= 10 ? (v + 0.5).rounded(.down) : ((v * 100) + 0.5).rounded(.down) / 100 }
func object<T: Encodable>(_ value: T) -> Any { try! JSONSerialization.jsonObject(with: JSONEncoder().encode(value)) }
func decoded<T: Decodable>(_ type: T.Type, _ dict: [String: Any]) -> T {
    try! JSONDecoder().decode(type, from: JSONSerialization.data(withJSONObject: dict))
}
let owned: [(String, Int, Bool, String?)] = [  // rareté, combien, éclat parfait, variante
    ("toc", 2, false, nil), ("fantaisie", 3, false, nil), ("argent", 3, true, nil), ("or", 2, true, nil),
    ("perles", 2, false, nil), ("saphir", 1, true, nil), ("emeraude", 1, false, nil), ("diamant", 1, true, "nuit"),
]
var serial = player.nextSerial
let now = Date().timeIntervalSince1970 * 1000
for (rarity, count, perfect, variant) in owned {
    for jewel in byRarity[rarity]!.prefix(count) {
        let factor = variant != nil ? catalog.tuning.glintRareVariantMultiplier : perfect ? catalog.tuning.glintPerfectMultiplier : 1
        var card: [String: Any] = ["serial": serial, "jewel": object(jewel), "value": rounded(jewel.value * factor),
                                   "perfect": perfect, "foundAt": now - Double(serial) * 60_000]
        if let variant { card["variant"] = variant }
        player.jewelCards.append(decoded(JewelCard.self, card))
        serial += 1
    }
}
player.nextSerial = serial
if ecrinRarity != "-" {
    // L'écrin posé : le plus beau bijou de sa rareté (un diadème s'il y en a un).
    let jewels = byRarity[ecrinRarity]!
    let jewel = jewels.first { $0.type == "diademe" } ?? jewels[0]
    var pending: [String: Any] = ["jewel": object(jewel), "sweetAngle": sweet]
    if variant != "-" { pending["variantIfPerfect"] = variant }
    player.currentEcrin = decoded(PendingEcrin.self, pending)
}
player.ecrins = ecrins
player.stats.perfectGlints = player.jewelCards.filter(\.perfect).count
player.stats.variants = player.jewelCards.filter { $0.variant != nil }.count
if title != "-" { player.wearTitle(title) }

// Rien en attente : pas de fête de niveau ni de fenêtre de succès au lancement.
player.acknowledgeLevelUp()
player.acknowledgeAchievementCatchUp()
for id in player.unseenAchievements { player.acknowledgeAchievement(id) }
player.ecrinCatchUp = nil
player.dust = raw["dust"] as! Int
player.stock = decoded(StockState.self, raw["stock"] as! [String: Any])
let encoder = JSONEncoder(); encoder.outputFormatting = .sortedKeys
FileHandle.standardOutput.write(try encoder.encode(player))
