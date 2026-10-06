// L'Atelier (cahier §6), première version : les recettes du carnet de grand-mère, des perles de la collection,
// une monture payée en poussière d'or (en attendant les métaux et la boutique de l'atelier), et le geste de sertissage.
// Recettes, montures et prix : provisoires (AGENTS.md §6).
import type { Tuning } from '../tuning';
import { pearlById, type PearlId } from './catalog';
import type { JewelType } from './jewels';
import { gainReputation, levelFromXp } from './levels';
import { pearlTint, traitsOf } from './pearlTraits';
import type { PearlCard, PlayerState } from './player';
import { afterEvent } from './progression';
import type { SettingResult } from './setting';

export type MetalId = 'argent' | 'or' | 'or-rose' | 'platine';

export interface Metal {
  id: MetalId;
  name: string;
  color: string;
  /** Prix de la monture, en poussière d'or. */
  price: number;
  /** Valeur ajoutée au bijou (euros fictifs). */
  value: number;
}

export const METALS: readonly Metal[] = [
  { id: 'argent', name: 'Argent 925', color: '#d7dbe0', price: 10, value: 80 },
  { id: 'or', name: 'Or 18 ct', color: '#e3b54d', price: 25, value: 400 },
  { id: 'or-rose', name: 'Or rose', color: '#e9b19a', price: 30, value: 450 },
  { id: 'platine', name: 'Platine', color: '#eef0f3', price: 60, value: 900 },
];

export function metalById(id: MetalId): Metal {
  return METALS.find((m) => m.id === id)!;
}

export interface Recipe {
  id: string;
  name: string;
  type: JewelType;
  /** Perles demandées : une sorte précise, ou n'importe laquelle (null). */
  pearl: PearlId | null;
  count: number;
  metal: MetalId;
  /** Niveau où la page du carnet est retrouvée. */
  level: number;
  /** Multiplicateur de la valeur des perles. */
  multiplier: number;
  flavor: string;
}

export const RECIPES: readonly Recipe[] = [
  { id: 'premiere-lueur', name: 'Bague « Première lueur »', type: 'bague', pearl: null, count: 1, metal: 'argent', level: 5, multiplier: 1.5, flavor: 'La première que Rose a montée. Elle tremblait un peu.' },
  { id: 'jumelles', name: 'Boucles « Jumelles »', type: 'boucles', pearl: 'rose', count: 2, metal: 'argent', level: 5, multiplier: 1.8, flavor: 'Deux perles rosées, presque pareilles. Presque.' },
  { id: 'maree-basse', name: 'Bracelet « Marée basse »', type: 'bracelet', pearl: 'white', count: 3, metal: 'argent', level: 6, multiplier: 2, flavor: 'Ce qu’on ramasse quand la mer se retire.' },
  { id: 'baroque', name: 'Broche « Baroque »', type: 'broche', pearl: 'baroque', count: 2, metal: 'or', level: 7, multiplier: 2, flavor: 'Bosselée, de travers, et parfaite comme ça.' },
  { id: 'rivage', name: 'Collier « Rivage »', type: 'collier', pearl: 'white', count: 7, metal: 'or', level: 8, multiplier: 2.4, flavor: 'Sept perles blanches et un fermoir en or : la recette de toujours.' },
  { id: 'aube-rosee', name: 'Collier « Aube rosée »', type: 'collier', pearl: 'rose', count: 5, metal: 'or-rose', level: 9, multiplier: 2.4, flavor: 'Pour les matins où la mer est rose.' },
  { id: 'nuit-encre', name: 'Bague « Nuit d’encre »', type: 'bague', pearl: 'black', count: 1, metal: 'platine', level: 10, multiplier: 2.5, flavor: 'Les connaisseurs se taisent. Les autres aussi.' },
  { id: 'soleil', name: 'Pendentif « Soleil »', type: 'pendentif', pearl: 'golden', count: 1, metal: 'or', level: 12, multiplier: 3, flavor: 'Il chauffe un peu la peau. Sûrement une impression.' },
];

/** Une création de l'atelier : une carte à part, signée par le joueur. */
export interface CraftedCard {
  serial: number;
  recipeId: string;
  name: string;
  type: JewelType;
  metal: MetalId;
  /** Couleurs des perles utilisées (pour le dessin). */
  pearlColors: string[];
  pearlIds: PearlId[];
  /** 1 à 5. */
  stars: number;
  setting: SettingResult['verdict'];
  value: number;
  foundAt: number;
}

export function isAtelierUnlocked(state: PlayerState, tuning: Tuning): boolean {
  return levelFromXp(state.reputation, tuning).level >= tuning.atelierLevel;
}

