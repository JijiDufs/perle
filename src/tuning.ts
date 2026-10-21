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
  /** Au-delà de cet angle (°), lâcher le pouce laisse le couvercle finir de s'ouvrir seul (ouverture à une main). */
  autoOpenFromAngle: number;
  /** iPhone Duo : sous cet angle (°) de la charnière, le téléphone est fermé (huître suivante, prêt à pêcher). */
  hingeClosedAngle: number;
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
  /** App iOS : le couvercle finit de s'ouvrir en douceur après la révélation (ms). */
  revealLidSettleMs: number;
  /** Éclair blanc des perles ★ quand la carte arrive (ms). */
  revealFlashMs: number;
  /** App iOS : une bulle d'information (le stock, juste après le tutoriel) s'efface au bout de (ms). */
  coachTipMs: number;
  /** App iOS : la bannière d'un succès obtenu s'efface au bout de (ms). */
  achievementBannerMs: number;
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
  /** Poussière d'or obtenue en fondant un doublon, selon sa rareté (— à ★★, perles et bijoux). */
  dustTier0: number;
  dustTier1: number;
  dustTier2: number;
  dustTier3: number;
  dustTier4: number;
  dustTier5: number;
  /** Prix d'une pièce manquante = poussière qu'elle rapporterait fondue × ce multiplicateur. */
  dustBuyMultiplier: number;
  /** Prix d'un écrin Velours en poussière d'or. */
  dustEcrinPrice: number;
  /** Réputation (expérience, cahier §9) : par huître ouverte, + par niveau de rareté de la perle. */
  repOyster: number;
  repPerTier: number;
  /** Bonus de lustre S / A (perle non fêlée). */
  repLustreS: number;
  repLustreA: number;
  /** Première perle d'une sorte, ou premier bijou d'une rareté. */
  repDiscovery: number;
  /** Par écrin ouvert, et bonus d'éclat parfait. */
  repEcrin: number;
  repPerfect: number;
  /** Expertise avec certificat (Bon ou Excellent). */
  repExpertise: number;
  /** Réputation pour passer du niveau n au niveau n+1 : base + croissance × n^puissance. */
  levelBaseXp: number;
  levelGrowthXp: number;
  levelGrowthPower: number;
  maxLevel: number;
  /** Récompenses de chaque niveau : huîtres (peuvent dépasser le maximum), poussière d'or ; un écrin tous les N niveaux. */
  levelRewardOysters: number;
  levelRewardDust: number;
  levelEcrinEvery: number;
  /** Succès (cahier §10) : poussière d'or selon le palier bronze / argent / or, et réputation. */
  achievementDustBronze: number;
  achievementDustSilver: number;
  achievementDustGold: number;
  achievementReputation: number;
  /** Quêtes du jour (cahier §15) : nombre, et récompense de chacune ; les trois donnent un écrin. */
  questsPerDay: number;
  questRewardDust: number;
  questRewardReputation: number;
  /** Récompense d'une lettre de grand-mère lue (La Maison). */
  chapterRewardDust: number;
  chapterRewardReputation: number;
  /** Réputation de la case du calendrier de connexion (en plus de sa récompense). */
  dailyRewardReputation: number;
  /** Niveau qui ouvre l'atelier (cahier §6 : 5). */
  atelierLevel: number;
  /** Sertissage : fermeture qui démarre le chrono, fermeture qui termine. */
  settingStartAt: number;
  settingCompleteAt: number;
  /** Durée idéale de la fermeture (ms) : plus court = brusque, plus long = hésitant. */
  settingIdealMinMs: number;
  settingIdealMaxMs: number;
  /** Irrégularité de vitesse (coefficient de variation) qui annule la note de régularité. */
  settingMaxVariation: number;
  /** Score du geste (0…1) à partir duquel le sertissage est parfait. */
  settingPerfectScore: number;
  /** Écart des doigts (pt) à refermer pour un sertissage complet ; un doigt seul : distance à glisser vers le bas. */
  settingPinchDistance: number;
  /** Réputation par bijou fabriqué. */
  repCraft: number;
  /** Trouvailles (cahier §5) : poussière d'or d'une pièce d'or engloutie, écrins d'une clé d'épave. */
  findCoinDust: number;
  findKeyEcrins: number;
  /** Écrins donnés par un album de trouvailles complété (cahier §10). */
  albumRewardEcrins: number;
  /** Chance qu'une perle porte une marque rare (jumelle, étoilée, lunaire, en cœur). */
  pearlMarkChance: number;
}

