import SwiftUI
import RealityKit

/// Essai (pas de décision au §6, comme l'huître 3D) : l'écrin en vrai volume, au pouce, sur iPhone classique.
/// Étui plat de joaillier construit par code : base et couvercle en cuir (grain calculé), filet d'or sur la tranche,
/// fermoir, dorures sur le dessus, plateau de velours, satin et écusson « Pearl Inc. » sous le couvercle. Le bijou
/// (sa photo, ou son dessin) est rendu en image et couché sur le plateau. Il reçoit le même angle que le dessin 2D :
/// aucune règle de jeu ici. `-Ecrin2D` au lancement remet le dessin 2D ; le Duo garde le dessin vu de dessus.
struct Ecrin3DView: UIViewRepresentable {
    /// Le geste, en degrés (0…180) ; le couvercle s'ouvre de `lidRatio` fois cet angle, comme le dessin 2D.
    var angle: Double
    var leatherHex: String
    /// Pénombre de l'intérieur (0…1), pour le bijou (qui n'est pas éclairé par la scène).
    var dim: Double
    /// Change quand le bijou change (bijou suivant, variante révélée).
    var jewelKey: String
    /// Dessine le bijou dans une image de `jewelPixels` px de côté, pour `jewelUnits` de plateau.
    var drawJewel: (Canvas2D) -> Void
    /// Où la vue est posée dans l'écran (pour rendre les points du bijou et du couvercle dans le repère de l'écran).
    var origin: CGPoint
    let probe: Ecrin3DProbe

    static let jewelPixels = 512.0
    static let jewelUnits = 0.8
    static var isEnabled: Bool { !ProcessInfo.processInfo.arguments.contains("-Ecrin2D") }
    /// Côté de la vue carrée, en largeurs d'écrin (de quoi garder le couvercle ouvert dans le cadre).
    static let viewSpan = 3.2

    func makeCoordinator() -> Ecrin3DScene { Ecrin3DScene() }

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        view.environment.background = .color(.clear)
        view.backgroundColor = .clear
        view.isOpaque = false
        context.coordinator.install(in: view)
        return view
    }

    func updateUIView(_ view: ARView, context: Context) {
        let scene = context.coordinator
        scene.update(angle: angle, leatherHex: leatherHex, dim: dim, jewelKey: jewelKey, drawJewel: drawJewel)
        probe.anchors = scene.anchors(in: view, origin: origin)
    }
}

/// Les points de l'écrin 3D à l'écran, lus par le dessin 2D des effets (lueur, étincelles, gerbe d'étoiles).
final class Ecrin3DProbe {
    var anchors: EcrinArt.Anchors?
}

/// La scène : l'écrin fait 1 de large (x), `D` de profondeur (z, charnière à −D/2), posé sur y = 0.
@MainActor final class Ecrin3DScene {
    // Proportions de l'étui, comme le dessin 2D (EcrinArt).
    static let W: Float = 1, D: Float = 0.78, H: Float = 0.11, T: Float = 0.085, R: Float = 0.045
    static let lidRatio = 0.64
    /// Le bijou est couché au milieu du plateau, un peu vers l'avant.
    static let jewelAt: SIMD3<Float> = [0, H + 0.004, 0.03]

    private let root = AnchorEntity(world: .zero)
    private let lidPivot = Entity()
    private let jewel = ModelEntity()
    private var leatherEntities: [ModelEntity] = []
    private var leatherKey = ""
    private var jewelKey = ""
    private var jewelTexture: TextureResource?
    private var dimKey = -1.0

