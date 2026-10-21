// Les bijoux des écrins (cahier §7). Raretés, probabilités, métaux, valeurs et textes repris
// du prototype Duo (docs/reference/prototype-duo.html). Valeurs en euros fictifs (cahier §17).
import type { Tuning } from '../tuning';
import type { Rng } from './rng';

export type JewelRarityId = 'toc' | 'fantaisie' | 'argent' | 'or' | 'perles' | 'saphir' | 'emeraude' | 'rubis' | 'diamant' | 'legende';
export type JewelType = 'bague' | 'collier' | 'bracelet' | 'boucles' | 'pendentif' | 'broche' | 'diademe';
/** Taille de la pierre (cahier §7 : « chaque tirage combine une rareté, un type, un métal, un poids »). */
export type GemCut = 'rond' | 'ovale' | 'poire' | 'coussin' | 'emeraude' | 'princesse' | 'coeur' | 'marquise';
/** Modèle du bijou : change son dessin, son nom et un peu sa valeur. */
export type JewelStyle =
  | 'solitaire' | 'trilogie' | 'cocktail' | 'jonc' | 'chevaliere' | 'perle'
  | 'riviere' | 'chaine' | 'rang' | 'sautoir'
  | 'tennis' | 'gourmette'
  | 'puces' | 'pendants' | 'creoles'
  | 'goutte' | 'coeur' | 'medaille' | 'coquillage'
  | 'fleur' | 'libellule' | 'etoile'
  | 'classique';

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
export const TOC_VARIANTS = [
  { name: 'Bague bonbon', metal: '#ff8fc4', gem: '#ff3d8b', metalName: 'Plastique', candy: true, flavor: 'Elle a un goût de fraise. Ne la garde pas trop longtemps.' },
  { name: 'Bague de fête foraine', metal: '#ffd400', gem: '#ff2a2a', metalName: 'Plastique', candy: true, flavor: 'Gagnée au chamboule-tout. Elle valait bien deux tickets.' },
  { name: 'Bague qui verdit', metal: '#9fa05a', gem: '#a9e8ff', metalName: 'Métal ?', candy: false, flavor: 'Ton doigt va changer de couleur. C’est normal.' },
];

const TYPE_NAME: Record<JewelType, string> = { bague: 'Bague', collier: 'Collier', bracelet: 'Bracelet', boucles: "Boucles d'oreilles", pendentif: 'Pendentif', broche: 'Broche', diademe: 'Diadème' };
export const TYPE_MULTIPLIER: Readonly<Record<JewelType, number>> = { bague: 1, collier: 1.4, bracelet: 1.2, boucles: 1.1, pendentif: 1.1, broche: 1.2, diademe: 1 };

export const JEWEL_TYPE_LABELS: Readonly<Record<JewelType, string>> = TYPE_NAME;

export const GEM_CUTS: Readonly<Record<GemCut, { label: string; value: number }>> = {
  rond: { label: 'Brillant rond', value: 1 },
  ovale: { label: 'Ovale', value: 1 },
  poire: { label: 'Poire', value: 1.1 },
  coussin: { label: 'Coussin', value: 1.05 },
  emeraude: { label: 'Émeraude', value: 1.05 },
  princesse: { label: 'Princesse', value: 1 },
  coeur: { label: 'Cœur', value: 1.2 },
  marquise: { label: 'Marquise', value: 1.1 },
};

export const JEWEL_STYLES: Readonly<Record<JewelStyle, { label: string; value: number }>> = {
  solitaire: { label: 'Solitaire', value: 1 },
  trilogie: { label: 'Trilogie', value: 1.3 },
  cocktail: { label: 'Cocktail', value: 1.5 },
  jonc: { label: 'Jonc', value: 0.9 },
  chevaliere: { label: 'Chevalière', value: 1.1 },
  perle: { label: 'Perle', value: 1 },
  riviere: { label: 'Rivière', value: 1.6 },
  chaine: { label: 'Chaîne', value: 0.8 },
  rang: { label: 'Rang', value: 1 },
  sautoir: { label: 'Sautoir', value: 1.3 },
  tennis: { label: 'Tennis', value: 1.4 },
  gourmette: { label: 'Gourmette', value: 1 },
  puces: { label: 'Puces', value: 0.9 },
  pendants: { label: 'Pendants', value: 1.1 },
  creoles: { label: 'Créoles', value: 0.9 },
  goutte: { label: 'Goutte', value: 1 },
  coeur: { label: 'Cœur', value: 1.1 },
  medaille: { label: 'Médaille', value: 0.8 },
  coquillage: { label: 'Coquillage', value: 0.9 },
  fleur: { label: 'Fleur', value: 1.1 },
  libellule: { label: 'Libellule', value: 1.3 },
  etoile: { label: 'Étoile de mer', value: 1.1 },
  classique: { label: 'Classique', value: 1.8 },
};

