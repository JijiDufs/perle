import SwiftUI
import RealityKit
import CoreImage.CIFilterBuiltins

/// Essai (branche `jules/essai-huitre-3d`, pas de décision au §6) : l'huître en vrai volume, au pouce.
/// Les deux valves sont construites par code, en éventail depuis la charnière comme le dessin 2D
/// (`ShellArt.outline`) : lamelles, volants, creux. Elles sont habillées d'une couleur calculée et de la
/// nacre tirée des images générées (Higgsfield, dossier Art/Oyster3D). `seed` (numéro de série) donne à
/// chaque huître son contour, ses volants et sa teinte. Elle reçoit le même angle que le dessin 2D :
/// aucune règle de jeu ici. `-Oyster2D` au lancement remet le dessin 2D.
struct Oyster3DView: UIViewRepresentable {
    /// Ouverture du couvercle, en degrés (0 : fermée, 180 : à plat).
    var angle: Double
    /// La perle, telle que la carte la montre (forme, reflet, marque) ; nil : rien dans la valve (huître vide, trouvaille, perle volée).
    var pearl: PearlLook?
    var cracked: Bool
    /// Rayon de la perle, pour une valve de longueur 1.
    var pearlRadius: Double
    /// Lumière qui filtre par l'entrebâillement ; nil : noire.
    var glowHex: String?
    /// Graine de la forme (numéro de série de l'huître), la même que le dessin 2D.
    var seed: Int

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
        context.coordinator.update(angle: angle, pearl: pearl, cracked: cracked, pearlRadius: pearlRadius, glowHex: glowHex, seed: seed)
    }
}

/// La scène : la valve du bas posée à plat, le couvercle sur sa charnière, la perle, les lumières.
/// La charnière est à z = −0,5 ; une valve mesure 1 de la charnière au bord côté joueur ; la vue SwiftUI fait 3 L × 4,4 L.
@MainActor final class Oyster3DScene {
    static let cameraElevation: Float = 58
    /// Nacre blanchie (l'image générée est trop rose, retour de Jules), les reflets restent par le vernis.
    private static let nacre = material(texture("oyster3d-nacre", saturation: 0.35, brightness: 0.08), roughness: 0.16, clearcoat: 1)
    private let root = AnchorEntity(world: .zero)
    private let lidPivot = Entity()
    private let lid = Entity()
    private let bottom = Entity()
    private let pearl = ModelEntity()
    private var glow = PointLight()
    private var pearlKey = ""
    private var seed = Int.min

    func install(in view: ARView) {
        lidPivot.position = [0, 0.004, ValveShape.hinge]
        lid.position = [0, 0, -ValveShape.hinge]
        lidPivot.addChild(lid)
        root.addChild(lidPivot)
        root.addChild(bottom)
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
        glow.position = [0, -ValveShape.depth * 0.3, 0.05]
        root.addChild(glow)

        // Caméra de trois quarts, au-dessus et devant : la charnière en haut de l'écran, comme au pouce.
        let camera = PerspectiveCamera()
        camera.camera.fieldOfViewInDegrees = 30
        let target: SIMD3<Float> = [0, 0.05, -0.47]
        let elevation: Float = Self.cameraElevation * .pi / 180, distance: Float = 8.6
        camera.look(at: target, from: target + [0, distance * sin(elevation), distance * cos(elevation)], relativeTo: nil)
        root.addChild(camera)

        view.scene.addAnchor(root)
    }

