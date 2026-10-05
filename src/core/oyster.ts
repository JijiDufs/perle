import type { Tuning } from '../tuning';
import { pearlById, type PearlId } from './catalog';
import { drawPearl, type DrawState } from './draw';
import type { Rng } from './rng';

/** Une huître fermée. Sa perle est décidée dès sa création (la lumière doit en prendre la couleur). */
export interface Oyster {
  pearlId: PearlId;
  /** Taille en mm, 0 pour une huître vide. */
  sizeMm: number;
}

export function createOyster(drawState: DrawState, rng: Rng, tuning: Tuning): { oyster: Oyster; drawState: DrawState } {
  const { pearl, state } = drawPearl(drawState, rng, tuning);
  return { oyster: oysterWith(pearl.id, rng), drawState: state };
}

/** Huître contenant une perle donnée, de taille tirée au hasard dans sa plage. */
export function oysterWith(pearlId: PearlId, rng: Rng): Oyster {
  const [min, max] = pearlById(pearlId).sizeMm;
  return { pearlId, sizeMm: Math.round((min + rng() * (max - min)) * 10) / 10 };
}
