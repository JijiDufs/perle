// Garde-fous de l'économie de l'app iOS (docs/duo-gadget.md §6 quater).
import { describe, expect, it } from 'vitest';
import { APP_CONSUMABLES, APP_ECONOMY, APP_FISH_THIEF, APP_LEVELS, APP_SELL_DUST_BY_TIER, APP_SKINS } from '../src/core/appEconomy';
import { FIND_PROBABILITY, PEARLS, pearlTier } from '../src/core/catalog';
import { levelFromXp, xpToNext } from '../src/core/levels';
import { DEFAULT_TUNING as t } from '../src/tuning';

/** Poussière moyenne par huître si tout est en double. */
const dustPerOyster = PEARLS.reduce((sum, p) => sum + p.probability * APP_SELL_DUST_BY_TIER[pearlTier(p.id)], 0);

describe('économie de l’app iOS', () => {
  it('la revente rapporte environ 2,5 ✦ par huître', () => {
    expect(dustPerOyster).toBeGreaterThan(2);
    expect(dustPerOyster).toBeLessThan(3);
    expect(FIND_PROBABILITY).toBeLessThan(0.1);
  });

  it('le bénitier demande environ trois semaines de jeu régulier', () => {
    const benitier = APP_SKINS.find((s) => s.id === 'benitier')!;
    const missions = APP_ECONOMY.missionsPerDay * APP_ECONOMY.missionRewardDust + APP_ECONOMY.missionBonusDust;
    const regularDay = 30 * dustPerOyster + missions;
    const days = benitier.dustPrice! / regularDay;
    expect(days).toBeGreaterThan(14);
    expect(days).toBeLessThan(35);
  });

  it('le poisson voleur ne prend que des perles ordinaires, de temps en temps', () => {
    expect(APP_FISH_THIEF.maxTier).toBeLessThanOrEqual(1);
    const stealable = PEARLS.filter((p) => p.glow !== null && pearlTier(p.id) <= APP_FISH_THIEF.maxTier);
    expect(stealable.every((p) => !p.goldenOrBetter)).toBe(true);
    // Une huître sur 12 à 25 environ : une surprise, pas une punition.
    const share = stealable.reduce((sum, p) => sum + p.probability, 0) * (1 - FIND_PROBABILITY) * APP_FISH_THIEF.chance;
    expect(share).toBeGreaterThan(0.04);
    expect(share).toBeLessThan(0.085);
    // On a le temps de le toucher.
    expect(APP_FISH_THIEF.fleeMs).toBeGreaterThanOrEqual(2000);
  });

  it('les pubs d’une journée rapportent moins que « Marée haute »', () => {
    const tide = APP_CONSUMABLES.find((c) => c.id === 'app.pearlinc.oysters.10')!;
    expect(APP_ECONOMY.rewardedAdOysters * APP_ECONOMY.rewardedAdsPerDay).toBeLessThan(tide.oysters);
  });

  it('acheter le bénitier en poussière coûte plus cher que l’acheter directement', () => {
    // Le plus gros pack qui ne suffit pas (1 200 ✦) coûte déjà plus que le skin (prix StoreKit, voir §6 ter).
    const packs = APP_CONSUMABLES.filter((c) => c.dust > 0).map((c) => c.dust);
    const benitier = APP_SKINS.find((s) => s.id === 'benitier')!;
    expect(packs.filter((d) => d >= benitier.dustPrice!).length).toBe(1);
  });

  it('l’huître d’or ne s’obtient qu’en achat', () => {
    const gold = APP_SKINS.find((s) => s.id === 'or')!;
    expect(gold.dustPrice).toBeNull();
    expect(gold.productId).not.toBeNull();
  });

  it('les 10 premiers niveaux vont plus vite, puis la courbe rejoint celle de la webapp', () => {
    const fast = APP_LEVELS.fastStart;
    for (let level = 1; level < fast.levels; level++) {
      expect(xpToNext(level, t, fast)).toBeLessThan(xpToNext(level, t));
      expect(xpToNext(level + 1, t, fast)).toBeGreaterThan(xpToNext(level, t, fast));
    }
    for (let level = fast.levels; level <= 60; level++) expect(xpToNext(level, t, fast)).toBe(xpToNext(level, t));
    // Première séance (4 huîtres du tutoriel + 10 du stock, ≈ 18 de réputation chacune, 5 découvertes) : niveau 4 ou 5.
    expect(levelFromXp(14 * 18 + 5 * t.repDiscovery, t, fast).level).toBeGreaterThanOrEqual(4);
  });

  it('le niveau 50 arrive en 4 à 6 mois de jeu régulier', () => {
    // Huître moyenne : rareté, et un lustre A une fois sur deux.
    const perOyster = PEARLS.reduce((sum, p) => sum + p.probability * (p.glow === null ? t.repOyster
      : t.repOyster + t.repPerTier * pearlTier(p.id) + t.repLustreA / 2), 0);
    const regularDay = 30 * perOyster + APP_ECONOMY.missionsPerDay * APP_LEVELS.missionReputation + APP_LEVELS.calendarReputation;
    let to50 = 0;
    for (let level = 1; level < 50; level++) to50 += xpToNext(level, t, APP_LEVELS.fastStart);
    const months = to50 / regularDay / 30;
    expect(months).toBeGreaterThan(4);
    expect(months).toBeLessThan(6);
  });

  it('les niveaux donnent surtout des huîtres, peu de poussière d’or', () => {
    expect(APP_LEVELS.rewardOysters * APP_ECONOMY.oysterDustPrice).toBeGreaterThan(10 * APP_LEVELS.rewardDust);
    // Les dix premiers niveaux (deux rangs compris) rapportent moins d'une journée de poussière d'un joueur régulier.
    expect(9 * APP_LEVELS.rewardDust + 2 * APP_LEVELS.rankRewardDust).toBeLessThan(105);
  });

  it('un seul skin offert au départ', () => {
    expect(APP_SKINS.filter((s) => s.grant === 'start').map((s) => s.id)).toEqual(['lagon']);
  });
});