export function isRecipeUnlocked(recipe: Recipe, state: PlayerState, tuning: Tuning): boolean {
  return levelFromXp(state.reputation, tuning).level >= recipe.level;
}

const LUSTRE_SCORE = { S: 1, A: 0.8, B: 0.6, C: 0.4 } as const;

/** Qualité d'une perle comme matériau (0…1) : son lustre, divisé par deux si elle est fêlée. */
export function pearlQuality(card: PearlCard): number {
  return LUSTRE_SCORE[card.lustre] * (card.cracked ? 0.5 : 1);
}

/**
 * Perles choisies pour une recette : les meilleures, mais on garde si possible un exemplaire de chaque sorte
 * dans la collection (le plus précieux). `lastCopy` : la recette entame ce dernier exemplaire.
 */
export function pickPearls(state: PlayerState, recipe: Recipe): { cards: PearlCard[]; missing: number; lastCopy: boolean } {
  const eligible = state.cards.filter((c) => c.pearlId !== 'empty' && (recipe.pearl === null || c.pearlId === recipe.pearl));
  // L'exemplaire gardé de chaque sorte : le plus précieux.
  const kept = new Set<number>();
  for (const id of new Set(eligible.map((c) => c.pearlId))) {
    const best = eligible.filter((c) => c.pearlId === id).sort((a, b) => b.value - a.value || a.serial - b.serial)[0];
    kept.add(best.serial);
  }
  const byQuality = (a: PearlCard, b: PearlCard) => pearlQuality(b) - pearlQuality(a) || b.value - a.value;
  const spare = eligible.filter((c) => !kept.has(c.serial)).sort(byQuality);
  const keptCards = eligible.filter((c) => kept.has(c.serial)).sort((a, b) => a.value - b.value);
  const cards = [...spare.slice(0, recipe.count)];
  let lastCopy = false;
  for (const card of keptCards) {
    if (cards.length >= recipe.count) break;
    cards.push(card);
    lastCopy = true;
  }
  return { cards, missing: recipe.count - cards.length, lastCopy };
}

/** Type d'une création : celui de sa recette (les premières broches et pendentifs étaient rangés en bague et collier). */
export function craftedType(card: Pick<CraftedCard, 'recipeId' | 'type'>): JewelType {
  return RECIPES.find((r) => r.id === card.recipeId)?.type ?? card.type;
}

export function canCraft(state: PlayerState, recipe: Recipe, tuning: Tuning): boolean {
  return isRecipeUnlocked(recipe, state, tuning) && pickPearls(state, recipe).missing === 0 && state.dust >= metalById(recipe.metal).price;
}

/** Étoiles : qualité des matériaux × réussite du geste (cahier §6), de 1 à 5. */
export function craftStars(materials: number, gesture: number): number {
  return Math.max(1, Math.min(5, Math.round(1 + 4 * (0.4 * materials + 0.6 * gesture))));
}

/** Fabrique le bijou : consomme les perles et la monture, crée la carte. null si impossible. */
export function craft(
  state: PlayerState,
  recipeId: string,
  setting: SettingResult,
  now: number,
  tuning: Tuning,
): { state: PlayerState; card: CraftedCard } | null {
  const recipe = RECIPES.find((r) => r.id === recipeId);
  if (!recipe || !canCraft(state, recipe, tuning)) return null;
  const { cards } = pickPearls(state, recipe);
  const metal = metalById(recipe.metal);
  const materials = cards.reduce((sum, c) => sum + pearlQuality(c), 0) / cards.length;
  const stars = craftStars(materials, setting.score);
  const pearlsValue = cards.reduce((sum, c) => sum + c.value, 0);
  const value = Math.round(pearlsValue * recipe.multiplier * (0.8 + 0.1 * stars) + metal.value);
  const card: CraftedCard = {
    serial: state.nextSerial,
    recipeId: recipe.id,
    name: recipe.name,
    type: recipe.type,
    metal: metal.id,
    pearlColors: cards.map((c) => pearlTint(pearlById(c.pearlId).color, traitsOf(c))),
    pearlIds: cards.map((c) => c.pearlId),
    stars,
    setting: setting.verdict,
    value,
    foundAt: now,
  };
  const used = new Set(cards.map((c) => c.serial));
  const next: PlayerState = {
    ...state,
    nextSerial: state.nextSerial + 1,
    dust: state.dust - metal.price,
    cards: state.cards.filter((c) => !used.has(c.serial)),
    craftedCards: [...state.craftedCards, card],
  };
  const gained = gainReputation(next, tuning.repCraft + (setting.verdict === 'parfait' ? tuning.repPerfect : 0), tuning);
  return { state: afterEvent(gained, { kind: 'craft', stars, perfect: setting.verdict === 'parfait' }, now, tuning), card };
}