export const DEFAULT_TUNING: Readonly<Tuning> = {
  popAngle: 15,
  resistanceDistance: 70,
  resistanceAngleRatio: 0.25,
  fullOpenDistance: 260,
  resistanceTickDistance: 18,
  fragileMinAngle: 20,
  fragileMaxAngle: 110,
  maxSafeVelocity: 380,
  velocityWindowMs: 60,
  revealAngle: 140,
  autoOpenFromAngle: 115,
  hingeClosedAngle: 8,
  lustreMaxVariationS: 0.25,
  lustreMaxVariationA: 0.45,
  lustreMaxVariationB: 0.7,
  lustreMinSamples: 4,
  revealSuspenseTier0Ms: 250,
  revealSuspenseTier1Ms: 700,
  revealSuspenseTier2Ms: 1200,
  revealSuspenseTier3Ms: 2000,
  revealLidSettleMs: 350,
  revealFlashMs: 500,
  coachTipMs: 7000,
  achievementBannerMs: 4500,
  pityThreshold: 25,
  oysterStockMax: 10,
  oysterRechargeMinutes: 20,
  glintMinAngle: 55,
  glintMaxAngle: 115,
  glintTolerance: 6,
  glintSparkleRange: 28,
  glintHoldMs: 900,
  glintMaxVelocity: 45,
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
  dustTier0: 1,
  dustTier1: 2,
  dustTier2: 5,
  dustTier3: 12,
  dustTier4: 40,
  dustTier5: 120,
  dustBuyMultiplier: 5,
  dustEcrinPrice: 60,
  repOyster: 10,
  repPerTier: 5,
  repLustreS: 10,
  repLustreA: 5,
  repDiscovery: 30,
  repEcrin: 25,
  repPerfect: 15,
  repExpertise: 20,
  levelBaseXp: 60,
  levelGrowthXp: 15,
  levelGrowthPower: 1.5,
  maxLevel: 100,
  levelRewardOysters: 3,
  levelRewardDust: 15,
  levelEcrinEvery: 3,
  achievementDustBronze: 10,
  achievementDustSilver: 30,
  achievementDustGold: 80,
  achievementReputation: 40,
  questsPerDay: 3,
  questRewardDust: 10,
  questRewardReputation: 30,
  chapterRewardDust: 20,
  chapterRewardReputation: 20,
  dailyRewardReputation: 15,
  atelierLevel: 5,
  settingStartAt: 0.08,
  settingCompleteAt: 0.95,
  settingIdealMinMs: 350,
  settingIdealMaxMs: 1000,
  settingMaxVariation: 1.2,
  settingPerfectScore: 0.85,
  settingPinchDistance: 140,
  repCraft: 30,
  findCoinDust: 15,
  findKeyEcrins: 1,
  albumRewardEcrins: 1,
  pearlMarkChance: 0.04,
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
  { key: 'autoOpenFromAngle', label: 'Ouverture automatique à partir de', unit: '°', min: 111, max: 180, step: 1 },
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
  { key: 'dustEcrinPrice', label: 'Poussière d’or : prix d’un écrin', unit: '✦', min: 5, max: 300, step: 5 },
  { key: 'dustBuyMultiplier', label: 'Poussière d’or : prix d’une pièce', unit: '× fonte', min: 1, max: 20, step: 1 },
  { key: 'levelBaseXp', label: 'Niveaux : réputation de base par niveau', unit: 'XP', min: 10, max: 500, step: 10 },
  { key: 'levelGrowthXp', label: 'Niveaux : croissance par niveau', unit: 'XP', min: 0, max: 100, step: 1 },
  { key: 'levelEcrinEvery', label: 'Niveaux : un écrin tous les', unit: 'niv.', min: 1, max: 10, step: 1 },
  { key: 'settingIdealMinMs', label: 'Sertissage : durée idéale min', unit: 'ms', min: 100, max: 1500, step: 50 },
  { key: 'settingIdealMaxMs', label: 'Sertissage : durée idéale max', unit: 'ms', min: 300, max: 3000, step: 50 },
  { key: 'settingPinchDistance', label: 'Sertissage : écart des doigts à refermer', unit: 'pt', min: 60, max: 300, step: 10 },
  { key: 'lustreMaxVariationB', label: 'Lustre B : irrégularité max', unit: '', min: 0.05, max: 2, step: 0.05 },
];

