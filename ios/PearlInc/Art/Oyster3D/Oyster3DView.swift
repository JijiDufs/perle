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
    /// Le skin porté (`APP_SKINS`) : couleurs, vernis, nacre, et la forme du bénitier.
    var skin: String

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
        // Réglage de test (`defaults write app.pearlinc.PearlInc OysterTestAngle 120`) : couvercle figé à cet angle, pour regarder la 3D posément.
        let testAngle = UserDefaults.standard.double(forKey: "OysterTestAngle")
        context.coordinator.update(angle: testAngle > 0 ? testAngle : angle, pearl: pearl, cracked: cracked, pearlRadius: pearlRadius,
                                   glowHex: glowHex, seed: seed, skin: skin)
    }
}

/// La scène : la valve du bas posée à plat, le couvercle sur sa charnière, la perle, les lumières.
/// La charnière est à z = −0,5 ; une valve mesure 1 de la charnière au bord côté joueur ; la vue SwiftUI fait 3 L × 5,6 L.
@MainActor final class Oyster3DScene {
    static let cameraElevation: Float = 58
    /// La nacre du skin porté (l'image générée, blanchie : elle était trop rose, retour de Jules).
    private var nacre = PhysicallyBasedMaterial()
    private let root = AnchorEntity(world: .zero)
    private let lidPivot = Entity()
    private let lid = Entity()
    private let bottom = Entity()
    private let pearl = ModelEntity()
    /// Le voile nacré autour de la perle, avec l'ombre de celle-ci.
    private let veil = ModelEntity()
    private var shape: ValveShape?
    private var glow = PointLight()
    private var pearlKey = ""
    private var seed = Int.min
    private var skin = ""

    func install(in view: ARView) {
        lidPivot.position = [0, 0.004, ValveShape.hinge]
        lid.position = [0, 0, -ValveShape.hinge]
        lidPivot.addChild(lid)
        root.addChild(lidPivot)
        root.addChild(bottom)
        root.addChild(pearl)
        root.addChild(veil)

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
        // Champ vertical élargi avec la vue (30° pour 4,4 L) : même taille à l'écran, même perspective, plus de place derrière
        // la charnière ; la visée remonte d'autant pour que la charnière reste à sa place.
        camera.camera.fieldOfViewInDegrees = 37.6
        let target: SIMD3<Float> = [0, 0.37, -0.98]
        let elevation: Float = Self.cameraElevation * .pi / 180, distance: Float = 8.6
        camera.look(at: target, from: target + [0, distance * sin(elevation), distance * cos(elevation)], relativeTo: nil)
        root.addChild(camera)

        view.scene.addAnchor(root)
    }

