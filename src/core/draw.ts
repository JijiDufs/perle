import type { Tuning } from '../tuning';
import { FIND_PROBABILITY, pearlById, PEARLS, type PearlType } from './catalog';
import { rollFind, type FindType } from './finds';
import type { Rng } from './rng';

export interface DrawState {
  /** Huîtres d'affilée sans perle dorée ou mieux. */
  sinceGoldenOrBetter: number;
}

export const INITIAL_DRAW_STATE: DrawState = { sinceGoldenOrBetter: 0 };

/** Vrai si la prochaine huître est garantie dorée ou mieux. */
export function isPityActive(state: DrawState, tuning: Tuning): boolean {
  return state.sinceGoldenOrBetter >= tuning.pityThreshold;
}

/**
 * Tire le contenu d'une huître selon les probabilités du catalogue : une perle, ou parfois
 * une trouvaille à la place (pearl = huître vide, find = la trouvaille).
 * Si la garantie est active, le tirage se fait parmi les perles dorées ou mieux,
 * au prorata de leurs probabilités (pas de trouvaille).
 */
export function drawPearl(state: DrawState, rng: Rng, tuning: Tuning): { pearl: PearlType; find: FindType | null; state: DrawState } {
  const pity = isPityActive(state, tuning);
  if (!pity && rng() < FIND_PROBABILITY) {
    return { pearl: pearlById('empty'), find: rollFind(rng), state: { sinceGoldenOrBetter: state.sinceGoldenOrBetter + 1 } };
  }
  const pearl = pickWeighted(pity ? PEARLS.filter((p) => p.goldenOrBetter) : PEARLS, rng);
  return {
    pearl,
    find: null,
    state: { sinceGoldenOrBetter: pearl.goldenOrBetter ? 0 : state.sinceGoldenOrBetter + 1 },
  };
}

function pickWeighted(pool: readonly PearlType[], rng: Rng): PearlType {
  const total = pool.reduce((sum, p) => sum + p.probability, 0);
  let roll = rng() * total;
  for (const pearl of pool) {
    roll -= pearl.probability;
    if (roll < 0) return pearl;
  }
  return pool[pool.length - 1];
}
