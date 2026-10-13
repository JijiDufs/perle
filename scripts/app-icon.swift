// Icône de Pearl Inc. : la perle qui luit dans le lagon, exactement le dessin SVG de la page pearl-inc.app.
// Lancé par scripts/make-app-icon.sh, ne pas compiler à la main.
// Produit : l'icône de l'app iOS (1024, carrée et opaque, comme l'exige Apple), l'icône à télécharger
// (carrée, et arrondie sur fond transparent), le favicon et l'icône d'écran d'accueil du site.
import AppKit
import SwiftUI

/// Le dessin, dans un repère de 120 × 120 (celui du SVG).
struct IconArt: View {
    /// Coins arrondis (squircle) comme sur l'écran d'accueil ; false : carré plein (iOS arrondit lui-même).
    var rounded: Bool

    var body: some View {
        Canvas { c, size in
            let k = size.width / 120
            c.scaleBy(x: k, y: k)
            if rounded { c.clip(to: squircle()) }
            // Le lagon, de la surface au sable.
            c.fill(Path(CGRect(x: 0, y: 0, width: 120, height: 120)), with: .linearGradient(
                Gradient(stops: [.init(color: hex(0x3cc4cc), location: 0), .init(color: hex(0x0f6f7d), location: 0.5),
                                 .init(color: hex(0x3f8f8a), location: 0.78), .init(color: hex(0xd8c49b), location: 1)]),
                startPoint: .zero, endPoint: CGPoint(x: 0, y: 120)))
            // Deux rayons de soleil.
            for (points, opacity) in [([(18.0, 0.0), (32, 0), (70, 120), (52, 120)], 1.0), ([(62.0, 0.0), (71, 0), (101, 120), (88, 120)], 0.7)] {
                var ray = Path()
                ray.addLines(points.map { CGPoint(x: $0.0, y: $0.1) })
                ray.closeSubpath()
                let box = ray.boundingRect
                var layer = c
                layer.opacity = opacity
                layer.fill(ray, with: .linearGradient(Gradient(colors: [.white.opacity(0.22), .white.opacity(0)]),
                                                      startPoint: CGPoint(x: box.minX, y: box.minY), endPoint: CGPoint(x: box.maxX, y: box.maxY)))
            }
            // Le halo, la perle, son reflet.
            c.fill(Path(ellipseIn: CGRect(x: 20, y: 24, width: 80, height: 80)), with: .radialGradient(
                Gradient(colors: [hex(0xfff6e0).opacity(0.95), hex(0xfff6e0).opacity(0)]),
                center: CGPoint(x: 60, y: 64), startRadius: 0, endRadius: 40))
            c.fill(Path(ellipseIn: CGRect(x: 39, y: 43, width: 42, height: 42)), with: .radialGradient(
                Gradient(stops: [.init(color: .white, location: 0), .init(color: hex(0xf3f0ea), location: 0.35), .init(color: hex(0x9c958d), location: 1)]),
                center: CGPoint(x: 39 + 0.36 * 42, y: 43 + 0.32 * 42), startRadius: 0, endRadius: 0.75 * 42))
            var shine = c
            shine.translateBy(x: 52.5, y: 55.5)
            shine.rotate(by: .degrees(-35))
            shine.fill(Path(ellipseIn: CGRect(x: -6.2, y: -3.6, width: 12.4, height: 7.2)), with: .color(.white.opacity(0.92)))
            // Le vernis du haut.
            c.fill(Path(CGRect(x: 0, y: 0, width: 120, height: 60)), with: .linearGradient(
                Gradient(stops: [.init(color: .white.opacity(0.28), location: 0), .init(color: .white.opacity(0), location: 0.45)]),
                startPoint: .zero, endPoint: CGPoint(x: 0, y: 60)))
            if rounded { c.stroke(squircle(), with: .color(.black.opacity(0.12)), lineWidth: 0.8) }
        }
    }

    private func hex(_ value: UInt32) -> Color {
        Color(.sRGB, red: Double((value >> 16) & 0xFF) / 255, green: Double((value >> 8) & 0xFF) / 255, blue: Double(value & 0xFF) / 255)
    }

    /// Coins continus façon iOS (superellipse), comme le contour du SVG.
    private func squircle() -> Path {
        var path = Path()
        let n = 5.0
        for i in 0...360 {
            let a = Double(i) / 360 * 2 * .pi
            let x = pow(abs(cos(a)), 2 / n) * (cos(a) < 0 ? -1 : 1)
            let y = pow(abs(sin(a)), 2 / n) * (sin(a) < 0 ? -1 : 1)
            let p = CGPoint(x: 60 + 60 * x, y: 60 + 60 * y)
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }
}

@MainActor
func write(_ view: some View, side: CGFloat, opaque: Bool, to path: String) {
    let renderer = ImageRenderer(content: view.frame(width: side, height: side))
    renderer.scale = 1
    guard var image = renderer.cgImage else { fatalError("Rendu impossible : \(path)") }
    if opaque {
        // L'App Store refuse une icône avec un canal alpha : on la recopie sur un fond plein.
        let context = CGContext(data: nil, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        image = context.makeImage()!
    }
    let url = URL(fileURLWithPath: path)
    try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try! NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!.write(to: url)
    print(path)
}

let root = CommandLine.arguments[1]
MainActor.assumeIsolated {
    write(IconArt(rounded: false), side: 1024, opaque: true, to: "\(root)/ios/PearlInc/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
    write(IconArt(rounded: false), side: 1024, opaque: true, to: "\(root)/docs/icone/pearl-inc-icone-1024.png")
    write(IconArt(rounded: true), side: 1024, opaque: false, to: "\(root)/docs/icone/pearl-inc-icone-1024-arrondie.png")
    write(IconArt(rounded: false), side: 180, opaque: true, to: "\(root)/site/apple-touch-icon.png")
    write(IconArt(rounded: true), side: 64, opaque: false, to: "\(root)/site/favicon-64.png")
    write(IconArt(rounded: true), side: 32, opaque: false, to: "\(root)/site/favicon-32.png")
}
