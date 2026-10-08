// swift-tools-version: 6.0
// PearlCore : la logique de jeu PURE de l'app iOS, miroir de src/core (AGENTS.md §3).
// Aucun accès à UIKit ni SwiftUI. Catalogues et réglages lus dans Resources/catalog.json,
// exporté depuis le TypeScript par `npm run ios:export`.
import PackageDescription

let package = Package(
    name: "PearlCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "PearlCore", targets: ["PearlCore"]),
    ],
    targets: [
        .target(
            name: "PearlCore",
            resources: [.copy("Resources/catalog.json")]
        ),
        .testTarget(
            name: "PearlCoreTests",
            dependencies: ["PearlCore"],
            resources: [.copy("Resources/parity.json")]
        ),
    ]
)
