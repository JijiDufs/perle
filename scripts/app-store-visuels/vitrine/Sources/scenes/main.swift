// Ouvertures pour la vidéo de lancement (scripts/video-lancement), image par image, avec le code de dessin et les
// moteurs de l'app (OpeningEngine, GlintEngine) : huîtres et écrins, iPhone classique (pouce) et iPhone Duo
// (écran intérieur, pose `.fold`, et écran extérieur, pose `.cover` ; l'angle suit celui du téléphone, 1 pour 1 ;
// l'écran extérieur montre la coquille ou l'écrin fermé, c'est le téléphone qui soulève le couvercle).
// Les prises du simulateur saccadent (≈ 20 images/s pour l'écrin) : ici, chaque image est calculée.
// usage : scenes <dossier> <prise> [i/s]  → <dossier>/<prise>/00000.jpg… (+ cover/ pour le Duo), <dossier>/<prise>.json
import AppKit
import PearlCore
import SwiftUI

let args = CommandLine.arguments
let out = args[1], shot = args[2]
let fps = args.count > 3 ? Double(args[3])! : 60
let catalog = Catalog.shared
let tuning = catalog.tuning

func smooth(_ a: Double, _ b: Double, _ x: Double) -> Double { let t = min(1, max(0, (x - a) / (b - a))); return t * t * (3 - 2 * t) }
func ease(_ x: Double) -> Double { let t = min(1, max(0, x)); return t * t * (3 - 2 * t) }

// ---------- Écrans ----------
/// iPhone 17 Pro (402 × 874 pt, rendu × 2), écran intérieur du Duo (951 × 669 pt) et extérieur (466 × 678 pt),
/// rendus à la taille des textures du Duo de pearl-inc.app (1420 × 1010 et 560 × 809).
enum Screen { case phone, inner, cover
    var size: CGSize { switch self { case .phone: CGSize(width: 402, height: 874); case .inner: CGSize(width: 951, height: 669); case .cover: CGSize(width: 466, height: 678) } }
    var scale: Double { switch self { case .phone: 2; case .inner: 1420 / 951; case .cover: 560 / 466 } }
}

@MainActor func save<V: View>(_ view: V, _ screen: Screen, _ path: String) {
    let r = ImageRenderer(content: view.frame(width: screen.size.width, height: screen.size.height))
    r.scale = screen.scale
    guard let img = r.cgImage else { fatalError("rendu \(path)") }
    try! NSBitmapImageRep(cgImage: img).representation(using: .jpeg, properties: [.compressionFactor: 0.93])!.write(to: URL(fileURLWithPath: path))
}

// ---------- Huître ----------
struct OysterShot { var pearl: String; var find: String? = nil; var skin = "lagon"; var sizeMm: Double; var shape = "ronde"; var overtone: String?
    var hold: Double; var resist: Double; var open: Double; var after: Double; var duo = false }

struct OysterScene: View {
    let screen: Screen, art: OysterArt
    var body: some View {
        Canvas { c, size in
            let pose: OysterArt.Pose = switch screen { case .phone: .thumb; case .inner: .fold(x: size.width / 2); case .cover: .cover }
            var a = art; a.pose = pose
            let layout = OysterArt.layout(size: size, look: a.look, pose: pose)
            let lagoon = LagoonArt(time: a.time, focus: layout.focus)
            lagoon.draw(&c, size: size)
            a.draw(&c, size: size)
            lagoon.drawOverlay(&c, size: size)
            a.drawRevealEffects(&c, size: size)
        }
    }
}

struct Frame: Encodable { var angle: Double; var phase: String; var finger: Double? }
struct Meta: Encodable { var fps: Double; var frames: [Frame]; var events: [String: Double] }

/// Distance du pouce (pt) pour un angle, comme ThumbMapping : 70 pt jusqu'au pop, puis 260 pt jusqu'à 180°.
func thumbDistance(_ angle: Double) -> Double { angle <= tuning.popAngle ? 70 * angle / tuning.popAngle : 70 + (angle - tuning.popAngle) / (180 - tuning.popAngle) * 260 }

