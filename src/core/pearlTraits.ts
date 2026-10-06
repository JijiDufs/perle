// Ce qui rend chaque perle unique : sa forme, son reflet (l'orient) et, rarement, une marque.
// Tirés avec la perle à la création de l'huître, puis sauvegardés (AGENTS.md, invariant 5).
// Listes, poids et facteurs de valeur : provisoires (AGENTS.md §6). Ils ne changent pas la rareté des perles.
import type { PearlId } from './catalog';
import type { Rng } from './rng';

export type PearlShape = 'ronde' | 'presque-ronde' | 'goutte' | 'bouton' | 'cerclee' | 'baroque';
export type PearlOvertone = 'argente' | 'creme' | 'rose' | 'lavande' | 'bleute' | 'vert-paon' | 'aubergine' | 'dore' | 'cuivre' | 'sang' | 'arc-en-ciel';
export type PearlMark = 'jumelle' | 'etoile' | 'lune' | 'coeur';

export interface PearlTraits {
  shape: PearlShape;
  overtone: PearlOvertone;
  /** Marque rare (null le plus souvent). */
  mark: PearlMark | null;
  /** 0…1 : petites irrégularités du dessin (lobes, position de la marque). */
  seed: number;
}

interface Trait {
  label: string;
  /** Facteur appliqué à la valeur de la perle. */
  value: number;
}

export const SHAPES: Readonly<Record<PearlShape, Trait>> = {
  ronde: { label: 'Ronde', value: 1.25 },
  'presque-ronde': { label: 'Presque ronde', value: 1 },
  goutte: { label: 'Goutte', value: 1.1 },
  bouton: { label: 'Bouton', value: 0.85 },
  cerclee: { label: 'Cerclée', value: 0.8 },
  baroque: { label: 'Baroque', value: 1 },
};

export const OVERTONES: Readonly<Record<PearlOvertone, Trait & { color: string }>> = {
  argente: { label: 'argenté', value: 1, color: '#dfe8f2' },
  creme: { label: 'crème', value: 0.95, color: '#f4e4c1' },
  rose: { label: 'rose', value: 1.1, color: '#ffc2d2' },
  lavande: { label: 'lavande', value: 1.1, color: '#c9b6ff' },
  bleute: { label: 'bleuté', value: 1.15, color: '#9cc4ff' },
  'vert-paon': { label: 'vert paon', value: 1.3, color: '#37c49c' },
  aubergine: { label: 'aubergine', value: 1.2, color: '#8a4f9e' },
  dore: { label: 'doré', value: 1.15, color: '#f2cf72' },
  cuivre: { label: 'cuivré', value: 1.05, color: '#de8d5c' },
  sang: { label: 'sang', value: 1, color: '#ff3160' },
  'arc-en-ciel': { label: 'arc-en-ciel', value: 1.5, color: '#b9f0ff' },
};

export const MARKS: Readonly<Record<PearlMark, Trait & { weight: number; description: string }>> = {
  jumelle: { label: 'Jumelle', value: 1.8, weight: 35, description: 'Deux perles soudées dans la même nacre.' },
  etoile: { label: 'Étoilée', value: 1.5, weight: 30, description: 'Un reflet en étoile, net comme un éclat.' },
  lune: { label: 'Lunaire', value: 1.4, weight: 25, description: 'Une tache pâle en croissant de lune.' },
  coeur: { label: 'En cœur', value: 2, weight: 10, description: 'La nacre a pris la forme d’un cœur.' },
};

type Weights<K extends string> = Partial<Record<K, number>>;
type FindablePearl = Exclude<PearlId, 'empty'>;

/** Formes possibles de chaque perle, avec leur poids. */
const SHAPE_WEIGHTS: Readonly<Record<FindablePearl, Weights<PearlShape>>> = {
  white: { ronde: 30, 'presque-ronde': 35, bouton: 15, goutte: 12, cerclee: 8 },
  rose: { ronde: 20, 'presque-ronde': 35, goutte: 25, bouton: 12, cerclee: 8 },
  baroque: { baroque: 100 },
  black: { ronde: 20, 'presque-ronde': 30, goutte: 20, cerclee: 20, bouton: 10 },
  golden: { ronde: 35, 'presque-ronde': 40, goutte: 15, bouton: 10 },
  giant: { ronde: 40, 'presque-ronde': 40, goutte: 20 },
  cursed: { 'presque-ronde': 60, cerclee: 40 },
};

