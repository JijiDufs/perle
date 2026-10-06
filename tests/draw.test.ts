import { describe, expect, it } from 'vitest';
import { FIND_PROBABILITY, PEARLS } from '../src/core/catalog';
import { drawPearl, INITIAL_DRAW_STATE, type DrawState } from '../src/core/draw';
import { seededRng } from '../src/core/rng';
import { DEFAULT_TUNING } from '../src/tuning';

describe('catalogue', () => {
  it('les probabilités font 100 % avec les trouvailles', () => {
    const total = PEARLS.reduce((s, p) => s + p.probability, 0) + FIND_PROBABILITY;
    expect(total).toBeCloseTo(1, 10);
  });
});

describe('tirage', () => {
  it('respecte les probabilités du catalogue (sans garantie)', () => {
    const rng = seededRng(42);
    const tuning = { ...DEFAULT_TUNING, pityThreshold: Infinity };
    const counts = new Map<string, number>();
    const draws = 200_000;
    for (let i = 0; i < draws; i++) {
      const { pearl, find } = drawPearl(INITIAL_DRAW_STATE, rng, tuning);
      const key = find ? 'find' : pearl.id;
      counts.set(key, (counts.get(key) ?? 0) + 1);
    }
    for (const pearl of PEARLS) {
      expect((counts.get(pearl.id) ?? 0) / draws).toBeCloseTo(pearl.probability, 2);
    }
    expect((counts.get('find') ?? 0) / draws).toBeCloseTo(FIND_PROBABILITY, 2);
  });

  it('garantit une perle dorée ou mieux après 25 huîtres sans', () => {
    const rng = seededRng(1);
    const state: DrawState = { sinceGoldenOrBetter: 25 };
    for (let i = 0; i < 1000; i++) {
      const result = drawPearl(state, rng, DEFAULT_TUNING);
      expect(result.pearl.goldenOrBetter).toBe(true);
      expect(result.find).toBeNull();
    }
  });

  it("n'active pas la garantie à 24", () => {
    const rng = seededRng(3);
    const state: DrawState = { sinceGoldenOrBetter: 24 };
    const results = Array.from({ length: 500 }, () => drawPearl(state, rng, DEFAULT_TUNING).pearl.goldenOrBetter);
    expect(results.some((r) => !r)).toBe(true);
  });

  it('remet le compteur à zéro après une perle dorée ou mieux, sinon l’incrémente', () => {
    const rng = seededRng(7);
    let state = INITIAL_DRAW_STATE;
    for (let i = 0; i < 2000; i++) {
      const before = state.sinceGoldenOrBetter;
      const result = drawPearl(state, rng, DEFAULT_TUNING);
      expect(result.state.sinceGoldenOrBetter).toBe(result.pearl.goldenOrBetter ? 0 : before + 1);
      expect(result.state.sinceGoldenOrBetter).toBeLessThanOrEqual(DEFAULT_TUNING.pityThreshold);
      state = result.state;
    }
  });
});