@MainActor func renderOyster(_ s: OysterShot) {
    let pearl = catalog.pearls.first { $0.id == s.pearl }!
    // PearlTraits n'a pas d'initialiseur public : on le décode, comme une sauvegarde.
    let traits = try! JSONDecoder().decode(PearlTraits.self, from: JSONSerialization.data(withJSONObject: [
        "shape": s.shape, "overtone": s.overtone ?? catalog.overtoneWeights[s.pearl]?.first?.id ?? "argente", "seed": 0.42]))
    let look: PearlLook? = s.find != nil || s.pearl == "empty" ? nil : PearlLook(pearl, traits: traits, catalog: catalog)
    let tier = s.find.map { f in min(3, catalog.finds.first { $0.id == f }!.tier - 1) } ?? pearl.revealTier  // comme GameModel.revealTier
    let glow = s.find != nil ? catalog.finds.first { $0.id == s.find }!.glow : pearl.glow
    let suspenseMs = [tuning.revealSuspenseTier0Ms, tuning.revealSuspenseTier1Ms, tuning.revealSuspenseTier2Ms, tuning.revealSuspenseTier3Ms][min(3, tier)]
    let popAt = s.hold + s.resist, revealAt = popAt + s.open
    let flashAt = revealAt + suspenseMs / 1000
    let total = flashAt + s.after
    // Le geste : rien, la résistance jusqu'au pop, puis une ouverture régulière qui ralentit un peu à la fin.
    func gesture(_ t: Double) -> Double {
        if t < s.hold { return 0 }
        if t < popAt { return tuning.popAngle * ease((t - s.hold) / s.resist) }
        let k = min(1, (t - popAt) / s.open)
        return tuning.popAngle + (tuning.revealAngle - tuning.popAngle) * (k * (1.25 - 0.25 * k))
    }
    let dir = "\(out)/\(s.duo ? "duo-" : "")\(s.find ?? s.pearl)\(s.skin == "lagon" ? "" : "-" + s.skin)"
    try! FileManager.default.createDirectory(atPath: dir + (s.duo ? "/cover" : ""), withIntermediateDirectories: true)
    var frames: [Frame] = []
    for i in 0..<Int(total * fps) {
        let t = Double(i) / fps
        let revealed = t >= revealAt
        let ms = (t - revealAt) * 1000
        // Au pouce, le couvercle finit seul (revealLidSettleMs) ; sur le Duo, c'est le téléphone qui continue jusqu'à plat.
        let angle = !revealed ? gesture(t) : s.duo ? tuning.revealAngle + 40 * smooth(0, 0.9, t - revealAt)
            : tuning.revealAngle + 40 * smooth(0, tuning.revealLidSettleMs, ms)
        let flash = tier >= 3 && t >= flashAt ? 1 - smooth(0, tuning.revealFlashMs, (t - flashAt) * 1000) : 0
        let art = OysterArt(angle: angle, pearl: look, glowColor: glow, sizeMm: s.sizeMm, findId: s.find, revealTier: tier, cracked: false,
                            trembles: s.find == nil && pearl.trembles, revealed: revealed, suspense: revealed ? smooth(0, max(suspenseMs, 1), ms) : 0,
                            flash: flash, time: 1.7 + t, look: SkinLook(skinId: s.skin), shapeSeed: 59)
        let phase = revealed ? "open" : angle == 0 ? "closed" : angle > tuning.fragileMinAngle && angle < tuning.fragileMaxAngle ? "fragile" : "opening"
        let finger: Double? = !s.duo && t > s.hold - 0.25 && t < revealAt + 0.12 ? 700 - thumbDistance(revealed ? 180 : angle) : nil
        frames.append(Frame(angle: angle, phase: phase, finger: finger))
        if s.duo {
            save(OysterScene(screen: .inner, art: art), .inner, String(format: "%@/%05d.jpg", dir, i))
            // Écran extérieur : la coquille fermée, immobile (seul le lagon vit), pendant toute l'ouverture.
            do { var closed = art; closed.angle = 0; closed.revealed = false; closed.suspense = 0; closed.flash = 0
                save(OysterScene(screen: .cover, art: closed), .cover, String(format: "%@/cover/%05d.jpg", dir, i)) }
        } else {
            save(OysterScene(screen: .phone, art: art), .phone, String(format: "%@/%05d.jpg", dir, i))
        }
    }
    let meta = Meta(fps: fps, frames: frames, events: ["pop": popAt, "reveal": revealAt, "card": flashAt, "total": total])
    try! JSONEncoder().encode(meta).write(to: URL(fileURLWithPath: dir + ".json"))
    print("\(frames.count) images → \(dir)")
}

