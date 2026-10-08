import SwiftUI

/// L'habit d'une coquille : silhouette et couleurs d'un skin (catalogue : src/core/appEconomy.ts).
/// Purement cosmétique : la lumière qui filtre reste celle de la perle.
struct SkinLook {
    enum Style {
        /// Huître : contour festonné, stries de croissance.
        case oyster
        /// Bénitier : grosses côtes en éventail, bord ondulé, manteau bleu-vert tacheté.
        case clam
        /// Or martelé : huître dorée, martelage, éclats qui scintillent.
        case gold
    }

    var style: Style
    var shellLight: Color
    var shellDark: Color
    var nacreLight: Color
    var nacreShade: Color
    var rim: Color?

    init(style: String, shellLight: String, shellDark: String, nacreLight: String, nacreShade: String, rim: String?) {
        switch style {
        case "clam": self.style = .clam
        case "gold": self.style = .gold
        default: self.style = .oyster
        }
        self.shellLight = Color(hex: shellLight)
        self.shellDark = Color(hex: shellDark)
        self.nacreLight = Color(hex: nacreLight)
        self.nacreShade = Color(hex: nacreShade)
        self.rim = rim.map { Color(hex: $0) }
    }

    /// L'huître du lagon, celle de départ.
    static let lagoon = SkinLook(style: "oyster", shellLight: "#8C806C", shellDark: "#4A4237",
                                 nacreLight: "#FBF7F2", nacreShade: "#D6CCE6", rim: nil)
}