export type Weights<K extends string> = Partial<Record<K, number>>;

/** Métaux possibles par rareté : [couleur, nom, poids]. Le métal de la rareté reste celui par défaut. */
export const METAL_OPTIONS: Partial<Record<JewelRarityId, readonly [string, string, number][]>> = {
  fantaisie: [['#d9b56b', 'Laiton', 60], ['#cfd5db', 'Métal argenté', 40]],
  argent: [['#d7dbe0', 'Argent 925', 80], ['#e8c27a', 'Vermeil', 20]],
  or: [['#e3b54d', 'Or jaune', 55], ['#e9b19a', 'Or rose', 25], ['#e8eaee', 'Or blanc', 20]],
  perles: [['#e3b54d', 'Or jaune', 50], ['#e8eaee', 'Or blanc', 30], ['#e9b19a', 'Or rose', 20]],
  saphir: [['#e8eaee', 'Or blanc', 50], ['#eef0f3', 'Platine', 30], ['#e3b54d', 'Or jaune', 20]],
  emeraude: [['#e3b54d', 'Or jaune', 55], ['#eef0f3', 'Platine', 25], ['#e8eaee', 'Or blanc', 20]],
  rubis: [['#e9b19a', 'Or rose', 45], ['#e3b54d', 'Or jaune', 35], ['#eef0f3', 'Platine', 20]],
  diamant: [['#eef0f3', 'Platine', 50], ['#e8eaee', 'Or blanc', 30], ['#e9b19a', 'Or rose', 20]],
};

/** Tailles possibles par pierre, avec leur poids. */
export const CUT_WEIGHTS: Partial<Record<JewelRarityId, Weights<GemCut>>> = {
  fantaisie: { rond: 70, ovale: 15, coeur: 15 },
  saphir: { ovale: 35, coussin: 25, rond: 20, poire: 10, marquise: 10 },
  emeraude: { emeraude: 55, ovale: 15, poire: 15, coussin: 15 },
  rubis: { poire: 25, coussin: 25, ovale: 20, rond: 15, coeur: 15 },
  diamant: { rond: 35, princesse: 15, poire: 12, ovale: 10, marquise: 10, coeur: 8, emeraude: 5, coussin: 5 },
};

/** Ce qui orne le bijou : des pierres, des perles, ou le métal seul. */
export type Ornament = 'gem' | 'pearls' | 'metal';

export const TYPE_WEIGHTS: Record<Ornament, Weights<JewelType>> = {
  gem: { bague: 26, collier: 16, bracelet: 14, boucles: 16, pendentif: 16, broche: 10 },
  metal: { bague: 26, collier: 18, bracelet: 18, boucles: 16, pendentif: 14, broche: 8 },
  pearls: { collier: 35, bracelet: 20, boucles: 25, pendentif: 20 },
};

export const STYLE_WEIGHTS: Record<Ornament, Partial<Record<JewelType, Weights<JewelStyle>>>> = {
  gem: {
    bague: { solitaire: 45, trilogie: 30, cocktail: 25 },
    collier: { solitaire: 55, riviere: 45 },
    bracelet: { tennis: 60, jonc: 40 },
    boucles: { puces: 45, pendants: 35, creoles: 20 },
    pendentif: { goutte: 50, coeur: 50 },
    broche: { fleur: 35, libellule: 35, etoile: 30 },
    diademe: { classique: 100 },
  },
  metal: {
    bague: { jonc: 55, chevaliere: 45 },
    collier: { chaine: 100 },
    bracelet: { jonc: 50, gourmette: 50 },
    boucles: { creoles: 100 },
    pendentif: { medaille: 50, coquillage: 50 },
    broche: { fleur: 35, libellule: 30, etoile: 35 },
  },
  pearls: {
    collier: { rang: 65, sautoir: 35 },
    bracelet: { rang: 100 },
    boucles: { puces: 50, pendants: 50 },
    pendentif: { goutte: 100 },
  },
};

/** Diadème possible à partir de cette rareté (poids parmi les types). */
export const DIADEM_MIN_TIER = 4;
export const DIADEM_WEIGHT = 2;