// ---------- Écrin ----------
struct EcrinScene: View {
    let screen: Screen, angle: Double, closeness: Double, perfect: Bool, perfectAgo: Double?, variant: String?, suspense: Double
    let jewel: Jewel, rarity: JewelRarity, time: Double
    var body: some View {
        Canvas { context, size in
            // Comme EcrinView.draw (iPhone : trois quarts ; Duo : vu de dessus, charnière sur le pli de l'écran intérieur).
            let c = Canvas2D(context)
            let w = Double(size.width), h = Double(size.height), t = time
            let visible = h - 190
            let top = screen != .phone
            let fold: Double? = screen == .inner ? w / 2 : nil
            let cx, cy, bw: Double
            // Sur le Duo de la vidéo, ni en-tête ni messages : l'écrin prend presque tout l'écran (plus grand que dans l'app,
            // qui lui garde de la place autour ; demande de Jules).
            if let fold { bw = min(min(fold, w - fold) * 1.25, h * 0.92); cx = fold + bw * 0.35; cy = h / 2 }
            else if top { bw = min(w * 0.92, h * 0.92); cx = w / 2; cy = h / 2 }
            else { bw = min(w * 0.86, visible * 0.68); cx = w / 2; cy = 100 + visible * 0.62 }
            let salon = SalonArt(time: t, focus: .init(x: cx, y: cy, w: bw * 0.8, h: bw * 0.45))
            salon.draw(c, w: w, h: h)
            let sparkle = perfect ? 1 : closeness
            let open = smooth(1, 25, angle)
            let v = variant.flatMap { catalog.jewelVariant($0) }
            let glow = v?.glow ?? rarity.glow
            let sparkleTier = v != nil ? max(rarity.tier, 5) : rarity.tier
            let look = JewelArt.Look(jewel, variant: v?.id, catalog: catalog)
            EcrinArt.drawShadow(c, cx: cx, cy: cy, width: bw, top: top)
            let anchors = EcrinArt.draw(
                c, cx: cx, cy: cy, width: bw, leather: EcrinArt.leathers[2], angle: fold == nil ? angle : 180,
                dim: 1 - smooth(4, 140, angle),
                sweep: rarity.tier >= 4 && angle == 0 ? (t * 0.5).truncatingRemainder(dividingBy: 1.6) - 0.3 : nil,
                top: top,
                drawJewel: { JewelArt.draw(c, 0, (JewelArt.yOffset(jewel) - 0.5) * 0.66, 0.66 / 440, look) },
                drawEffects: { x, y, unit in
                    guard let glow else { return }
                    drawGlow(c, x, y, unit * (0.32 + Double(sparkleTier) * 0.04), glow, open * (0.12 + 0.45 * sparkle) + suspense * 0.3)
                    JewelArt.drawSparkles(c, x, y, tier: sparkleTier, glow: glow, t: t, alpha: open * (0.15 + 0.85 * sparkle) + suspense * 0.5, scale: unit / 700)
                })
            let leak = fold == nil ? smooth(0.5, 10, angle) * (1 - smooth(40, 95, angle)) : 0
            if leak > 0.001 { drawGlow(c, anchors.lidEdge.0, anchors.lidEdge.1, bw * 0.5, rarity.glow ?? "#fff1d6", leak * 0.6) }
            if let ago = perfectAgo {
                let elapsed = ago * 1000
                for wave in 0..<(v != nil ? 2 : 1) {
                    let delay = Double(wave) * 250
                    let burst = 1 - smooth(0, 700 + Double(wave) * 400, elapsed - delay)
                    guard burst > 0, elapsed >= delay else { continue }
                    for i in 0..<14 {
                        let a = Double(i) / 14 * 2 * .pi + Double(wave) * 0.22
                        let radius = bw / 600 * (120 + (1 - burst) * (300 + Double(wave) * 120))
                        JewelArt.drawStar(c, anchors.jewel.0 + cos(a) * radius, anchors.jewel.1 + sin(a) * radius * 0.8,
                                          bw / 600 * (30 * burst + 8), burst, wave == 1 ? glow ?? "#fff3c4" : "#fff3c4")
                    }
                }
            }
            salon.drawOverlay(c, w: w, h: h)
        }
    }
}

