// Ce qui suit chaque action du joueur : statistiques, quêtes du jour, succès.
// Appelé par le Core lui-même (player.ts, dust.ts, expertise.ts) : les vues n'ont rien à faire.
import type { Tuning } from '../tuning';
import { ACHIEVEMENTS, achievementReward, isDone } from './achievements';
import { pearlTier, type PearlId } from './catalog';
import { gainReputation } from './levels';
import type { Lustre } from './lustre';
import type { PlayerState } from './player';
import { advanceQuests, isClaimable, questsForDay, type QuestEvent } from './quests';
import { isEcrinUnlocked, isInTutorial } from './tutorial';

export interface PlayerStats {
  emptyOysters: number;
  /** Huîtres d'affilée sans fêlure (en cours, et meilleure série). */
  crackFreeStreak: number;
  bestCrackFreeStreak: number;
  lustreS: number;
  perfectGlints: number;
  variants: number;
  melted: number;
  excellentCertificates: number;
  /** Bijoux fabriqués à l'atelier, sertissages parfaits, et créations 5 étoiles. */
  crafted: number;
  perfectSettings: number;
  fiveStars: number;
}

export const INITIAL_STATS: PlayerStats = {
  emptyOysters: 0,
  crackFreeStreak: 0,
  bestCrackFreeStreak: 0,
  lustreS: 0,
  perfectGlints: 0,
  variants: 0,
  melted: 0,
  excellentCertificates: 0,
  crafted: 0,
  perfectSettings: 0,
  fiveStars: 0,
};

export type GameEvent =
  | { kind: 'oyster'; pearlId: PearlId; lustre: Lustre; cracked: boolean }
  | { kind: 'ecrin'; perfect: boolean; variant: boolean }
  | { kind: 'melt' }
  | { kind: 'expertise'; excellent: boolean }
  | { kind: 'craft'; stars: number; perfect: boolean };

function updateStats(stats: PlayerStats, event: GameEvent): PlayerStats {
  switch (event.kind) {
    case 'oyster': {
      const empty = event.pearlId === 'empty';
      const crackFreeStreak = event.cracked && !empty ? 0 : stats.crackFreeStreak + 1;
      return {
        ...stats,
        emptyOysters: stats.emptyOysters + (empty ? 1 : 0),
        crackFreeStreak,
        bestCrackFreeStreak: Math.max(stats.bestCrackFreeStreak, crackFreeStreak),
        lustreS: stats.lustreS + (!empty && !event.cracked && event.lustre === 'S' ? 1 : 0),
      };
    }
    case 'ecrin':
      return { ...stats, perfectGlints: stats.perfectGlints + (event.perfect ? 1 : 0), variants: stats.variants + (event.variant ? 1 : 0) };
    case 'melt':
      return { ...stats, melted: stats.melted + 1 };
    case 'expertise':
      return { ...stats, excellentCertificates: stats.excellentCertificates + (event.excellent ? 1 : 0) };
    case 'craft':
      return {
        ...stats,
        crafted: stats.crafted + 1,
        perfectSettings: stats.perfectSettings + (event.perfect ? 1 : 0),
        fiveStars: stats.fiveStars + (event.stars >= 5 ? 1 : 0),
      };
  }
}

function questEvent(event: GameEvent): QuestEvent | null {
  switch (event.kind) {
    case 'oyster': {
      const empty = event.pearlId === 'empty';
      return { kind: 'oyster', tier: empty ? 0 : pearlTier(event.pearlId), lustre: event.lustre, cracked: event.cracked && !empty, empty };
    }
    case 'ecrin':
      return { kind: 'ecrin', perfect: event.perfect };
    case 'melt':
      return { kind: 'melt' };
    case 'expertise':
    case 'craft':
      return null;
  }
}

/** Les quêtes du jour du joueur (null pendant le tutoriel : une chose à la fois). */
export function currentQuests(state: PlayerState, now: number, tuning: Tuning) {
  if (isInTutorial(state.oystersOpened)) return null;
  return questsForDay(state.quests, now, isEcrinUnlocked(state), tuning);
}

/** Donne les succès nouvellement remplis, avec leurs récompenses. */
export function unlockAchievements(state: PlayerState, now: number, tuning: Tuning): PlayerState {
  let next = state;
  for (const achievement of ACHIEVEMENTS) {
    if (next.achievements[achievement.id] !== undefined || !isDone(achievement, next)) continue;
    const reward = achievementReward(achievement.tier, tuning);
    next = { ...next, achievements: { ...next.achievements, [achievement.id]: now }, dust: next.dust + reward.dust };
    next = gainReputation(next, reward.reputation, tuning);
  }
  return next;
}

/** Après une action : statistiques, quêtes du jour, succès. */
export function afterEvent(state: PlayerState, event: GameEvent, now: number, tuning: Tuning): PlayerState {
  let next: PlayerState = { ...state, stats: updateStats({ ...INITIAL_STATS, ...state.stats }, event) };
  const quests = currentQuests(next, now, tuning);
  const qe = questEvent(event);
  if (quests) next = { ...next, quests: qe ? advanceQuests(quests, qe) : quests };
  return unlockAchievements(next, now, tuning);
}

/** Récupère la récompense d'une quête terminée ; les trois récupérées donnent un écrin. */
export function claimQuest(state: PlayerState, index: number, now: number, tuning: Tuning): PlayerState {
  const quests = currentQuests(state, now, tuning);
  const quest = quests?.quests[index];
  if (!quests || !quest || !isClaimable(quest)) return state;
  const list = quests.quests.map((q, i) => (i === index ? { ...q, claimed: true } : q));
  const allClaimed = list.every((q) => q.claimed);
  const bonus = allClaimed && !quests.bonusClaimed;
  let next: PlayerState = {
    ...state,
    quests: { ...quests, quests: list, bonusClaimed: quests.bonusClaimed || bonus },
    dust: state.dust + tuning.questRewardDust,
    ecrins: state.ecrins + (bonus ? 1 : 0),
  };
  next = gainReputation(next, tuning.questRewardReputation, tuning);
  return next;
}