    /// Les deux valves, tirées de la graine : contour, volants, couleurs. Reconstruites à chaque huître.
    private func build(seed: Int) {
        let style = OysterStyle.forSkin(skin)
        let ph = ShellArt.phases(seed: seed)
        // Bénitier : 4 ou 5 grands plis arrondis, éventail large (moins qu'en 2D, il débordait de l'écran), valve bombée.
        let s = ValveShape(phases: ph, frills: style.frills, ribs: style.isClam ? (style.ribCount > 0 ? style.ribCount : 5) : 0,
                           breadth: 1.0, spread: style.isClam ? 1.5 : 1.42, domeHeight: style.isClam ? 0.1 : 0.05, ribDepth: style.ribDepth, scallop: style.scallop)
        shape = s
        nacre = Self.material(Self.texture("oyster3d-nacre", saturation: style.nacreSaturation, brightness: style.nacreBrightness),
                              roughness: style.nacreRoughness, clearcoat: 1, tint: style.nacreTint)
        let shell = Self.material(ShellTexture.make(layers: style.edges.count + 1, seed: seed, style: style),
                                  roughness: style.roughness, clearcoat: style.clearcoat, metallic: style.metallic)
        // Les couches du couvercle, trois sur le bord de la valve du bas.
        let lidLayers = Lamellae(edges: style.edges, step: style.lamellaStep, riser: style.lamellaRiser, wave: style.wave, waveFrequency: style.waveFrequency, phase: Float(s.phases.2))
        let skirtLayers = Lamellae(edges: [0.97, 0.935, 0.9], step: 0.01, riser: 0.012, wave: 0.02, waveFrequency: style.waveFrequency, phase: Float(s.phases.1))
        bottom.children.removeAll()
        lid.children.removeAll()

        // Valve du bas : nacre creusée, et l'extérieur brun qui déborde tout autour en trois lamelles.
        bottom.addChild(ModelEntity(mesh: ValveMesh.make(s, scale: 1, up: true) { rho, phi in
            (-s.bowl(rho) + s.rimWave(rho, phi) + s.ribRelief(rho, phi), nil)
        }, materials: [nacre]))
        bottom.addChild(ModelEntity(mesh: ValveMesh.make(s, scale: 1.06, up: true, rings: 90) { rho, phi in
            let layers = skirtLayers.sample(rho, phi)
            // 0,05 sous la nacre : ses trois couches (0,03) ne doivent pas la percer là où le creux est nul (charnière).
            return (-s.bowl(rho) * 1.08 - 0.05 + layers.height + s.rimWave(rho, phi) * 1.2 + s.ribRelief(rho, phi), layers.uv)
        }, materials: [shell]))

        // Couvercle : lamelles empilées depuis la charnière (les bandes concentriques du 2D), nacre dessous.
        lid.addChild(ModelEntity(mesh: ValveMesh.make(s, scale: 1.06, up: true, rings: 150) { rho, phi in
            let sample = lidLayers.sample(rho, phi)
            return (s.dome(rho) + sample.height + s.rimWave(rho, phi) * 1.2 + s.ribRelief(rho, phi), sample.uv)
        }, materials: [shell]))
        // Dessous du couvercle. Bénitier : une face intérieure plate, qui part du niveau de la charnière (sinon le
        // dessous, bombé, s'en écartait de 0,065 : les deux valves ne se rejoignaient pas et on voyait entre elles,
        // retour de Jules) ; la valve est donc épaisse au sommet et fine au bord, comme une vraie.
        lid.addChild(ModelEntity(mesh: ValveMesh.make(s, scale: 1.02, up: false) { rho, phi in
            ((style.isClam ? 0 : s.dome(rho) - 0.008) + s.rimWave(rho, phi) + s.ribRelief(rho, phi), nil)
        }, materials: [nacre]))
    }

    /// Le voile nacré translucide posé sur la nacre autour de la perle (le manteau de l'huître, en joli), et l'ombre de
    /// la perle dessinée dessus (`pearlRadius` en unités de valve ; nil : huître vide). Il suit le creux de la valve.
    private func placeVeil(_ s: ValveShape, pearlRadius: Double?) {
        guard let texture = Self.veilTexture(s.phases, pearlRadius: pearlRadius, style: OysterStyle.forSkin(skin)) else { return }
        var material = UnlitMaterial()
        material.color = .init(texture: .init(texture))
        material.blending = .transparent(opacity: 1.0)
        material.opacityThreshold = 0.02
        veil.model = ModelComponent(mesh: ValveMesh.make(s, scale: 1, up: true) { rho, phi in
            (-s.bowl(rho) + s.rimWave(rho, phi) + s.ribRelief(rho, phi) + 0.012, nil)  // assez au-dessus de la nacre pour ne pas scintiller avec elle
        }, materials: [material])
    }

