import type { Tuning } from '../tuning';

/**
 * Stock d'huîtres (énergie, cahier §5) : un maximum, et une huître qui revient à intervalle fixe.
 * Le minuteur ne tourne que lorsque le stock n'est pas plein.
 */
export interface StockState {
  count: number;
  /** Instant (ms) à partir duquel court la prochaine recharge. */
  lastRefillAt: number;
}

const MINUTE = 60_000;

export function rechargeIntervalMs(tuning: Tuning): number {
  return tuning.oysterRechargeMinutes * MINUTE;
}

/** Ajoute les huîtres revenues depuis la dernière recharge, sans dépasser le maximum. */
export function refreshStock(stock: StockState, now: number, tuning: Tuning): StockState {
  const max = tuning.oysterStockMax;
  if (stock.count >= max) return { count: Math.max(stock.count, 0), lastRefillAt: now };
  // Horloge reculée (changement d'heure manuel) : on repart de maintenant, sans rien gagner.
  if (now < stock.lastRefillAt) return { ...stock, lastRefillAt: now };
  const interval = rechargeIntervalMs(tuning);
  const gained = Math.floor((now - stock.lastRefillAt) / interval);
  if (gained <= 0) return stock;
  const count = Math.min(max, stock.count + gained);
  return { count, lastRefillAt: count >= max ? now : stock.lastRefillAt + gained * interval };
}

/** Retire une huître. Renvoie null si le stock est vide. */
export function consumeOyster(stock: StockState, now: number, tuning: Tuning): StockState | null {
  const fresh = refreshStock(stock, now, tuning);
  if (fresh.count <= 0) return null;
  // Si le stock était plein, le minuteur démarre maintenant.
  const lastRefillAt = fresh.count >= tuning.oysterStockMax ? now : fresh.lastRefillAt;
  return { count: fresh.count - 1, lastRefillAt };
}

/** Temps (ms) avant la prochaine huître, ou null si le stock est plein. */
export function nextRefillIn(stock: StockState, now: number, tuning: Tuning): number | null {
  const fresh = refreshStock(stock, now, tuning);
  if (fresh.count >= tuning.oysterStockMax) return null;
  return Math.max(0, fresh.lastRefillAt + rechargeIntervalMs(tuning) - now);
}
