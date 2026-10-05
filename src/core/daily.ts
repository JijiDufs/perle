// Rendez-vous quotidiens (cahier §15) : calendrier de connexion sur 7 jours (un écrin le 7e),
// et série de jours consécutifs avec un « joker » par semaine pour ne pas punir un jour d'absence.
// Récompenses : provisoires (AGENTS.md §6).
import type { Tuning } from '../tuning';
import { gainReputation } from './levels';
import type { PlayerState } from './player';
import { unlockAchievements } from './progression';
import { dayKey } from './quests';
import { isInTutorial } from './tutorial';

export interface CalendarReward {
  oysters: number;
  dust: number;
  ecrins: number;
}

/** Les 7 cases du calendrier, puis on recommence. */
export const CALENDAR: readonly CalendarReward[] = [
  { oysters: 3, dust: 0, ecrins: 0 },
  { oysters: 0, dust: 20, ecrins: 0 },
  { oysters: 5, dust: 0, ecrins: 0 },
  { oysters: 0, dust: 30, ecrins: 0 },
  { oysters: 5, dust: 0, ecrins: 0 },
  { oysters: 0, dust: 50, ecrins: 0 },
  { oysters: 0, dust: 30, ecrins: 1 },
];

export interface LoginState {
  /** Dernier jour récupéré (AAAA-MM-JJ), ou null. */
  lastClaimDay: string | null;
  /** Prochaine case du calendrier (0…6). */
  calendarIndex: number;
  /** Jours consécutifs, et meilleure série. */
  streak: number;
  bestStreak: number;
  /** Jour où le joker a servi pour la dernière fois. */
  jokerUsedDay: string | null;
}

export const INITIAL_LOGIN: LoginState = { lastClaimDay: null, calendarIndex: 0, streak: 0, bestStreak: 0, jokerUsedDay: null };

const DAY = 86_400_000;

/** Nombre de jours entre deux dates AAAA-MM-JJ (b - a). */
function daysBetween(a: string, b: string): number {
  const parse = (d: string) => {
    const [y, m, day] = d.split('-').map(Number);
    return Date.UTC(y, m - 1, day);
  };
  return Math.round((parse(b) - parse(a)) / DAY);
}

/** La case du jour peut être récupérée (une fois par jour, après le tutoriel). */
export function canClaimDaily(state: PlayerState, now: number): boolean {
  return !isInTutorial(state.oystersOpened) && state.login.lastClaimDay !== dayKey(now);
}

/** Le joker est disponible s'il n'a pas servi dans les 7 derniers jours. */
export function jokerAvailable(login: LoginState, now: number): boolean {
  return login.jokerUsedDay === null || daysBetween(login.jokerUsedDay, dayKey(now)) >= 7;
}

/** Série prévue si l'on récupère aujourd'hui (pour l'afficher avant). */
export function streakIfClaimed(login: LoginState, now: number): { streak: number; jokerUsed: boolean } {
  const today = dayKey(now);
  if (login.lastClaimDay === null) return { streak: 1, jokerUsed: false };
  const gap = daysBetween(login.lastClaimDay, today);
  if (gap <= 0) return { streak: login.streak, jokerUsed: false };
  if (gap === 1) return { streak: login.streak + 1, jokerUsed: false };
  // Un seul jour manqué et le joker est libre : la série continue.
  if (gap === 2 && jokerAvailable(login, now)) return { streak: login.streak + 1, jokerUsed: true };
  return { streak: 1, jokerUsed: false };
}

/** Récupère la case du jour : récompense, série, case suivante. */
export function claimDaily(state: PlayerState, now: number, tuning: Tuning): PlayerState {
  if (!canClaimDaily(state, now)) return state;
  const reward = CALENDAR[state.login.calendarIndex % CALENDAR.length];
  const { streak, jokerUsed } = streakIfClaimed(state.login, now);
  const today = dayKey(now);
  const login: LoginState = {
    lastClaimDay: today,
    calendarIndex: (state.login.calendarIndex + 1) % CALENDAR.length,
    streak,
    bestStreak: Math.max(state.login.bestStreak, streak),
    jokerUsedDay: jokerUsed ? today : state.login.jokerUsedDay,
  };
  const next: PlayerState = {
    ...state,
    login,
    stock: { ...state.stock, count: state.stock.count + reward.oysters },
    dust: state.dust + reward.dust,
    ecrins: state.ecrins + reward.ecrins,
  };
  return unlockAchievements(gainReputation(next, tuning.dailyRewardReputation, tuning), now, tuning);
}