    /// Le voile, dessiné dans le repère de la texture projetée de `ValveMesh` (u = 0,5 + x / 1,8 ; v = 0,46 − z / 1,3).
    /// `mantle` : le manteau du bénitier (bleu-vert tacheté, presque opaque, comme `ClamArt`) à la place du voile ivoire.
    private static func veilTexture(_ ph: ShellArt.Phases, pearlRadius: Double?, style: OysterStyle) -> TextureResource? {
        let mantle = style.mantle
        let w = 1024.0, k = w / Double(ValveMesh.uvSpan.x), h = Double(ValveMesh.uvSpan.y) * k
        let renderer = ImageRenderer(content: Canvas { c, _ in
            let cx = w / 2, cy = (0.06 + 0.54 * Double(ValveMesh.uvSpan.y)) * k
            // Le manteau dépasse la charnière et les côtés (le maillage s'arrête là) : avec un bord frisé plus court,
            // selon la graine, un coin de porcelaine blanche se voyait entre lui et la charnière.
            let rx = (mantle ? 0.72 : 0.36) * k, ry = (mantle ? 0.64 : 0.4) * k
            func outline(_ scale: Double, _ lace: Double) -> Path {
                var path = Path()
                for i in 0...180 {
                    let a = Double(i) / 180 * 2 * .pi
                    let frill = scale * (1 + 0.03 * sin(a * 18 + ph.2) + 0.025 * sin(a * 7 + ph.0) + lace * sin(a * 40 + ph.1))
                    let p = CGPoint(x: cx + cos(a) * rx * frill, y: cy + sin(a) * ry * frill)
                    if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
                }
                path.closeSubpath()
                return path
            }
            let body = outline(1, 0)
            if mantle {
                // Le manteau du bénitier : chair bleu-vert, bord frisé plus clair, « yeux » clairs cerclés de sombre.
                let m = style.mantleColors
                // Opaque : RealityKit trame le semi-transparent en quadrillage (vu au simulateur).
                c.fill(body, with: .radialGradient(Gradient(stops: [
                    .init(color: Color(hex: m[0]), location: 0), .init(color: Color(hex: m[1]), location: 0.45),
                    .init(color: Color(hex: m[2]), location: 0.78), .init(color: Color(hex: m[3]), location: 1)]),
                    center: CGPoint(x: cx, y: cy - ry * 0.1), startRadius: 0, endRadius: rx * 1.1))
                // Rayures sombres qui rayonnent, puis le bord frisé plus clair.
                for i in 0..<14 {
                    let a = Double(i) / 14 * 2 * .pi + ph.1
                    var stripe = Path()
                    stripe.move(to: CGPoint(x: cx + cos(a) * rx * 0.2, y: cy + sin(a) * ry * 0.2))
                    stripe.addQuadCurve(to: CGPoint(x: cx + cos(a) * rx * 0.95, y: cy + sin(a) * ry * 0.95),
                                        control: CGPoint(x: cx + cos(a + 0.25) * rx * 0.6, y: cy + sin(a + 0.25) * ry * 0.6))
                    c.stroke(stripe, with: .color(rgba(20, 40, 110, 0.3)), lineWidth: k * 0.02)
                }
                c.stroke(outline(1.02, 0.03), with: .color(Color(hex: style.mantleRim).opacity(0.65)), lineWidth: 6)
                var seed = (ph.0 * 1000).rounded(.down) + 7
                func rand() -> Double { seed = (seed * 16807).truncatingRemainder(dividingBy: 2_147_483_647); return seed / 2_147_483_647 }
                for _ in 0..<70 {
                    let a = rand() * 2 * .pi, d = 0.3 + 0.65 * sqrt(rand())
                    let p = CGPoint(x: cx + cos(a) * rx * d, y: cy + sin(a) * ry * d), r = k * (0.008 + rand() * 0.012)
                    c.fill(Path(ellipseIn: CGRect(x: p.x - r * 1.6, y: p.y - r * 1.6, width: r * 3.2, height: r * 3.2)), with: .color(rgba(10, 30, 70, 0.35)))
                    c.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)), with: .color(Color(hex: style.mantleDots).opacity(0.8)))
                }
            } else {
                // Translucide : ivoire au centre, rosé au bord, la nacre reste visible dessous ; une dentelle plus claire autour.
                c.fill(body, with: .radialGradient(Gradient(stops: [
                    .init(color: rgba(255, 250, 240, 0.55), location: 0), .init(color: rgba(246, 228, 216, 0.5), location: 0.7),
                    .init(color: rgba(232, 200, 194, 0.38), location: 1)]),
                    center: CGPoint(x: cx - rx * 0.1, y: cy - ry * 0.15), startRadius: 0, endRadius: rx * 1.05))
                c.stroke(body, with: .color(rgba(255, 255, 255, 0.5)), lineWidth: 6)
                c.stroke(outline(1.06, 0.02), with: .color(rgba(255, 250, 245, 0.35)), lineWidth: 4)
            }
            if let pearlRadius {
                // L'ombre de la perle, à plat sur la nacre (la perle elle-même est dessinée sans, pour qu'elles ne se chevauchent pas).
                let r = pearlRadius * k
                c.fill(Path(CGRect(x: cx - r * 2, y: cy - r * 2, width: r * 4, height: r * 4)), with: .radialGradient(
                    Gradient(colors: [rgba(60, 40, 30, 0.4), rgba(60, 40, 30, 0)]),
                    center: CGPoint(x: cx + r * 0.15, y: cy + r * 0.35), startRadius: r * 0.3, endRadius: r * 1.3))
            }
        }.frame(width: w, height: h))
        renderer.scale = 1
        renderer.isOpaque = false
        guard let image = renderer.cgImage.flatMap(Ecrin3DScene.straightAlpha) else { return nil }
        return try? TextureResource.generate(from: image, options: .init(semantic: .color))
    }

    func update(angle: Double, pearl: PearlLook?, cracked: Bool, pearlRadius: Double, glowHex: String?, seed: Int, skin: String) {
        if seed != self.seed || skin != self.skin {
            self.seed = seed
            self.skin = skin
            build(seed: seed)
            pearlKey = ""  // la perle et le voile suivent la nouvelle valve
        }
        let theta = Float(min(max(angle, 0), 180) * .pi / 180)
        lidPivot.orientation = simd_quatf(angle: -theta, axis: [1, 0, 0])

        let key = (pearl.map { "\($0.id)/\($0.shape ?? "")/\($0.overtone ?? "")/\($0.mark ?? "")/\($0.seed)/\(cracked)" } ?? "-") + "/\(pearlRadius)"
        if key != pearlKey {
            pearlKey = key
            if let pearl {
                let r = Float(pearlRadius) * 1.3  // un peu plus grande que son rayon de jeu, pour remplir la valve (choix de Jules)
                // La perle de la carte (forme, reflet, marque, fêlure), dessinée par PearlArt et posée sur un carré
                // tourné vers la caméra, comme le bijou dans l'écrin : on voit dans l'huître ce que la carte montrera.
                var material = UnlitMaterial()
                if let texture = Self.pearlTexture(pearl, cracked: cracked) { material.color = .init(texture: .init(texture)) }
                material.blending = .transparent(opacity: 1.0)
                material.opacityThreshold = 0.02
                self.pearl.model = ModelComponent(mesh: .generatePlane(width: 4 * r, depth: 4 * r), materials: [material])
                // Posée sur le voile (ou le manteau du bénitier, qui bombe au milieu d'un pli) : le bas du carré incliné ne doit pas passer dessous.
                let floor = shape.map { -$0.bowl(0.56) + $0.ribRelief(0.56, .pi / 2) + 0.012 } ?? -ValveShape.depth
                self.pearl.position = [0, floor + r * 1.2, 0.06]
                self.pearl.orientation = simd_quatf(angle: (90 - Self.cameraElevation) * .pi / 180, axis: [1, 0, 0])
                self.pearl.isEnabled = true
            } else {
                self.pearl.isEnabled = false
            }
            if let shape { placeVeil(shape, pearlRadius: pearl == nil ? nil : pearlRadius * 1.3) }
        }

        // La lueur monte avec l'entrebâillement, puis se fond dans la lumière du jour.
        let open = Float(min(1, angle / 35) * max(0.35, 1 - max(0, angle - 70) / 110))
        glow.light.color = glowHex.map { UIColor(Color(hex: $0)) } ?? .black
        glow.light.intensity = glowHex == nil ? 0 : 3000 * open
    }

    /// La perle dessinée comme sur la carte (`PearlArt`), le carré faisant quatre rayons (ombre comprise).
    private static func pearlTexture(_ pearl: PearlLook, cracked: Bool) -> TextureResource? {
        let px = 384.0
        let renderer = ImageRenderer(content: Canvas { context, _ in
            PearlArt.draw(&context, px / 2, px / 2, px / 4, pearl, cracked: cracked, shadow: false)
            // Éclaircie d'un cinquième dans la valve seulement (la carte reste telle quelle) : les photos sont sombres
            // en leur milieu et la nacre autour est très claire (retour de Jules).
            var light = context
            light.blendMode = .plusLighter
            light.opacity = 0.2
            PearlArt.draw(&light, px / 2, px / 2, px / 4, pearl, cracked: cracked, shadow: false)
        }.frame(width: px, height: px))
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

    private static func material(_ texture: TextureResource?, roughness: Float, clearcoat: Float, metallic: Float = 0,
                                 tint: SIMD3<Float> = [1, 1, 1]) -> PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()
        let color = UIColor(red: CGFloat(tint.x), green: CGFloat(tint.y), blue: CGFloat(tint.z), alpha: 1)
        material.baseColor = .init(tint: color, texture: texture.map { .init($0) })
        material.roughness = .init(floatLiteral: roughness)
        material.metallic = .init(floatLiteral: metallic)
        material.clearcoat = .init(floatLiteral: clearcoat)
        material.clearcoatRoughness = 0.1
        material.faceCulling = .none
        return material
    }
}

