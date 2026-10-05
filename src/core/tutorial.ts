import type { PearlId } from './catalog';

/**
 * Les premières huîtres d'un joueur sont écrites à l'avance (cahier §15) :
 * 1. une perle rosée garantie, pour une première révélation réussie ;
 * 2-4. trois huîtres de plus, dont une vide pour faire comprendre le hasard.
 * Ensuite, tirage normal. Elles comptent normalement pour la garantie « dorée ou mieux ».
 */
export const TUTORIAL_PEARLS: readonly PearlId[] = ['rose', 'white', 'empty', 'baroque'];

/** Perle imposée pour la n-ième huître (0 = la première), ou null si le tirage est libre. */
export function scriptedPearl(oystersOpened: number): PearlId | null {
  return TUTORIAL_PEARLS[oystersOpened] ?? null;
}

export function isInTutorial(oystersOpened: number): boolean {
  return oystersOpened < TUTORIAL_PEARLS.length;
}

/** La toute première perle ne peut pas se fêler : la zone fragile s'apprend à partir de la 2e huître. */
export function isCrackProtected(oystersOpened: number): boolean {
  return oystersOpened === 0;
}
