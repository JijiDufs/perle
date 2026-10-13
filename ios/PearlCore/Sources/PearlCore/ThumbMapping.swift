// Conversion pure du geste du pouce en angle, miroir de thumbDistanceToAngle (src/input/thumb.ts).
// La source de geste elle-même (le doigt sur l'écran) vit dans l'app, dans Input/.

/// Distance parcourue par le pouce (pt, vers le haut) → angle d'ouverture (°).
/// Pendant la résistance, la coquille bouge à peine ; au-delà, l'angle saute à l'angle du pop.
public func thumbDistanceToAngle(_ distance: Double, _ tuning: Tuning) -> Double {
    if distance <= 0 { return 0 }
    if distance < tuning.resistanceDistance {
        return tuning.popAngle * tuning.resistanceAngleRatio * (distance / tuning.resistanceDistance)
    }
    let beyond = distance - tuning.resistanceDistance
    return min(180, tuning.popAngle + (beyond * (180 - tuning.popAngle)) / tuning.fullOpenDistance)
}

/// Distance de pouce pour une ouverture complète (180°).
public func thumbFullDistance(_ tuning: Tuning) -> Double {
    tuning.resistanceDistance + tuning.fullOpenDistance
}
