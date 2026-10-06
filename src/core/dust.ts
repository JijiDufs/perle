// Poussière d'or (cahier §7) : un doublon se fond en poussière d'or, qui achète précisément la pièce
// manquante de son choix, ou un écrin (choix de Jules, AGENTS.md §6). Personne ne reste bloqué par le hasard.
import { dustForTier, type Tuning } from '../tuning';
import { PEARLS, pearlById, pearlTier, type PearlId } from './catalog';
import { JEWEL_RARITIES, jewelOfRarity, jewelRarity, type JewelRarityId } from './jewels';
import { defaultTraits } from './pearlTraits';
import { pearlValue, type JewelCard, type PearlCard, type PlayerState } from './player';
import { afterEvent } from './progression';
import type { Rng } from './rng';

export type PieceKind = 'pearl' | 'jewel';

/** Une « pièce » de la collection : une sorte de perle, ou une rareté de bijou (une case de l'encyclopédie). */
export type Piece = { kind: 'pearl'; id: PearlId } | { kind: 'jewel'; id: JewelRarityId };

export { pearlTier };

export function pieceTier(piece: Piece): number {
  return piece.kind === 'pearl' ? pearlTier(piece.id) : jewelRarity(piece.id).tier;
}

/** Poussière que rapporte une pièce fondue. */
export const meltValue = (piece: Piece, tuning: Tuning): number => dustForTier(tuning, pieceTier(piece));

/** Prix d'une pièce manquante. */
export const piecePrice = (piece: Piece, tuning: Tuning): number => meltValue(piece, tuning) * tuning.dustBuyMultiplier;

const pieceOfPearlCard = (card: PearlCard): Piece => ({ kind: 'pearl', id: card.pearlId });
const pieceOfJewelCard = (card: JewelCard): Piece => ({ kind: 'jewel', id: card.jewel.rarityId });

/** Une carte précieuse (éclat parfait, variante, certificat) n'est jamais fondue en lot. */
const isSpecialJewel = (card: JewelCard) => card.perfect || !!card.variant || !!card.expertise;

/** Pièce d'une carte, ou null si le numéro de série n'existe pas. */
function findCard(state: PlayerState, serial: number): { piece: Piece; kind: PieceKind } | null {
  const pearl = state.cards.find((c) => c.serial === serial);
  if (pearl) return { piece: pieceOfPearlCard(pearl), kind: 'pearl' };
  const jewel = state.jewelCards.find((c) => c.serial === serial);
  if (jewel) return { piece: pieceOfJewelCard(jewel), kind: 'jewel' };
  return null;
}

function countOf(state: PlayerState, piece: Piece): number {
  return piece.kind === 'pearl'
    ? state.cards.filter((c) => c.pearlId === piece.id).length
    : state.jewelCards.filter((c) => c.jewel.rarityId === piece.id).length;
}

/** Un doublon peut être fondu : il reste toujours au moins un exemplaire de chaque pièce. */
export function canMelt(state: PlayerState, serial: number): boolean {
  const found = findCard(state, serial);
  return found !== null && countOf(state, found.piece) >= 2;
}

/** Poussière que rapporterait la carte fondue (0 si elle n'existe pas). */
export function meltValueOfCard(state: PlayerState, serial: number, tuning: Tuning): number {
  const found = findCard(state, serial);
  return found ? meltValue(found.piece, tuning) : 0;
}

/** Fond une carte en double. Sans effet si ce n'est pas un doublon. */
export function meltCard(state: PlayerState, serial: number, tuning: Tuning, now = 0): PlayerState {
  if (!canMelt(state, serial)) return state;
  const dust = state.dust + meltValueOfCard(state, serial, tuning);
  const melted = {
    ...state,
    dust,
    cards: state.cards.filter((c) => c.serial !== serial),
    jewelCards: state.jewelCards.filter((c) => c.serial !== serial),
  };
  return afterEvent(melted, { kind: 'melt' }, now, tuning);
}

/**
 * Doublons « ordinaires » à fondre en lot : pour chaque pièce, on garde l'exemplaire le plus précieux,
 * et on ne touche jamais aux perles marquées ni aux bijoux à éclat parfait, variante ou certificat.
 */
