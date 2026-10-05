// Les bijoux des écrins (cahier §7). Raretés, probabilités, métaux, valeurs et textes repris
// du prototype Duo (docs/reference/prototype-duo.html). Valeurs en euros fictifs (cahier §17).
import type { Tuning } from '../tuning';
import type { Rng } from './rng';

export type JewelRarityId = 'toc' | 'fantaisie' | 'argent' | 'or' | 'perles' | 'saphir' | 'emeraude' | 'rubis' | 'diamant' | 'legende';
export type JewelType = 'bague' | 'collier' | 'bracelet' | 'boucles' | 'diademe';

export interface JewelRarity {
  id: JewelRarityId;
  label: string;
  /** 0 (toc) à 5 (légende). */
  tier: number;
  /** Symbole affiché : —, ◆ … ★★. */
  rarity: string;
  /** Probabilité de tirage (0…1). La somme fait 1. */
  probability: number;
  glow: string | null;
  metal: string;
  metalName: string;
  gem: string | null;
  suffix: string;
  carats: readonly [number, number] | null;
  /** Estimation en euros fictifs [min, max], avant carats et type de bijou. */
  value: readonly [number, number];
  flavor: string;
}

export const RARITY_SYMBOLS = ['—', '◆', '◆◆', '◆◆◆', '★', '★★'];
const r = (o: Omit<JewelRarity, 'rarity'>): JewelRarity => ({ ...o, rarity: RARITY_SYMBOLS[o.tier] });

export const JEWEL_RARITIES: readonly JewelRarity[] = [
  r({ id: 'toc', label: 'Toc', tier: 0, probability: 0.14, glow: null, metal: '#ff8fc4', metalName: 'Plastique', gem: '#ff3d8b', suffix: '', carats: null, value: [0.5, 3], flavor: '' }),
  r({ id: 'fantaisie', label: 'Fantaisie', tier: 1, probability: 0.24, glow: '#ffffff', metal: '#d9b56b', metalName: 'Laiton', gem: '#eef6ff', suffix: 'en strass', carats: null, value: [15, 60], flavor: 'Ça brille comme un vrai. De loin, la nuit.' }),
  r({ id: 'argent', label: 'Argent', tier: 1, probability: 0.2, glow: '#e6f0ff', metal: '#d7dbe0', metalName: 'Argent 925', gem: null, suffix: 'en argent', carats: null, value: [60, 250], flavor: 'Sobre, élégant, offert sans arrière-pensée.' }),
  r({ id: 'or', label: 'Or', tier: 2, probability: 0.14, glow: '#ffd27a', metal: '#e3b54d', metalName: 'Or 18 ct', gem: null, suffix: 'en or', carats: null, value: [400, 1500], flavor: "Le poids rassurant de l'or 18 carats." }),
  r({ id: 'perles', label: 'Perles', tier: 2, probability: 0.09, glow: '#fff1d6', metal: '#e3b54d', metalName: 'Or 18 ct', gem: null, suffix: '', carats: null, value: [600, 2500], flavor: "Chaque perle sort d'une huître. Quelqu'un en a beaucoup ouvert." }),
  r({ id: 'saphir', label: 'Saphir', tier: 3, probability: 0.07, glow: '#5d86ff', metal: '#e8eaee', metalName: 'Or blanc', gem: '#1f4fd1', suffix: 'au saphir', carats: [0.8, 3.5], value: [1200, 2200], flavor: 'Un bleu de nuit profonde, taillé pour durer.' }),
  r({ id: 'emeraude', label: 'Émeraude', tier: 3, probability: 0.05, glow: '#4dffb0', metal: '#e3b54d', metalName: 'Or jaune', gem: '#13a36b', suffix: "à l'émeraude", carats: [0.8, 3], value: [1800, 3000], flavor: 'Verte comme une promesse, et aussi fragile.' }),
  r({ id: 'rubis', label: 'Rubis', tier: 4, probability: 0.04, glow: '#ff4060', metal: '#e9b19a', metalName: 'Or rose', gem: '#c8102e', suffix: 'au rubis', carats: [0.8, 3], value: [3000, 5000], flavor: "La pierre des déclarations qu'on ne retire pas." }),
  r({ id: 'diamant', label: 'Diamant', tier: 4, probability: 0.025, glow: '#bfefff', metal: '#eef0f3', metalName: 'Platine', gem: '#f2fbff', suffix: '', carats: [0.5, 3], value: [6000, 11000], flavor: "Pour toujours. Ou au moins jusqu'au prochain écrin." }),
  r({ id: 'legende', label: 'Légende', tier: 5, probability: 0.005, glow: '#9ffcff', metal: '#eef0f3', metalName: 'Platine', gem: '#7df3ff', suffix: '', carats: [40, 45], value: [6000, 7000], flavor: "Aucun registre ne dit d'où il vient." }),
];

