import Foundation
import PearlCore

/// La langue de l'app : celle que l'iPhone a choisie parmi les traductions livrées (français, anglais).
/// Français pour les francophones, anglais pour tous les autres (CFBundleDevelopmentRegion = en).
/// Le joueur peut en changer pour cette app seule : Réglages iOS → Pearl Inc. → Langue.
enum AppLanguage {
    /// « fr » ou « en ».
    static var code: String { Bundle.main.preferredLocalizations.first == "fr" ? "fr" : "en" }
    static var isFrench: Bool { code == "fr" }
}

/// Textes du jeu qui se composent (noms, numéros, missions), dans la langue de l'app.
enum GameText {
    /// « N° 000042 » / « No. 000042 ».
    static func serial(_ serial: Int) -> String {
        let digits = serialDigits(serial)
        return String(localized: "N° \(digits)", comment: "Numéro de série d'une carte")
    }

    /// « #000042 », sur les cartes.
    static func serialTag(_ serial: Int) -> String { "#" + serialDigits(serial) }

    private static func serialDigits(_ serial: Int) -> String {
        serialLabel(serial).replacingOccurrences(of: "N° ", with: "")
    }

    /// Le nom d'une perle, fêlée ou non : « Perle rosée fêlée » / « Cracked rosé pearl ».
    static func pearlName(_ name: String, cracked: Bool) -> String {
        cracked ? String(localized: "\(name) fêlée", comment: "Perle fêlée ; %@ = nom de la perle") : name
    }

    /// « Ronde · reflet crème · Étoilée ».
    static func traits(shape: String, overtone: String, mark: String?) -> String {
        let base = String(localized: "\(shape) · reflet \(overtone)", comment: "Forme et reflet d'une perle")
        return mark.map { "\(base) · \($0)" } ?? base
    }

    /// Valeur d'un bijou : au centième sous 10, à l'unité au-delà (comme la webapp, sans l'euro).
    static func jewelValue(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(value < 10 ? 2 : 0)))
    }

    /// Le texte d'une mission du jour.
    static func mission(_ mission: Mission) -> String {
        let goal = mission.goal
        switch mission.kind {
        case .open: return String(localized: "Ouvrir \(goal) huîtres", comment: "Mission du jour")
        case .lustreA: return String(localized: "Obtenir \(goal) lustres A ou S", comment: "Mission du jour")
        case .lustreS: return String(localized: "Obtenir \(goal) lustres S", comment: "Mission du jour")
        case .rare: return String(localized: "Trouver une perle ◆◆ ou plus rare", comment: "Mission du jour")
        case .noCrack: return String(localized: "Ouvrir \(goal) huîtres d’affilée sans fêlure", comment: "Mission du jour")
        case .sell: return String(localized: "Revendre \(goal) doublons au comptoir", comment: "Mission du jour")
        case .share: return String(localized: "Partager une carte", comment: "Mission du jour")
        case .find: return String(localized: "Pêcher une trouvaille", comment: "Mission du jour")
        case .fish: return String(localized: "Rattraper le poisson voleur", comment: "Mission du jour")
        }
    }

    /// « 12:05 » ou « 3 h 12 » (« 3h 12m » en anglais).
    static func countdown(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded(.up)))
        let hours = total / 3600, minutes = (total % 3600) / 60, rest = total % 60
        if hours > 0 {
            let mm = String(format: "%02d", minutes)
            return String(localized: "\(hours) h \(mm)", comment: "Compte à rebours en heures et minutes")
        }
        return String(format: "%d:%02d", minutes, rest)
    }
}
