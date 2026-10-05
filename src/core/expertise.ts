// Expertise à la loupe (cahier §7) : repérer les inclusions d'une pierre pour obtenir un certificat
// qui augmente la valeur du bijou. Une seule expertise par bijou.
import type { Tuning } from '../tuning';
import { jewelRarity, roundValue } from './jewels';
import { gainReputation, reputationFor } from './levels';
import type { JewelCard, PlayerState } from './player';
import { seededRng } from './rng';

export type ExpertiseGrade = 'excellent' | 'bon' | 'non-concluant';

export interface ExpertiseRecord {
  grade: ExpertiseGrade;
  found: number;
  total: number;
  /** Bonus appliqué à la valeur (0,25 = +25 %). */
  bonus: number;
  at: number;
}

/** Une inclusion, en coordonnées du disque de la pierre (centre 0,0 ; rayon 1). */
export interface Inclusion {
  x: number;
  y: number;
  /** Forme dessinée : point, plume ou aiguille. */
  kind: 'point' | 'plume' | 'aiguille';
  angle: number;
}

export const GRADE_LABELS: Record<ExpertiseGrade, string> = {
  excellent: 'Excellent',
  bon: 'Bon',
  'non-concluant': 'Non concluant',
};

/** Seules les pierres précieuses s'expertisent (pas le toc, le strass, l'argent, l'or ou les perles). */
export function isExpertisable(card: JewelCard): boolean {
  return card.jewel.gem !== null && !card.jewel.candy && jewelRarity(card.jewel.rarityId).tier >= 3;
}

export function canExpertise(card: JewelCard): boolean {
  return isExpertisable(card) && !card.expertise;
}

/**
 * Inclusions d'une pierre : positions fixes pour une carte donnée (graine = numéro de série),
 * pour qu'on ne puisse pas relancer jusqu'à une disposition facile.
 * 3 inclusions, 4 pour les pièces ★, 5 pour la légende.
 */
export function inclusionsFor(card: JewelCard): Inclusion[] {
  const tier = jewelRarity(card.jewel.rarityId).tier;
  const count = tier >= 5 ? 5 : tier >= 4 ? 4 : 3;
  const rng = seededRng(card.serial * 7919 + 17);
  const kinds: Inclusion['kind'][] = ['point', 'plume', 'aiguille'];
  const inclusions: Inclusion[] = [];
  let guard = 0;
  while (inclusions.length < count && guard++ < 500) {
    const r = 0.15 + Math.sqrt(rng()) * 0.6;
    const a = rng() * Math.PI * 2;
    const candidate: Inclusion = { x: Math.cos(a) * r, y: Math.sin(a) * r, kind: kinds[Math.floor(rng() * kinds.length)], angle: rng() * Math.PI };
    if (inclusions.every((o) => Math.hypot(o.x - candidate.x, o.y - candidate.y) > 0.35)) inclusions.push(candidate);
  }
  return inclusions;
}

/** Index de l'inclusion sous le viseur (coordonnées du disque), ou -1. */
export function inclusionAt(inclusions: readonly Inclusion[], x: number, y: number, tuning: Tuning): number {
  let best = -1;
  let bestDistance = tuning.expertiseHitRadius;
  inclusions.forEach((inclusion, i) => {
    const d = Math.hypot(inclusion.x - x, inclusion.y - y);
    if (d <= bestDistance) {
      best = i;
      bestDistance = d;
    }
  });
  return best;
}

export function gradeExpertise(found: number, total: number, tuning: Tuning): { grade: ExpertiseGrade; bonus: number } {
  if (total > 0 && found >= total) return { grade: 'excellent', bonus: tuning.expertiseBonusExcellent };
  if (total > 0 && found >= Math.ceil(total * tuning.expertiseGoodRatio)) return { grade: 'bon', bonus: tuning.expertiseBonusGood };
  return { grade: 'non-concluant', bonus: 0 };
}

/** Enregistre l'expertise d'une carte et revalorise le bijou. Sans effet si la carte est déjà expertisée. */
export function recordExpertise(state: PlayerState, serial: number, found: number, total: number, now: number, tuning: Tuning): PlayerState {
  const card = state.jewelCards.find((c) => c.serial === serial);
  if (!card || !canExpertise(card)) return state;
  const { grade, bonus } = gradeExpertise(found, total, tuning);
  const updated: JewelCard = { ...card, value: roundValue(card.value * (1 + bonus)), expertise: { grade, found, total, bonus, at: now } };
  const next = { ...state, jewelCards: state.jewelCards.map((c) => (c.serial === serial ? updated : c)) };
  return gainReputation(next, reputationFor({ kind: 'expertise', certified: bonus > 0 }, tuning), tuning);
}