/** Les bijoux en toc : l'humour du jeu (cahier §2). */
const TOC_VARIANTS = [
  { name: 'Bague bonbon', metal: '#ff8fc4', gem: '#ff3d8b', metalName: 'Plastique', candy: true, flavor: 'Elle a un goût de fraise. Ne la garde pas trop longtemps.' },
  { name: 'Bague de fête foraine', metal: '#ffd400', gem: '#ff2a2a', metalName: 'Plastique', candy: true, flavor: 'Gagnée au chamboule-tout. Elle valait bien deux tickets.' },
  { name: 'Bague qui verdit', metal: '#9fa05a', gem: '#a9e8ff', metalName: 'Métal ?', candy: false, flavor: 'Ton doigt va changer de couleur. C’est normal.' },
];

const TYPES: readonly JewelType[] = ['bague', 'collier', 'bracelet', 'boucles'];
const TYPE_NAME: Record<JewelType, string> = { bague: 'Bague', collier: 'Collier', bracelet: 'Bracelet', boucles: "Boucles d'oreilles", diademe: 'Diadème' };
const TYPE_MULTIPLIER: Record<JewelType, number> = { bague: 1, collier: 1.4, bracelet: 1.2, boucles: 1.1, diademe: 1 };

/** Un bijou tiré, tel qu'il est dessiné et affiché. */
export interface Jewel {
  rarityId: JewelRarityId;
  type: JewelType;
  name: string;
  metal: string;
  metalName: string;
  gem: string | null;
  /** Pierre « bonbon » (toc) plutôt que taillée. */
  candy: boolean;
  /** Rang de perles (bijoux « Perles »). */
  pearls: boolean;
  carats: number;
  /** Estimation de base, avant l'éclat parfait. */
  value: number;
  flavor: string;
}

export function jewelRarity(id: JewelRarityId): JewelRarity {
  const found = JEWEL_RARITIES.find((j) => j.id === id);
  if (!found) throw new Error(`Rareté de bijou inconnue : ${id}`);
  return found;
}

export interface JewelDrawState {
  /** Écrins d'affilée sans bijou ★ ou mieux. */
  sinceStarOrBetter: number;
}

export const INITIAL_JEWEL_DRAW: JewelDrawState = { sinceStarOrBetter: 0 };

const isStarOrBetter = (rarity: JewelRarity) => rarity.tier >= 4;
const pick = <T>(list: readonly T[], rng: Rng): T => list[Math.min(list.length - 1, Math.floor(rng() * list.length))];

/** Arrondit une estimation : à l'euro au-delà de 10 €, au centime en dessous. */
export function roundValue(value: number): number {
  return value >= 10 ? Math.round(value) : Math.round(value * 100) / 100;
}

/** Tire un bijou. Garantie : ★ ou mieux après `ecrinPityThreshold` écrins sans. */
export function rollJewel(state: JewelDrawState, rng: Rng, tuning: Tuning): { jewel: Jewel; state: JewelDrawState } {
  const pool = state.sinceStarOrBetter >= tuning.ecrinPityThreshold ? JEWEL_RARITIES.filter(isStarOrBetter) : JEWEL_RARITIES;
  const total = pool.reduce((sum, j) => sum + j.probability, 0);
  let roll = rng() * total;
  let rarity = pool[pool.length - 1];
  for (const candidate of pool) {
    roll -= candidate.probability;
    if (roll < 0) {
      rarity = candidate;
      break;
    }
  }

  return {
    jewel: jewelOfRarity(rarity, rng),
    state: { sinceStarOrBetter: isStarOrBetter(rarity) ? 0 : state.sinceStarOrBetter + 1 },
  };
}

