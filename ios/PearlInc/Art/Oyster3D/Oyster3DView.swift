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
    private let root = AnchorEntity(world: .zero)
    private let lidPivot = Entity()
    private let pearl = ModelEntity()
    private var glow = PointLight()
    private var pearlKey = ""

    func install(in view: ARView) {
        let s = Self.shape
        let nacre = Self.material(texture: "oyster3d-nacre", roughness: 0.16, clearcoat: 1)
        let shell = Self.material(texture: "oyster3d-shell", roughness: 0.42, clearcoat: 0.5)

        // Valve du bas : nacre creusée, et l'extérieur brun qui déborde en volants tout autour.
        root.addChild(ModelEntity(mesh: ValveMesh.make(s, scale: 1, up: true) { rho, phi in
            -s.depth * (1 - rho * rho) + s.rimWave(rho, phi)
        }, materials: [nacre]))
        root.addChild(ModelEntity(mesh: ValveMesh.make(s, scale: 1.1, up: true) { rho, phi in
            -s.depth * 1.08 * (1 - rho * rho) - 0.012 + s.rimWave(rho, phi) * 1.4
        }, materials: [shell]))

        // Couvercle : dôme à gradins dehors, nacre dessous ; il tourne autour de la charnière (axe x).
        lidPivot.position = [0, 0.004, -s.halfLength]
        let lid = Entity()
        lid.position = [0, 0, s.halfLength]
        lid.addChild(ModelEntity(mesh: ValveMesh.make(s, scale: 1.1, up: true) { rho, phi in
            s.dome * pow(1 - rho * rho, 0.7) + 0.012 * sin(rho * 7 * .pi) * rho + s.rimWave(rho, phi) * 1.4
        }, materials: [shell]))
        lid.addChild(ModelEntity(mesh: ValveMesh.make(s, scale: 1.02, up: false) { rho, phi in
            s.dome * 0.7 * pow(1 - rho * rho, 0.7) - 0.006 + s.rimWave(rho, phi)
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

    private static func material(texture name: String, roughness: Float, clearcoat: Float) -> PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()
        if let texture = texture(name) { material.baseColor = .init(texture: .init(texture)) }
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

    /// Point du contour (x, z) pour rho 0…1 (centre → bord) et phi (π/2 : côté joueur, −π/2 : charnière).
    func footprint(_ rho: Float, _ phi: Float, scale: Float) -> SIMD2<Float> {
        let back = max(0, -sin(phi))
        let frill = 1 + 0.05 * sin(frills * phi + 0.7) * pow(rho, 3)
        let r = rho * frill * scale
        return [halfWidth * (1 - 0.35 * back) * r * cos(phi), halfLength * r * sin(phi)]
    }
}

/// Une valve en grille polaire (anneaux × rayons), normales calculées, texture projetée de dessus.
enum ValveMesh {
    static let rings = 30, spokes = 132

    static func make(_ s: ValveShape, scale: Float, up: Bool, height: (Float, Float) -> Float) -> MeshResource {
        func point(_ rho: Float, _ phi: Float) -> SIMD3<Float> {
            let p = s.footprint(rho, phi, scale: scale)
            return [p.x, height(rho, phi), p.y]
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
                uvs.append([0.5 + p.x / (2.2 * s.halfWidth * scale), 0.5 - p.z / (2.2 * s.halfLength * scale)])
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
