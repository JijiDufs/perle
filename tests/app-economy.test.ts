// Garde-fous de l'économie de l'app iOS (docs/duo-gadget.md §6 quater).
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { ACHIEVEMENTS } from '../src/core/achievements';
import { APP_ACHIEVEMENT_REWARDS, APP_ACHIEVEMENTS, APP_CONSUMABLES, APP_ECONOMY, APP_ECRINS, APP_FISH_THIEF, APP_LEVELS, APP_SELL_DUST_BY_TIER, APP_SKINS } from '../src/core/appEconomy';
import { JEWEL_RARITIES } from '../src/core/jewels';
import { INITIAL_LOGIN } from '../src/core/daily';
import { FIND_ALBUMS, FINDS } from '../src/core/finds';
import { MARKS, OVERTONES } from '../src/core/pearlTraits';
import type { PlayerState } from '../src/core/player';
import { INITIAL_STATS } from '../src/core/progression';
import { FIND_PROBABILITY, PEARLS, pearlTier } from '../src/core/catalog';
import { levelFromXp, xpToNext } from '../src/core/levels';
import { DEFAULT_TUNING as t } from '../src/tuning';

/** Poussière moyenne par huître si tout est en double. */
const dustPerOyster = PEARLS.reduce((sum, p) => sum + p.probability * APP_SELL_DUST_BY_TIER[pearlTier(p.id)], 0);

