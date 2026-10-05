// Tous les paramètres réglables du jeu. Aucun autre fichier ne doit contenir ces nombres.
// Les valeurs « à régler » sont des points de départ, à ajuster sur un vrai iPhone
// depuis l'écran Réglages.

export interface Tuning {
  /** Angle (°) auquel la coquille cède avec un « pop ». */
  popAngle: number;
  /** Distance de pouce (pt) à parcourir pendant la résistance avant le pop. */
  resistanceDistance: number;
  /** Part de popAngle atteinte pendant la résistance (0…1) : la coquille bouge à peine. */
  resistanceAngleRatio: number;
  /** Distance de pouce (pt) pour aller du pop à 180°. */
  fullOpenDistance: number;
  /** Distance de pouce (pt) entre deux tics haptiques pendant la résistance. */
  resistanceTickDistance: number;
  /** Début de la zone fragile (°). Cahier §5. */
  fragileMinAngle: number;
  /** Fin de la zone fragile (°). Cahier §5. */
  fragileMaxAngle: number;
  /** Vitesse (°/s) au-delà de laquelle la perle se fêle dans la zone fragile. */
  maxSafeVelocity: number;
  /** Fenêtre (ms) sur laquelle la vitesse est mesurée, pour lisser le bruit du doigt. */
  velocityWindowMs: number;
  /** Angle (°) à partir duquel la perle est révélée. */
  revealAngle: number;
  /** Coefficient de variation de la vitesse max pour chaque note de lustre (plus bas = plus régulier). */
  lustreMaxVariationS: number;
  lustreMaxVariationA: number;
  lustreMaxVariationB: number;
  /** Nombre minimal de mesures de vitesse pour noter le lustre ; en dessous : C. */
  lustreMinSamples: number;
  /** Durée du suspense (ms) entre la révélation et la carte, selon la rareté (catalog.revealTier). */
  revealSuspenseTier0Ms: number;
  revealSuspenseTier1Ms: number;
  revealSuspenseTier2Ms: number;
  revealSuspenseTier3Ms: number;
  /** Huîtres d'affilée sans perle dorée ou mieux avant que la suivante soit garantie. Cahier §5. */
  pityThreshold: number;
  /** Stock d'huîtres maximum. Cahier §5 : 10. */
  oysterStockMax: number;
  /** Minutes pour qu'une huître revienne. Cahier §5 : 30 ; 20 pendant la bêta (AGENTS.md §6). */
  oysterRechargeMinutes: number;
  /** Écrin : plage (°) dans laquelle l'angle d'éclat est tiré au hasard. */
  glintMinAngle: number;
  glintMaxAngle: number;
  /** Écart (°) à l'angle d'éclat en deçà duquel on « tient » l'éclat. */
  glintTolerance: number;
  /** Écart (°) au-delà duquel le bijou ne scintille plus du tout. */
  glintSparkleRange: number;
  /** Durée (ms) à tenir immobile sur l'angle d'éclat pour un éclat parfait. Cahier §7 : une seconde. */
  glintHoldMs: number;
  /** Vitesse (°/s) en dessous de laquelle le geste compte comme immobile. */
  glintMaxVelocity: number;
  /** Multiplicateur de valeur d'un éclat parfait. Cahier §7 : ×1,5. */
  glintPerfectMultiplier: number;
  /** Chance (0…1) qu'un éclat parfait révèle une variante rare (cahier §7 ; valeur provisoire, AGENTS.md §6). */
  glintRareVariantChance: number;
  /** Multiplicateur de valeur d'une variante rare (remplace celui de l'éclat parfait). */
  glintRareVariantMultiplier: number;
  /** Écrins d'affilée sans bijou ★ ou mieux avant que le suivant soit garanti. Cahier §7. */
  ecrinPityThreshold: number;
  /** Huîtres ouvertes pour gagner un écrin (bêta, AGENTS.md §6). */
  oystersPerEcrin: number;
  /** Expertise à la loupe (cahier §7) : durée du mini-jeu (ms). */
  expertiseDurationMs: number;
  /** Rayon (en fraction du rayon de la pierre) dans lequel le viseur « tient » une inclusion. */
  expertiseHitRadius: number;
  /** Temps (ms) à garder le viseur sur une inclusion pour la repérer. */
  expertiseDwellMs: number;
  /** Part minimale d'inclusions trouvées pour un certificat « Bon ». */
  expertiseGoodRatio: number;
  /** Bonus de valeur des certificats « Excellent » et « Bon » (0,25 = +25 %). */
  expertiseBonusExcellent: number;
  expertiseBonusGood: number;
}

