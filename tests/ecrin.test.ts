import { describe, expect, it } from 'vitest';
import { GlintEngine, rollSweetAngle } from '../src/core/glint';
import { INITIAL_JEWEL_DRAW, JEWEL_RARITIES, jewelRarity, rollJewel, rollRareVariant, withVariant } from '../src/core/jewels';
import { ensureEcrin, INITIAL_PLAYER_STATE, recordEcrin, recordOpening, type PlayerState } from '../src/core/player';
import { seededRng } from '../src/core/rng';
import { TUTORIAL_PEARLS } from '../src/core/tutorial';
import { DEFAULT_TUNING } from '../src/tuning';

const t = DEFAULT_TUNING;
/** Sans montée de niveau, pour compter seulement les écrins gagnés en ouvrant des huîtres. */
const noLevels = { ...DEFAULT_TUNING, levelBaseXp: 1e9 };

describe('bijoux', () => {
  it('les probabilités font 100 %', () => {
    expect(JEWEL_RARITIES.reduce((s, j) => s + j.probability, 0)).toBeCloseTo(1, 10);
  });

  it('respecte les probabilités (sans garantie)', () => {
    const rng = seededRng(9);
    const tuning = { ...t, ecrinPityThreshold: Infinity };
    const counts = new Map<string, number>();
    const draws = 100_000;
    for (let i = 0; i < draws; i++) {
      const { jewel } = rollJewel(INITIAL_JEWEL_DRAW, rng, tuning);
      counts.set(jewel.rarityId, (counts.get(jewel.rarityId) ?? 0) + 1);
    }
    for (const rarity of JEWEL_RARITIES) expect((counts.get(rarity.id) ?? 0) / draws).toBeCloseTo(rarity.probability, 2);
  });

  it('garantit un bijou ★ ou mieux après 20 écrins sans', () => {
    const rng = seededRng(4);
    for (let i = 0; i < 500; i++) {
      const { jewel, state } = rollJewel({ sinceStarOrBetter: 20 }, rng, t);
      expect(jewelRarity(jewel.rarityId).tier).toBeGreaterThanOrEqual(4);
      expect(state.sinceStarOrBetter).toBe(0);
    }
  });

  it('donne des bijoux cohérents (toc = bague, légende = diadème, perles = rang de perles)', () => {
    const rng = seededRng(12);
    for (let i = 0; i < 5000; i++) {
      const { jewel } = rollJewel(INITIAL_JEWEL_DRAW, rng, t);
      if (jewel.rarityId === 'toc') expect(jewel.type).toBe('bague');
      if (jewel.rarityId === 'legende') expect(jewel.type).toBe('diademe');
      expect(jewel.pearls).toBe(jewel.rarityId === 'perles');
      expect(jewel.value).toBeGreaterThan(0);
      expect(jewel.name.trim()).not.toBe('');
    }
  });

  it('tire l’angle d’éclat dans la plage prévue', () => {
    const rng = seededRng(1);
    for (let i = 0; i < 1000; i++) {
      const angle = rollSweetAngle(rng, t);
      expect(angle).toBeGreaterThanOrEqual(t.glintMinAngle);
      expect(angle).toBeLessThanOrEqual(t.glintMaxAngle);
    }
  });
});

/** Ouvre jusqu'à `angle` à vitesse modérée ; renvoie l'instant final. */
function openTo(engine: GlintEngine, angle: number, start = 0): number {
  engine.push({ angle: 1, time: start });
  engine.push({ angle: t.popAngle, time: start + 100 });
  let time = start + 100;
  for (let a = t.popAngle; a < angle; a += 2) {
    time += 16;
    engine.push({ angle: a, time });
  }
  time += 16;
  engine.push({ angle, time });
  return time;
}

describe("angle d'éclat", () => {
  it('éclat parfait en tenant le pouce immobile sur l’angle', () => {
    const engine = new GlintEngine(t, 90);
    let time = openTo(engine, 90);
    let perfect = false;
    for (let i = 0; i < 80 && !perfect; i++) {
      time += 16;
      perfect = engine.tick(time).some((e) => e.type === 'perfect');
    }
    expect(perfect).toBe(true);
    expect(time).toBeGreaterThanOrEqual(t.glintHoldMs);
  });

  it('pas d’éclat en restant loin de l’angle', () => {
    const engine = new GlintEngine(t, 90);
    let time = openTo(engine, 60);
    for (let i = 0; i < 200; i++) engine.tick((time += 16));
    expect(engine.perfect).toBe(false);
    expect(engine.closeness).toBe(0);
  });

  it('pas d’éclat si on bouge sans arrêt autour de l’angle', () => {
    const engine = new GlintEngine(t, 90);
    let time = openTo(engine, 84);
    for (let i = 0; i < 200; i++) {
      time += 16;
      engine.push({ angle: 84 + (i % 2 ? 0 : 12), time });
    }
    expect(engine.perfect).toBe(false);
  });

  it('le scintillement augmente en approchant', () => {
    const engine = new GlintEngine(t, 90);
    let time = openTo(engine, 70);
    engine.tick((time += 16));
    const far = engine.closeness;
    engine.push({ angle: 88, time: (time += 16) });
    expect(engine.closeness).toBeGreaterThan(far);
  });

  it('révèle le bijou en ouvrant jusqu’au bout, avec ou sans éclat', () => {
    const engine = new GlintEngine(t, 90);
    const time = openTo(engine, 60);
    const events = engine.push({ angle: 179, time: time + 400 });
    expect(events).toContainEqual({ type: 'reveal', perfect: false });
  });
});