/// Le rendu de la coquille selon le skin : couleurs des lamelles, vernis, nacre, et la forme du bénitier.
/// L'huître du lagon est le rendu choisi par Jules parmi quatre essais (2026-11-06).
struct OysterStyle {
    var deep: SIMD3<Float>, mid: SIMD3<Float>, warm: SIMD3<Float>, lip: SIMD3<Float>, grey: SIMD3<Float>
    var roughness: Float, clearcoat: Float
    var edges: [Float], wave: Float, waveFrequency: Int, frills: Float
    var metallic: Float = 0
    /// Hauteur d'une couche et largeur de sa tombée.
    var lamellaStep: Float = 0.022
    var lamellaRiser: Float = 0.03
    /// La nacre : teinte, désaturation et éclaircissement de l'image, rugosité.
    var nacreTint: SIMD3<Float> = [1, 1, 1]
    var nacreSaturation: Float = 0.35
    var nacreBrightness: Float = 0.08
    var nacreRoughness: Float = 0.16
    /// Part de la couleur « grise » sur une couche sur deux (0,35 : une nuance ; 0,9 : de l'émail).
    var altMix: Float = 0.35
    /// Bénitier : éventail large à gros plis (nombre, profondeur, feston du bord), et son manteau à la place du voile.
    var isClam = false
    var mantle = false
    var ribCount = 0  // 0 : 4 ou 5 selon la graine
    var ribDepth: Float = 0.11
    var scallop: Float = 0.1
    /// Le manteau : dégradé du centre au bord, « yeux » clairs, bord frisé.
    var mantleColors = ["#39d6c2", "#1c8fb0", "#2a4da0", "#3a2366"]
    var mantleDots = "#c8fff5"
    var mantleRim = "#8cf0e1"

