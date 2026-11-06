import SwiftUI
import RealityKit

/// Essai (branche `jules/essai-huitre-3d`, pas de décision au §6) : l'huître en vrai volume, au pouce.
/// Les deux valves sont construites par code (contour en goutte, volants, creux, dôme à gradins) et
/// habillées des textures tirées des images générées (Higgsfield, dossier Art/Oyster3D). Elle reçoit
/// le même angle que le dessin 2D : aucune règle de jeu ici. `-Oyster2D` au lancement remet le dessin 2D.
struct Oyster3DView: UIViewRepresentable {
    /// Ouverture du couvercle, en degrés (0 : fermée, 180 : à plat).
    var angle: Double
    /// Couleur de la perle ; nil : rien dans la valve (huître vide, trouvaille, perle volée).
    var pearlHex: String?
    /// Rayon de la perle, pour une valve de longueur 1.
    var pearlRadius: Double
    /// Lumière qui filtre par l'entrebâillement ; nil : noire.
    var glowHex: String?

    static var isEnabled: Bool { !ProcessInfo.processInfo.arguments.contains("-Oyster2D") }

    func makeCoordinator() -> Oyster3DScene { Oyster3DScene() }

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        view.environment.background = .color(.clear)
        view.backgroundColor = .clear
        view.isOpaque = false
        context.coordinator.install(in: view)
        return view
    }

    func updateUIView(_ view: ARView, context: Context) {
        context.coordinator.update(angle: angle, pearlHex: pearlHex, pearlRadius: pearlRadius, glowHex: glowHex)
    }
}

/// La scène : la valve du bas posée à plat, le couvercle sur sa charnière, la perle, les lumières.
/// Une valve mesure 1 de long (z de −0,5 à la charnière à +0,5 côté joueur) ; la vue SwiftUI fait 3 × L.
@MainActor final class Oyster3DScene {
    private static let shape = ValveShape()
    /// Six couches sur le couvercle, trois sur le bord de la valve du bas.
    private static let lidLayers = Lamellae(edges: [0.93, 0.8, 0.67, 0.54, 0.41, 0.28], step: 0.022, riser: 0.03)
    private static let skirtLayers = Lamellae(edges: [0.97, 0.935, 0.9], step: 0.01, riser: 0.012, wave: 0.02)
    private let root = AnchorEntity(world: .zero)
    private let lidPivot = Entity()
    private let pearl = ModelEntity()
    private var glow = PointLight()
    private var pearlKey = ""

