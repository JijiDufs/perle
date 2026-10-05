import { describe, expect, it } from 'vitest';
import { buyEcrin, buyPiece, canMelt, meltCard, meltOrdinaryDuplicates, meltValue, missingPieces, ordinaryDuplicates, pearlTier, piecePrice } from '../src/core/dust';
import { jewelOfRarity, jewelRarity } from '../src/core/jewels';
import { INITIAL_PLAYER_STATE, type JewelCard, type PearlCard, type PlayerState } from '../src/core/player';
import { seededRng } from '../src/core/rng';
import { DEFAULT_TUNING } from '../src/tuning';

const t = DEFAULT_TUNING;

const pearl = (serial: number, pearlId: PearlCard['pearlId'], value = 10): PearlCard => ({ serial, pearlId, sizeMm: 6, value, lustre: 'B', cracked: false, foundAt: 0 });
const jewel = (serial: number, rarityId: JewelCard['jewel']['rarityId'], extra: Partial<JewelCard> = {}): JewelCard => {
  const j = jewelOfRarity(jewelRarity(rarityId), seededRng(serial));
  return { serial, jewel: j, value: j.value, perfect: false, variant: null, foundAt: 0, ...extra };
};
const withCards = (cards: PearlCard[], jewelCards: JewelCard[] = [], dust = 0): PlayerState => ({ ...INITIAL_PLAYER_STATE, cards, jewelCards, dust, nextSerial: 100 });

describe("poussière d'or", () => {
  it('lit le niveau des perles sur leur symbole', () => {
    expect(pearlTier('white')).toBe(1);
    expect(pearlTier('black')).toBe(3);
    expect(pearlTier('golden')).toBe(4);
    expect(pearlTier('cursed')).toBe(5);
  });

  it('ne fond jamais le dernier exemplaire', () => {
    const state = withCards([pearl(1, 'white'), pearl(2, 'rose')]);
    expect(canMelt(state, 1)).toBe(false);
    expect(meltCard(state, 1, t)).toBe(state);
  });

  it('fond un doublon en poussière selon sa rareté', () => {
    const state = withCards([pearl(1, 'golden'), pearl(2, 'golden')]);
    const after = meltCard(state, 2, t);
    expect(after.cards.map((c) => c.serial)).toEqual([1]);
    expect(after.dust).toBe(t.dustTier4);
  });

  it('la fonte en lot garde le plus bel exemplaire et les bijoux précieux', () => {
    const state = withCards(
      [pearl(1, 'white', 8), pearl(2, 'white', 12), pearl(3, 'white', 9), pearl(4, 'rose')],
      [jewel(10, 'argent'), jewel(11, 'argent', { perfect: true, value: 1 }), jewel(12, 'argent', { value: 0 }), jewel(13, 'saphir', { variant: 'nuit' })],
    );
    expect(ordinaryDuplicates(state).sort()).toEqual([1, 12, 3].sort());
    const after = meltOrdinaryDuplicates(state, t);
    expect(after.cards.map((c) => c.serial)).toEqual([2, 4]);
    expect(after.jewelCards.map((c) => c.serial)).toEqual([10, 11, 13]);
    expect(after.dust).toBe(3 * t.dustTier1);
  });

  it('liste les pièces manquantes, sans l’huître vide', () => {
    const state = withCards([pearl(1, 'white')], [jewel(2, 'toc')]);
    const missing = missingPieces(state);
    expect(missing).toHaveLength(6 + 9);
    expect(missing.some((p) => p.kind === 'pearl' && (p.id === 'white' || p.id === 'empty'))).toBe(false);
    expect(missing.some((p) => p.kind === 'jewel' && p.id === 'toc')).toBe(false);
  });

  it('achète précisément la pièce manquante choisie', () => {
    const piece = { kind: 'jewel', id: 'diamant' } as const;
    const price = piecePrice(piece, t);
    expect(price).toBe(meltValue(piece, t) * t.dustBuyMultiplier);
    expect(buyPiece(withCards([], [], price - 1), piece, seededRng(1), 0, t)).toBeNull();
    const bought = buyPiece(withCards([], [], price + 3), piece, seededRng(1), 5, t)!;
    expect(bought.state.dust).toBe(3);
    expect(bought.state.jewelCards).toHaveLength(1);
    expect((bought.card as JewelCard).jewel.rarityId).toBe('diamant');
    expect(bought.card.fromDust).toBe(true);
    expect(bought.state.nextSerial).toBe(101);
    // Déjà possédée : plus à vendre.
    expect(buyPiece({ ...bought.state, dust: 10_000 }, piece, seededRng(1), 0, t)).toBeNull();
  });

  it('achète une perle manquante sans toucher à la garantie', () => {
    const piece = { kind: 'pearl', id: 'golden' } as const;
    const state = { ...withCards([], [], 1000), draw: { sinceGoldenOrBetter: 12 } };
    const bought = buyPiece(state, piece, seededRng(2), 0, t)!;
    const card = bought.card as PearlCard;
    expect(card.pearlId).toBe('golden');
    expect(card.sizeMm).toBeGreaterThanOrEqual(10);
    expect(card.sizeMm).toBeLessThanOrEqual(14);
    expect(bought.state.draw.sinceGoldenOrBetter).toBe(12);
  });

  it('achète un écrin', () => {
    expect(buyEcrin(withCards([], [], t.dustEcrinPrice - 1), t)).toBeNull();
    const after = buyEcrin(withCards([], [], t.dustEcrinPrice), t)!;
    expect(after.dust).toBe(0);
    expect(after.ecrins).toBe(1);
  });
});
