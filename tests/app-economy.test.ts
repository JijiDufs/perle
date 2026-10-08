// Garde-fous de l'économie de l'app iOS (docs/duo-gadget.md §6 quater).
import { describe, expect, it } from 'vitest';
import { APP_CONSUMABLES, APP_ECONOMY, APP_MISSING_PEARL_PRICE_BY_TIER, APP_SELL_DUST_BY_TIER, APP_SKINS } from '../src/core/appEconomy';
import { FIND_PROBABILITY, PEARLS, pearlTier } from '../src/core/catalog';

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

  it('les perles ★ et ★★ ne s’achètent pas', () => {
    expect(APP_MISSING_PEARL_PRICE_BY_TIER[4]).toBeNull();
    expect(APP_MISSING_PEARL_PRICE_BY_TIER[5]).toBeNull();
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

  it('un seul skin offert au départ', () => {
    expect(APP_SKINS.filter((s) => s.grant === 'start').map((s) => s.id)).toEqual(['lagon']);
  });
});