    /// Huître du lagon : brun foncé mat, bandes aux écarts du dessin 2D, volants serrés, sept couches.
    static let lagoon = OysterStyle(deep: [0.08, 0.05, 0.04], mid: [0.2, 0.14, 0.11], warm: [0.32, 0.24, 0.18], lip: [0.55, 0.47, 0.38], grey: [0.26, 0.24, 0.26],
                                    roughness: 0.72, clearcoat: 0.1, edges: [0.915, 0.83, 0.745, 0.66, 0.575, 0.49, 0.32], wave: 0.045, waveFrequency: 24, frills: 26)
    /// Rousse vernie : brun roux mouillé, vagues larges et douces. Gardée par Jules pour un futur skin, pas encore au catalogue
    /// (`defaults write app.pearlinc.PearlInc OysterSkin rousse` pour la voir).
    static let rousse = OysterStyle(deep: [0.14, 0.07, 0.05], mid: [0.36, 0.2, 0.14], warm: [0.55, 0.34, 0.22], lip: [0.8, 0.66, 0.52], grey: [0.38, 0.33, 0.33],
                                    roughness: 0.45, clearcoat: 0.6, edges: [0.93, 0.8, 0.67, 0.54, 0.41, 0.28], wave: 0.03, waveFrequency: 10, frills: 12)
    /// Huître d'or : or martelé, nacre champagne (la palette 2D `ShellPalette.gold`).
    static let gold = OysterStyle(deep: [0.3, 0.19, 0.04], mid: [0.6, 0.42, 0.12], warm: [0.82, 0.62, 0.22], lip: [1, 0.9, 0.6], grey: [0.72, 0.56, 0.22],
                                  roughness: 0.4, clearcoat: 0.7, edges: lagoon.edges, wave: 0.045, waveFrequency: 24, frills: 26, metallic: 0.35,
                                  nacreTint: [1, 0.93, 0.76], nacreSaturation: 0.5, nacreBrightness: 0.1)
    /// Première marée : sable mouillé et écume, nacre bleutée (`ShellPalette.firstTide`).
    static let firstTide = OysterStyle(deep: [0.3, 0.26, 0.19], mid: [0.55, 0.48, 0.36], warm: [0.74, 0.67, 0.54], lip: [0.95, 0.93, 0.86], grey: [0.62, 0.63, 0.65],
                                       roughness: 0.7, clearcoat: 0.2, edges: lagoon.edges, wave: 0.045, waveFrequency: 24, frills: 26, nacreTint: [0.92, 0.97, 1])
    /// Bénitier : porcelaine crème à gros plis, manteau bleu-vert tacheté (comme `ClamArt`).
    /// D'après les photos de Jules (valve de bénitier vue de dessus) : un éventail compact et arrondi, beige mat taché de
    /// brun, cinq plis arrondis, et des volants concentriques empilés (neuf rangs à grosse lèvre) parallèles au bord.
    static let clam = OysterStyle(deep: [0.5, 0.42, 0.33], mid: [0.78, 0.73, 0.64], warm: [0.86, 0.82, 0.74], lip: [0.94, 0.91, 0.85], grey: [0.72, 0.66, 0.56],
                                  roughness: 0.85, clearcoat: 0.05, edges: stride(from: 0.95, through: 0.2, by: -0.095).map { Float($0) }, wave: 0.012,
                                  waveFrequency: 20, frills: 14, lamellaStep: 0.022, lamellaRiser: 0.035,
                                  nacreSaturation: 0.08, nacreBrightness: 0.15, nacreRoughness: 0.3, altMix: 0.2, isClam: true, mantle: true,
                                  ribDepth: 0.1, scallop: 0.1)