export const DEFAULT_TUNING: Readonly<Tuning> = {
  popAngle: 15,
  resistanceDistance: 90,
  resistanceAngleRatio: 0.25,
  fullOpenDistance: 380,
  resistanceTickDistance: 18,
  fragileMinAngle: 20,
  fragileMaxAngle: 110,
  maxSafeVelocity: 260,
  velocityWindowMs: 60,
  revealAngle: 140,
  lustreMaxVariationS: 0.25,
  lustreMaxVariationA: 0.45,
  lustreMaxVariationB: 0.7,
  lustreMinSamples: 4,
  revealSuspenseTier0Ms: 250,
  revealSuspenseTier1Ms: 700,
  revealSuspenseTier2Ms: 1200,
  revealSuspenseTier3Ms: 2000,
  pityThreshold: 25,
  oysterStockMax: 10,
  oysterRechargeMinutes: 20,
  glintMinAngle: 55,
  glintMaxAngle: 125,
  glintTolerance: 6,
  glintSparkleRange: 28,
  glintHoldMs: 900,
  glintMaxVelocity: 30,
  glintPerfectMultiplier: 1.5,
  glintRareVariantChance: 0.12,
  glintRareVariantMultiplier: 2,
  ecrinPityThreshold: 20,
  oystersPerEcrin: 8,
  expertiseDurationMs: 20_000,
  expertiseHitRadius: 0.09,
  expertiseDwellMs: 350,
  expertiseGoodRatio: 2 / 3,
  expertiseBonusExcellent: 0.25,
  expertiseBonusGood: 0.12,
};

/** Description des paramètres exposés dans l'écran Réglages. */
export interface TuningField {
  key: keyof Tuning;
  label: string;
  unit: string;
  min: number;
  max: number;
  step: number;
}

export const TUNING_FIELDS: readonly TuningField[] = [
  { key: 'resistanceDistance', label: 'Résistance avant le pop', unit: 'pt', min: 20, max: 250, step: 5 },
  { key: 'resistanceAngleRatio', label: 'Mouvement pendant la résistance', unit: '× pop', min: 0, max: 0.9, step: 0.05 },
  { key: 'resistanceTickDistance', label: 'Espacement des tics de résistance', unit: 'pt', min: 5, max: 60, step: 1 },
  { key: 'popAngle', label: 'Angle du pop', unit: '°', min: 5, max: 19, step: 1 },
  { key: 'fullOpenDistance', label: 'Course du pouce (pop → 180°)', unit: 'pt', min: 150, max: 700, step: 10 },
  { key: 'maxSafeVelocity', label: 'Vitesse max en zone fragile', unit: '°/s', min: 60, max: 800, step: 10 },
  { key: 'velocityWindowMs', label: 'Lissage de la vitesse', unit: 'ms', min: 16, max: 200, step: 4 },
  { key: 'revealAngle', label: 'Angle de révélation', unit: '°', min: 111, max: 180, step: 1 },
  { key: 'lustreMaxVariationS', label: 'Lustre S : irrégularité max', unit: '', min: 0.05, max: 1, step: 0.05 },
  { key: 'lustreMaxVariationA', label: 'Lustre A : irrégularité max', unit: '', min: 0.05, max: 1.5, step: 0.05 },
  { key: 'revealSuspenseTier0Ms', label: 'Suspense perle courante', unit: 'ms', min: 0, max: 2000, step: 50 },
  { key: 'revealSuspenseTier1Ms', label: 'Suspense perle ◆◆', unit: 'ms', min: 0, max: 3000, step: 50 },
  { key: 'revealSuspenseTier2Ms', label: 'Suspense perle ◆◆◆', unit: 'ms', min: 0, max: 4000, step: 50 },
  { key: 'revealSuspenseTier3Ms', label: 'Suspense perle ★ et plus', unit: 'ms', min: 0, max: 6000, step: 50 },
  { key: 'oysterStockMax', label: 'Stock d’huîtres maximum', unit: '', min: 1, max: 30, step: 1 },
  { key: 'oysterRechargeMinutes', label: 'Recharge d’une huître', unit: 'min', min: 1, max: 60, step: 1 },
  { key: 'glintTolerance', label: 'Écrin : tolérance de l’angle d’éclat', unit: '°', min: 1, max: 20, step: 1 },
  { key: 'glintHoldMs', label: 'Écrin : temps à tenir l’éclat', unit: 'ms', min: 200, max: 2500, step: 50 },
  { key: 'glintMaxVelocity', label: 'Écrin : vitesse « immobile » max', unit: '°/s', min: 5, max: 120, step: 5 },
  { key: 'expertiseDurationMs', label: 'Expertise : durée', unit: 'ms', min: 5000, max: 60000, step: 1000 },
  { key: 'expertiseHitRadius', label: 'Expertise : tolérance du viseur', unit: '× pierre', min: 0.03, max: 0.2, step: 0.01 },
  { key: 'expertiseDwellMs', label: 'Expertise : temps sur une inclusion', unit: 'ms', min: 100, max: 1500, step: 50 },
  { key: 'oystersPerEcrin', label: 'Huîtres pour gagner un écrin', unit: '', min: 1, max: 30, step: 1 },
  { key: 'lustreMaxVariationB', label: 'Lustre B : irrégularité max', unit: '', min: 0.05, max: 2, step: 0.05 },
];

/** Durée du suspense de révélation pour un niveau de rareté donné. */
export function revealSuspenseMs(tuning: Tuning, tier: 0 | 1 | 2 | 3): number {
  return [tuning.revealSuspenseTier0Ms, tuning.revealSuspenseTier1Ms, tuning.revealSuspenseTier2Ms, tuning.revealSuspenseTier3Ms][tier];
}