    func install(in view: ARView) {
        let s = Self.shape
        let nacre = Self.material(Self.texture("oyster3d-nacre"), roughness: 0.16, clearcoat: 1)
        let shell = Self.material(ShellTexture.make(layers: Self.lidLayers.edges.count + 1), roughness: 0.62, clearcoat: 0.25)

        // Valve du bas : nacre creusée, et l'extérieur brun qui déborde tout autour en trois lamelles.
        root.addChild(ModelEntity(mesh: ValveMesh.make(s, scale: 1, up: true) { rho, phi in
            (-s.depth * (1 - rho * rho) + s.rimWave(rho, phi), nil)
        }, materials: [nacre]))
        let skirt = Self.skirtLayers
        root.addChild(ModelEntity(mesh: ValveMesh.make(s, scale: 1.1, up: true, rings: 90) { rho, phi in
            let layers = skirt.sample(rho, phi)
            return (-s.depth * 1.08 * (1 - rho * rho) - 0.02 + layers.height + s.rimWave(rho, phi) * 1.2, layers.uv)
        }, materials: [shell]))

        // Couvercle : lamelles empilées autour d'un sommet près de la charnière (comme une vraie huître),
        // nacre dessous ; il tourne autour de la charnière (axe x).
        lidPivot.position = [0, 0.004, -s.halfLength]
        let lid = Entity()
        lid.position = [0, 0, s.halfLength]
        let layers = Self.lidLayers
        lid.addChild(ModelEntity(mesh: ValveMesh.make(s, scale: 1.1, up: true, rings: 150, apexZ: -0.6) { rho, phi in
            let sample = layers.sample(rho, phi)
            return (0.05 * pow(1 - rho * rho, 0.6) + sample.height + s.rimWave(rho, phi) * 1.2, sample.uv)
        }, materials: [shell]))
        lid.addChild(ModelEntity(mesh: ValveMesh.make(s, scale: 1.02, up: false) { rho, phi in
            (0.05 * pow(1 - rho * rho, 0.7) - 0.008 + s.rimWave(rho, phi), nil)
        }, materials: [nacre]))
        lidPivot.addChild(lid)
        root.addChild(lidPivot)

        root.addChild(pearl)

        // Lumière : une principale qui projette l'ombre du couvercle, une douce en face, et la lueur dans la valve.
        let sun = DirectionalLight()
        sun.light = DirectionalLightComponent(color: .white, intensity: 4200)
        sun.shadow = DirectionalLightComponent.Shadow(maximumDistance: 4, depthBias: 1.5)
        sun.look(at: .zero, from: [-1.2, 3.5, 1.6], relativeTo: nil)
        root.addChild(sun)
        let fill = DirectionalLight()
        fill.light = DirectionalLightComponent(color: UIColor(red: 0.75, green: 0.9, blue: 1, alpha: 1), intensity: 1400)
        fill.look(at: .zero, from: [1.5, 1.2, 2], relativeTo: nil)
        root.addChild(fill)
        glow.light.attenuationRadius = 0.9
        glow.position = [0, -s.depth * 0.3, 0.05]
        root.addChild(glow)

        // Caméra de trois quarts, au-dessus et devant : la charnière en haut de l'écran, comme au pouce.
        let camera = PerspectiveCamera()
        camera.camera.fieldOfViewInDegrees = 30
        let target: SIMD3<Float> = [0, 0, -0.2]
        let elevation: Float = 58 * .pi / 180, distance: Float = 5.6
        camera.look(at: target, from: target + [0, distance * sin(elevation), distance * cos(elevation)], relativeTo: nil)
        root.addChild(camera)

        view.scene.addAnchor(root)
    }

    func update(angle: Double, pearlHex: String?, pearlRadius: Double, glowHex: String?) {
        let theta = Float(min(max(angle, 0), 180) * .pi / 180)
        lidPivot.orientation = simd_quatf(angle: -theta, axis: [1, 0, 0])

        let key = "\(pearlHex ?? "-")/\(pearlRadius)"
        if key != pearlKey {
            pearlKey = key
            if let pearlHex {
                let r = Float(pearlRadius)
                var material = PhysicallyBasedMaterial()
                // Nacre grise teintée de la couleur de la perle : des reflets qui tournent, pas une bille unie.
                material.baseColor = .init(tint: UIColor(Color(hex: pearlHex)), texture: Self.texture("oyster3d-pearl").map { .init($0) })
                material.roughness = 0.2
                material.clearcoat = 1.0
                material.clearcoatRoughness = 0.03
                pearl.model = ModelComponent(mesh: .generateSphere(radius: r), materials: [material])
                pearl.position = [0, -Self.shape.depth + r * 0.9, 0.06]
                pearl.isEnabled = true
            } else {
                pearl.isEnabled = false
            }
        }

        // La lueur monte avec l'entrebâillement, puis se fond dans la lumière du jour.
        let open = Float(min(1, angle / 35) * max(0.35, 1 - max(0, angle - 70) / 110))
        glow.light.color = glowHex.map { UIColor(Color(hex: $0)) } ?? .black
        glow.light.intensity = glowHex == nil ? 0 : 3000 * open
    }

    private static func texture(_ name: String) -> TextureResource? {
        Bundle.main.url(forResource: name, withExtension: "jpg").flatMap { try? TextureResource.load(contentsOf: $0) }
    }

    private static func material(_ texture: TextureResource?, roughness: Float, clearcoat: Float) -> PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()
        if let texture { material.baseColor = .init(texture: .init(texture)) }
        material.roughness = .init(floatLiteral: roughness)
        material.clearcoat = .init(floatLiteral: clearcoat)
        material.clearcoatRoughness = 0.1
        material.faceCulling = .none
        return material
    }
}

