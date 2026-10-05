// Niveaux, réputation et rangs de prestige (cahier §8 et §9).
// Rangs et déblocages : textes du cahier. Gains et courbe : src/tuning.ts (provisoires, AGENTS.md §6).
import type { Tuning } from '../tuning';
import { pearlTier, type PearlId } from './catalog';
import type { Lustre } from './lustre';
import type { StockState } from './stock';

export interface Rank {
  id: string;
  title: string;
  level: number;
  /** Ce que le rang ouvre, d'après le cahier. */
  opens: string;
}

/** Rangs de prestige (cahier §8). */
export const RANKS: readonly Rank[] = [
  { id: 'pecheur', title: 'Pêcheur', level: 1, opens: 'La Crique, l’ouverture d’huîtres' },
  { id: 'perlier', title: 'Perlier', level: 5, opens: 'L’atelier, les premières recettes' },
  { id: 'artisan', title: 'Artisan', level: 10, opens: 'La vitrine, les commandes clients' },
  { id: 'joaillier', title: 'Joaillier', level: 20, opens: 'Deuxième établi, taille de pierres, Salon hebdomadaire' },
  { id: 'maitre', title: 'Maître joaillier', level: 35, opens: 'Personnel, pièces maîtresses, musée' },
  { id: 'maison', title: 'Maison de haute joaillerie', level: 50, opens: 'Collections signées, défilés' },
];

export interface Milestone {
  level: number;
  label: string;
  /** Déjà jouable dans le prototype ; sinon, « à venir ». */
  available: boolean;
}

/** Déblocages (cahier §9). Seuls ceux qui existent dans le prototype sont marqués disponibles. */
export const MILESTONES: readonly Milestone[] = [
  { level: 1, label: 'Pêche, La Crique', available: true },
  { level: 1, label: 'Écrins (après le tutoriel)', available: true },
  { level: 5, label: 'Atelier (dans la Maison)', available: true },
  { level: 8, label: 'Commandes clients, Le Lagon', available: false },
  { level: 10, label: 'Vitrine, amis et cadeaux', available: false },
  { level: 15, label: 'Le Récif, taille de pierres', available: false },
  { level: 20, label: 'Deuxième établi, Salon hebdomadaire', available: false },
  { level: 25, label: 'Les Abysses, épaves', available: false },
  { level: 35, label: 'Personnel, musée ouvert', available: false },
  { level: 40, label: 'La Fosse polaire', available: false },
  { level: 50, label: 'Maison de haute joaillerie, collections signées', available: false },
];

/** Réputation pour passer du niveau `level` au suivant. */
export function xpToNext(level: number, tuning: Tuning): number {
  return Math.round(tuning.levelBaseXp + tuning.levelGrowthXp * Math.pow(level, tuning.levelGrowthPower));
}

export interface LevelProgress {
  level: number;
  /** Réputation acquise dans le niveau en cours. */
  into: number;
  /** Réputation nécessaire pour le niveau suivant (0 au niveau maximum). */
  needed: number;
}

export function levelFromXp(xp: number, tuning: Tuning): LevelProgress {
  let level = 1;
  let rest = Math.max(0, xp);
  while (level < tuning.maxLevel && rest >= xpToNext(level, tuning)) {
    rest -= xpToNext(level, tuning);
    level++;
  }
  return { level, into: level >= tuning.maxLevel ? 0 : rest, needed: level >= tuning.maxLevel ? 0 : xpToNext(level, tuning) };
}

export function rankForLevel(level: number): Rank {
  return [...RANKS].reverse().find((r) => level >= r.level) ?? RANKS[0];
}

/** Prochain rang, ou null au dernier. */
export function nextRank(level: number): Rank | null {
  return RANKS.find((r) => r.level > level) ?? null;
}

/** Prochain déblocage (après le niveau donné), pour donner un horizon (cahier §15). */
export function nextMilestone(level: number): Milestone | null {
  return MILESTONES.find((m) => m.level > level) ?? null;
}

export interface LevelReward {
  level: number;
  oysters: number;
  dust: number;
  ecrins: number;
  /** Rang atteint à ce niveau, s'il y en a un. */
  rank: Rank | null;
}

/** Récompense en arrivant au niveau `level`. Un écrin de plus en changeant de rang. */
export function levelReward(level: number, tuning: Tuning): LevelReward {
  const rank = RANKS.find((r) => r.level === level && r.level > 1) ?? null;
  const ecrins = (level % tuning.levelEcrinEvery === 0 ? 1 : 0) + (rank ? 1 : 0);
  return { level, oysters: tuning.levelRewardOysters, dust: tuning.levelRewardDust, ecrins, rank };
}

/** Ce qui rapporte de la réputation. */
export type ReputationEvent =
  | { kind: 'oyster'; pearlId: PearlId; lustre: Lustre; cracked: boolean; discovery: boolean }
  | { kind: 'ecrin'; perfect: boolean; discovery: boolean }
  | { kind: 'expertise'; certified: boolean };

export function reputationFor(event: ReputationEvent, tuning: Tuning): number {
  switch (event.kind) {
    case 'oyster': {
      if (event.pearlId === 'empty') return tuning.repOyster;
      const lustre = event.cracked ? 0 : event.lustre === 'S' ? tuning.repLustreS : event.lustre === 'A' ? tuning.repLustreA : 0;
      return tuning.repOyster + tuning.repPerTier * pearlTier(event.pearlId) + lustre + (event.discovery ? tuning.repDiscovery : 0);
    }
    case 'ecrin':
      return tuning.repEcrin + (event.perfect ? tuning.repPerfect : 0) + (event.discovery ? tuning.repDiscovery : 0);
    case 'expertise':
      return event.certified ? tuning.repExpertise : 0;
  }
}

/** Ce que la réputation touche dans l'état du joueur. */
export interface ReputationState {
  reputation: number;
  /** Dernier niveau dont la récompense a été donnée (une seule fois par niveau). */
  rewardedLevel: number;
  stock: StockState;
  dust: number;
  ecrins: number;
}

/** Ajoute de la réputation et donne les récompenses des niveaux franchis. */
export function gainReputation<S extends ReputationState>(state: S, amount: number, tuning: Tuning): S {
  if (amount <= 0) return state;
  const reputation = state.reputation + amount;
  const { level } = levelFromXp(reputation, tuning);
  let next: S = { ...state, reputation };
  for (let l = state.rewardedLevel + 1; l <= level; l++) {
    const reward = levelReward(l, tuning);
    next = {
      ...next,
      rewardedLevel: l,
      stock: { ...next.stock, count: next.stock.count + reward.oysters },
      dust: next.dust + reward.dust,
      ecrins: next.ecrins + reward.ecrins,
    };
  }
  return next;
}
