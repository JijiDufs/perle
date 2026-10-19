// La charnière de l'iPhone Duo comme source de geste (docs/duo-gadget.md §7) : l'angle du téléphone
// devient l'angle de l'huître, avec les mêmes OpeningSample que le pouce (invariant n° 2).
// Pour qu'une huître ne s'ouvre pas d'un coup sur un téléphone déjà ouvert, la charnière ne la pilote
// qu'une fois « armée » : le téléphone a été refermé depuis l'arrivée de l'huître.

/// Ce que la charnière demande au jeu.
public enum HingeAction: Equatable, Sendable {
    /// Rien à faire (téléphone ouvert mais pas encore armé, ou toujours fermé).
    case none
    /// Le téléphone vient de se fermer : huître suivante sur la carte, coquille qui se referme pendant la résistance.
    case closed
    /// L'angle (°) à donner au moteur d'ouverture.
    case sample(Double)
}

public struct HingeTracker: Sendable, Equatable {
    /// Le téléphone a été fermé depuis l'arrivée de l'huître : il peut l'ouvrir.
    public private(set) var armed = false
    /// Le téléphone est fermé (sous `hingeClosedAngle`).
    public private(set) var isClosed = false
    private let closedBelow: Double

    public init(tuning: Tuning) {
        closedBelow = tuning.hingeClosedAngle
    }

    /// Nouvel angle de la charnière, en degrés (0 = fermé, 180 = à plat).
    public mutating func update(degrees: Double) -> HingeAction {
        let angle = min(max(degrees, 0), 180)
        if angle <= closedBelow {
            let wasClosed = isClosed
            isClosed = true
            armed = true
            return wasClosed ? .none : .closed
        }
        isClosed = false
        return armed ? .sample(angle) : .none
    }

    /// Nouvelle huître pendant que le téléphone est ouvert (carte touchée) : il faudra le refermer d'abord.
    public mutating func disarmIfOpen() {
        if !isClosed { armed = false }
    }
}
