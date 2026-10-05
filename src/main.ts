import './style.css';
import type { PlayerState } from './core/player';
import { unlockAchievements } from './core/progression';
import type { AppContext } from './features/context';
import { mountCollectionScreen } from './features/collection/collectionScreen';
import { mountEcrinScreen } from './features/ecrin/ecrinScreen';
import { mountHouseScreen } from './features/house/houseScreen';
import { createShell, type ScreenName } from './features/nav/shell';
import { mountOysterScreen } from './features/oyster/oysterScreen';
import { mountTuningScreen } from './features/tuning/tuningScreen';
import { track } from './platform/analytics';
import { registerOffline } from './platform/offline';
import { loadPlayer, loadSettings, loadTuning, savePlayer, saveSettings, saveTuning, type Settings } from './platform/storage';
import type { Tuning } from './tuning';

const SCREENS: Record<ScreenName, (root: HTMLElement, ctx: AppContext) => () => void> = {
  oyster: mountOysterScreen,
  ecrin: mountEcrinScreen,
  collection: mountCollectionScreen,
  house: mountHouseScreen,
  tuning: mountTuningScreen,
};

let player: PlayerState = loadPlayer();
// Succès déjà remplis par une ancienne sauvegarde : donnés tout de suite, sans bannière.
player = unlockAchievements(player, Date.now(), loadTuning());
savePlayer(player);
let tuning: Tuning = loadTuning();
let settings: Settings = loadSettings();
// Première version avec la pastille « nouveau » : les cartes déjà là ne sont pas nouvelles.
if (settings.seenSerial < 0) {
  settings = { ...settings, seenSerial: player.nextSerial - 1 };
  saveSettings(settings);
}

const ctx: AppContext = {
  get player() { return player; },
  get tuning() { return tuning; },
  get settings() { return settings; },
  rng: Math.random,
  setPlayer(state) { player = state; savePlayer(state); shell.update(shellState()); },
  setTuning(value) { tuning = value; saveTuning(value); shell.update(shellState()); },
  setSettings(value) { settings = value; saveSettings(value); shell.update(shellState()); },
  goTo(screen) { show(screen); },
  showRewards() { shell.showRewards(); },
};

const shellState = () => ({ player, tuning, settings });
const shell = createShell(document.querySelector<HTMLElement>('#app')!, (name) => show(name), shellState, () => ctx);
let unmount: () => void = () => {};

function show(name: ScreenName): void {
  unmount();
  // Nouvel élément à chaque écran : aucun écouteur ne survit d'un écran à l'autre.
  const root = document.createElement('div');
  const direction = shell.setActive(name);
  shell.host.replaceChildren(root);
  unmount = SCREENS[name](root, ctx);
  // Après le montage : chaque écran pose ses propres classes.
  if (direction !== 0) root.classList.add('screen-enter', direction > 0 ? 'from-right' : 'from-left');
  track('screen_view', { screen: name });
}

track('session_start', { oystersOpened: player.oystersOpened, standalone: matchMedia('(display-mode: standalone)').matches });
show('oyster');
// Calendrier du jour, succès et niveaux en attente, à l'ouverture et au retour dans l'app.
shell.showRewards();
document.addEventListener('visibilitychange', () => {
  if (document.visibilityState === 'visible') shell.showRewards();
});
registerOffline();
