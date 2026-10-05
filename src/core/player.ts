import { DEFAULT_TUNING, type Tuning } from '../tuning';
import { pearlById, type PearlId } from './catalog';
import { INITIAL_DRAW_STATE, type DrawState } from './draw';
import { rollSweetAngle } from './glint';
import { INITIAL_JEWEL_DRAW, roundValue, rollJewel, type Jewel, type JewelDrawState } from './jewels';
import type { Lustre } from './lustre';
import { createOyster, oysterWith, type Oyster } from './oyster';
import type { Rng } from './rng';
import { consumeOyster, type StockState } from './stock';
import { scriptedPearl, TUTORIAL_PEARLS } from './tutorial';

/** Une carte à collectionner, créée à chaque perle révélée. */
export interface PearlCard {
  serial: number;
  pearlId: PearlId;
  sizeMm: number;
  value: number;
  lustre: Lustre;
  cracked: boolean;
  /** Date de révélation (ms). */
  foundAt: number;
}

/** Une carte de bijou, créée à chaque écrin ouvert. */
export interface JewelCard {
  serial: number;
  jewel: Jewel;
  /** Estimation finale (×1,5 si éclat parfait). */
  value: number;
  perfect: boolean;
  foundAt: number;
}

/** Écrin en cours d'ouverture : bijou et angle d'éclat décidés à l'avance, sauvegardés. */
export interface PendingEcrin {
  jewel: Jewel;
  sweetAngle: number;
}

export interface PlayerState {
  draw: DrawState;
  /** Huître en cours, sauvegardée : recharger la page ne relance pas le tirage. */
  currentOyster: Oyster | null;
  nextSerial: number;
  oystersOpened: number;
  cards: PearlCard[];
  /** Huîtres disponibles (énergie). */
  stock: StockState;
  /** Écrins gagnés, pas encore ouverts. */
  ecrins: number;
  /** Huîtres ouvertes depuis le dernier écrin gagné. */
  oystersSinceEcrin: number;
  jewelDraw: JewelDrawState;
  currentEcrin: PendingEcrin | null;
  jewelCards: JewelCard[];
}

export const INITIAL_PLAYER_STATE: PlayerState = {
  draw: INITIAL_DRAW_STATE,
  currentOyster: null,
  nextSerial: 1,
  oystersOpened: 0,
  cards: [],
  stock: { count: DEFAULT_TUNING.oysterStockMax, lastRefillAt: 0 },
  ecrins: 0,
  oystersSinceEcrin: 0,
  jewelDraw: INITIAL_JEWEL_DRAW,
  currentEcrin: null,
  jewelCards: [],
};

/**
 * Renvoie l'huître en cours, ou en pêche une nouvelle.
 * Les huîtres du tutoriel sont offertes ; les suivantes coûtent une huître du stock.
 * Stock vide : l'état revient sans huître en cours (currentOyster null).
 */
export function ensureOyster(state: PlayerState, rng: Rng, tuning: Tuning, now: number): PlayerState {
  if (state.currentOyster) return state;
  const scripted = scriptedPearl(state.oystersOpened);
  if (scripted) {
    const oyster = oysterWith(scripted, rng);
    const goldenOrBetter = pearlById(scripted).goldenOrBetter;
    const draw = { sinceGoldenOrBetter: goldenOrBetter ? 0 : state.draw.sinceGoldenOrBetter + 1 };
    return { ...state, currentOyster: oyster, draw };
  }
  const stock = consumeOyster(state.stock, now, tuning);
  if (!stock) return state;
  const { oyster, drawState } = createOyster(state.draw, rng, tuning);
  return { ...state, currentOyster: oyster, draw: drawState, stock };
}

/** Valeur d'une perle : base × taille relative, divisée par deux si fêlée. */
export function pearlValue(pearlId: PearlId, sizeMm: number, cracked: boolean): number {
  const pearl = pearlById(pearlId);
  if (pearl.baseValue === 0) return 0;
  const [min, max] = pearl.sizeMm;
  const sizeFactor = sizeMm / ((min + max) / 2);
  return Math.round(pearl.baseValue * sizeFactor * (cracked ? 0.5 : 1));
}

/**
 * Gain d'écrins à l'ouverture d'une huître : le premier à la fin du tutoriel (cahier §15),
 * puis un toutes les `oystersPerEcrin` huîtres.
 */
function earnEcrins(state: PlayerState, tuning: Tuning): { state: PlayerState; earned: boolean } {
  const opened = state.oystersOpened; // déjà incrémenté
  if (opened < TUTORIAL_PEARLS.length) return { state, earned: false };
  if (opened === TUTORIAL_PEARLS.length) return { state: { ...state, ecrins: state.ecrins + 1, oystersSinceEcrin: 0 }, earned: true };
  const since = state.oystersSinceEcrin + 1;
  if (since >= tuning.oystersPerEcrin) return { state: { ...state, ecrins: state.ecrins + 1, oystersSinceEcrin: 0 }, earned: true };
  return { state: { ...state, oystersSinceEcrin: since }, earned: false };
}

/**
 * Enregistre l'huître ouverte. Renvoie la carte créée (null pour une huître vide)
 * et si un écrin vient d'être gagné.
 */
export function recordOpening(
  state: PlayerState,
  result: { lustre: Lustre; cracked: boolean },
  now: number,
  tuning: Tuning = DEFAULT_TUNING,
): { state: PlayerState; card: PearlCard | null; ecrinEarned: boolean } {
  const oyster = state.currentOyster;
  if (!oyster) throw new Error('Aucune huître en cours');
  const earned = earnEcrins({ ...state, currentOyster: null, oystersOpened: state.oystersOpened + 1 }, tuning);
  const base = earned.state;
  if (oyster.pearlId === 'empty') return { state: base, card: null, ecrinEarned: earned.earned };

  const card: PearlCard = {
    serial: state.nextSerial,
    pearlId: oyster.pearlId,
    sizeMm: oyster.sizeMm,
    value: pearlValue(oyster.pearlId, oyster.sizeMm, result.cracked),
    lustre: result.lustre,
    cracked: result.cracked,
    foundAt: now,
  };
  return { state: { ...base, nextSerial: state.nextSerial + 1, cards: [...state.cards, card] }, card, ecrinEarned: earned.earned };
}

/** Renvoie l'écrin en cours, ou en ouvre un nouveau s'il en reste (sinon currentEcrin reste null). */
export function ensureEcrin(state: PlayerState, rng: Rng, tuning: Tuning): PlayerState {
  if (state.currentEcrin || state.ecrins <= 0) return state;
  const { jewel, state: jewelDraw } = rollJewel(state.jewelDraw, rng, tuning);
  return { ...state, ecrins: state.ecrins - 1, jewelDraw, currentEcrin: { jewel, sweetAngle: rollSweetAngle(rng, tuning) } };
}

/** Enregistre l'écrin ouvert et crée sa carte. */
export function recordEcrin(state: PlayerState, result: { perfect: boolean }, now: number, tuning: Tuning): { state: PlayerState; card: JewelCard } {
  const pending = state.currentEcrin;
  if (!pending) throw new Error('Aucun écrin en cours');
  const value = roundValue(pending.jewel.value * (result.perfect ? tuning.glintPerfectMultiplier : 1));
  const card: JewelCard = { serial: state.nextSerial, jewel: pending.jewel, value, perfect: result.perfect, foundAt: now };
  return {
    state: { ...state, currentEcrin: null, nextSerial: state.nextSerial + 1, jewelCards: [...state.jewelCards, card] },
    card,
  };
}