/** Durée du suspense de révélation pour un niveau de rareté donné. */
export function revealSuspenseMs(tuning: Tuning, tier: 0 | 1 | 2 | 3): number {
  return [tuning.revealSuspenseTier0Ms, tuning.revealSuspenseTier1Ms, tuning.revealSuspenseTier2Ms, tuning.revealSuspenseTier3Ms][tier];
}

/** Poussière d'or que rapporte un doublon fondu, selon son niveau de rareté (0 = —, 5 = ★★). */
export function dustForTier(tuning: Tuning, tier: number): number {
  return [tuning.dustTier0, tuning.dustTier1, tuning.dustTier2, tuning.dustTier3, tuning.dustTier4, tuning.dustTier5][Math.max(0, Math.min(5, tier))];
}

// ── App iOS : musique d'ambiance et effets sonores, générés par code (ios/PearlInc/Platform/Audio.swift),
// sans aucun fichier audio (AGENTS.md §6). Les effets reprennent ceux de la webapp (src/platform/audio.ts,
// features/oyster/oysterScreen.ts) : mêmes fréquences, mêmes durées. Volumes : 0…1 ; fréquences : Hz.

/** Bruit bref filtré (craquement, pop, fêlure) : un bruit blanc qui s'éteint, passé dans un filtre passe-bande. */
export interface NoiseSound {
  durationMs: number;
  /** Centre du filtre (Hz). */
  frequency: number;
  gain: number;
}

/** Notes égrenées (carillons, tintements) : jouées l'une après l'autre, chacune monte puis s'éteint. */
export interface ToneSound {
  notes: readonly number[];
  wave: 'sine' | 'triangle' | 'sawtooth' | 'square';
  /** Écart entre deux notes (ms). */
  gapMs: number;
  /** Montée de chaque note (ms), puis extinction jusqu'au silence en decayMs. */
  attackMs: number;
  decayMs: number;
  gain: number;
}

export interface AppAudio {
  sampleRate: number;
  /** Volume général des effets et de la musique (avant le volume de l'iPhone). */
  effectsVolume: number;
  musicVolume: number;
  /** Part de réverbération (0…100 %) : un peu d'espace, comme sous une voûte. */
  effectsReverbMix: number;
  musicReverbMix: number;
  /** Largeur du filtre des bruits (facteur Q, comme la webapp). */
  noiseQ: number;
  /** Tic de résistance ; la fréquence monte de tickFrequencyStep à chaque tic (comme la webapp). */
  tick: NoiseSound;
  tickFrequencyStep: number;
  /** La coquille cède. */
  pop: NoiseSound;
  /** La perle se fêle. */
  crack: NoiseSound;
  /** Le couvercle s'ouvre en grand (début du suspense). */
  lid: NoiseSound;
  /** Battement du suspense : un son grave qui descend, plus fort pour les perles rares. */
  pulseStartFrequency: number;
  pulseEndFrequency: number;
  pulseDurationMs: number;
  /** Montée du battement (ms), pour qu'il ne claque pas. */
  pulseAttackMs: number;
  pulseGain: number;
  pulseGainPerTier: number;
  /** Écart entre deux battements du suspense (ms), comme l'haptique. */
  pulseEveryMs: number;
  /** Carillon de révélation : chimeBaseNotes notes, plus une par niveau de rareté (revealTier). */
  chime: ToneSound;
  chimeBaseNotes: number;
  /** La perle maudite grince ; l'huître vide descend ; une trouvaille sautille. */
  cursedChime: ToneSound;
  emptyChime: ToneSound;
  findChime: ToneSound;
  /** Poussière d'or gagnée (revente, mission) : le tintement cristallin de la fonte (webapp). */
  ding: ToneSound;
  /** Bouton, onglet, coquille équipée : un « toc » doux. */
  tap: ToneSound;
  /** Le poisson voleur file avec la perle (« bloup-bloup » moqueur) ; perdue : on reprend la descente de l'huître vide. */
  fishChime: ToneSound;
  /** Récompense (calendrier, pub, huître achetée) et achat (coquille, boutique) : niveau du carillon (0…3). */
  rewardChimeLevel: number;
  purchaseChimeLevel: number;
  /** Musique d'ambiance du lagon : une nappe d'accords lente, le ressac, et quelques notes de carillon. */
  musicFadeMs: number;
  /** Pendant le suspense, la musique baisse (part du volume) pour laisser la place au carillon. */
  musicSuspenseDuck: number;
  /** Accords de la nappe (Hz), chacun tenu chordSeconds, enchaînés en fondu sur chordCrossfadeSeconds. */
  chords: readonly (readonly number[])[];
  chordSeconds: number;
  chordCrossfadeSeconds: number;
  /** Volume de chaque note de la nappe, part de l'harmonique (octave), lente ondulation du volume. */
  padGain: number;
  padHarmonic: number;
  padTremoloHz: number;
  padTremoloDepth: number;
  /** Ressac : bruit adouci (filtre passe-bas) qui enfle et retombe, sur deux vagues de périodes différentes. */
  waveGain: number;
  waveCutoffHz: number;
  wavePeriodsSeconds: readonly number[];
  /** Notes de carillon au hasard (gamme pentatonique), espacées de sparkleGapMin à sparkleGapMax secondes. */
  sparkleNotes: readonly number[];
  sparkleGapMinSeconds: number;
  sparkleGapMaxSeconds: number;
  sparkleDecaySeconds: number;
  sparkleGain: number;
}

