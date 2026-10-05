import { describe, expect, it } from 'vitest';
import { canExpertise, gradeExpertise, inclusionAt, inclusionsFor, isExpertisable, recordExpertise } from '../src/core/expertise';
import { rollJewel, type Jewel, type JewelRarityId } from '../src/core/jewels';
import { INITIAL_PLAYER_STATE, type JewelCard, type PlayerState } from '../src/core/player';
import { seededRng } from '../src/core/rng';
import { DEFAULT_TUNING } from '../src/tuning';

const t = DEFAULT_TUNING;

function jewelOf(rarityId: JewelRarityId): Jewel {
  const rng = seededRng(3);
  for (let i = 0; i < 100_000; i++) {
    const { jewel } = rollJewel({ sinceStarOrBetter: 0 }, rng, { ...t, ecrinPityThreshold: Infinity });
    if (jewel.rarityId === rarityId) return jewel;
  }
  throw new Error(rarityId);
}

const cardOf = (rarityId: JewelRarityId, serial = 10): JewelCard => ({ serial, jewel: jewelOf(rarityId), value: 1000, perfect: false, foundAt: 0 });

describe('expertise à la loupe', () => {
  it('ne concerne que les pierres précieuses', () => {
    for (const id of ['saphir', 'emeraude', 'rubis', 'diamant', 'legende'] as const) expect(isExpertisable(cardOf(id))).toBe(true);
    for (const id of ['toc', 'fantaisie', 'argent', 'or', 'perles'] as const) expect(isExpertisable(cardOf(id))).toBe(false);
  });

  it('place 3, 4 ou 5 inclusions selon la rareté, toujours au même endroit pour une carte', () => {
    expect(inclusionsFor(cardOf('saphir'))).toHaveLength(3);
    expect(inclusionsFor(cardOf('diamant'))).toHaveLength(4);
    expect(inclusionsFor(cardOf('legende'))).toHaveLength(5);
    expect(inclusionsFor(cardOf('rubis', 42))).toEqual(inclusionsFor(cardOf('rubis', 42)));
    expect(inclusionsFor(cardOf('rubis', 42))).not.toEqual(inclusionsFor(cardOf('rubis', 43)));
  });

  it('garde les inclusions dans la pierre et assez espacées', () => {
    for (let serial = 1; serial < 200; serial++) {
      const list = inclusionsFor(cardOf('legende', serial));
      for (const a of list) {
        expect(Math.hypot(a.x, a.y)).toBeLessThanOrEqual(0.76);
        for (const b of list) if (a !== b) expect(Math.hypot(a.x - b.x, a.y - b.y)).toBeGreaterThan(0.35);
      }
    }
  });

  it('trouve l’inclusion sous le viseur, rien à côté', () => {
    const list = inclusionsFor(cardOf('diamant'));
    expect(inclusionAt(list, list[2].x + 0.02, list[2].y, t)).toBe(2);
    expect(inclusionAt(list, 5, 5, t)).toBe(-1);
  });

  it('note : tout trouvé = Excellent, deux tiers = Bon, sinon non concluant', () => {
    expect(gradeExpertise(4, 4, t)).toEqual({ grade: 'excellent', bonus: 0.25 });
    expect(gradeExpertise(3, 4, t)).toEqual({ grade: 'bon', bonus: 0.12 });
    expect(gradeExpertise(2, 3, t).grade).toBe('bon');
    expect(gradeExpertise(1, 3, t)).toEqual({ grade: 'non-concluant', bonus: 0 });
  });

  it('revalorise le bijou une seule fois', () => {
    const state: PlayerState = { ...INITIAL_PLAYER_STATE, jewelCards: [cardOf('rubis', 7)] };
    const after = recordExpertise(state, 7, 3, 3, 123, t);
    expect(after.jewelCards[0].value).toBe(1250);
    expect(after.jewelCards[0].expertise).toMatchObject({ grade: 'excellent', found: 3, total: 3 });
    expect(canExpertise(after.jewelCards[0])).toBe(false);
    expect(recordExpertise(after, 7, 3, 3, 456, t)).toBe(after);
  });
});