describe('économie de l’app iOS', () => {
  it('la revente rapporte environ 2 ✦ par huître', () => {
    expect(dustPerOyster).toBeGreaterThan(1.5);
    expect(dustPerOyster).toBeLessThan(2.5);
    expect(FIND_PROBABILITY).toBeLessThan(0.1);
  });

  it('le bénitier demande environ trois semaines de jeu régulier', () => {
    const benitier = APP_SKINS.find((s) => s.id === 'benitier')!;
    const missions = APP_ECONOMY.missionsPerDay * APP_ECONOMY.missionRewardDust + APP_ECONOMY.missionBonusDust;
    // Le rythme réel (pubs, calendrier, niveaux, succès) est vérifié par la simulation Swift (EconomySimulationTests).
    const regularDay = 30 * dustPerOyster + missions;
    const days = benitier.dustPrice! / regularDay;
    expect(days).toBeGreaterThan(21);
    expect(days).toBeLessThan(45);
  });

  it('le poisson voleur prend une perle de temps en temps, quelle que soit sa rareté', () => {
    const pearls = PEARLS.filter((p) => p.glow !== null);
    // Une huître sur 25 à 60 environ : une surprise rare (il peut prendre une perle rare, choix de Jules).
    const share = pearls.reduce((sum, p) => sum + p.probability, 0) * APP_FISH_THIEF.chance;
    expect(share).toBeGreaterThan(0.015);
    expect(share).toBeLessThan(0.04);
    // On a le temps de le toucher.
    expect(APP_FISH_THIEF.fleeMs).toBeGreaterThanOrEqual(2000);
  });

  it('les pubs d’une journée rapportent moins que « Marée haute »', () => {
    const tide = APP_CONSUMABLES.find((c) => c.id === 'app.pearlinc.oysters.10')!;
    expect(APP_ECONOMY.rewardedAdOysters * APP_ECONOMY.rewardedAdsPerDay).toBeLessThan(tide.oysters);
  });

  it('acheter le bénitier en poussière coûte plus cher que l’acheter directement', () => {
    // Seule la Malle (9,99 €) suffit : elle coûte plus que le skin (2,99 €, prix StoreKit, voir §6 ter).
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

  it('les niveaux donnent surtout de la poussière d’or, des huîtres de temps en temps', () => {
    // Des huîtres à chaque niveau faisaient boule de neige (audit P0-1) : 205 huîtres à la première séance.
    expect(APP_LEVELS.rewardOystersEvery).toBeGreaterThanOrEqual(5);
    expect(APP_LEVELS.rewardOysters + APP_LEVELS.rankRewardOysters).toBeLessThanOrEqual(10);
    expect(APP_LEVELS.rewardDust).toBeGreaterThan(0);
    // Les dix premiers niveaux (deux rangs compris) rapportent moins d'une journée de poussière d'un joueur régulier.
    expect(9 * APP_LEVELS.rewardDust + 2 * APP_LEVELS.rankRewardDust).toBeLessThan(105);
  });

  it('les succès repris de la webapp gardent son objectif, son palier, son titre et son secret', () => {
    const empty = { cards: [], findCards: [], oystersOpened: 0, stats: INITIAL_STATS, login: INITIAL_LOGIN, jewelCards: [], craftedCards: [] } as unknown as PlayerState;
    expect(new Set(APP_ACHIEVEMENTS.map((a) => a.id)).size).toBe(APP_ACHIEVEMENTS.length);
    for (const app of APP_ACHIEVEMENTS) {
      const web = ACHIEVEMENTS.find((a) => a.id === app.id);
      if (!web) continue;
      expect(web.progress(empty)[1], app.id).toBe(app.goal);
      expect([web.tier, web.secret ?? false, web.album ?? false], app.id).toEqual([app.tier, app.secret ?? false, app.album ?? false]);
      // Titre de la webapp, sauf « Gardien de la Crique » (pas encore de carte des lagons dans l'app).
      if (app.id !== 'crique-complete') expect(web.title, app.id).toBe(app.title);
    }
  });

  it('chaque succès vise quelque chose qui existe', () => {
    const targets: Partial<Record<string, readonly string[]>> = {
      pearl: PEARLS.map((p) => p.id), find: FINDS.map((f) => f.id), album: FIND_ALBUMS.map((a) => a.id),
      mark: Object.keys(MARKS), overtone: Object.keys(OVERTONES), jewel: JEWEL_RARITIES.map((j) => j.id),
    };
    for (const a of APP_ACHIEVEMENTS) {
      const ids = targets[a.measure];
      if (ids) expect(ids, a.id).toContain(a.target);
      else expect(a.target, a.id).toBeUndefined();
      if (a.measure === 'album') expect(FINDS.filter((f) => f.album === a.target).length, a.id).toBe(a.goal);
      if (a.album) expect(a.measure, a.id).toBe('album');
    }
  });

  it('tous les succès réunis ne donnent pas d’huîtres, et moins d’un quart du bénitier en poussière', () => {
    const rewards = APP_ACHIEVEMENTS.map((a) => APP_ACHIEVEMENT_REWARDS[a.tier]);
    const dust = rewards.reduce((sum, r) => sum + r.dust, 0);
    const oysters = rewards.reduce((sum, r) => sum + r.oysters, 0) + APP_ACHIEVEMENTS.filter((a) => a.album).length * APP_ACHIEVEMENT_REWARDS.albumOysters;
    expect(dust).toBeLessThan(APP_SKINS.find((s) => s.id === 'benitier')!.dustPrice! / 4);
    expect(oysters).toBe(0);
  });

  it('un écrin coûte 10 huîtres de poussière, un à trois jours de revente', () => {
    expect(APP_ECRINS.dustPrice).toBe(10 * APP_ECONOMY.oysterDustPrice);
    const missions = APP_ECONOMY.missionsPerDay * APP_ECONOMY.missionRewardDust + APP_ECONOMY.missionBonusDust;
    const regularDay = 30 * dustPerOyster + missions;
    expect(APP_ECRINS.dustPrice / regularDay).toBeGreaterThan(1);
    expect(APP_ECRINS.dustPrice / regularDay).toBeLessThan(3);
    // Revendre le bijou d'un écrin rapporte bien moins que son prix : pas de boucle écrin → poussière → écrin.
    const resale = JEWEL_RARITIES.reduce((sum, j) => sum + j.probability * APP_SELL_DUST_BY_TIER[j.tier], 0);
    expect(resale * 20).toBeLessThan(APP_ECRINS.dustPrice);
  });

  it('un écrin acheté n’est jamais moins cher que ses 200 ✦ achetés en pack (prix de PearlInc.storekit)', () => {
    const storekit = JSON.parse(readFileSync(resolve(__dirname, '../ios/PearlInc.storekit'), 'utf8')) as { products: { productID: string; displayPrice: string }[] };
    const price = (id: string) => Number(storekit.products.find((p) => p.productID === id)!.displayPrice);
    const cheapestDust = Math.min(...APP_CONSUMABLES.filter((c) => c.dust > 0).map((c) => price(c.id) / c.dust));
    const ecrins = APP_CONSUMABLES.filter((c) => c.ecrins > 0);
    expect(ecrins.length).toBeGreaterThan(0);
    for (const product of ecrins) {
      expect(product.oysters + product.dust, product.id).toBe(0);
      expect(price(product.id) / product.ecrins, product.id).toBeGreaterThanOrEqual(cheapestDust * APP_ECRINS.dustPrice);
    }
  });

  it('un écrin toutes les 12 huîtres : deux ou trois par jour de jeu régulier, plus un à chaque rang', () => {
    // Plus qu'un plein de stock : un écrin ne tombe pas à chaque séance courte.
    expect(APP_ECRINS.oysterEvery).toBeGreaterThan(t.oysterStockMax);
    const regularDay = 30 / APP_ECRINS.oysterEvery;
    expect(regularDay).toBeGreaterThanOrEqual(2);
    expect(regularDay).toBeLessThanOrEqual(3);
    expect(APP_ECRINS.rankEcrins).toBe(1);
  });

  it('un seul skin offert au départ', () => {
    expect(APP_SKINS.filter((s) => s.grant === 'start').map((s) => s.id)).toEqual(['lagon']);
  });
});