    static func forSkin(_ id: String) -> OysterStyle {
        return switch UserDefaults.standard.string(forKey: "OysterSkin") ?? id {  // réglage de test : voir un skin sans le posséder
        case "or": Self.gold
        case "premiere-maree": Self.firstTide
        case "benitier": Self.clam
        case "rousse": Self.rousse
        default: Self.lagoon
        }
    }
}

/// Forme commune aux deux valves, celle du dessin 2D (`ShellArt.outline`) : un éventail en demi-cercle
/// qui part de la charnière (le sommet, rho = 0) et s'élargit vers le joueur, rien derrière la charnière. `phases` (bosses, volants) rend chaque huître unique, comme en 2D.
struct ValveShape {
    /// La charnière, en z ; le bord côté joueur est 1 plus loin.
    static let hinge: Float = -0.5
    static let depth: Float = 0.13
    var phases: ShellArt.Phases
    var frills: Float
    /// Bénitier (`ClamArt`) : nombre de plis (0 : huître), élargissement latéral, demi-ouverture de l'éventail.
    var ribs = 0
    var breadth: Float = 1.0
    var spread: Float = 1.42
    /// Bombé du couvercle (le bénitier est plus profond) ; profondeur des plis et feston du bord.
    var domeHeight: Float = 0.05
    var ribDepth: Float = 0.11
    var scallop: Float = 0.1