/** Le seul bijou Légende. */
export const LEGEND_NAME = 'Diadème des Abysses';

/** Comment on nomme les pierres : une (« au saphir »), plusieurs avec (« aux saphirs »), plusieurs de (« de saphirs »). */
export const GEM_WORDS: Partial<Record<JewelRarityId, { one: string; with: string; of: string }>> = {
  fantaisie: { one: 'en strass', with: 'en strass', of: 'de strass' },
  saphir: { one: 'au saphir', with: 'aux saphirs', of: 'de saphirs' },
  emeraude: { one: "à l'émeraude", with: 'aux émeraudes', of: "d'émeraudes" },
  rubis: { one: 'au rubis', with: 'aux rubis', of: 'de rubis' },
  diamant: { one: 'diamant', with: 'aux diamants', of: 'de diamants' },
};

/**
 * Noms des bijoux selon ce qui les orne et leur modèle (clé « modèle.type » pour un type précis, sinon « modèle »).
 * {one}, {with}, {of} : les pierres (GEM_WORDS) ; {metal} : le métal en minuscules (« argent », « or rose »).
 * Données plutôt que code : l'app iOS a les mêmes en anglais (catalogEnglish.ts).
 */
export const JEWEL_NAMES: Readonly<Record<Ornament, Readonly<Record<string, string>>>> = {
  pearls: {
    'rang.bracelet': 'Bracelet de perles',
    rang: 'Collier de perles',
    sautoir: 'Sautoir de perles',
    puces: "Puces d'oreilles perle",
    pendants: "Pendants d'oreilles perle",
    goutte: 'Pendentif perle',
  },
  metal: {
    'jonc.bague': 'Bague jonc en {metal}',
    jonc: 'Jonc en {metal}',
    chevaliere: 'Chevalière en {metal}',
    chaine: 'Chaîne en {metal}',
    gourmette: 'Gourmette en {metal}',
    creoles: 'Créoles en {metal}',
    medaille: 'Médaille en {metal}',
    coquillage: 'Pendentif coquillage en {metal}',
    fleur: 'Broche fleur en {metal}',
    libellule: 'Broche libellule en {metal}',
    etoile: 'Broche étoile de mer en {metal}',
  },
  gem: {
    'solitaire.bague': 'Solitaire {one}',
    solitaire: 'Collier {one}',
    trilogie: 'Bague trilogie {with}',
    cocktail: 'Bague cocktail {one}',
    riviere: 'Rivière {of}',
    tennis: 'Bracelet tennis {of}',
    jonc: 'Jonc serti {of}',
    puces: "Puces d'oreilles {one}",
    pendants: "Pendants d'oreilles {one}",
    creoles: 'Créoles serties {of}',
    goutte: 'Pendentif goutte {one}',
    coeur: 'Pendentif cœur {one}',
    fleur: 'Broche fleur {with}',
    libellule: 'Broche libellule {with}',
    etoile: 'Broche étoile de mer {with}',
    classique: 'Diadème {of}',
  },
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

const ornamentOf = (rarity: JewelRarity): Ornament => (rarity.id === 'perles' ? 'pearls' : rarity.gem ? 'gem' : 'metal');

/** Nom du bijou selon son modèle, ses pierres ou son métal. */
function jewelName(type: JewelType, style: JewelStyle, rarity: JewelRarity, metalName: string): string {
  const names = JEWEL_NAMES[ornamentOf(rarity)];
  const words = GEM_WORDS[rarity.id];
  const template = names[`${style}.${type}`] ?? names[style] ?? TYPE_NAME[type];
  return template
    .replace('{metal}', metalName.toLowerCase().replace(' 925', ''))
    .replace('{one}', words?.one ?? '')
    .replace('{with}', words?.with ?? '')
    .replace('{of}', words?.of ?? '');
}

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
  /** Couleurs des perles (bijoux de l'atelier) ; sinon perles blanches. */
  pearlColors?: string[];
  /** Modèle (absent des bijoux d'avant les modèles : le dessin en déduit un). */
  style?: JewelStyle;
  /** Taille de la pierre (bijoux à pierre seulement). */
  cut?: GemCut;
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

/** Types qu'un bijou de cette rareté peut avoir (carnet des variantes). */
export function jewelTypesFor(rarityId: JewelRarityId): JewelType[] {
  if (rarityId === 'toc') return ['bague'];
  if (rarityId === 'legende') return ['diademe'];
  const rarity = jewelRarity(rarityId);
  const ornament = ornamentOf(rarity);
  const types = Object.keys(TYPE_WEIGHTS[ornament]) as JewelType[];
  return ornament === 'gem' && rarity.tier >= DIADEM_MIN_TIER ? [...types, 'diademe'] : types;
}

/** Un pendentif goutte porte une pierre taillée en poire, un pendentif cœur une pierre en cœur. */
export const FORCED_CUTS: Partial<Record<JewelStyle, GemCut>> = { goutte: 'poire', coeur: 'coeur' };

/** Tailles qu'une pierre de cette rareté peut avoir, pendentifs compris (vide : pas de pierre taillée). */
export function gemCutsFor(rarityId: JewelRarityId): GemCut[] {
  const cuts = Object.keys(CUT_WEIGHTS[rarityId] ?? {}) as GemCut[];
  if (!cuts.length) return cuts;
  return [...new Set([...cuts, ...Object.values(FORCED_CUTS)])];
}

/** Les types de bijoux d'un écrin complet (cahier §10 : 6 types ; le diadème est à part). */
export const MAIN_JEWEL_TYPES: readonly JewelType[] = ['bague', 'collier', 'bracelet', 'boucles', 'pendentif', 'broche'];

/**
 * Fabrique un bijou d'une rareté donnée : type, modèle, métal, taille de pierre, carats, nom et estimation.
 * Sert au tirage et à la poussière d'or.
 */
export function jewelOfRarity(rarity: JewelRarity, rng: Rng): Jewel {
  const carats = () => (rarity.carats ? Math.round((rarity.carats[0] + rng() * (rarity.carats[1] - rarity.carats[0])) * 100) / 100 : 0);
  const estimate = (type: JewelType, style: JewelStyle | undefined, cut: GemCut | undefined, weight: number) => {
    const base = rarity.value[0] + rng() * (rarity.value[1] - rarity.value[0]);
    const styleFactor = style ? JEWEL_STYLES[style].value : 1;
    const cutFactor = cut ? GEM_CUTS[cut].value : 1;
    return roundValue(base * (weight ? Math.max(1, weight) : 1) * TYPE_MULTIPLIER[type] * styleFactor * cutFactor);
  };

  if (rarity.id === 'toc') {
    const variant = TOC_VARIANTS[Math.min(TOC_VARIANTS.length - 1, Math.floor(rng() * TOC_VARIANTS.length))];
    const value = estimate('bague', undefined, undefined, 0);
    return { rarityId: rarity.id, type: 'bague', name: variant.name, metal: variant.metal, metalName: variant.metalName, gem: variant.gem, candy: variant.candy, pearls: false, carats: 0, value, flavor: variant.flavor, style: 'solitaire' };
  }
  if (rarity.id === 'legende') {
    const weight = carats();
    return { rarityId: rarity.id, type: 'diademe', name: LEGEND_NAME, metal: rarity.metal, metalName: rarity.metalName, gem: rarity.gem, candy: false, pearls: false, carats: weight, value: estimate('diademe', undefined, undefined, weight), flavor: rarity.flavor, style: 'classique', cut: 'rond' };
  }

  const ornament = ornamentOf(rarity);
  const typeWeights: Weights<JewelType> = { ...TYPE_WEIGHTS[ornament] };
  if (ornament === 'gem' && rarity.tier >= DIADEM_MIN_TIER) typeWeights.diademe = DIADEM_WEIGHT;
  const type = pickWeighted(typeWeights, rng);
  const style = pickWeighted(STYLE_WEIGHTS[ornament][type]!, rng);
  const options = METAL_OPTIONS[rarity.id] ?? [[rarity.metal, rarity.metalName, 1] as const];
  const [metal, metalName] = options[Number(pickWeighted(Object.fromEntries(options.map(([, , weight], i) => [String(i), weight])), rng))];
  const cutWeights = CUT_WEIGHTS[rarity.id];
  const rolledCut = cutWeights ? pickWeighted(cutWeights, rng) : undefined;
  const cut = rolledCut && (FORCED_CUTS[style] ?? rolledCut);
  const weight = carats();
  return {
    rarityId: rarity.id,
    type,
    name: jewelName(type, style, rarity, metalName),
    metal,
    metalName,
    gem: rarity.gem,
    candy: false,
    pearls: rarity.id === 'perles',
    carats: weight,
    value: estimate(type, style, cut, weight),
    flavor: rarity.flavor,
    style,
    ...(cut ? { cut } : {}),
  };
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
