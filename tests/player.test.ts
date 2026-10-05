import { describe, expect, it } from 'vitest';
import { ensureOyster, INITIAL_PLAYER_STATE, pearlValue, recordOpening, type PlayerState } from '../src/core/player';
import { seededRng } from '../src/core/rng';
import { TUTORIAL_PEARLS } from '../src/core/tutorial';
import { thumbDistanceToAngle } from '../src/input/thumb';
import { DEFAULT_TUNING } from '../src/tuning';

describe('joueur', () => {
  it("garde la même huître tant qu'elle n'est pas ouverte (pas de relance en rechargeant)", () => {
    const rng = seededRng(5);
    const first = ensureOyster(INITIAL_PLAYER_STATE, rng, DEFAULT_TUNING, 0);
    const again = ensureOyster(first, rng, DEFAULT_TUNING, 0);
    expect(again).toBe(first);
  });

  it('crée une carte numérotée pour une perle, rien pour une huître vide', () => {
    const withPearl: PlayerState = { ...INITIAL_PLAYER_STATE, currentOyster: { pearlId: 'white', sizeMm: 6.5 } };
    const first = recordOpening(withPearl, { lustre: 'A', cracked: false }, 1000);
    expect(first.card).toMatchObject({ serial: 1, pearlId: 'white', lustre: 'A' });
    expect(first.state.currentOyster).toBeNull();
    expect(first.state.nextSerial).toBe(2);

    const empty: PlayerState = { ...first.state, currentOyster: { pearlId: 'empty', sizeMm: 0 } };
    const second = recordOpening(empty, { lustre: 'S', cracked: false }, 2000);
    expect(second.card).toBeNull();
    expect(second.state.cards).toHaveLength(1);
    expect(second.state.oystersOpened).toBe(2);
  });

  it('déroule les huîtres du tutoriel dans l’ordre, puis tire librement', () => {
    const rng = seededRng(11);
    let state = INITIAL_PLAYER_STATE;
    const seen: string[] = [];
    for (let i = 0; i < TUTORIAL_PEARLS.length; i++) {
      state = ensureOyster(state, rng, { ...DEFAULT_TUNING, oysterStockMax: 1000 }, i);
      seen.push(state.currentOyster!.pearlId);
      state = recordOpening(state, { lustre: 'A', cracked: false }, i).state;
    }
    expect(seen).toEqual(TUTORIAL_PEARLS);
    expect(seen[0]).toBe('rose');
    expect(seen).toContain('empty');
    expect(state.draw.sinceGoldenOrBetter).toBe(TUTORIAL_PEARLS.length);
    // Après le tutoriel, le tirage reprend : sur 200 huîtres, on ne retombe pas sur le script.
    const after = new Set<string>();
    state = { ...state, stock: { count: 1000, lastRefillAt: 0 } };
    for (let i = 0; i < 200; i++) {
      state = ensureOyster(state, rng, { ...DEFAULT_TUNING, oysterStockMax: 1000 }, i);
      after.add(state.currentOyster!.pearlId);
      state = recordOpening(state, { lustre: 'A', cracked: false }, i).state;
    }
    expect(after.size).toBeGreaterThan(4);
  });

  it('offre les huîtres du tutoriel, puis consomme le stock et s’arrête quand il est vide', () => {
    const rng = seededRng(2);
    const t = { ...DEFAULT_TUNING, oysterStockMax: 3, oysterRechargeMinutes: 20 };
    let state: PlayerState = { ...INITIAL_PLAYER_STATE, stock: { count: 3, lastRefillAt: 0 } };
    let opened = 0;
    for (let i = 0; i < 20; i++) {
      state = ensureOyster(state, rng, t, 0);
      if (!state.currentOyster) break;
      state = recordOpening(state, { lustre: 'A', cracked: false }, 0).state;
      opened++;
    }
    expect(opened).toBe(TUTORIAL_PEARLS.length + 3);
    expect(state.stock.count).toBe(0);
    // 20 minutes plus tard, une huître est revenue.
    expect(ensureOyster(state, rng, t, 20 * 60_000).currentOyster).not.toBeNull();
  });

  it('divise la valeur par deux si la perle est fêlée', () => {
    // À un point d'arrondi près.
    expect(Math.abs(pearlValue('black', 10, true) - pearlValue('black', 10, false) / 2)).toBeLessThanOrEqual(1);
  });
});

describe('geste du pouce', () => {
  const t = DEFAULT_TUNING;

  it('bouge à peine pendant la résistance puis saute au pop', () => {
    const justBefore = thumbDistanceToAngle(t.resistanceDistance - 0.01, t);
    expect(justBefore).toBeLessThan(t.popAngle * t.resistanceAngleRatio + 0.01);
    expect(thumbDistanceToAngle(t.resistanceDistance, t)).toBe(t.popAngle);
  });

  it('atteint 180° au bout de la course, sans dépasser', () => {
    expect(thumbDistanceToAngle(t.resistanceDistance + t.fullOpenDistance, t)).toBeCloseTo(180);
    expect(thumbDistanceToAngle(10_000, t)).toBe(180);
  });

  it('est croissant', () => {
    let previous = -1;
    for (let d = 0; d < 600; d += 3) {
      const angle = thumbDistanceToAngle(d, t);
      expect(angle).toBeGreaterThanOrEqual(previous);
      previous = angle;
    }
  });
});
