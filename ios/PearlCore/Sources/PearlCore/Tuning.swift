// Les paramètres réglables du jeu, lus dans catalog.json (exporté depuis src/tuning.ts).
// Aucun autre fichier ne doit contenir ces nombres (AGENTS.md, invariant 3).
// Seuls les champs dont l'app iOS a besoin sont déclarés ; les autres sont ignorés.

public struct Tuning: Codable, Sendable, Equatable {
    /// Angle (°) auquel la coquille cède avec un « pop ».
    public var popAngle: Double
    /// Distance de pouce (pt) à parcourir pendant la résistance avant le pop.
    public var resistanceDistance: Double
    /// Part de popAngle atteinte pendant la résistance (0…1).
    public var resistanceAngleRatio: Double
    /// Distance de pouce (pt) pour aller du pop à 180°.
    public var fullOpenDistance: Double
    /// Distance de pouce (pt) entre deux tics haptiques pendant la résistance.
    public var resistanceTickDistance: Double
    /// Zone fragile (°). Cahier §5.
    public var fragileMinAngle: Double
    public var fragileMaxAngle: Double
    /// Vitesse (°/s) au-delà de laquelle la perle se fêle dans la zone fragile.
    public var maxSafeVelocity: Double
    /// Fenêtre (ms) sur laquelle la vitesse est mesurée.
    public var velocityWindowMs: Double
    /// Angle (°) à partir duquel la perle est révélée.
    public var revealAngle: Double
    /// Au-delà de cet angle (°), lâcher le pouce laisse le couvercle finir seul.
    public var autoOpenFromAngle: Double
    /// iPhone Duo : sous cet angle (°) de la charnière, le téléphone est fermé.
    public var hingeClosedAngle: Double
    /// Coefficient de variation de la vitesse max pour chaque note de lustre.
    public var lustreMaxVariationS: Double
    public var lustreMaxVariationA: Double
    public var lustreMaxVariationB: Double
    /// Nombre minimal de mesures de vitesse pour noter le lustre ; en dessous : C.
    public var lustreMinSamples: Int
    /// Durée du suspense (ms) avant la carte, selon la rareté.
    public var revealSuspenseTier0Ms: Double
    public var revealSuspenseTier1Ms: Double
    public var revealSuspenseTier2Ms: Double
    public var revealSuspenseTier3Ms: Double
    /// Le couvercle finit de s'ouvrir en douceur après la révélation, et éclair blanc des ★ (ms).
    public var revealLidSettleMs: Double
    public var revealFlashMs: Double
    /// Une bulle d'information (le stock, juste après le tutoriel) s'efface au bout de (ms).
    public var coachTipMs: Double
    /// Huîtres d'affilée sans perle dorée ou mieux avant que la suivante soit garantie.
    public var pityThreshold: Int
    /// Stock d'huîtres maximum, et minutes pour qu'une huître revienne.
    public var oysterStockMax: Int
    public var oysterRechargeMinutes: Double
    /// Chance d'une marque rare sur une perle.
    public var pearlMarkChance: Double
    /// Poussière d'or d'un doublon fondu, selon sa rareté (— à ★★).
    public var dustTier0: Int
    public var dustTier1: Int
    public var dustTier2: Int
    public var dustTier3: Int
    public var dustTier4: Int
    public var dustTier5: Int

    public func revealSuspenseMs(tier: Int) -> Double {
        switch tier {
        case 0: revealSuspenseTier0Ms
        case 1: revealSuspenseTier1Ms
        case 2: revealSuspenseTier2Ms
        default: revealSuspenseTier3Ms
        }
    }
}
