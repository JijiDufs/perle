import { describe, expect, it } from 'vitest';
import { consumeOyster, nextRefillIn, refreshStock, type StockState } from '../src/core/stock';
import { DEFAULT_TUNING } from '../src/tuning';

const t = { ...DEFAULT_TUNING, oysterStockMax: 10, oysterRechargeMinutes: 20 };
const MIN = 60_000;
const full: StockState = { count: 10, lastRefillAt: 0 };

describe("stock d'huîtres", () => {
  it('consomme une huître et démarre le minuteur quand le stock était plein', () => {
    const after = consumeOyster(full, 1000, t)!;
    expect(after).toEqual({ count: 9, lastRefillAt: 1000 });
    expect(nextRefillIn(after, 1000, t)).toBe(20 * MIN);
  });

  it('refuse quand le stock est vide', () => {
    expect(consumeOyster({ count: 0, lastRefillAt: 0 }, 5 * MIN, t)).toBeNull();
  });

  it('rend une huître toutes les 20 minutes, en gardant le temps restant', () => {
    const stock: StockState = { count: 0, lastRefillAt: 0 };
    expect(refreshStock(stock, 19 * MIN, t).count).toBe(0);
    const after45 = refreshStock(stock, 45 * MIN, t);
    expect(after45.count).toBe(2);
    expect(nextRefillIn(stock, 45 * MIN, t)).toBe(15 * MIN);
  });

  it('ne dépasse jamais le maximum et arrête le minuteur une fois plein', () => {
    const stock: StockState = { count: 3, lastRefillAt: 0 };
    const later = refreshStock(stock, 24 * 60 * MIN, t);
    expect(later.count).toBe(10);
    expect(nextRefillIn(later, 24 * 60 * MIN, t)).toBeNull();
  });

  it('ne fait rien gagner si l’horloge recule', () => {
    const stock: StockState = { count: 2, lastRefillAt: 100 * MIN };
    const back = refreshStock(stock, 10 * MIN, t);
    expect(back.count).toBe(2);
    expect(refreshStock(back, 29 * MIN, t).count).toBe(2);
    expect(refreshStock(back, 30 * MIN, t).count).toBe(3);
  });

  it('vider tout le stock puis attendre 3 h 20 le remplit', () => {
    let stock: StockState | null = full;
    for (let i = 0; i < 10; i++) stock = consumeOyster(stock!, 0, t);
    expect(stock!.count).toBe(0);
    expect(refreshStock(stock!, 200 * MIN, t).count).toBe(10);
  });
});