describe('écrins du joueur', () => {
  function openOysters(state: PlayerState, n: number): { state: PlayerState; earned: number } {
    let earned = 0;
    for (let i = 0; i < n; i++) {
      const result = recordOpening({ ...state, currentOyster: { pearlId: 'white', sizeMm: 6 } }, { lustre: 'A', cracked: false }, i, noLevels);
      state = result.state;
      if (result.ecrinEarned) earned++;
    }
    return { state, earned };
  }

  it('offre le premier écrin à la fin du tutoriel, puis un toutes les 8 huîtres', () => {
    const afterTutorial = openOysters(INITIAL_PLAYER_STATE, TUTORIAL_PEARLS.length);
    expect(afterTutorial.state.ecrins).toBe(1);
    const afterMore = openOysters(afterTutorial.state, t.oystersPerEcrin * 2);
    expect(afterMore.earned).toBe(2);
    expect(afterMore.state.ecrins).toBe(3);
  });

  it('ouvre un écrin, garde le même tant qu’il n’est pas fini, puis crée la carte', () => {
    const rng = seededRng(3);
    const start: PlayerState = { ...INITIAL_PLAYER_STATE, ecrins: 2 };
    const opened = ensureEcrin(start, rng, t);
    expect(opened.ecrins).toBe(1);
    expect(ensureEcrin(opened, rng, t)).toBe(opened);
    const base = opened.currentEcrin!.jewel.value;
    const { state, card } = recordEcrin(opened, { perfect: true }, 123, t);
    expect(card.perfect).toBe(true);
    expect(Math.abs(card.value - base * 1.5)).toBeLessThanOrEqual(1); // arrondi à l’euro
    expect(state.currentEcrin).toBeNull();
    expect(state.jewelCards).toHaveLength(1);
    expect(state.nextSerial).toBe(start.nextSerial + 1);
  });

  it('n’ouvre rien sans écrin', () => {
    expect(ensureEcrin(INITIAL_PLAYER_STATE, seededRng(1), t).currentEcrin).toBeNull();
  });
});

describe('variante rare', () => {
  it('apparaît dans environ 12 % des écrins, réparties entre les trois variantes', () => {
    const rng = seededRng(21);
    const counts = new Map<string, number>();
    const draws = 100_000;
    for (let i = 0; i < draws; i++) {
      const v = rollRareVariant(rng, t) ?? 'aucune';
      counts.set(v, (counts.get(v) ?? 0) + 1);
    }
    expect(1 - counts.get('aucune')! / draws).toBeCloseTo(t.glintRareVariantChance, 2);
    for (const id of ['aurore', 'nuit', 'givre']) expect(counts.get(id)! / draws).toBeCloseTo(t.glintRareVariantChance / 3, 2);
  });

  it('transforme le bijou : nom, métal, pierre et texte', () => {
    const { jewel } = rollJewel({ sinceStarOrBetter: 20 }, seededRng(5), t);
    const aurora = withVariant(jewel, 'aurore');
    expect(aurora.name).toBe(`${jewel.name} · Aurore`);
    expect(aurora.metalName).toBe('Or aurore');
    expect(aurora.rarityId).toBe(jewel.rarityId);
    expect(withVariant(jewel, null)).toBe(jewel);
  });

  const pendingWithVariant = (perfect: boolean) => {
    const opened = ensureEcrin({ ...INITIAL_PLAYER_STATE, ecrins: 1 }, seededRng(8), t);
    const state: PlayerState = { ...opened, currentEcrin: { ...opened.currentEcrin!, variantIfPerfect: 'nuit' } };
    const base = state.currentEcrin!.jewel.value;
    return { base, ...recordEcrin(state, { perfect }, 0, t) };
  };

  it('s’applique sur un éclat parfait, avec une valeur ×2', () => {
    const { base, card } = pendingWithVariant(true);
    expect(card.variant).toBe('nuit');
    expect(Math.abs(card.value - base * 2)).toBeLessThanOrEqual(1);
  });

  it('ne s’applique pas sans éclat parfait', () => {
    const { base, card } = pendingWithVariant(false);
    expect(card.variant).toBeNull();
    expect(card.value).toBe(base);
  });

  it('est tirée à l’ouverture de l’écrin et sauvegardée avec lui', () => {
    const opened = ensureEcrin({ ...INITIAL_PLAYER_STATE, ecrins: 1 }, seededRng(8), t);
    expect(opened.currentEcrin).toHaveProperty('variantIfPerfect');
  });
});
