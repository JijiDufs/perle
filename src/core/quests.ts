// Quêtes du jour (cahier §15) : trois petits objectifs, renouvelés chaque jour à minuit (heure locale).
// Tirées avec une graine = le jour : tout le monde a les mêmes, et recharger ne les change pas.
import type { Tuning } from '../tuning';
import type { Lustre } from './lustre';
import { seededRng } from './rng';

export type QuestKind = 'open' | 'lustreA' | 'lustreS' | 'rare' | 'noCrack' | 'ecrin' | 'perfect' | 'melt';

export interface Quest {
  kind: QuestKind;
  goal: number;
  progress: number;
  claimed: boolean;
}

export interface DailyQuests {
  /** Jour local, AAAA-MM-JJ. */
  day: string;
  quests: Quest[];
  /** Bonus des trois quêtes (un écrin) déjà donné. */
  bonusClaimed: boolean;
}

interface QuestTemplate {
  kind: QuestKind;
  goals: readonly number[];
  /** Demande un écrin à ouvrir : seulement quand le joueur en a. */
  needsEcrin?: boolean;
}

const POOL: readonly QuestTemplate[] = [
  { kind: 'open', goals: [5, 8] },
  { kind: 'lustreA', goals: [2, 3] },
  { kind: 'lustreS', goals: [1] },
  { kind: 'rare', goals: [1] },
  { kind: 'noCrack', goals: [3, 5] },
  { kind: 'ecrin', goals: [1], needsEcrin: true },
  { kind: 'perfect', goals: [1], needsEcrin: true },
  { kind: 'melt', goals: [1, 3] },
];

export function questText(quest: Pick<Quest, 'kind' | 'goal'>): string {
  const n = quest.goal;
  const s = n > 1 ? 's' : '';
  switch (quest.kind) {
    case 'open':
      return `Ouvrir ${n} huîtres`;
    case 'lustreA':
      return `Obtenir ${n} lustre${s} A ou S`;
    case 'lustreS':
      return `Obtenir ${n} lustre${s} S`;
    case 'rare':
      return 'Trouver une perle ◆◆ ou plus rare';
    case 'noCrack':
      return `Ouvrir ${n} huîtres d’affilée sans fêlure`;
    case 'ecrin':
      return 'Ouvrir un écrin';
    case 'perfect':
      return 'Réussir un éclat parfait';
    case 'melt':
      return `Fondre ${n} doublon${s} en poussière d’or`;
  }
}

/** Jour local d'un instant (ms), AAAA-MM-JJ. */
export function dayKey(now: number): string {
  const d = new Date(now);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

/** Temps (ms) avant minuit, heure locale : le renouvellement des quêtes. */
export function msUntilNextDay(now: number): number {
  const d = new Date(now);
  const midnight = new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1).getTime();
  return midnight - now;
}

/** Les quêtes du jour, tirées si besoin. `ecrinsAvailable` : le joueur a débloqué les écrins. */
export function questsForDay(current: DailyQuests | null, now: number, ecrinsAvailable: boolean, tuning: Tuning): DailyQuests {
  const day = dayKey(now);
  if (current?.day === day) return current;
  const seed = Number(day.split('-').join(''));
  const rng = seededRng(seed);
  const pool = POOL.filter((t) => ecrinsAvailable || !t.needsEcrin);
  const quests: Quest[] = [];
  while (quests.length < Math.min(tuning.questsPerDay, pool.length)) {
    const template = pool[Math.floor(rng() * pool.length)];
    if (quests.some((q) => q.kind === template.kind)) continue;
    // Lustre S et lustre A ensemble : trop proches.
    if (quests.some((q) => (q.kind === 'lustreS' && template.kind === 'lustreA') || (q.kind === 'lustreA' && template.kind === 'lustreS'))) continue;
    const goal = template.goals[Math.floor(rng() * template.goals.length)];
    quests.push({ kind: template.kind, goal, progress: 0, claimed: false });
  }
  return { day, quests, bonusClaimed: false };
}

/** Ce qui fait avancer une quête. */
export type QuestEvent =
  | { kind: 'oyster'; tier: number; lustre: Lustre; cracked: boolean; empty: boolean }
  | { kind: 'ecrin'; perfect: boolean }
  | { kind: 'melt' };

export function advanceQuests(daily: DailyQuests, event: QuestEvent): DailyQuests {
  const quests = daily.quests.map((quest) => {
    if (quest.progress >= quest.goal) return quest;
    let progress = quest.progress;
    if (event.kind === 'oyster') {
      const pearl = !event.empty;
      if (quest.kind === 'open') progress++;
      if (quest.kind === 'lustreA' && pearl && !event.cracked && (event.lustre === 'A' || event.lustre === 'S')) progress++;
      if (quest.kind === 'lustreS' && pearl && !event.cracked && event.lustre === 'S') progress++;
      if (quest.kind === 'rare' && event.tier >= 2) progress++;
      if (quest.kind === 'noCrack') progress = event.cracked ? 0 : progress + 1;
    } else if (event.kind === 'ecrin') {
      if (quest.kind === 'ecrin') progress++;
      if (quest.kind === 'perfect' && event.perfect) progress++;
    } else if (event.kind === 'melt' && quest.kind === 'melt') {
      progress++;
    }
    return { ...quest, progress: Math.min(progress, quest.goal) };
  });
  return { ...daily, quests };
}

export const isComplete = (quest: Quest) => quest.progress >= quest.goal;
export const isClaimable = (quest: Quest) => isComplete(quest) && !quest.claimed;
