// Sauvegarde locale (localStorage). Toutes les lectures sont protégées :
// navigation privée ou stockage bloqué → le jeu repart de zéro sans planter.
import type { CardSort } from '../core/collection';
import { INITIAL_PLAYER_STATE, type PlayerState } from '../core/player';
import { DEFAULT_TUNING, type Tuning } from '../tuning';

const PLAYER_KEY = 'perle.player.v1';
// v2 : course du pouce raccourcie pour l'ouverture à une main ; les anciens réglages sont ignorés.
const TUNING_KEY = 'perle.tuning.v2';
const SETTINGS_KEY = 'perle.settings.v1';

export interface Settings {
  /** Affiche les mesures en direct (angle, vitesse, zone fragile). */
  showHud: boolean;
  /** Sons générés (craquement, pop, carillon). */
  sound: boolean;
  /** Tri choisi dans la collection. */
  collectionSort: CardSort;
  /** L'aide « Ajouter à l'écran d'accueil » a été fermée. */
  installHintDismissed: boolean;
}

const DEFAULT_SETTINGS: Settings = { showHud: true, sound: true, collectionSort: 'rarity', installHintDismissed: false };

function read<T>(key: string, fallback: T): T {
  try {
    const raw = localStorage.getItem(key);
    return raw ? { ...fallback, ...JSON.parse(raw) } : fallback;
  } catch {
    return fallback;
  }
}

function write(key: string, value: unknown): void {
  try {
    localStorage.setItem(key, JSON.stringify(value));
  } catch {
    // Stockage indisponible : on continue sans sauvegarde.
  }
}

export const loadPlayer = (): PlayerState => read(PLAYER_KEY, INITIAL_PLAYER_STATE);
export const savePlayer = (state: PlayerState): void => write(PLAYER_KEY, state);
export const loadTuning = (): Tuning => read(TUNING_KEY, { ...DEFAULT_TUNING });
export const saveTuning = (tuning: Tuning): void => write(TUNING_KEY, tuning);
export const loadSettings = (): Settings => read(SETTINGS_KEY, DEFAULT_SETTINGS);
export const saveSettings = (settings: Settings): void => write(SETTINGS_KEY, settings);
