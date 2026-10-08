// Planche des skins d'huître, dessinée avec le code de l'app (ios/PearlInc/Art) sur le Mac.
// Lancé par scripts/make-skin-sheet.sh, ne pas compiler à la main.
import AppKit
import SwiftUI

struct SkinEntry: Decodable {
    let id: String
    let name: String
    let description: String
    let style: String
    let dustPrice: Int?
    let productId: String?
    let grant: String?
    let shellLight: String
    let shellDark: String
    let nacreLight: String
    let nacreShade: String
    let rim: String?

    var look: SkinLook {
        SkinLook(style: style, shellLight: shellLight, shellDark: shellDark, nacreLight: nacreLight, nacreShade: nacreShade, rim: rim)
    }

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

struct Cell: View {
    let skin: SkinEntry
    let open: Bool

    var body: some View {
        ZStack {
            LinearGradient(colors: [Palette.lagoonTop, Palette.lagoonMid, Palette.sand], startPoint: .top, endPoint: .bottom)
            Canvas { context, size in
                // Ouverte, le couvercle se rabat au-dessus de la charnière : on recule un peu pour le voir.
                var context = context
                if open {
                    context.translateBy(x: size.width / 2, y: size.height / 2 + 72)
                    context.scaleBy(x: 0.72, y: 0.72)
                    context.translateBy(x: -size.width / 2, y: -size.height / 2)
                }
                OysterArt(
                    angle: open ? 180 : 0,
                    pearlColor: open ? Color(hex: "#F2C4CC") : nil,
                    glowColor: open ? Color(hex: "#ffb3c6") : nil,
                    pearlRadiusRatio: 0.025 + 10 * 0.0028,
                    cracked: false, trembles: false, revealed: open, time: 0.9,
                    look: skin.look, maxWidth: 220
                ).draw(&context, size: size)
            }
        }
        .frame(width: 300, height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
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
