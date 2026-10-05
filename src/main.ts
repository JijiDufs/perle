import './style.css';
import type { PlayerState } from './core/player';
import type { AppContext } from './features/context';
import { mountCollectionScreen } from './features/collection/collectionScreen';
import { mountEcrinScreen } from './features/ecrin/ecrinScreen';
import { mountOysterScreen } from './features/oyster/oysterScreen';
import { mountTuningScreen } from './features/tuning/tuningScreen';
import { track } from './platform/analytics';
import { registerOffline } from './platform/offline';
import { loadPlayer, loadSettings, loadTuning, savePlayer, saveSettings, saveTuning, type Settings } from './platform/storage';
import type { Tuning } from './tuning';

type ScreenName = 'oyster' | 'ecrin' | 'collection' | 'tuning';
const SCREENS: Record<ScreenName, (root: HTMLElement, ctx: AppContext) => () => void> = {
  oyster: mountOysterScreen,
  ecrin: mountEcrinScreen,
  collection: mountCollectionScreen,
  tuning: mountTuningScreen,
};

let player: PlayerState = loadPlayer();
let tuning: Tuning = loadTuning();
let settings: Settings = loadSettings();

const ctx: AppContext = {
  get player() { return player; },
  get tuning() { return tuning; },
  get settings() { return settings; },
  rng: Math.random,
  setPlayer(state) { player = state; savePlayer(state); updateBadge(); },
  setTuning(value) { tuning = value; saveTuning(value); },
  setSettings(value) { settings = value; saveSettings(value); },
  goTo(screen) { show(screen); },
};

const app = document.querySelector<HTMLElement>('#app')!;
app.innerHTML = `
  <header class="topbar">
    <nav class="tabs" aria-label="Écrans">
      <button data-screen="oyster">Huître</button>
      <button data-screen="ecrin">Écrin<span class="badge" hidden></span></button>
      <button data-screen="collection">Collection</button>
      <button data-screen="tuning" aria-label="Réglages">⚙︎</button>
    </nav>
    <span class="chip">BÊTA</span>
  </header>
  <main class="screen-host"></main>
`;
const host = app.querySelector<HTMLElement>('.screen-host')!;
const badge = app.querySelector<HTMLElement>('.badge')!;

/** Pastille sur l'onglet Écrin : écrins gagnés pas encore ouverts (+ celui en cours). */
function updateBadge(): void {
  const count = player.ecrins + (player.currentEcrin ? 1 : 0);
  badge.hidden = count === 0;
  badge.textContent = String(count);
}
let unmount: () => void = () => {};

function show(name: ScreenName): void {
  unmount();
  // Nouvel élément à chaque écran : aucun écouteur ne survit d'un écran à l'autre.
  const root = document.createElement('div');
  host.replaceChildren(root);
  unmount = SCREENS[name](root, ctx);
  app.querySelectorAll<HTMLButtonElement>('.topbar .tabs button').forEach((b) => b.classList.toggle('active', b.dataset.screen === name));
  track('screen_view', { screen: name });
}

app.querySelector('.topbar .tabs')!.addEventListener('click', (event) => {
  const name = (event.target as HTMLElement).closest<HTMLElement>('[data-screen]')?.dataset.screen as ScreenName | undefined;
  if (name) show(name);
});

track('session_start', { oystersOpened: player.oystersOpened, standalone: matchMedia('(display-mode: standalone)').matches });
updateBadge();
show('oyster');
registerOffline();
