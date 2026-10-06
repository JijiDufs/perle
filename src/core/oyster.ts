import type { Tuning } from '../tuning';
import { pearlById, type PearlId } from './catalog';
import { drawPearl, type DrawState } from './draw';
import { rollTraits, type PearlTraits } from './pearlTraits';
import type { Rng } from './rng';

/** Une huître fermée. Sa perle est décidée dès sa création (la lumière doit en prendre la couleur). */
export interface Oyster {
  /** 'empty' quand l'huître cache une trouvaille à la place d'une perle. */
  pearlId: PearlId;
  /** Taille en mm, 0 pour une huître vide. */
  sizeMm: number;
  /** Trouvaille cachée à la place de la perle (core/finds.ts). */
  findId?: string;
  /** Forme, reflet et marque de la perle (core/pearlTraits.ts), tirés avec elle. */
  traits?: PearlTraits;
}

export function createOyster(drawState: DrawState, rng: Rng, tuning: Tuning): { oyster: Oyster; drawState: DrawState } {
  const { pearl, find, state } = drawPearl(drawState, rng, tuning);
  if (find) return { oyster: { pearlId: 'empty', sizeMm: 0, findId: find.id }, drawState: state };
  return { oyster: oysterWith(pearl.id, rng, tuning.pearlMarkChance), drawState: state };
}

/**
 * Huître contenant une perle donnée, de taille tirée au hasard dans sa plage, avec ses traits.
 * `markChance` : chance d'une marque rare (0 par défaut : tutoriel).
 */
export function oysterWith(pearlId: PearlId, rng: Rng, markChance = 0): Oyster {
  const [min, max] = pearlById(pearlId).sizeMm;
  const sizeMm = Math.round((min + rng() * (max - min)) * 10) / 10;
  if (pearlId === 'empty') return { pearlId, sizeMm };
  return { pearlId, sizeMm, traits: rollTraits(pearlId, rng, markChance) };
}
