import SwiftUI

/// Cadre des cartes selon la perle, porté de src/art/cardStyle.ts (le prototype de pearl-inc.app) :
/// dégradé [haut-gauche, bas-droite], et texte clair (`dark`) ou foncé.
struct CardFrame {
    let colors: [String]
    let dark: Bool

    var ink: Color { Color(hex: dark ? "#eef0ff" : "#1b2326") }

    static func pearl(_ id: String) -> CardFrame {
        switch id {
        case "empty": CardFrame(colors: ["#c9cfcf", "#7d8889"], dark: false)
        case "baroque": CardFrame(colors: ["#e6defa", "#a698cf"], dark: false)
        case "black": CardFrame(colors: ["#5b5f86", "#1d2033"], dark: true)
        case "golden": CardFrame(colors: ["#f7dc8c", "#b07d1c"], dark: false)
        case "giant": CardFrame(colors: ["#ffd6f0", "#7fd6ff"], dark: false)
        case "cursed": CardFrame(colors: ["#5a1238", "#12030b"], dark: true)
        default: CardFrame(colors: ["#f1edf4", "#bdb5c9"], dark: false)
        }
    }

    /// Une trouvaille prend le cadre de la perle de même ampleur (◆ … ★★).
    static func find(tier: Int) -> CardFrame {
        pearl(["white", "white", "baroque", "golden", "giant"][min(max(tier - 1, 0), 4)])
    }

    /// Fond de la vitrine où repose la perle.
    var well: [String] { dark ? ["#3b3f5c", "#14161f"] : ["#fdfaff", "#e3daf0", "#b2a8c4"] }
}