/** Fabrique un bijou d'une rareté donnée (type, nom, carats, estimation). Sert au tirage et à la poussière d'or. */
export function jewelOfRarity(rarity: JewelRarity, rng: Rng): Jewel {
  let type = pick(TYPES, rng);
  let name: string;
  let metal = rarity.metal;
  let metalName = rarity.metalName;
  let gem = rarity.gem;
  let candy = false;
  let flavor = rarity.flavor;
  if (rarity.id === 'toc') {
    const variant = pick(TOC_VARIANTS, rng);
    type = 'bague';
    ({ name, metal, metalName, gem, candy, flavor } = variant);
  } else if (rarity.id === 'perles') {
    type = pick(['collier', 'bracelet', 'boucles'] as const, rng);
    name = { collier: 'Collier de perles', bracelet: 'Bracelet de perles', boucles: "Boucles d'oreilles perles" }[type];
  } else if (rarity.id === 'diamant') {
    name = { bague: 'Solitaire diamant', collier: 'Rivière de diamants', bracelet: 'Bracelet de diamants', boucles: "Puces d'oreilles diamant", diademe: 'Diadème de diamants' }[type];
  } else if (rarity.id === 'legende') {
    type = 'diademe';
    name = 'Diadème des Abysses';
  } else {
    name = `${TYPE_NAME[type]} ${rarity.suffix}`;
  }

  const carats = rarity.carats ? Math.round((rarity.carats[0] + rng() * (rarity.carats[1] - rarity.carats[0])) * 100) / 100 : 0;
  const base = rarity.value[0] + rng() * (rarity.value[1] - rarity.value[0]);
  const value = roundValue(base * (carats ? Math.max(1, carats) : 1) * TYPE_MULTIPLIER[type]);

  return { rarityId: rarity.id, type, name, metal, metalName, gem, candy, pearls: rarity.id === 'perles', carats, value, flavor };
}

/** Variantes rares révélées par un éclat parfait (cahier §7). Couleurs : provisoires (AGENTS.md §6). */
export type JewelVariantId = 'aurore' | 'nuit' | 'givre';

export interface JewelVariant {
  id: JewelVariantId;
  label: string;
  metal: string;
  metalName: string;
  gem: string;
  glow: string;
  /** Cadre de la carte [haut-gauche, bas-droite] et texte clair ou foncé. */
  frame: { colors: [string, string]; dark: boolean };
  flavor: string;
}

export const JEWEL_VARIANTS: readonly JewelVariant[] = [
  { id: 'aurore', label: 'Aurore', metal: '#f1b9dc', metalName: 'Or aurore', gem: '#ffc4ec', glow: '#ff9ad5', frame: { colors: ['#ffd1e8', '#9af0ff'], dark: false }, flavor: 'Elle a gardé la couleur du premier rayon du matin.' },
  { id: 'nuit', label: 'Nuit', metal: '#3a3d5c', metalName: 'Or noir', gem: '#7f8cff', glow: '#7f8cff', frame: { colors: ['#3b3f6b', '#0b0c1a'], dark: true }, flavor: 'Taillée à minuit, elle ne brille que pour ceux qui savent regarder.' },
  { id: 'givre', label: 'Givre', metal: '#dff3ff', metalName: 'Platine givré', gem: '#bff3ff', glow: '#aef4ff', frame: { colors: ['#f2fbff', '#9ad7f0'], dark: false }, flavor: 'Froide au toucher, même en plein été.' },
];

export function jewelVariant(id: JewelVariantId): JewelVariant {
  const found = JEWEL_VARIANTS.find((v) => v.id === id);
  if (!found) throw new Error(`Variante inconnue : ${id}`);
  return found;
}

/** Tire la variante qu'aurait l'écrin en cas d'éclat parfait (null : pas de variante). */
export function rollRareVariant(rng: Rng, tuning: Tuning): JewelVariantId | null {
  if (rng() >= tuning.glintRareVariantChance) return null;
  return pick(JEWEL_VARIANTS, rng).id;
}

/** Le bijou transformé par sa variante : métal, pierre, nom et texte. */
export function withVariant(jewel: Jewel, variantId: JewelVariantId | null | undefined): Jewel {
  if (!variantId) return jewel;
  const variant = jewelVariant(variantId);
  return {
    ...jewel,
    name: `${jewel.name} · ${variant.label}`,
    metal: variant.metal,
    metalName: variant.metalName,
    gem: jewel.gem ? variant.gem : null,
    flavor: variant.flavor,
  };
}
