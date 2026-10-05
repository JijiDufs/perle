import type { PlayerState } from '../core/player';
import type { Rng } from '../core/rng';
import type { Settings } from '../platform/storage';
import type { Tuning } from '../tuning';

/** Ce que les écrans partagent. Chaque setter sauvegarde aussitôt. */
export interface AppContext {
  readonly player: PlayerState;
  readonly tuning: Tuning;
  readonly settings: Settings;
  readonly rng: Rng;
  setPlayer(state: PlayerState): void;
  setTuning(tuning: Tuning): void;
  setSettings(settings: Settings): void;
  /** Change d'écran. */
  goTo(screen: 'oyster' | 'ecrin' | 'collection' | 'tuning'): void;
}