    func install(in view: ARView) {
        let W = Self.W, D = Self.D, H = Self.H, T = Self.T, R = Self.R
        let gold = Self.gold()

        // Base : cuir, filet d'or sur la tranche, plateau de velours en creux, fermoir à poussoir.
        let base = ModelEntity(mesh: .generateBox(width: W, height: H, depth: D, cornerRadius: R * 0.2), materials: [])
        base.position = [0, H / 2, 0]
        root.addChild(base)
        leatherEntities.append(base)
        let filet = ModelEntity(mesh: .generateBox(width: W + 0.004, height: 0.006, depth: D + 0.004, cornerRadius: 0.003), materials: [gold])
        filet.position = [0, H * 0.45, 0]
        root.addChild(filet)
        root.addChild(Self.plane(width: W - 0.1, depth: D - 0.1, y: H + 0.0006, texture: Self.velvet(), up: true))
        let clasp = ModelEntity(mesh: .generateBox(width: 0.09, height: 0.064, depth: 0.014, cornerRadius: 0.006), materials: [gold])
        clasp.position = [0, H * 0.82, D / 2 + 0.004]
        root.addChild(clasp)

        // Le bijou, couché sur le plateau (image sans éclairage : la photo garde ses couleurs).
        jewel.position = Self.jewelAt
        root.addChild(jewel)

        // Couvercle : il tourne autour de la charnière (axe x, à l'arrière, au ras du dessus de la base).
        // Charnière au ras de l'arête arrière de la base, couverte d'un dos de cuir : les deux moitiés restent attachées.
        lidPivot.position = [0, H, -D / 2]
        let spine = ModelEntity(mesh: .generateCylinder(height: W - 0.03, radius: 0.014), materials: [])
        spine.position = lidPivot.position
        spine.orientation = simd_quatf(angle: .pi / 2, axis: [0, 0, 1])
        root.addChild(spine)
        leatherEntities.append(spine)
        let lid = ModelEntity(mesh: .generateBox(width: W, height: T, depth: D, cornerRadius: R * 0.2), materials: [])
        lid.position = [0, T / 2, D / 2]
        lidPivot.addChild(lid)
        leatherEntities.append(lid)
        let lidFilet = ModelEntity(mesh: .generateBox(width: W + 0.004, height: 0.006, depth: D + 0.004, cornerRadius: 0.003), materials: [gold])
        lidFilet.position = [0, T * 0.5, D / 2]
        lidPivot.addChild(lidFilet)
        let tooling = Self.plane(width: W - 0.04, depth: D - 0.04, y: T + 0.0008, texture: Self.tooling(), up: true)
        tooling.position.z = D / 2
        lidPivot.addChild(tooling)
        let satin = Self.plane(width: W - 0.1, depth: D - 0.1, y: -0.0008, texture: Self.satin(), up: false)
        satin.position.z = D / 2
        lidPivot.addChild(satin)
        root.addChild(lidPivot)

        // Lumière du salon : d'en haut, un peu de face et de la gauche (comme le dessin 2D), une douce en face.
        let sun = DirectionalLight()
        sun.light = DirectionalLightComponent(color: UIColor(red: 1, green: 0.96, blue: 0.9, alpha: 1), intensity: 4200)
        sun.shadow = DirectionalLightComponent.Shadow(maximumDistance: 4, depthBias: 1.5)
        sun.look(at: .zero, from: [-0.8, 1.6, 1], relativeTo: nil)
        root.addChild(sun)
        let fill = DirectionalLight()
        fill.light = DirectionalLightComponent(color: UIColor(red: 1, green: 0.85, blue: 0.75, alpha: 1), intensity: 1300)
        fill.look(at: .zero, from: [1.4, 0.8, 1.6], relativeTo: nil)
        root.addChild(fill)

        // Caméra de trois quarts (46° au-dessus de l'horizon), comme le dessin 2D ; l'écrin prend 1 / viewSpan de la vue.
        let camera = PerspectiveCamera()
        let distance: Float = 5 // plus loin que le dessin 2D (3,4) : moins de déformation quand le couvercle monte
        camera.camera.fieldOfViewInDegrees = Float(2 * atan(Ecrin3DView.viewSpan / 2 / Double(distance)) * 180 / .pi)
        let target: SIMD3<Float> = [0, H * 0.5, 0]
        let elevation: Float = 46 * .pi / 180
        camera.look(at: target, from: target + [0, distance * sin(elevation), distance * cos(elevation)], relativeTo: nil)
        root.addChild(camera)

        view.scene.addAnchor(root)
    }

    func update(angle: Double, leatherHex: String, dim: Double, jewelKey key: String, drawJewel: @escaping (Canvas2D) -> Void) {
        let alpha = Float(min(180, max(0, angle)) * Self.lidRatio * .pi / 180)
        lidPivot.orientation = simd_quatf(angle: -alpha, axis: [1, 0, 0])

        if leatherHex != leatherKey {
            leatherKey = leatherHex
            let leather = Self.leather(leatherHex)
            for entity in leatherEntities { entity.model?.materials = [leather] }
        }
        if key != jewelKey {
            jewelKey = key
            jewelTexture = Self.jewelTexture(drawJewel)
            dimKey = -1
        }
        // Le bijou suit la pénombre de l'intérieur (par pas, pour ne pas refaire le matériau à chaque image).
        let shade = (dim * 20).rounded() / 20
        if shade != dimKey, let jewelTexture {
            dimKey = shade
            var material = UnlitMaterial()
            let k = 1 - shade * 0.75
            material.color = .init(tint: UIColor(white: k, alpha: 1), texture: .init(jewelTexture))
            material.blending = .transparent(opacity: 1.0)
            material.opacityThreshold = 0.02
            let size = Float(Ecrin3DView.jewelUnits)
            jewel.model = ModelComponent(mesh: .generatePlane(width: size, depth: size), materials: [material])
        }
    }