export function ordinaryDuplicates(state: PlayerState): number[] {
  const serials: number[] = [];
  const keepBest = <C extends { serial: number; value: number }>(cards: readonly C[], keyOf: (c: C) => string, protect: (c: C) => boolean) => {
    const groups = new Map<string, C[]>();
    for (const card of cards) groups.set(keyOf(card), [...(groups.get(keyOf(card)) ?? []), card]);
    for (const group of groups.values()) {
      const sorted = [...group].sort((a, b) => b.value - a.value || a.serial - b.serial);
      // Le meilleur exemplaire est gardé ; s'il est protégé, il compte aussi comme l'exemplaire gardé.
      for (const card of sorted.slice(1)) if (!protect(card)) serials.push(card.serial);
    }
  };
  // Une perle marquée (jumelle, étoilée…) n'est jamais fondue en lot.
  keepBest(state.cards, (c) => c.pearlId, (c) => !!c.traits?.mark);
  keepBest(state.jewelCards, (c) => c.jewel.rarityId, isSpecialJewel);
  return serials;
}

/** Poussière que rapporterait la fonte de tous les doublons ordinaires. */
export function ordinaryDuplicatesValue(state: PlayerState, tuning: Tuning): number {
  return ordinaryDuplicates(state).reduce((sum, serial) => sum + meltValueOfCard(state, serial, tuning), 0);
}

export function meltOrdinaryDuplicates(state: PlayerState, tuning: Tuning, now = 0): PlayerState {
  return ordinaryDuplicates(state).reduce((s, serial) => meltCard(s, serial, tuning, now), state);
}

/** Pièces jamais obtenues (l'huître vide n'est pas une pièce), de la moins chère à la plus chère. */
export function missingPieces(state: PlayerState): Piece[] {
  const pearls: Piece[] = PEARLS.filter((p) => p.id !== 'empty').map((p) => ({ kind: 'pearl', id: p.id }));
  const jewels: Piece[] = JEWEL_RARITIES.map((j) => ({ kind: 'jewel', id: j.id }));
  return [...pearls, ...jewels].filter((piece) => countOf(state, piece) === 0).sort((a, b) => pieceTier(a) - pieceTier(b));
}

/**
 * Achète une pièce manquante. La carte achetée est ordinaire (lustre B, sans éclat parfait) et marquée
 * « poussière d'or ». null si la pièce est déjà possédée ou trop chère. Le tirage et ses garanties ne bougent pas.
 */
export function buyPiece(
  state: PlayerState,
  piece: Piece,
  rng: Rng,
  now: number,
  tuning: Tuning,
): { state: PlayerState; card: PearlCard | JewelCard } | null {
  const price = piecePrice(piece, tuning);
  if (countOf(state, piece) > 0 || state.dust < price || (piece.kind === 'pearl' && piece.id === 'empty')) return null;
  const serial = state.nextSerial;
  const paid = { ...state, dust: state.dust - price, nextSerial: serial + 1 };
  if (piece.kind === 'pearl') {
    const [min, max] = pearlById(piece.id).sizeMm;
    const sizeMm = Math.round((min + rng() * (max - min)) * 10) / 10;
    const traits = defaultTraits(piece.id as Exclude<PearlId, 'empty'>);
    const card: PearlCard = { serial, pearlId: piece.id, sizeMm, value: pearlValue(piece.id, sizeMm, false, traits), lustre: 'B', cracked: false, foundAt: now, fromDust: true, traits };
    return { state: { ...paid, cards: [...state.cards, card] }, card };
  }
  const jewel = jewelOfRarity(jewelRarity(piece.id), rng);
  const card: JewelCard = { serial, jewel, value: jewel.value, perfect: false, variant: null, foundAt: now, fromDust: true };
  return { state: { ...paid, jewelCards: [...state.jewelCards, card] }, card };
}

/** Achète un écrin Velours (il s'ajoute aux écrins à ouvrir). null si pas assez de poussière. */
export function buyEcrin(state: PlayerState, tuning: Tuning): PlayerState | null {
  if (state.dust < tuning.dustEcrinPrice) return null;
  return { ...state, dust: state.dust - tuning.dustEcrinPrice, ecrins: state.ecrins + 1 };
}
