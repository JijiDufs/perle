import { describe, expect, it } from 'vitest';
import { ACHIEVEMENTS, earnedTitles } from '../src/core/achievements';
import { meltCard } from '../src/core/dust';
import { INITIAL_PLAYER_STATE, recordOpening, type PearlCard, type PlayerState } from '../src/core/player';
import { claimQuest, currentQuests } from '../src/core/progression';
import { advanceQuests, dayKey, questsForDay, type DailyQuests } from '../src/core/quests';
import { TUTORIAL_PEARLS } from '../src/core/tutorial';
import { DEFAULT_TUNING } from '../src/tuning';

/** Sans montée de niveau : ses récompenses brouilleraient les comptes. */
const t = { ...DEFAULT_TUNING, levelBaseXp: 1e9 };
const NOON = new Date(2026, 9, 5, 12).getTime();
const afterTutorial: PlayerState = { ...INITIAL_PLAYER_STATE, oystersOpened: TUTORIAL_PEARLS.length };
const open = (state: PlayerState, pearlId: PearlCard['pearlId'], lustre: 'S' | 'A' | 'B' | 'C', cracked = false, now = NOON) =>
  recordOpening({ ...state, currentOyster: { pearlId, sizeMm: 7 } }, { lustre, cracked }, now, t).state;

describe('succès', () => {
  it('ont des identifiants uniques', () => {
    expect(new Set(ACHIEVEMENTS.map((a) => a.id)).size).toBe(ACHIEVEMENTS.length);
  });

  it('se débloquent une seule fois, avec leur récompense', () => {
    const first = open(INITIAL_PLAYER_STATE, 'black', 'B');
    expect(first.achievements['premiere-perle']).toBe(NOON);
    expect(first.achievements['perle-noire']).toBe(NOON);
    expect(first.dust).toBe(2 * t.achievementDustBronze);
    const again = open(first, 'black', 'B', false, NOON + 1);
    expect(again.achievements['perle-noire']).toBe(NOON);
    expect(again.dust).toBe(first.dust);
  });

  it('suivent les séries sans fêlure, et une fêlure remet la série à zéro', () => {
    let state = afterTutorial;
    for (let i = 0; i < 9; i++) state = open(state, 'white', 'B');
    state = open(state, 'white', 'B', true);
    expect(state.stats.crackFreeStreak).toBe(0);
    expect(state.stats.bestCrackFreeStreak).toBe(9);
    expect(state.achievements['sans-felure-10']).toBeUndefined();
    // Une huître vide ne casse pas la série.
    for (let i = 0; i < 9; i++) state = open(state, 'white', 'B');
    state = open(state, 'empty', 'C', true);
    expect(state.stats.crackFreeStreak).toBe(10);
    expect(state.achievements['sans-felure-10']).toBeDefined();
    expect(earnedTitles(state)).toContain('Main de velours');
  });

  it('comptent les doublons fondus', () => {
    const cards: PearlCard[] = [1, 2, 3].map((serial) => ({ serial, pearlId: 'white', sizeMm: 6, value: 10, lustre: 'B', cracked: false, foundAt: 0 }));
    const state = meltCard({ ...afterTutorial, cards }, 2, t);
    expect(state.stats.melted).toBe(1);
  });
});

describe('quêtes du jour', () => {
  it('pas de quête pendant le tutoriel', () => {
    expect(currentQuests(INITIAL_PLAYER_STATE, NOON, t)).toBeNull();
  });

  it('les mêmes trois quêtes toute la journée, de nouvelles le lendemain', () => {
    const today = questsForDay(null, NOON, true, t);
    expect(today.quests).toHaveLength(3);
    expect(new Set(today.quests.map((q) => q.kind)).size).toBe(3);
    expect(questsForDay(null, NOON + 3600_000, true, t)).toEqual(today);
    expect(questsForDay(today, NOON + 24 * 3600_000, true, t).day).toBe(dayKey(NOON + 24 * 3600_000));
  });

  it('sans écrin débloqué, pas de quête d’écrin', () => {
    for (let day = 0; day < 60; day++) {
      const quests = questsForDay(null, NOON + day * 24 * 3600_000, false, t);
      expect(quests.quests.some((q) => q.kind === 'ecrin' || q.kind === 'perfect')).toBe(false);
    }
  });

  it('avancent avec le jeu, se récupèrent une fois, et les trois donnent un écrin', () => {
    const daily: DailyQuests = {
      day: dayKey(NOON),
      bonusClaimed: false,
      quests: [
        { kind: 'open', goal: 2, progress: 0, claimed: false },
        { kind: 'noCrack', goal: 2, progress: 0, claimed: false },
        { kind: 'rare', goal: 1, progress: 0, claimed: false },
      ],
    };
    let state: PlayerState = { ...afterTutorial, quests: daily };
    state = open(state, 'white', 'B', true);
    expect(state.quests!.quests.map((q) => q.progress)).toEqual([1, 0, 0]);
    state = open(state, 'baroque', 'B');
    state = open(state, 'white', 'B');
    expect(state.quests!.quests.map((q) => q.progress)).toEqual([2, 2, 1]);

    const dust = state.dust;
    const ecrins = state.ecrins;
    state = claimQuest(state, 0, NOON, t);
    expect(state.dust).toBe(dust + t.questRewardDust);
    expect(claimQuest(state, 0, NOON, t)).toBe(state);
    state = claimQuest(claimQuest(state, 1, NOON, t), 2, NOON, t);
    expect(state.ecrins).toBe(ecrins + 1);
    expect(state.quests!.bonusClaimed).toBe(true);
  });

  it('une série sans fêlure repart de zéro à la fêlure', () => {
    const daily = questsForDay(null, NOON, true, t);
    const withStreak = { ...daily, quests: [{ kind: 'noCrack' as const, goal: 3, progress: 2, claimed: false }] };
    const cracked = advanceQuests(withStreak, { kind: 'oyster', tier: 1, lustre: 'B', cracked: true, empty: false });
    expect(cracked.quests[0].progress).toBe(0);
  });
});
