// Planche des skins d'huître, dessinée avec le code de l'app (ios/PearlInc/Art) sur le Mac.
// Lancé par scripts/make-skin-sheet.sh, ne pas compiler à la main.
import AppKit
import SwiftUI

struct SkinEntry: Decodable {
    let id: String
    let name: String
    let description: String
    let dustPrice: Int?
    let productId: String?
    let grant: String?

    /// Comment l'obtenir. Les prix en euros sont ceux proposés dans docs/duo-gadget.md §6 ter
    /// (dans l'app, ils viendront de StoreKit).
    var howToGet: String {
        if grant == "start" { return "Offerte au départ" }
        if grant == "signup" { return "Réservée aux inscrits" }
        let euros = ["benitier": "2,99 €", "or": "9,99 €"][id]
        let dust = dustPrice.map { "\($0.formatted(.number.locale(Locale(identifier: "fr_FR")))) ✦" }
        return [dust, euros].compactMap { $0 }.joined(separator: " ou ")
    }
}

struct Catalog: Decodable {
    struct Economy: Decodable { let skins: [SkinEntry] }
    let economy: Economy
}

/// Une perle rosée, presque ronde, reflet rose : pour montrer l'intérieur.
let rosePearl = PearlLook(id: "rose", color: "#F2C4CC", glow: "#ffb3c6", shape: "presque-ronde",
                          overtone: "rose", overtoneColor: "#ffc2d2", mark: nil, seed: 0.4)

struct Cell: View {
    let skin: SkinEntry
    let open: Bool
    var seed = 7
    var side: CGFloat = 300
    /// Angle d'ouverture imposé (étapes de l'ouverture) ; nil : fermée ou grande ouverte.
    var angle: Double?

    var body: some View {
        ZStack {
            Canvas { context, size in
                let stepAngle = angle ?? (open ? 180 : 0)
                let look = SkinLook(skinId: skin.id)
                let length = angle != nil ? min(size.width * 0.4, size.height * 0.4)
                    : open ? min(size.width * 0.36, size.height * 0.3) : min(size.width * 0.42, size.height * 0.5)
                let layout = OysterArt.layout(size: size, look: look, length: length)
                let lagoon = LagoonArt(time: 0.9, focus: .init(x: layout.hx, y: layout.hy, size: layout.L))
                lagoon.draw(&context, size: size)
                OysterArt(
                    angle: stepAngle, pearl: rosePearl, glowColor: rosePearl.glow, sizeMm: 7.5,
                    cracked: false, trembles: false, revealed: stepAngle >= 140, time: 0.9,
                    look: look, shapeSeed: seed, length: length
                ).draw(&context, size: size)
                lagoon.drawOverlay(&context, size: size)
            }
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: side * 0.07, style: .continuous))
    }
}

struct Sheet: View {
    let skins: [SkinEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Pearl Inc. · Skins d’huître").font(.system(size: 40, weight: .bold))
                Text("Purement cosmétiques : la lumière qui filtre garde toujours la couleur de la perle.")
                    .font(.system(size: 20)).foregroundStyle(.white.opacity(0.7))
            }
            HStack(alignment: .top, spacing: 24) {
                ForEach(skins, id: \.id) { skin in
                    VStack(alignment: .leading, spacing: 14) {
                        Cell(skin: skin, open: false)
                        Cell(skin: skin, open: true)
                        Text(skin.name).font(.system(size: 26, weight: .bold))
                        Text(skin.howToGet).font(.system(size: 19, weight: .semibold)).foregroundStyle(Palette.gold)
                        Text(skin.description).font(.system(size: 17)).foregroundStyle(.white.opacity(0.75))
                            .frame(width: 300, alignment: .leading).fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(width: 300, alignment: .top)
                }
            }
            Text("En haut : fermée, posée sur le lagon. En bas : ouverte, avec une perle rosée.")
                .font(.system(size: 16)).foregroundStyle(.white.opacity(0.5))
            VStack(alignment: .leading, spacing: 12) {
                Text("Chaque huître est unique").font(.system(size: 26, weight: .bold))
                Text("À chaque huître, la coquille change un peu : bosses, dentelure, taches, algues et balanes ; pour le bénitier, le nombre de plis et la largeur.")
                    .font(.system(size: 17)).foregroundStyle(.white.opacity(0.75))
                HStack(spacing: 16) {
                    ForEach([3, 11, 25, 40], id: \.self) { seed in Cell(skin: skins[0], open: false, seed: seed, side: 141) }
                    ForEach([3, 11, 25, 40], id: \.self) { seed in Cell(skin: skins[1], open: false, seed: seed, side: 141) }
                }
            }
            VStack(alignment: .leading, spacing: 12) {
                Text("L’ouverture du bénitier").font(.system(size: 26, weight: .bold))
                Text("Vu de dessus comme l’huître, le couvercle se soulève de la même façon : la porcelaine, puis le manteau bleu-vert et la perle.")
                    .font(.system(size: 17)).foregroundStyle(.white.opacity(0.75))
                HStack(spacing: 16) {
                    ForEach([0.0, 30, 60, 100, 140, 180], id: \.self) { step in
                        VStack(spacing: 6) {
                            Cell(skin: skins[1], open: false, side: 192, angle: step)
                            Text("\(Int(step))°").font(.system(size: 15, weight: .semibold)).foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }
            }
            Text(" ")
                .font(.system(size: 16)).foregroundStyle(.white.opacity(0.5))
        }
        .padding(48)
        .foregroundStyle(.white)
        .background(Palette.night)
    }
}

let arguments = CommandLine.arguments
let catalogURL = URL(fileURLWithPath: arguments[1])
let outputURL = URL(fileURLWithPath: arguments[2])
let catalog = try JSONDecoder().decode(Catalog.self, from: Data(contentsOf: catalogURL))

MainActor.assumeIsolated {
    let renderer = ImageRenderer(content: Sheet(skins: catalog.economy.skins))
    renderer.scale = 2
    guard let image = renderer.cgImage else { fatalError("Rendu impossible") }
    let bitmap = NSBitmapImageRep(cgImage: image)
    do {
        try bitmap.representation(using: .png, properties: [:])!.write(to: outputURL)
    } catch {
        fatalError("Écriture impossible : \(error)")
    }
    print(outputURL.path)
}
