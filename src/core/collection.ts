import { PEARLS, type PearlId } from './catalog';
import { JEWEL_RARITIES, type JewelRarityId } from './jewels';
import type { JewelCard, PearlCard } from './player';

export type CardSort = 'rarity' | 'recent' | 'value';

/** Rang de rareté : 0 = la plus rare (probabilité la plus faible). */
const RARITY_RANK: ReadonlyMap<PearlId, number> = new Map(
  [...PEARLS].sort((a, b) => a.probability - b.probability).map((p, i) => [p.id, i]),
);

export function rarityRank(id: PearlId): number {
  return RARITY_RANK.get(id) ?? PEARLS.length;
}

/**
 * Trie les cartes sans modifier la liste d'origine.
 * - rarity : la plus rare d'abord, puis la plus précieuse, puis la plus récente ;
 * - recent : la plus récente d'abord ;
 * - value : la plus précieuse d'abord, puis la plus rare.
 */
export function sortCards(cards: readonly PearlCard[], sort: CardSort): PearlCard[] {
  const byRecent = (a: PearlCard, b: PearlCard) => b.serial - a.serial;
  const byRarity = (a: PearlCard, b: PearlCard) => rarityRank(a.pearlId) - rarityRank(b.pearlId);
  const byValue = (a: PearlCard, b: PearlCard) => b.value - a.value;
  const compare =
    sort === 'recent'
      ? byRecent
      : sort === 'value'
        ? (a: PearlCard, b: PearlCard) => byValue(a, b) || byRarity(a, b) || byRecent(a, b)
        : (a: PearlCard, b: PearlCard) => byRarity(a, b) || byValue(a, b) || byRecent(a, b);
  return [...cards].sort(compare);
}

/** Garde seulement les cartes d'une perle donnée (null = toutes). */
export function filterCards(cards: readonly PearlCard[], pearlId: PearlId | null): PearlCard[] {
  return pearlId ? cards.filter((c) => c.pearlId === pearlId) : [...cards];
}

/**
 * Rang de rareté d'un bijou : 0 = le plus précieux. On trie par niveau (toc 0 … légende 5), pas par
 * probabilité : le toc (14 %) est plus rare que l'argent (20 %) mais ne vaut rien. À niveau égal, le moins probable d'abord.
 */
const JEWEL_RANK: ReadonlyMap<JewelRarityId, number> = new Map(
  [...JEWEL_RARITIES].sort((a, b) => b.tier - a.tier || a.probability - b.probability).map((j, i) => [j.id, i]),
);

export function jewelRarityRank(id: JewelRarityId): number {
  return JEWEL_RANK.get(id) ?? JEWEL_RARITIES.length;
}

/** Même tri que les perles, pour les cartes de bijoux. */
export function sortJewelCards(cards: readonly JewelCard[], sort: CardSort): JewelCard[] {
  const byRecent = (a: JewelCard, b: JewelCard) => b.serial - a.serial;
  const byRarity = (a: JewelCard, b: JewelCard) => jewelRarityRank(a.jewel.rarityId) - jewelRarityRank(b.jewel.rarityId);
  const byValue = (a: JewelCard, b: JewelCard) => b.value - a.value;
  const compare =
    sort === 'recent'
      ? byRecent
      : sort === 'value'
        ? (a: JewelCard, b: JewelCard) => byValue(a, b) || byRarity(a, b) || byRecent(a, b)
        : (a: JewelCard, b: JewelCard) => byRarity(a, b) || byValue(a, b) || byRecent(a, b);
  return [...cards].sort(compare);
}
