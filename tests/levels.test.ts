import { describe, expect, it } from 'vitest';
import { recordExpertise } from '../src/core/expertise';
import { gainReputation, levelFromXp, levelReward, rankForLevel, reputationFor, xpToNext } from '../src/core/levels';
import { INITIAL_PLAYER_STATE, recordOpening, type PlayerState } from '../src/core/player';
import { DEFAULT_TUNING } from '../src/tuning';

const t = DEFAULT_TUNING;

describe('niveaux et réputation', () => {
  it('déduit le niveau de la réputation', () => {
    expect(levelFromXp(0, t)).toEqual({ level: 1, into: 0, needed: xpToNext(1, t) });
    const two = xpToNext(1, t);
    expect(levelFromXp(two, t).level).toBe(2);
    expect(levelFromXp(two + xpToNext(2, t) - 1, t)).toEqual({ level: 2, into: xpToNext(2, t) - 1, needed: xpToNext(2, t) });
    expect(levelFromXp(1e12, t).level).toBe(t.maxLevel);
  });

  it('demande de plus en plus de réputation par niveau', () => {
    for (let level = 1; level < 60; level++) expect(xpToNext(level + 1, t)).toBeGreaterThan(xpToNext(level, t));
  });

  it('suit les rangs du cahier', () => {
    expect(rankForLevel(1).title).toBe('Pêcheur');
    expect(rankForLevel(4).title).toBe('Pêcheur');
    expect(rankForLevel(5).title).toBe('Perlier');
    expect(rankForLevel(52).title).toBe('Maison de haute joaillerie');
  });

  it('récompense chaque niveau une seule fois, avec un écrin tous les 3 niveaux et à chaque rang', () => {
    expect(levelReward(2, t).ecrins).toBe(0);
    expect(levelReward(3, t).ecrins).toBe(1);
    expect(levelReward(5, t)).toMatchObject({ ecrins: 1, rank: { title: 'Perlier' } });
    const toThree = xpToNext(1, t) + xpToNext(2, t);
    const state = gainReputation(INITIAL_PLAYER_STATE, toThree, t);
    expect(state.rewardedLevel).toBe(3);
    expect(state.dust).toBe(2 * t.levelRewardDust);
    expect(state.ecrins).toBe(1);
    expect(state.stock.count).toBe(INITIAL_PLAYER_STATE.stock.count + 2 * t.levelRewardOysters);
    // Un peu plus de réputation sans changer de niveau : rien de plus.
    const again = gainReputation(state, 1, t);
    expect(again.dust).toBe(state.dust);
    expect(again.rewardedLevel).toBe(3);
  });

  it('valorise la rareté, le lustre et les découvertes', () => {
    const base = { kind: 'oyster', lustre: 'B', cracked: false, discovery: false } as const;
    expect(reputationFor({ ...base, pearlId: 'empty' }, t)).toBe(t.repOyster);
    expect(reputationFor({ ...base, pearlId: 'golden' }, t)).toBeGreaterThan(reputationFor({ ...base, pearlId: 'white' }, t));
    expect(reputationFor({ ...base, pearlId: 'white', lustre: 'S' }, t)).toBe(reputationFor({ ...base, pearlId: 'white' }, t) + t.repLustreS);
    expect(reputationFor({ ...base, pearlId: 'white', lustre: 'S', cracked: true }, t)).toBe(reputationFor({ ...base, pearlId: 'white' }, t));
    expect(reputationFor({ ...base, pearlId: 'white', discovery: true }, t)).toBe(reputationFor({ ...base, pearlId: 'white' }, t) + t.repDiscovery);
  });

  it("ouvrir une huître rapporte de la réputation, avec un bonus de découverte la première fois", () => {
    const withOyster: PlayerState = { ...INITIAL_PLAYER_STATE, currentOyster: { pearlId: 'white', sizeMm: 6 } };
    const first = recordOpening(withOyster, { lustre: 'B', cracked: false }, 0, t).state;
    const second = recordOpening({ ...first, currentOyster: { pearlId: 'white', sizeMm: 6 } }, { lustre: 'B', cracked: false }, 0, t).state;
    expect(first.reputation).toBe(t.repOyster + t.repPerTier + t.repDiscovery);
    expect(second.reputation - first.reputation).toBe(t.repOyster + t.repPerTier);
  });

  it('une expertise sans certificat ne rapporte rien', () => {
    expect(recordExpertise(INITIAL_PLAYER_STATE, 999, 0, 3, 0, t)).toBe(INITIAL_PLAYER_STATE);
  });
});