@MainActor func renderEcrin(duo: Bool) {
    // Le bijou de la partie vitrine : un diadème de rubis (variante Aurore), comme sur la carte filmée.
    let rng = seededRng(2026)
    var draw = JewelDrawState.initial
    var jewel: Jewel?
    for _ in 0..<20000 { let r = catalog.rollJewel(draw, rng); draw = r.state
        if r.jewel.rarityId == "rubis" && r.jewel.type == "diademe" && r.jewel.cut == "coeur" { jewel = r.jewel; break } }
    let rarity = catalog.jewelRarity("rubis")
    let sweet = 82.0, variant = "aurore"
    // Le geste : pop, on monte doucement vers l'éclat, on cherche un peu, on tient, puis on ouvre jusqu'au bout.
    let hold = duo ? 1.3 : 0.5, popAt = hold + 0.55
    let keys: [(Double, Double)] = [(0, 0), (hold, 0), (popAt, tuning.popAngle), (popAt + 0.75, sweet - 9), (popAt + 1.05, sweet + 3),
                                    (popAt + 1.3, sweet), (popAt + 2.5, sweet), (popAt + 3.0, 180)]
    func gesture(_ t: Double) -> Double {
        for k in 1..<keys.count where t <= keys[k].0 { let (t0, a0) = keys[k - 1], (t1, a1) = keys[k]; return a0 + (a1 - a0) * ease((t - t0) / (t1 - t0)) }
        return 180
    }
    let engine = GlintEngine(tuning: tuning, sweetAngle: sweet)
    let dir = "\(out)/\(duo ? "duo-" : "")ecrin"
    try! FileManager.default.createDirectory(atPath: dir + (duo ? "/cover" : ""), withIntermediateDirectories: true)
    var frames: [Frame] = [], events: [String: Double] = [:]
    var perfectAt: Double?, revealAt: Double?
    let suspenseMs = tuning.revealSuspenseTier3Ms  // variante rare : mise en scène maximale
    var i = 0
    while true {
        let t = Double(i) / fps
        if let r = revealAt, t > r + suspenseMs / 1000 + 1.2 { break }
        let g = gesture(t)
        // Le geste nourrit le vrai moteur (pop, éclat parfait, révélation) ; le temps avance aussi immobile.
        for e in engine.push(OpeningSample(angle: g, time: t * 1000)) {
            switch e { case .pop: events["pop"] = t; case .perfect: perfectAt = t; events["perfect"] = t
            case .reveal: revealAt = t; events["reveal"] = t; events["card"] = t + suspenseMs / 1000 }
        }
        let revealed = revealAt != nil
        let angle = revealed ? max(engine.angle, g) : engine.angle
        let suspense = revealAt.map { smooth(0, suspenseMs, (t - $0) * 1000) } ?? 0
        let isVariant = perfectAt != nil
        let phase = revealed ? "suspense" : engine.phase == .closed ? "closed" : engine.phase == .resisting ? "resist"
            : isVariant ? "variant" : angle > tuning.fragileMinAngle && angle < tuning.revealAngle ? (engine.closeness > 0.75 ? "near" : "search") : "more"
        let finger: Double? = !duo && t > hold - 0.25 && !revealed ? 600 - thumbDistance(g) : nil
        frames.append(Frame(angle: angle, phase: phase, finger: finger))
        let scene = { (screen: Screen) in EcrinScene(screen: screen, angle: angle, closeness: engine.closeness, perfect: engine.perfect,
                                                     perfectAgo: perfectAt.map { t - $0 }, variant: isVariant ? variant : nil, suspense: suspense,
                                                     jewel: jewel!, rarity: rarity, time: 40 + t) }
        if duo {
            save(scene(.inner), .inner, String(format: "%@/%05d.jpg", dir, i))
            do { save(EcrinScene(screen: .cover, angle: 0, closeness: 0, perfect: false, perfectAgo: nil, variant: nil, suspense: 0,
                                            jewel: jewel!, rarity: rarity, time: 40 + t), .cover, String(format: "%@/cover/%05d.jpg", dir, i)) }
        } else {
            save(scene(.phone), .phone, String(format: "%@/%05d.jpg", dir, i))
        }
        i += 1
    }
    events["total"] = Double(i) / fps
    try! JSONEncoder().encode(Meta(fps: fps, frames: frames, events: events)).write(to: URL(fileURLWithPath: dir + ".json"))
    print("\(i) images → \(dir) \(events)")
}

MainActor.assumeIsolated {
    switch shot {
    // L'accroche : lente, on sent la résistance, puis la lumière dorée.
    case "golden": renderOyster(OysterShot(pearl: "golden", sizeMm: 13.8, overtone: "dore", hold: 0.6, resist: 0.7, open: 1.5, after: 0.3))
    case "black": renderOyster(OysterShot(pearl: "black", sizeMm: 12.9, overtone: "vert-paon", hold: 0.2, resist: 0.35, open: 0.9, after: 0.2))
    case "find": renderOyster(OysterShot(pearl: "empty", find: "canard", sizeMm: 0, hold: 0.2, resist: 0.35, open: 0.9, after: 0.2))
    case "giant": renderOyster(OysterShot(pearl: "giant", skin: "benitier", sizeMm: 25.6, shape: "presque-ronde", overtone: "arc-en-ciel", hold: 0.2, resist: 0.35, open: 0.9, after: 0.2))
    case "cursed": renderOyster(OysterShot(pearl: "cursed", sizeMm: 13, shape: "presque-ronde", overtone: "sang", hold: 0.5, resist: 0.6, open: 1.3, after: 0.2))
    case "rose-or": renderOyster(OysterShot(pearl: "rose", skin: "or", sizeMm: 9, overtone: "rose", hold: 0.3, resist: 0.4, open: 1.0, after: 0.2))
    case "duo-golden": renderOyster(OysterShot(pearl: "golden", sizeMm: 13.8, overtone: "dore", hold: 1.4, resist: 0.6, open: 1.4, after: 0.6, duo: true))
    case "ecrin": renderEcrin(duo: false)
    case "duo-ecrin": renderEcrin(duo: true)
    default: fatalError("prise inconnue : \(shot)")
    }
}
