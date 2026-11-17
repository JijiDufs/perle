// Les scènes 3D de l'app (Oyster3DScene, Ecrin3DScene ; RealityKit) rendues sur le Mac, sans simulateur, vues de trois
// quarts comme au pouce. Chaque angle est rendu sur fond noir puis sur fond blanc : le script en tire la transparence
// (scripts/site/rendus-3d.sh).
// usage : huitre3d huitre <dossier> <perle> <forme> <reflet> <graine> <fêlée 0|1> <largeur pt> <hauteur pt> <angle>…
//         huitre3d ecrin  <dossier> <cuir #hex> <rareté> <type> <style> <largeur pt> <hauteur pt> <angle>…
//         → <dossier>/<angle>-noir.png et <angle>-blanc.png
import AppKit
import PearlCore
import RealityKit
import SwiftUI

let args = CommandLine.arguments
let mode = args[1], out = args[2]
let catalog = Catalog.shared

@MainActor func snapshot(_ view: ARView) async -> NSImage? {
    await withCheckedContinuation { done in view.snapshot(saveToHDR: false) { done.resume(returning: $0) } }
}

@MainActor func write(_ image: NSImage, _ path: String) {
    guard let tiff = image.tiffRepresentation, let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:])
    else { fatalError("image illisible : \(path)") }
    try! png.write(to: URL(fileURLWithPath: path))
}

/// Une fenêtre hors de l'écran (rien ne s'affiche chez l'utilisateur, mais RealityKit dessine), puis chaque angle sur noir et sur blanc.
@MainActor func render(size: CGSize, angles: [Double], install: (ARView) -> Void, update: @escaping (Double) -> Void) {
    let app = NSApplication.shared
    app.setActivationPolicy(.prohibited)
    let window = NSWindow(contentRect: NSRect(origin: CGPoint(x: -20000, y: -20000), size: size), styleMask: [.borderless],
                          backing: .buffered, defer: false)
    let view = ARView(frame: NSRect(origin: .zero, size: size))
    window.contentView = view
    window.orderFrontRegardless()
    install(view)
    Task { @MainActor in
        for angle in angles {
            for (name, color) in [("noir", NSColor.black), ("blanc", NSColor.white)] {
                view.environment.background = .color(color)
                update(angle)
                try? await Task.sleep(for: .milliseconds(500))
                guard let image = await snapshot(view) else { fatalError("pas d'image à \(angle)°") }
                write(image, "\(out)/\(String(format: "%05.1f", angle))-\(name).png")
            }
            print("\(angle)°")
        }
        exit(0)
    }
}

// Le code de main.swift tourne sur le fil principal : on le dit au compilateur.
MainActor.assumeIsolated {
    switch mode {
    case "huitre":
        let pearlId = args[3], shape = args[4], overtone = args[5], seed = Int(args[6])!, cracked = args[7] == "1"
        let size = CGSize(width: Double(args[8])!, height: Double(args[9])!)
        guard let type = catalog.pearls.first(where: { $0.id == pearlId }) else { fatalError("perle inconnue : \(pearlId)") }
        let look = PearlLook(id: type.id, color: type.color, glow: type.glow, shape: shape, overtone: overtone,
                             overtoneColor: catalog.overtones[overtone]?.color, mark: nil, seed: 0.5)
        let sizeMm = type.sizeMm.reduce(0, +) / Double(max(1, type.sizeMm.count))
        let pearlRadius = 0.05 + sizeMm * 0.0055  // OysterArt.pearlRadius, pour une valve de longueur 1
        let scene = Oyster3DScene()
        render(size: size, angles: args.dropFirst(10).map { Double($0)! }, install: scene.install) { angle in
            scene.update(angle: angle, pearl: look, findId: nil, cracked: cracked, pearlRadius: pearlRadius, glowHex: type.glow,
                         seed: seed, skin: "lagon", view: .thumb)
        }
    case "ecrin":
        let leather = args[3], rarityId = args[4]
        let size = CGSize(width: Double(args[7])!, height: Double(args[8])!)
        // Le bijou comme l'app le dessine (sa photo, couchée sur le plateau) ; le métal par défaut de sa rareté.
        let json = """
        {"rarityId":"\(rarityId)","type":"\(args[5])","style":"\(args[6])","metal":"\(catalog.jewelRarity(rarityId).metal)",
         "metalName":"","candy":false,"pearls":false,"carats":3,"value":1}
        """
        let jewel = try! JSONDecoder().decode(Jewel.self, from: Data(json.utf8))
        let look = JewelArt.Look(jewel, variant: nil, catalog: catalog)
        let scene = Ecrin3DScene()
        render(size: size, angles: args.dropFirst(9).map { Double($0)! }, install: scene.install) { angle in
            // La pénombre de l'intérieur, comme EcrinView au pouce : le bijou ne reste sombre qu'à peine entrouvert.
            let t = min(1, max(0, (angle - 2) / 43)), dim = 1 - t * t * (3 - 2 * t)
            scene.update(angle: angle, leatherHex: leather, dim: dim, jewelKey: "site", drawJewel: { c in EcrinArt.drawJewel(c, jewel, look) },
                         view: .thumb)
        }
    default:
        fatalError("mode inconnu : \(mode)")
    }
}
NSApplication.shared.run()