/** Reflets possibles de chaque perle, avec leur poids. */
const OVERTONE_WEIGHTS: Readonly<Record<FindablePearl, Weights<PearlOvertone>>> = {
  white: { argente: 45, creme: 35, rose: 15, bleute: 5 },
  rose: { rose: 60, lavande: 20, creme: 15, 'arc-en-ciel': 5 },
  baroque: { lavande: 35, argente: 30, rose: 20, 'arc-en-ciel': 15 },
  black: { 'vert-paon': 35, aubergine: 35, bleute: 20, cuivre: 10 },
  golden: { dore: 70, cuivre: 25, 'arc-en-ciel': 5 },
  giant: { argente: 45, bleute: 40, 'arc-en-ciel': 15 },
  cursed: { sang: 80, aubergine: 20 },
};

/** Traits d'une perle d'avant les traits, ou achetée à la poussière d'or : la forme et le reflet les plus classiques. */
const DEFAULT_TRAITS: Readonly<Record<FindablePearl, Omit<PearlTraits, 'mark' | 'seed'>>> = {
  white: { shape: 'presque-ronde', overtone: 'argente' },
  rose: { shape: 'presque-ronde', overtone: 'rose' },
  baroque: { shape: 'baroque', overtone: 'lavande' },
  black: { shape: 'presque-ronde', overtone: 'vert-paon' },
  golden: { shape: 'ronde', overtone: 'dore' },
  giant: { shape: 'ronde', overtone: 'argente' },
  cursed: { shape: 'presque-ronde', overtone: 'sang' },
};

function pickWeighted<K extends string>(weights: Weights<K>, rng: Rng): K {
  const entries = Object.entries(weights) as [K, number][];
  const total = entries.reduce((sum, [, w]) => sum + w, 0);
  let roll = rng() * total;
  for (const [key, weight] of entries) {
    roll -= weight;
    if (roll < 0) return key;
  }
  return entries[entries.length - 1][0];
}

/** Tire les traits d'une perle. `markChance` : chance d'une marque rare (0 pendant le tutoriel). */
export function rollTraits(pearlId: FindablePearl, rng: Rng, markChance: number): PearlTraits {
  const shape = pickWeighted(SHAPE_WEIGHTS[pearlId], rng);
  const overtone = pickWeighted(OVERTONE_WEIGHTS[pearlId], rng);
  const markWeights = Object.fromEntries(Object.entries(MARKS).map(([id, mark]) => [id, mark.weight])) as Weights<PearlMark>;
  const mark = rng() < markChance ? pickWeighted(markWeights, rng) : null;
  return { shape, overtone, mark, seed: Math.round(rng() * 1000) / 1000 };
}

export function defaultTraits(pearlId: FindablePearl): PearlTraits {
  return { ...DEFAULT_TRAITS[pearlId], mark: null, seed: 0.5 };
}

/** Les traits d'une carte, ou ceux par défaut pour les cartes d'avant les traits. */
export function traitsOf(card: { pearlId: PearlId; traits?: PearlTraits }): PearlTraits | null {
  if (card.pearlId === 'empty') return null;
  return card.traits ?? defaultTraits(card.pearlId);
}

export function traitsValueFactor(traits: PearlTraits): number {
  return SHAPES[traits.shape].value * OVERTONES[traits.overtone].value * (traits.mark ? MARKS[traits.mark].value : 1);
}

/** « Goutte · reflet vert paon ». */
export function traitsLabel(traits: PearlTraits): string {
  return `${SHAPES[traits.shape].label} · reflet ${OVERTONES[traits.overtone].label}`;
}

/** Formes et reflets qu'une perle peut avoir (carnet des variantes). */
export function shapesOf(pearlId: FindablePearl): PearlShape[] {
  return Object.keys(SHAPE_WEIGHTS[pearlId]) as PearlShape[];
}

export function overtonesOf(pearlId: FindablePearl): PearlOvertone[] {
  return Object.keys(OVERTONE_WEIGHTS[pearlId]) as PearlOvertone[];
}

/** Couleur de la perle teintée par son reflet (montures de l'atelier). */
export function pearlTint(baseColor: string, traits: PearlTraits | null): string {
  if (!traits) return baseColor;
  const mix = (a: string, b: string, k: number) => {
    const ca = [1, 3, 5].map((i) => parseInt(a.slice(i, i + 2), 16));
    const cb = [1, 3, 5].map((i) => parseInt(b.slice(i, i + 2), 16));
    return `#${ca.map((v, i) => Math.round(v + (cb[i] - v) * k).toString(16).padStart(2, '0')).join('')}`;
  };
  return mix(baseColor, OVERTONES[traits.overtone].color, 0.25);
}
