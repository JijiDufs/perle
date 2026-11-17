// Rendu haute définition de l'art du jeu (code de dessin de l'app iOS) pour les visuels App Store :
// scènes du lagon (×3, comme sur iPhone), perles, trouvailles et bijoux sur fond transparent. Lancé par render.sh.
import AppKit
import PearlCore
import SwiftUI
// Le dessin de l'app charge ses photos en UIImage (iOS) : même nom sur Mac. render.sh copie les photos à côté de l'exécutable (Bundle.main).
typealias UIImage = NSImage
extension Image { init(uiImage: NSImage) { self.init(nsImage: uiImage) } }

struct PearlEntry: Decodable { let id: String; let color: String; let glow: String? }
struct Overtone: Decodable { let color: String? }
struct FindEntry: Decodable { let id: String; let glow: String }
struct Cat: Decodable { let pearls: [PearlEntry]; let overtones: [String: Overtone]; let finds: [FindEntry] }

let args = CommandLine.arguments
let cat = try! JSONDecoder().decode(Cat.self, from: Data(contentsOf: URL(fileURLWithPath: args[1])))
let out = args[2]

func look(_ id: String, shape: String? = nil, overtone: String? = nil, mark: String? = nil, seed: Double = 0.4) -> PearlLook {
    let p = cat.pearls.first { $0.id == id }!
    return PearlLook(id: id, color: p.color, glow: p.glow, shape: shape, overtone: overtone,
                     overtoneColor: overtone.flatMap { cat.overtones[$0]?.color }, mark: mark, seed: seed)
}

@MainActor func save<V: View>(_ view: V, _ name: String, scale: CGFloat = 1) {
    let r = ImageRenderer(content: view)
    r.scale = scale
    r.isOpaque = false
    guard let img = r.cgImage else { fatalError("rendu \(name)") }
    try! NSBitmapImageRep(cgImage: img).representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(out)/\(name).png"))
    print(name)
}

/// Une scène complète : lagon + huître, comme dans l'app, à n'importe quelle taille.
struct Scene: View {
    var w: Double, h: Double
    var skin = "lagon"
    var angle: Double
    var pearl: PearlLook?
    var findId: String?
    var length: Double
    var cy: Double            // ordonnée de la charnière
    var revealed = false
    var suspense = 0.0
    var tier = 3
    var time = 0.9
    var seed = 7
    var lagoon = true
    var body: some View {
        Canvas { c, size in
            let lk = SkinLook(skinId: skin)
            var layout = OysterArt.layout(size: size, look: lk, length: length)
            let dy = cy - layout.hy
            layout.hy = cy
            let lag = LagoonArt(time: time, focus: layout.focus)
            if lagoon { lag.draw(&c, size: size) }
            var cc = c
            cc.translateBy(x: 0, y: dy)
            let art = OysterArt(angle: angle, pearl: pearl, glowColor: findId != nil ? "#7fd8ff" : pearl?.glow, sizeMm: 12, findId: findId,
                                revealTier: tier, cracked: false, trembles: false, revealed: revealed, suspense: suspense,
                                time: time, look: lk, shapeSeed: seed, length: length)
            art.draw(&cc, size: size)
            if lagoon { lag.drawOverlay(&c, size: size) }
            art.drawRevealEffects(&cc, size: size)
        }
        .frame(width: w, height: h)
    }
}

/// Le lagon seul, sur plusieurs écrans de large : le fond continu des visuels qui se suivent (même hauteur et même
/// foyer de lumière que la capture du héros, qui recouvre le premier écran).
struct WideLagoon: View {
    var screens: Double
    var body: some View {
        Canvas { c, size in
            let layout = OysterArt.layout(size: CGSize(width: 402, height: 874), look: SkinLook(skinId: "lagon"))
            let lagoon = LagoonArt(time: 1.7, focus: layout.focus)
            lagoon.draw(&c, size: size)
            lagoon.drawOverlay(&c, size: size)
        }
        .frame(width: 402 * screens, height: 874)
    }
}

/// Le lagon de jour en paysage pour les bannières (render-bannieres.sh), en points de scène : le décor sous l'huître
/// (`overlay` faux) ou la vignette qui passe devant elle (`overlay` vrai, fond transparent). Foyer = l'huître posée.
struct BannerLagoon: View {
    var w: Double, h: Double, fx: Double, fy: Double, overlay: Bool
    var body: some View {
        Canvas { c, size in
            let lagoon = LagoonArt(time: 1.7, focus: .init(x: fx, y: fy, size: phoneFocus.size), style: .lagoon)
            if overlay { lagoon.drawOverlay(&c, size: size) } else { lagoon.draw(&c, size: size) }
        }
        .frame(width: w, height: h)
    }
}
/// Le foyer du lagon sur l'écran de l'iPhone (402 × 874 points) : là où la capture de l'huître est posée.
let phoneFocus = OysterArt.layout(size: CGSize(width: 402, height: 874), look: SkinLook(skinId: "lagon")).focus
/// Une perle seule, sur fond transparent, avec son halo.
struct Solo: View {
    var pearl: PearlLook
    var side: Double = 900
    var halo = 0.9
    var body: some View {
        Canvas { c, size in
            let r = side * 0.24
            PearlArt.glow(&c, side / 2, side / 2, side * 0.5, pearl.glow, halo, additive: false)
            PearlArt.draw(&c, side / 2, side / 2, r, pearl, cracked: false)
        }
        .frame(width: side, height: side)
    }
}

