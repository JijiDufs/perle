// swift-tools-version:5.9
// Outils des visuels App Store : `vitrine` (partie de démonstration cohérente, pour seed.py) et `art`
// (dessin haute définition avec le code de l'app, pour render.sh).
import PackageDescription
let package = Package(name: "vitrine", platforms: [.macOS(.v14)],
  dependencies: [.package(path: "../../../ios/PearlCore")],
  targets: [
    .executableTarget(name: "vitrine", dependencies: [.product(name: "PearlCore", package: "PearlCore")]),
    // Art/ : lien vers ios/PearlInc/Art (le dessin du jeu), sans ce qui ne sert qu'à l'écran de l'app.
    .executableTarget(name: "art", dependencies: [.product(name: "PearlCore", package: "PearlCore")],
                      exclude: ["Art/LagoonBackground.swift", "Art/CardStyle.swift"]),
  ])