/// Forme commune aux deux valves : contour en goutte (plus étroit vers la charnière), volants du bord.
struct ValveShape {
    var halfWidth: Float = 0.4
    var halfLength: Float = 0.5
    var frills: Float = 13
    var depth: Float = 0.13
    var dome: Float = 0.15

    /// Le bord ondule aussi en hauteur.
    func rimWave(_ rho: Float, _ phi: Float) -> Float { 0.02 * sin(frills * phi + 0.7) * pow(rho, 6) }

    /// Point (x, z) pour rho 0…1 (du sommet au bord) et phi (π/2 : côté joueur, −π/2 : charnière).
    /// Le sommet est au centre, ou décalé vers la charnière (apexZ < 0) pour les lamelles du couvercle.
    func footprint(_ rho: Float, _ phi: Float, scale: Float, apexZ: Float = 0) -> SIMD2<Float> {
        let back = max(0, -sin(phi))
        let frill = 1 + 0.05 * sin(frills * phi + 0.7)
        let edge = SIMD2<Float>(halfWidth * (1 - 0.35 * back) * frill * scale * cos(phi), halfLength * frill * scale * sin(phi))
        let apex = SIMD2<Float>(0, apexZ * halfLength)
        return apex + (edge - apex) * rho
    }
}

/// Une valve en grille polaire (anneaux × rayons), normales calculées, texture projetée de dessus.
enum ValveMesh {
    static let spokes = 180

    /// `surface` donne la hauteur et, pour la coquille, ses coordonnées de texture (nil : projetée de dessus).
    static func make(_ s: ValveShape, scale: Float, up: Bool, rings: Int = 30, apexZ: Float = 0,
                     surface: (Float, Float) -> (Float, SIMD2<Float>?)) -> MeshResource {
        func point(_ rho: Float, _ phi: Float) -> SIMD3<Float> {
            let p = s.footprint(rho, phi, scale: scale, apexZ: apexZ)
            return [p.x, surface(rho, phi).0, p.y]
        }
        var positions: [SIMD3<Float>] = [], normals: [SIMD3<Float>] = [], uvs: [SIMD2<Float>] = []
        let e: Float = 0.002
        for i in 0..<rings {
            let rho = max(0.001, Float(i) / Float(rings - 1))
            for j in 0..<spokes {
                let phi = Float(j) / Float(spokes) * 2 * .pi
                let p = point(rho, phi)
                var n = simd_normalize(simd_cross(point(rho, phi + e) - point(rho, phi - e), point(min(1, rho + e), phi) - point(max(0, rho - e), phi)))
                if (n.y < 0) == up { n = -n }
                positions.append(p)
                normals.append(n.x.isNaN ? (up ? [0, 1, 0] : [0, -1, 0]) : n)
                // L'image a la charnière en haut (v = 1) et le bord côté joueur en bas.
                uvs.append(surface(rho, phi).1 ?? [0.5 + p.x / (2.2 * s.halfWidth * scale), 0.5 - p.z / (2.2 * s.halfLength * scale)])
            }
        }
        var indices: [UInt32] = []
        for i in 0..<(rings - 1) {
            for j in 0..<spokes {
                let a = UInt32(i * spokes + j), b = UInt32(i * spokes + (j + 1) % spokes)
                let c = a + UInt32(spokes), d = b + UInt32(spokes)
                indices += up ? [a, b, c, b, d, c] : [a, c, b, b, c, d]
            }
        }
        var descriptor = MeshDescriptor(name: "valve")
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.normals = MeshBuffers.Normals(normals)
        descriptor.textureCoordinates = MeshBuffers.TextureCoordinates(uvs)
        descriptor.primitives = .triangles(indices)
        return try! MeshResource.generate(from: [descriptor])
    }
}

/// Les lamelles d'une coquille d'huître : des couches empilées, chacune avec son bord ondulé en relief.
/// C'est la forme qui fait les reliefs (la lumière les suit), la texture ne fait que les colorer.
struct Lamellae {
    /// Où chaque couche s'arrête (rho), du bord vers le sommet.
    var edges: [Float]
    /// Hauteur d'une marche.
    var step: Float
    /// Largeur de la tombée du bord.
    var riser: Float
    /// Ondulation du bord de chaque couche.
    var wave: Float = 0.045

