import { describe, expect, it } from 'vitest';
import type { PearlId } from '../src/core/catalog';
import { filterCards, jewelRarityRank, rarityRank, sortCards, sortJewelCards } from '../src/core/collection';
import type { Jewel, JewelRarityId } from '../src/core/jewels';
import type { JewelCard, PearlCard } from '../src/core/player';

const card = (serial: number, pearlId: PearlId, value: number): PearlCard => ({
  serial,
  pearlId,
  value,
  sizeMm: 7,
  lustre: 'A',
  cracked: false,
  foundAt: serial,
});

const cards = [card(1, 'white', 10), card(2, 'golden', 120), card(3, 'cursed', 666), card(4, 'giant', 300), card(5, 'white', 12), card(6, 'golden', 60)];
const serials = (list: PearlCard[]) => list.map((c) => c.serial);

describe('tri de la collection', () => {
  it('classe les perles de la plus rare à la plus commune', () => {
    expect(rarityRank('cursed')).toBeLessThan(rarityRank('giant'));
    expect(rarityRank('giant')).toBeLessThan(rarityRank('golden'));
    expect(rarityRank('golden')).toBeLessThan(rarityRank('black'));
    expect(rarityRank('rose')).toBeLessThan(rarityRank('white'));
  });

  it('par rareté : la plus rare d’abord, puis la plus précieuse', () => {
    expect(serials(sortCards(cards, 'rarity'))).toEqual([3, 4, 2, 6, 5, 1]);
  });

  it('par date : la plus récente d’abord', () => {
    expect(serials(sortCards(cards, 'recent'))).toEqual([6, 5, 4, 3, 2, 1]);
  });

  it('par valeur : la plus précieuse d’abord', () => {
    expect(serials(sortCards(cards, 'value'))).toEqual([3, 4, 2, 6, 5, 1]);
  });

  it('ne modifie pas la liste d’origine', () => {
    const copy = [...cards];
    sortCards(cards, 'rarity');
    expect(cards).toEqual(copy);
  });

  it('filtre par perle', () => {
    expect(serials(filterCards(cards, 'golden'))).toEqual([2, 6]);
    expect(filterCards(cards, null)).toHaveLength(cards.length);
  });
});

describe('tri des bijoux', () => {
  const jewelCard = (serial: number, rarityId: JewelRarityId, value: number): JewelCard => ({
    serial,
    value,
    perfect: false,
    foundAt: serial,
    jewel: { rarityId, value } as Jewel,
  });
  const jewels = [jewelCard(1, 'toc', 2), jewelCard(2, 'diamant', 9000), jewelCard(3, 'legende', 6500), jewelCard(4, 'or', 900)];

  it('classe la légende avant le diamant, et le toc en dernier', () => {
    expect(jewelRarityRank('legende')).toBeLessThan(jewelRarityRank('diamant'));
    expect(jewelRarityRank('toc')).toBeGreaterThan(jewelRarityRank('or'));
  });

  it('trie par rareté, valeur ou date', () => {
    expect(sortJewelCards(jewels, 'rarity').map((c) => c.serial)).toEqual([3, 2, 4, 1]);
    expect(sortJewelCards(jewels, 'value').map((c) => c.serial)).toEqual([2, 3, 4, 1]);
    expect(sortJewelCards(jewels, 'recent').map((c) => c.serial)).toEqual([4, 3, 2, 1]);
  });
});