    /// Les deux valves, tirées de la graine : contour, volants, couleurs. Reconstruites à chaque huître.
    private func build(seed: Int) {
        let style = OysterStyle.current
        let s = ValveShape(phases: ShellArt.phases(seed: seed), frills: style.frills)
        let shell = Self.material(ShellTexture.make(layers: style.edges.count + 1, seed: seed, style: style), roughness: style.roughness, clearcoat: style.clearcoat)
        // Les couches du couvercle, trois sur le bord de la valve du bas.
        let lidLayers = Lamellae(edges: style.edges, step: 0.022, riser: 0.03, wave: style.wave, waveFrequency: style.waveFrequency, phase: Float(s.phases.2))
        let skirtLayers = Lamellae(edges: [0.97, 0.935, 0.9], step: 0.01, riser: 0.012, wave: 0.02, waveFrequency: style.waveFrequency, phase: Float(s.phases.1))
        bottom.children.removeAll()
        lid.children.removeAll()

        // Valve du bas : nacre creusée, et l'extérieur brun qui déborde tout autour en trois lamelles.
        bottom.addChild(ModelEntity(mesh: ValveMesh.make(s, scale: 1, up: true) { rho, phi in
            (-s.bowl(rho) + s.rimWave(rho, phi), nil)
        }, materials: [Self.nacre]))
        bottom.addChild(ModelEntity(mesh: ValveMesh.make(s, scale: 1.06, up: true, rings: 90) { rho, phi in
            let layers = skirtLayers.sample(rho, phi)
            // 0,05 sous la nacre : ses trois couches (0,03) ne doivent pas la percer là où le creux est nul (charnière).
            return (-s.bowl(rho) * 1.08 - 0.05 + layers.height + s.rimWave(rho, phi) * 1.2, layers.uv)
        }, materials: [shell]))

        // Couvercle : lamelles empilées depuis la charnière (les bandes concentriques du 2D), nacre dessous.
        lid.addChild(ModelEntity(mesh: ValveMesh.make(s, scale: 1.06, up: true, rings: 150) { rho, phi in
            let sample = lidLayers.sample(rho, phi)
            return (s.dome(rho) + sample.height + s.rimWave(rho, phi) * 1.2, sample.uv)
        }, materials: [shell]))
        lid.addChild(ModelEntity(mesh: ValveMesh.make(s, scale: 1.02, up: false) { rho, phi in
            (s.dome(rho) - 0.008 + s.rimWave(rho, phi), nil)
        }, materials: [Self.nacre]))
    }

    func update(angle: Double, pearl: PearlLook?, cracked: Bool, pearlRadius: Double, glowHex: String?, seed: Int) {
        if seed != self.seed {
            self.seed = seed
            build(seed: seed)
        }
        let theta = Float(min(max(angle, 0), 180) * .pi / 180)
        lidPivot.orientation = simd_quatf(angle: -theta, axis: [1, 0, 0])

        let key = (pearl.map { "\($0.id)/\($0.shape ?? "")/\($0.overtone ?? "")/\($0.mark ?? "")/\($0.seed)/\(cracked)" } ?? "-") + "/\(pearlRadius)"
        if key != pearlKey {
            pearlKey = key
            if let pearl {
                let r = Float(pearlRadius)
                // La perle de la carte (forme, reflet, marque, fêlure), dessinée par PearlArt et posée sur un carré
                // tourné vers la caméra, comme le bijou dans l'écrin : on voit dans l'huître ce que la carte montrera.
                var material = UnlitMaterial()
                if let texture = Self.pearlTexture(pearl, cracked: cracked) { material.color = .init(texture: .init(texture)) }
                material.blending = .transparent(opacity: 1.0)
                material.opacityThreshold = 0.02
                self.pearl.model = ModelComponent(mesh: .generatePlane(width: 4 * r, depth: 4 * r), materials: [material])
                self.pearl.position = [0, -ValveShape.depth + r * 0.9, 0.06]
                self.pearl.orientation = simd_quatf(angle: (90 - Self.cameraElevation) * .pi / 180, axis: [1, 0, 0])
                self.pearl.isEnabled = true
            } else {
                self.pearl.isEnabled = false
            }
        }

        // La lueur monte avec l'entrebâillement, puis se fond dans la lumière du jour.
        let open = Float(min(1, angle / 35) * max(0.35, 1 - max(0, angle - 70) / 110))
        glow.light.color = glowHex.map { UIColor(Color(hex: $0)) } ?? .black
        glow.light.intensity = glowHex == nil ? 0 : 3000 * open
    }

    /// La perle dessinée comme sur la carte (`PearlArt`), le carré faisant quatre rayons (ombre comprise).
    private static func pearlTexture(_ pearl: PearlLook, cracked: Bool) -> TextureResource? {
        let px = 384.0
        let renderer = ImageRenderer(content: Canvas { context, _ in PearlArt.draw(&context, px / 2, px / 2, px / 4, pearl, cracked: cracked) }
            .frame(width: px, height: px))
        renderer.scale = 1
        renderer.isOpaque = false
        guard let image = renderer.cgImage.flatMap(Ecrin3DScene.straightAlpha) else { return nil }
        return try? TextureResource.generate(from: image, options: .init(semantic: .color))
    }