    /// Rayon du contour dans la direction f (0 : vers le joueur, ±π : derrière la charnière), longueur 1.
    /// Rien derrière la charnière (sinon, couvercle levé, ce dos passerait sous la valve du bas) : la
    /// valve se referme sur la charnière en quelques degrés, comme le trait droit du 2D.
    func radius(_ f: Float) -> Float {
        let a = abs(f)
        if ribs > 0 {
            // Bénitier (photos de Jules) : un éventail compact et tout en rondeur, large devant, épaules rondes, et
            // rien derrière la charnière (un dos rond y passait sous la valve du bas) ; le bord festonné par les plis.
            let half = Float.pi / 2
            guard a <= half + 0.12 else { return 0.01 }
            let round = (0.25 + 0.75 * pow((1 + cos(min(a, half))) / 2, 0.9)) * (a <= half ? 1 : 1 - (a - half) / 0.12)
            let u = (f + spread) / (2 * spread)
            let fade = a <= spread ? 1 - pow(a / spread, 6) : 0  // le feston s'efface sur les épaules
            return round * (1 + 0.03 * sin(2 * f + Float(phases.0)) + 0.015 * sin(5 * f + Float(phases.1)))
                * (1 + scallop * fade * cos(2 * .pi * (u * Float(ribs) - 0.5)))
        }
        let r = a <= 1.42 ? pow(cos(a), 0.55) : max(0.01, 0.35 * (1 - (a - 1.42) / 0.12))
        return r * (1 + 0.06 * sin(3 * f + Float(phases.0)) + 0.04 * sin(7 * f + Float(phases.1)))
    }

    /// Où l'on est sur les plis du bénitier : 1 sur une crête, −1 dans un creux (0 sur l'huître).
    func ribPhase(_ phi: Float) -> Float {
        guard ribs > 0 else { return 0 }
        var f = phi - .pi / 2
        if f > .pi { f -= 2 * .pi }
        let u = min(1, max(0, (f + spread) / (2 * spread)))
        return cos(2 * .pi * (u * Float(ribs) - 0.5))
    }
    /// Relief des plis : de grandes ondulations arrondies qui rayonnent depuis la charnière, profondes au bord.
    /// Sur le bénitier, les plis s'effacent avant la charnière : leurs creux y dessinaient un V sombre sous le couvercle levé (retour de Jules).
    func ribRelief(_ rho: Float, _ phi: Float) -> Float { ribDepth * ribPhase(phi) * pow(rho, ribs > 0 ? 2.4 : 1.3) }

    /// Creux de la valve du bas : nul à la charnière et au bord, le plus profond à mi-longueur (la perle).
    func bowl(_ rho: Float) -> Float { Self.depth * 4 * rho * (1 - rho) }
    /// Bombé du couvercle, le plus haut vers la charnière.
    func dome(_ rho: Float) -> Float { domeHeight * pow(1 - rho * rho, 0.6) }
    /// Le bord ondule aussi en hauteur.
    func rimWave(_ rho: Float, _ phi: Float) -> Float { 0.02 * sin(frills * phi + Float(phases.2)) * pow(rho, 6) }

    /// Point (x, z) pour rho 0…1 (de la charnière au bord) et phi (π/2 : côté joueur, −π/2 : derrière).
    func footprint(_ rho: Float, _ phi: Float, scale: Float) -> SIMD2<Float> {
        var f = phi - .pi / 2
        if f > .pi { f -= 2 * .pi }
        let frill = 1 + (ribs > 0 ? 0.015 : 0.05) * sin(frills * phi + Float(phases.2)) * pow(max(0, cos(f)), 0.3)
        let r = radius(f) * frill * scale * rho
        // x à rebours de f : même sens de parcours qu'avant (sinon les faces sont à l'envers et l'huître éclairée par-dessous).
        return [-breadth * r * sin(f), ValveShape.hinge + r * cos(f)]
    }
}

/// Une valve en grille polaire (anneaux × rayons), normales calculées, texture projetée de dessus.
enum ValveMesh {
    static let spokes = 180
    /// Étendue (x, z) couverte par la texture projetée de dessus, en unités de valve (le bénitier est large).
    static let uvSpan: SIMD2<Float> = [1.8, 1.3]

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
                uvs.append(surface(rho, phi).1 ?? [0.5 + p.x / (uvSpan.x * scale), 0.46 - p.z / (uvSpan.y * scale)])
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
                if layer % 2 == greyLayers { c = mix(c, grey * (0.6 + u * 0.6), style.altMix) }
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
