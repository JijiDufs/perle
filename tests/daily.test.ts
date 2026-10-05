import { describe, expect, it } from 'vitest';
import { CALENDAR, canClaimDaily, claimDaily } from '../src/core/daily';
import { INITIAL_PLAYER_STATE, type PlayerState } from '../src/core/player';
import { TUTORIAL_PEARLS } from '../src/core/tutorial';
import { DEFAULT_TUNING } from '../src/tuning';

const t = { ...DEFAULT_TUNING, levelBaseXp: 1e9, achievementDustBronze: 0, achievementDustSilver: 0, achievementDustGold: 0 };
const day = (n: number) => new Date(2026, 9, 5 + n, 10).getTime();
const player: PlayerState = { ...INITIAL_PLAYER_STATE, oystersOpened: TUTORIAL_PEARLS.length };

describe('calendrier et série', () => {
  it('pas pendant le tutoriel, une fois par jour', () => {
    expect(canClaimDaily(INITIAL_PLAYER_STATE, day(0))).toBe(false);
    const claimed = claimDaily(player, day(0), t);
    expect(canClaimDaily(claimed, day(0) + 3600_000)).toBe(false);
    expect(claimDaily(claimed, day(0), t)).toBe(claimed);
    expect(canClaimDaily(claimed, day(1))).toBe(true);
  });

  it('donne la case du jour et avance ; écrin le 7e jour, puis recommence', () => {
    let state = player;
    for (let i = 0; i < 7; i++) state = claimDaily(state, day(i), t);
    expect(state.ecrins).toBe(CALENDAR.reduce((n, r) => n + r.ecrins, 0));
    expect(state.dust).toBe(CALENDAR.reduce((n, r) => n + r.dust, 0));
    expect(state.login.calendarIndex).toBe(0);
    expect(state.login.streak).toBe(7);
    expect(state.achievements['serie-7']).toBeDefined();
  });

  it('un jour manqué : le joker garde la série, une fois par semaine', () => {
    let state = claimDaily(claimDaily(player, day(0), t), day(1), t);
    state = claimDaily(state, day(3), t); // jour 2 manqué : joker
    expect(state.login.streak).toBe(3);
    state = claimDaily(state, day(5), t); // jour 4 manqué : joker déjà utilisé
    expect(state.login.streak).toBe(1);
    expect(state.login.bestStreak).toBe(3);
  });

  it('deux jours manqués : la série repart', () => {
    const state = claimDaily(claimDaily(player, day(0), t), day(3), t);
    expect(state.login.streak).toBe(1);
  });
});