/** Enveloppe des carillons de la webapp : montée 20 ms, extinction en 900 ms, une note toutes les 90 ms. */
const WEB_CHIME = { gapMs: 90, attackMs: 20, decayMs: 900 } as const;

export const APP_AUDIO: Readonly<AppAudio> = {
  sampleRate: 44_100,
  effectsVolume: 1,
  musicVolume: 0.7,
  effectsReverbMix: 18,
  musicReverbMix: 35,
  noiseQ: 2.5,
  tick: { durationMs: 30, frequency: 700, gain: 0.12 },
  tickFrequencyStep: 60,
  pop: { durationMs: 90, frequency: 1400, gain: 0.6 },
  crack: { durationMs: 150, frequency: 3200, gain: 0.5 },
  lid: { durationMs: 400, frequency: 600, gain: 0.12 },
  pulseStartFrequency: 150,
  pulseEndFrequency: 75,
  pulseDurationMs: 180,
  pulseAttackMs: 5,
  pulseGain: 0.12,
  pulseGainPerTier: 0.04,
  pulseEveryMs: 350,
  chime: { notes: [523, 659, 784, 988, 1175, 1568], wave: 'sine', ...WEB_CHIME, gain: 0.12 },
  chimeBaseNotes: 3,
  cursedChime: { notes: [220, 233, 311, 207], wave: 'sawtooth', ...WEB_CHIME, gain: 0.05 },
  emptyChime: { notes: [330, 262], wave: 'sine', ...WEB_CHIME, gain: 0.12 },
  findChime: { notes: [392, 587, 494, 784, 988, 1175], wave: 'triangle', ...WEB_CHIME, gain: 0.12 },
  ding: { notes: [1568, 2093, 2637], wave: 'sine', gapMs: 60, attackMs: 10, decayMs: 700, gain: 0.08 },
  tap: { notes: [880], wave: 'sine', gapMs: 0, attackMs: 4, decayMs: 90, gain: 0.07 },
  fishChime: { notes: [784, 659, 988, 784], wave: 'triangle', gapMs: 85, attackMs: 4, decayMs: 160, gain: 0.1 },
  rewardChimeLevel: 1,
  purchaseChimeLevel: 2,
  musicFadeMs: 1500,
  musicSuspenseDuck: 0.35,
  // Do majeur doux : Do maj7, La m7, Fa maj7, Sol 6 (sous les carillons, eux aussi en do majeur).
  chords: [
    [130.81, 196.0, 246.94, 329.63],
    [110.0, 164.81, 261.63, 392.0],
    [87.31, 220.0, 261.63, 329.63],
    [98.0, 146.83, 246.94, 329.63],
  ],
  chordSeconds: 9,
  chordCrossfadeSeconds: 3,
  padGain: 0.04,
  padHarmonic: 0.15,
  padTremoloHz: 0.09,
  padTremoloDepth: 0.3,
  waveGain: 0.02,
  waveCutoffHz: 450,
  wavePeriodsSeconds: [9, 13.5],
  sparkleNotes: [1046.5, 1174.66, 1318.51, 1567.98, 1760.0, 2093.0],
  sparkleGapMinSeconds: 2.5,
  sparkleGapMaxSeconds: 7,
  sparkleDecaySeconds: 2.2,
  sparkleGain: 0.05,
};