    /// Le bijou, le bord avant du couvercle et l'échelle (pt par unité), dans le repère de l'écran.
    func anchors(in view: ARView, origin: CGPoint) -> EcrinArt.Anchors? {
        guard view.bounds.width > 0,
              let jewelPoint = view.project(Self.jewelAt),
              let side = view.project(Self.jewelAt + [0.1, 0, 0]) else { return nil }
        let edge = lidPivot.convert(position: [0, 0, Self.D], to: nil)
        guard let edgePoint = view.project(edge) else { return nil }
        let unit = Double(hypot(side.x - jewelPoint.x, side.y - jewelPoint.y)) * 10
        return EcrinArt.Anchors(jewel: (origin.x + jewelPoint.x, origin.y + jewelPoint.y), scale: unit,
                                lidEdge: (origin.x + edgePoint.x, origin.y + edgePoint.y))
    }

    // MARK: - Matériaux et textures (dessinés par code)

    /// Cuir lisse : la couleur de l'écrin sur un grain fin calculé, un peu satiné.
    private static func leather(_ hex: String) -> PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: UIColor(Color(hex: hex)), texture: grain.map { .init($0) })
        material.roughness = 0.48
        material.clearcoat = 0.35
        material.clearcoatRoughness = 0.35
        return material
    }

    private static func gold() -> PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: UIColor(red: 0.86, green: 0.68, blue: 0.33, alpha: 1))
        material.metallic = 1.0
        material.roughness = 0.22
        return material
    }

    /// Grain du cuir : un bruit doux, presque blanc (la teinte vient du cuir).
    private static let grain: TextureResource? = {
        let size = 256
        var pixels = [UInt8](repeating: 255, count: size * size * 4)
        var seed: UInt32 = 12345
        for i in 0..<(size * size) {
            seed = seed &* 1_664_525 &+ 1_013_904_223
            let v = UInt8(222 + Int(seed >> 24) % 34)
            pixels[i * 4] = v; pixels[i * 4 + 1] = v; pixels[i * 4 + 2] = v
        }
        guard let provider = CGDataProvider(data: Data(pixels) as CFData),
              let image = CGImage(width: size, height: size, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: size * 4,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                                  provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
        else { return nil }
        return try? TextureResource.generate(from: image, options: .init(semantic: .color))
    }()

    /// Un plan à plat (vers le haut, ou vers le bas sous le couvercle) habillé d'une image sans éclairage propre.
    private static func plane(width: Float, depth: Float, y: Float, texture: TextureResource?, up: Bool) -> ModelEntity {
        var material = PhysicallyBasedMaterial()
        if let texture { material.baseColor = .init(texture: .init(texture)) }
        material.roughness = 0.7
        material.blending = .transparent(opacity: 1.0)
        material.opacityThreshold = 0.02
        let entity = ModelEntity(mesh: .generatePlane(width: width, depth: depth), materials: [material])
        entity.position = [0, y, 0]
        // Sous le couvercle : retourné autour de x, pour que l'écusson se lise à l'endroit quand le couvercle est ouvert.
        if !up { entity.orientation = simd_quatf(angle: .pi, axis: [1, 0, 0]) }
        return entity
    }

    /// Dessine une texture avec Canvas2D (comme le reste du jeu), en `w` × `h` px.
    private static func texture(_ w: Double, _ h: Double, opaque: Bool = false, _ draw: @escaping (Canvas2D) -> Void) -> TextureResource? {
        let renderer = ImageRenderer(content: Canvas { context, _ in draw(Canvas2D(context)) }.frame(width: w, height: h))
        renderer.scale = 1
        renderer.isOpaque = opaque
        guard let image = renderer.cgImage.flatMap({ opaque ? $0 : straightAlpha($0) }) else { return nil }
        return try? TextureResource.generate(from: image, options: .init(semantic: .color))
    }

    /// RealityKit lit les couleurs comme non prémultipliées : sans cette conversion, les pixels mi-transparents
    /// (métal fin, éclats des diamants) sont assombris deux fois, et les diamants et diadèmes paraissent sombres.
    static func straightAlpha(_ image: CGImage) -> CGImage? {
        let w = image.width, h = image.height
        var pixels = [UInt8](repeating: 0, count: w * h * 4)
        let space = CGColorSpace(name: CGColorSpace.sRGB)!
        guard let context = CGContext(data: &pixels, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: space,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        context.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        for i in stride(from: 0, to: pixels.count, by: 4) where pixels[i + 3] > 0 && pixels[i + 3] < 255 {
            let a = Int(pixels[i + 3])
            for k in 0..<3 { pixels[i + k] = UInt8(min(255, Int(pixels[i + k]) * 255 / a)) }
        }
        guard let provider = CGDataProvider(data: Data(pixels) as CFData) else { return nil }
        return CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: w * 4, space: space,
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue), provider: provider,
                       decode: nil, shouldInterpolate: true, intent: .defaultIntent)
    }

    private static func jewelTexture(_ drawJewel: @escaping (Canvas2D) -> Void) -> TextureResource? {
        let px = Ecrin3DView.jewelPixels
        return texture(px, px) { c in
            c.translate(px / 2, px / 2)
            c.scale(px / Ecrin3DView.jewelUnits, px / Ecrin3DView.jewelUnits)
            drawJewel(c)
        }
    }

    /// Plateau de velours sombre, plus clair au milieu.
    private static func velvet() -> TextureResource? {
        texture(512, 400, opaque: true) { c in
            let g = c.createRadialGradient(256, 180, 0, 256, 200, 300)
            g.addColorStop(0, "#2b2f45")
            g.addColorStop(1, "#0d0f1a")
            c.fillStyle = g
            c.fillRect(0, 0, 512, 400)
        }
    }

    /// Dorures du dessus : double filet, fleurons d'angle, cartouche à la perle (fond transparent).
    private static func tooling() -> TextureResource? {
        texture(1000, 760) { c in
            c.strokeStyle = JewelArt.goldGradient(c, 0, 0, 1000, 760)
            c.lineWidth = 5
            c.beginPath(); c.rect(40, 40, 920, 680); c.stroke()
            c.lineWidth = 2.5
            c.beginPath(); c.rect(58, 58, 884, 644); c.stroke()
            c.fillStyle = JewelArt.goldGradient(c, 0, 0, 1000, 760)
            for (x, y) in [(58.0, 58.0), (942, 58), (58, 702), (942, 702)] {
                c.beginPath()
                c.arc(x, y, 11, 0, .pi * 2)
                c.fill()
            }
            c.beginPath()
            c.ellipse(500, 380, 120, 62, 0, 0, .pi * 2)
            c.lineWidth = 3
            c.stroke()
            c.beginPath()
            c.arc(500, 360, 16, 0, .pi * 2)
            c.fill()
            c.setFont(size: 26, weight: 600, serif: false)
            c.fillStyle = "#d9b25a"
            c.fillText("P E A R L   I N C .", 500, 408)
        }
    }

    /// Satin ivoire capitonné sous le couvercle, avec l'écusson de la Maison.
    private static func satin() -> TextureResource? {
        texture(900, 680, opaque: true) { c in
            let g = c.createLinearGradient(0, 0, 900, 680)
            g.addColorStop(0, "#f6ecda")
            g.addColorStop(0.5, "#e8d8bd")
            g.addColorStop(1, "#d9c6a6")
            c.fillStyle = g
            c.fillRect(0, 0, 900, 680)
            c.strokeStyle = "rgba(120, 90, 50, 0.16)"
            c.lineWidth = 2
            for k in stride(from: -680.0, through: 900, by: 70) {
                c.beginPath(); c.moveTo(k, 0); c.lineTo(k + 680, 680); c.stroke()
                c.beginPath(); c.moveTo(k + 680, 0); c.lineTo(k, 680); c.stroke()
            }
            c.fillStyle = "rgba(250, 244, 230, 0.97)"
            c.beginPath()
            c.ellipse(450, 340, 170, 76, 0, 0, .pi * 2)
            c.fill()
            c.strokeStyle = JewelArt.goldGradient(c, 280, 0, 620, 0)
            c.lineWidth = 5
            c.stroke()
            c.fillStyle = "#b8862b"
            c.setFont(size: 22, weight: 600, serif: false)
            c.fillText("P E A R L   I N C .", 450, 318)
            c.setFont(size: 36, weight: 400, serif: true)
            c.fillText("Perles fines", 450, 360)
        }
    }
}