    /// Image du dossier, le cas échéant désaturée et éclaircie.
    private static func texture(_ name: String, saturation: Float = 1, brightness: Float = 0) -> TextureResource? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "jpg") else { return nil }
        if saturation == 1 && brightness == 0 { return try? TextureResource.load(contentsOf: url) }
        guard let input = CIImage(contentsOf: url) else { return nil }
        let filter = CIFilter.colorControls()
        filter.inputImage = input
        filter.saturation = saturation
        filter.brightness = brightness
        guard let output = filter.outputImage, let image = CIContext().createCGImage(output, from: input.extent) else { return nil }
        return try? TextureResource.generate(from: image, options: .init(semantic: .color))
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

/// Rendu de la coquille, choisi par Jules parmi quatre essais (2026-11-06) : brun foncé mat, bandes aux
/// écarts du dessin 2D, volants serrés. Le second est gardé pour un futur skin (`OysterStyle 2` dans les
/// réglages de l'app, en attendant qu'il soit branché sur un skin).
struct OysterStyle {
    var deep: SIMD3<Float>, mid: SIMD3<Float>, warm: SIMD3<Float>, lip: SIMD3<Float>, grey: SIMD3<Float>
    var roughness: Float, clearcoat: Float
    var edges: [Float], wave: Float, waveFrequency: Int, frills: Float

    static let all: [OysterStyle] = [
        // Sombre : sept couches, la petite du sommet comprise (Jules trouvait le haut trop grand avec six).
        OysterStyle(deep: [0.08, 0.05, 0.04], mid: [0.2, 0.14, 0.11], warm: [0.32, 0.24, 0.18], lip: [0.55, 0.47, 0.38], grey: [0.26, 0.24, 0.26],
                    roughness: 0.72, clearcoat: 0.1, edges: [0.915, 0.83, 0.745, 0.66, 0.575, 0.49, 0.32], wave: 0.045, waveFrequency: 24, frills: 26),
        // Rousse vernie : brun roux mouillé, vagues larges et douces. Pour un skin.
        OysterStyle(deep: [0.14, 0.07, 0.05], mid: [0.36, 0.2, 0.14], warm: [0.55, 0.34, 0.22], lip: [0.8, 0.66, 0.52], grey: [0.38, 0.33, 0.33],
                    roughness: 0.45, clearcoat: 0.6, edges: [0.93, 0.8, 0.67, 0.54, 0.41, 0.28], wave: 0.03, waveFrequency: 10, frills: 12),
    ]
    static var current: OysterStyle { all[max(0, min(all.count - 1, UserDefaults.standard.integer(forKey: "OysterStyle") - 1))] }
}

/// Forme commune aux deux valves, celle du dessin 2D (`ShellArt.outline`) : un éventail en demi-cercle
/// qui part de la charnière (le sommet, rho = 0) et s'élargit vers le joueur, rien derrière la charnière. `phases` (bosses, volants) rend chaque huître unique, comme en 2D.
struct ValveShape {
    /// La charnière, en z ; le bord côté joueur est 1 plus loin.
    static let hinge: Float = -0.5
    static let depth: Float = 0.13
    var phases: ShellArt.Phases
    var frills: Float

    /// Rayon du contour dans la direction f (0 : vers le joueur, ±π : derrière la charnière), longueur 1.
    func radius(_ f: Float) -> Float {
        let a = abs(f)
        // Rien derrière la charnière (sinon, couvercle levé, ce dos passerait sous la valve du bas) : la
        // valve se referme sur la charnière en quelques degrés, comme le trait droit du 2D.
        let r = a <= 1.42 ? pow(cos(a), 0.55) : max(0.01, 0.35 * (1 - (a - 1.42) / 0.12))
        return r * (1 + 0.06 * sin(3 * f + Float(phases.0)) + 0.04 * sin(7 * f + Float(phases.1)))
    }

    /// Creux de la valve du bas : nul à la charnière et au bord, le plus profond à mi-longueur (la perle).
    func bowl(_ rho: Float) -> Float { Self.depth * 4 * rho * (1 - rho) }
    /// Bombé du couvercle, le plus haut vers la charnière.
    func dome(_ rho: Float) -> Float { 0.05 * pow(1 - rho * rho, 0.6) }
    /// Le bord ondule aussi en hauteur.
    func rimWave(_ rho: Float, _ phi: Float) -> Float { 0.02 * sin(frills * phi + Float(phases.2)) * pow(rho, 6) }

