import SwiftUI

/// L'habit d'une coquille (un skin). Purement cosmétique : la lumière qui filtre reste celle de la perle.
/// Les couleurs vivent ici, avec le dessin (comme src/art/shell.ts) ; le catalogue ne connaît que l'identifiant.
enum SkinLook {
    /// Une huître (même dessin que la webapp), aux couleurs du skin.
    case oyster(ShellPalette, rim: Color?, sparkles: Bool)
    /// Le bénitier.
    case clam

    init(skinId: String) {
        switch skinId {
        case "benitier": self = .clam
        case "premiere-maree": self = .oyster(.firstTide, rim: rgba(222, 232, 240, 0.9), sparkles: false)
        case "or": self = .oyster(.gold, rim: rgba(255, 236, 170, 0.8), sparkles: true)
        default: self = .lagoon
        }
    }

    /// L'huître du lagon, celle de départ.
    static let lagoon = SkinLook.oyster(.lagoon, rim: nil, sparkles: false)
}