    private func edge(_ k: Int, _ phi: Float) -> Float {
        // Moins de volants sur les petites couches du sommet ; fréquences entières (pas de couture à phi = 0).
        edges[k] * (1 + wave * sin(Float(max(4, 12 - k * 2 + k / 2)) * phi + Float(k) * 2.1))
    }

    /// Hauteur ajoutée, et coordonnées de texture : u avance de couche en couche, du sommet vers le bord
    /// (continu d'une couche à l'autre : la couleur change net au bord, pas en dents de peigne).
    func sample(_ rho: Float, _ phi: Float) -> (height: Float, uv: SIMD2<Float>) {
        var height: Float = 0, layer = 0
        for k in edges.indices {
            let b = edge(k, phi)
            // Chaque couche monte d'une marche ; son bord roule un peu avant de tomber, et ondule en hauteur.
            let lip = exp(-pow((rho - (b - riser * 1.4)) / (riser * 0.8), 2)) * (0.45 + 0.3 * sin((14 + Float(k)) * phi + Float(k)))
            height += step * (1 - smooth(b - riser, b, rho) + lip)
            if rho < b { layer = k + 1 }
        }
        let outer = layer == 0 ? 1 : edge(layer - 1, phi)
        let inner = layer < edges.count ? edge(layer, phi) : 0
        let u = min(1, max(0, (rho - inner) / max(0.001, outer - inner)))
        return (height, [(Float(edges.count - layer) + u) / Float(edges.count + 1), 0.5])
    }

    private func smooth(_ a: Float, _ b: Float, _ x: Float) -> Float {
        let t = min(1, max(0, (x - a) / (b - a)))
        return t * t * (3 - 2 * t)
    }
}

/// La couleur des lamelles, calculée (pas d'image) : pied sombre sous la couche du dessus, brun strié,
/// bord clair ; une couche sur deux un peu plus grise, comme sur une vraie huître.
enum ShellTexture {
    static func make(layers: Int) -> TextureResource? {
        let segment = 64, width = layers * segment, height = 4
        var pixels = [UInt8](repeating: 255, count: width * height * 4)
        func mix(_ a: SIMD3<Float>, _ b: SIMD3<Float>, _ t: Float) -> SIMD3<Float> { a + (b - a) * min(1, max(0, t)) }
        let deep = SIMD3<Float>(0.13, 0.09, 0.08), mid = SIMD3<Float>(0.33, 0.25, 0.21)
        let warm = SIMD3<Float>(0.47, 0.37, 0.3), lip = SIMD3<Float>(0.76, 0.7, 0.62), grey = SIMD3<Float>(0.4, 0.38, 0.41)
        for y in 0..<height {
            for x in 0..<width {
                // Une couche par segment ; u : 0 au pied (sous la couche du dessus), 1 au bord.
                let layer = x / segment
                let u = (Float(x % segment) + 0.5) / Float(segment)
                var c = u < 0.18 ? mix(deep, mid, u / 0.18) : u < 0.86 ? mix(mid, warm, (u - 0.18) / 0.68) : mix(warm, lip, (u - 0.86) / 0.14)
                c *= 1 + 0.05 * sin(u * 25 + Float(layer) * 1.3) // stries de croissance
                if layer % 2 == 1 { c = mix(c, grey * (0.6 + u * 0.6), 0.35) }
                let noise = Float((x * 73 + y * 151) % 17) / 17 * 0.05 - 0.025
                let i = (y * width + x) * 4
                pixels[i] = UInt8(min(255, max(0, (c.x + noise) * 255)))
                pixels[i + 1] = UInt8(min(255, max(0, (c.y + noise) * 255)))
                pixels[i + 2] = UInt8(min(255, max(0, (c.z + noise) * 255)))
            }
        }
        guard let provider = CGDataProvider(data: Data(pixels) as CFData),
              let image = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                                  provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
        else { return nil }
        return try? TextureResource.generate(from: image, options: .init(semantic: .color))
    }
}