struct FindSolo: View {
    var id: String
    var side: Double = 900
    var glow: String
    var body: some View {
        Canvas { c, size in
            PearlArt.glow(&c, side / 2, side / 2, side * 0.5, glow, 0.8, additive: false)
            FindArt.draw(c, side / 2, side / 2, side * 0.32, id: id, t: 0.9)
        }
        .frame(width: side, height: side)
    }
}

/// Un bijou seul, sur fond transparent, avec son halo (tiré par le moteur des écrins, graine fixe).
struct JewelSolo: View {
    var look: JewelArt.Look
    var glow: String
    var side: Double = 900
    var body: some View {
        Canvas { c, size in
            PearlArt.glow(&c, side / 2, side / 2, side * 0.5, glow, 0.7, additive: false)
            JewelArt.draw(Canvas2D(c), side / 2, side * JewelArt.yOffset(look.jewel), side / 440, look)
        }
        .frame(width: side, height: side)
    }
}

let W = 1320.0, H = 2868.0
// `art <catalogue> <sortie> banniere <nom> <largeur> <hauteur> <foyer x> <foyer y> <échelle>` (points de scène) :
// le lagon des bannières seulement ; `art <catalogue> <sortie> foyer` : le foyer de l'écran de l'iPhone.
if args.count > 3 {
    MainActor.assumeIsolated {
        if args[3] == "foyer" { return print(phoneFocus.x, phoneFocus.y, phoneFocus.size) }
        let n = args[5...9].map { Double($0)! }
        for overlay in [false, true] {
            save(BannerLagoon(w: n[0], h: n[1], fx: n[2], fy: n[3], overlay: overlay), "\(args[4])-\(overlay ? "vignette" : "lagon")", scale: n[4])
        }
    }
    exit(0)
}
MainActor.assumeIsolated {
    let golden = look("golden", shape: "ronde", overtone: "dore")
    let pearls: [(String, PearlLook)] = [
        ("white", look("white", shape: "ronde", overtone: "argente")),
        ("rose", look("rose", shape: "ronde", overtone: "rose")),
        ("baroque", look("baroque", shape: "baroque", overtone: "creme", seed: 0.3)),
        ("black", look("black", shape: "ronde", overtone: "vert-paon")),
        ("golden", golden),
        ("giant", look("giant", shape: "presque-ronde", overtone: "arc-en-ciel")),
        ("cursed", look("cursed", shape: "presque-ronde", overtone: "sang", seed: 0.6)),
    ]
    for (name, l) in pearls { save(Solo(pearl: l), "pearl-\(name)") }
    // Le héros : l'huître du lagon entrouverte, lumière dorée, comme dans l'app (points × 3).
    save(Scene(w: 440, h: 956, angle: 34, pearl: golden, length: 318, cy: 520, time: 1.7), "hero-golden-34", scale: 3)
    save(WideLagoon(screens: 3), "lagoon-wide", scale: 1320.0 / 402)
    for find in cat.finds { save(FindSolo(id: find.id, glow: find.glow), "find-\(find.id)") }
    // Bijoux : le premier de chaque rareté tiré par le moteur (comme la partie vitrine), un diadème pour le rubis.
    let catalog = Catalog.shared
    let rng = seededRng(2026)
    var draw = JewelDrawState.initial
    var byRarity: [String: [Jewel]] = [:]
    for _ in 0..<5000 { let r = catalog.rollJewel(draw, rng); draw = r.state; byRarity[r.jewel.rarityId, default: []].append(r.jewel) }
    for (rarity, variant) in [("toc", nil), ("perles", nil), ("saphir", nil), ("emeraude", nil), ("diamant", nil), ("rubis", "aurore")] as [(String, String?)] {
        let jewels = byRarity[rarity]!
        let jewel = rarity == "rubis" ? jewels.first { $0.type == "diademe" } ?? jewels[0] : jewels[0]
        let glow = variant.flatMap { catalog.jewelVariant($0)?.glow } ?? catalog.jewelRarity(rarity).glow ?? "#fff1d6"
        save(JewelSolo(look: JewelArt.Look(jewel, variant: variant, catalog: catalog), glow: glow), "jewel-\(rarity)")
    }
}
