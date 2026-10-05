import { describe, expect, it } from 'vitest';
import { canCraft, craft, craftStars, isAtelierUnlocked, pickPearls, RECIPES } from '../src/core/atelier';
import { xpToNext } from '../src/core/levels';
import { INITIAL_PLAYER_STATE, type PearlCard, type PlayerState } from '../src/core/player';
import { judgeSetting, SettingEngine } from '../src/core/setting';
import { DEFAULT_TUNING } from '../src/tuning';

const t = DEFAULT_TUNING;
const xpForLevel = (level: number) => Array.from({ length: level - 1 }, (_, i) => xpToNext(i + 1, t)).reduce((a, b) => a + b, 0);
const pearl = (serial: number, pearlId: PearlCard['pearlId'], lustre: PearlCard['lustre'] = 'B', value = 10, cracked = false): PearlCard => ({
  serial,
  pearlId,
  sizeMm: 6,
  value,
  lustre,
  cracked,
  foundAt: 0,
});
const crafter = (cards: PearlCard[], level = 8, dust = 100): PlayerState => ({ ...INITIAL_PLAYER_STATE, oystersOpened: 40, reputation: xpForLevel(level), rewardedLevel: level, cards, dust, nextSerial: 100 });
const perfect = judgeSetting(600, [1.5, 1.6, 1.55, 1.6], t);

describe('sertissage', () => {
  it('juge la fermeture : parfaite, brusque, hésitante', () => {
    expect(perfect.verdict).toBe('parfait');
    expect(judgeSetting(120, [8, 8, 8], t).verdict).toBe('brusque');
    expect(judgeSetting(2600, [0.4, 0.4, 0.4], t).verdict).toBe('hesitant');
    expect(judgeSetting(120, [8, 8, 8], t).score).toBeLessThan(perfect.score);
  });

  it('le moteur termine à la fermeture complète ; lâcher avant recommence', () => {
    const engine = new SettingEngine(t);
    engine.push({ closure: 0.1, time: 0 });
    engine.push({ closure: 0.5, time: 300 });
    engine.release();
    expect(engine.closure).toBe(0);
    for (let i = 0; i <= 10; i++) engine.push({ closure: i / 10, time: 1000 + i * 60 });
    expect(engine.done).toBe(true);
    expect(engine.result!.durationMs).toBeGreaterThan(0);
  });
});

describe('atelier', () => {
  it('ouvre au niveau 5', () => {
    expect(isAtelierUnlocked(crafter([], 4), t)).toBe(false);
    expect(isAtelierUnlocked(crafter([], 5), t)).toBe(true);
  });

  it('garde un exemplaire de chaque perle quand c’est possible, et prend les meilleures', () => {
    const cards = [pearl(1, 'white', 'C', 8), pearl(2, 'white', 'S', 9), pearl(3, 'white', 'A', 12), pearl(4, 'white', 'B', 7)];
    const marée = RECIPES.find((r) => r.id === 'maree-basse')!;
    const pick = pickPearls(crafter(cards), marée);
    expect(pick.missing).toBe(0);
    expect(pick.lastCopy).toBe(false);
    expect(pick.cards.map((c) => c.serial)).not.toContain(3); // la plus précieuse est gardée
    expect(pick.cards.map((c) => c.serial)).toEqual([2, 4, 1]);
    const short = pickPearls(crafter(cards.slice(0, 3)), marée);
    expect(short.lastCopy).toBe(true);
  });

  it('fabrique : consomme perles et monture, crée une carte notée', () => {
    const recipe = RECIPES.find((r) => r.id === 'jumelles')!;
    const state = crafter([pearl(1, 'rose', 'S', 18), pearl(2, 'rose', 'S', 20), pearl(3, 'rose', 'A', 25)]);
    expect(canCraft(state, recipe, t)).toBe(true);
    // Sans récompense de succès ni de niveau, pour voir seulement le prix de la monture.
    const quiet = { ...t, levelRewardDust: 0, achievementDustBronze: 0, achievementDustSilver: 0, achievementDustGold: 0 };
    const result = craft(state, 'jumelles', perfect, 5, quiet)!;
    expect(result.state.cards.map((c) => c.serial)).toEqual([3]);
    expect(result.state.dust).toBe(state.dust - 10);
    expect(result.card.stars).toBe(5);
    expect(result.card.serial).toBe(100);
    expect(result.state.craftedCards).toHaveLength(1);
    expect(result.state.stats.crafted).toBe(1);
    expect(result.state.achievements['fait-main']).toBeDefined();
  });

  it('refuse sans perles, sans poussière, ou avant le niveau de la recette', () => {
    const rivage = RECIPES.find((r) => r.id === 'rivage')!;
    const whites = Array.from({ length: 8 }, (_, i) => pearl(i + 1, 'white'));
    expect(canCraft(crafter(whites.slice(0, 5)), rivage, t)).toBe(false);
    expect(canCraft(crafter(whites, 8, 0), rivage, t)).toBe(false);
    expect(canCraft(crafter(whites, 7), rivage, t)).toBe(false);
    expect(canCraft(crafter(whites, 8), rivage, t)).toBe(true);
    expect(craft(crafter(whites, 7), 'rivage', perfect, 0, t)).toBeNull();
  });

  it('étoiles : matériaux et geste', () => {
    expect(craftStars(1, 1)).toBe(5);
    expect(craftStars(0, 0)).toBe(1);
    expect(craftStars(0.6, 0.5)).toBe(3);
  });
});