    /// Point (x, z) pour rho 0…1 (de la charnière au bord) et phi (π/2 : côté joueur, −π/2 : derrière).
    func footprint(_ rho: Float, _ phi: Float, scale: Float) -> SIMD2<Float> {
        var f = phi - .pi / 2
        if f > .pi { f -= 2 * .pi }
        let frill = 1 + 0.05 * sin(frills * phi + Float(phases.2)) * pow(max(0, cos(f)), 0.3)
        let r = radius(f) * frill * scale * rho
        // x à rebours de f : même sens de parcours qu'avant (sinon les faces sont à l'envers et l'huître éclairée par-dessous).
        return [-1.05 * r * sin(f), ValveShape.hinge + r * cos(f)]
    }
}

/// Une valve en grille polaire (anneaux × rayons), normales calculées, texture projetée de dessus.
enum ValveMesh {
    static let spokes = 180

    /// `surface` donne la hauteur et, pour la coquille, ses coordonnées de texture (nil : projetée de dessus).
    static func make(_ s: ValveShape, scale: Float, up: Bool, rings: Int = 30,
                     surface: (Float, Float) -> (Float, SIMD2<Float>?)) -> MeshResource {
        func point(_ rho: Float, _ phi: Float) -> SIMD3<Float> {
            let p = s.footprint(rho, phi, scale: scale)
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
                uvs.append(surface(rho, phi).1 ?? [0.5 + p.x / (1.5 * scale), 0.46 - p.z / (1.3 * scale)])
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
    /// Ondulation du bord de chaque couche, et son nombre de vagues (sur la plus grande couche).
    var wave: Float = 0.045
    var waveFrequency: Int = 18
    /// Décalage des ondulations, propre à chaque huître.
    var phase: Float = 0

    private func edge(_ k: Int, _ phi: Float) -> Float {
        // Moins de volants sur les petites couches du sommet ; fréquences entières (pas de couture à phi = 0).
        edges[k] * (1 + wave * sin(Float(max(6, waveFrequency - k * 3)) * phi + Float(k) * 2.1 + phase))
    }

    /// Hauteur ajoutée, et coordonnées de texture : u avance de couche en couche, du sommet vers le bord
    /// (continu d'une couche à l'autre : la couleur change net au bord, pas en dents de peigne).
    func sample(_ rho: Float, _ phi: Float) -> (height: Float, uv: SIMD2<Float>) {
        var height: Float = 0, layer = 0
        for k in edges.indices {
            let b = edge(k, phi)
            // Chaque couche monte d'une marche ; son bord roule un peu avant de tomber, et ondule en hauteur.
            let lip = exp(-pow((rho - (b - riser * 1.4)) / (riser * 0.8), 2)) * (0.45 + 0.3 * sin((21 + Float(k)) * phi + Float(k) + phase))
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
/// bord clair ; une couche sur deux un peu plus grise, comme sur une vraie huître. La graine donne à
/// chaque huître sa teinte (plus ou moins rousse, plus ou moins claire) et le rang de ses couches grises.
enum ShellTexture {
    static func make(layers: Int, seed: Int, style: OysterStyle) -> TextureResource? {
        let segment = 64, width = layers * segment, height = 4
        var pixels = [UInt8](repeating: 255, count: width * height * 4)
        func mix(_ a: SIMD3<Float>, _ b: SIMD3<Float>, _ t: Float) -> SIMD3<Float> { a + (b - a) * min(1, max(0, t)) }
        let (deep, mid, warm, lip, grey) = (style.deep, style.mid, style.warm, style.lip, style.grey)
        let ph = ShellArt.phases(seed: seed)
        let tint = SIMD3<Float>(0.9 + 0.2 * Float(ph.0 / 6.3), 1, 0.85 + 0.3 * Float(ph.1 / 6.3)) * (0.85 + 0.3 * Float(ph.2 / 6.3))
        let greyLayers = abs(seed) % 2
        for y in 0..<height {
            for x in 0..<width {
                // Une couche par segment ; u : 0 au pied (sous la couche du dessus), 1 au bord.
                let layer = x / segment
                let u = (Float(x % segment) + 0.5) / Float(segment)
                var c = u < 0.18 ? mix(deep, mid, u / 0.18) : u < 0.86 ? mix(mid, warm, (u - 0.18) / 0.68) : mix(warm, lip, (u - 0.86) / 0.14)
                c *= 1 + 0.05 * sin(u * 25 + Float(layer) * 1.3) // stries de croissance
                if layer % 2 == greyLayers { c = mix(c, grey * (0.6 + u * 0.6), 0.35) }
                c *= tint
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
