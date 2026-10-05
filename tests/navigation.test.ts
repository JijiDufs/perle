import { describe, expect, it } from 'vitest';
import { newCardsSince } from '../src/core/collection';
import { INITIAL_PLAYER_STATE, type PearlCard } from '../src/core/player';
import { isEcrinUnlocked, TUTORIAL_PEARLS } from '../src/core/tutorial';

const pearl = (serial: number): PearlCard => ({ serial, pearlId: 'white', sizeMm: 6, value: 10, lustre: 'B', cracked: false, foundAt: 0 });

describe('navigation', () => {
  it("l'onglet Écrin se débloque à la fin du tutoriel, ou dès qu'on a un écrin", () => {
    expect(isEcrinUnlocked(INITIAL_PLAYER_STATE)).toBe(false);
    expect(isEcrinUnlocked({ ...INITIAL_PLAYER_STATE, oystersOpened: TUTORIAL_PEARLS.length - 1 })).toBe(false);
    expect(isEcrinUnlocked({ ...INITIAL_PLAYER_STATE, oystersOpened: TUTORIAL_PEARLS.length })).toBe(true);
    expect(isEcrinUnlocked({ ...INITIAL_PLAYER_STATE, ecrins: 1 })).toBe(true);
  });

  it('compte les cartes arrivées depuis la dernière visite', () => {
    const state = { ...INITIAL_PLAYER_STATE, cards: [pearl(1), pearl(4), pearl(6)] };
    expect(newCardsSince(state, 3)).toBe(2);
    expect(newCardsSince(state, 6)).toBe(0);
  });
});
