// Coquille de l'application : barre de ressources en haut, onglets en bas (à portée de pouce),
// pastilles, onglets qui se débloquent au fil du jeu, transition entre écrans.
// Les règles (déblocage, nouvelles cartes, stock) viennent du Core ; ce fichier ne fait qu'afficher.
import { newCardsSince } from '../../core/collection';
import type { PlayerState } from '../../core/player';
import { nextRefillIn, refreshStock } from '../../core/stock';
import { isEcrinUnlocked, isInTutorial } from '../../core/tutorial';
import type { Settings } from '../../platform/storage';
import type { Tuning } from '../../tuning';
import { ICONS } from './icons';

export type ScreenName = 'oyster' | 'ecrin' | 'collection' | 'tuning';

/** Ordre des onglets : sert au sens de la transition. */
const ORDER: ScreenName[] = ['oyster', 'ecrin', 'collection', 'tuning'];

export interface ShellState {
  player: PlayerState;
  tuning: Tuning;
  settings: Settings;
}

export interface Shell {
  host: HTMLElement;
  /** Met à jour pastilles, ressources et verrous. */
  update(state: ShellState): void;
  /** Marque l'onglet actif et renvoie le sens de la transition (-1, 0, 1). */
  setActive(name: ScreenName): -1 | 0 | 1;
  toast(text: string): void;
}

const formatWait = (ms: number) => {
  const total = Math.ceil(ms / 1000);
  const minutes = Math.floor(total / 60);
  return `${minutes}:${String(total % 60).padStart(2, '0')}`;
};

export function createShell(app: HTMLElement, onNavigate: (name: ScreenName) => void, getState: () => ShellState): Shell {
  app.innerHTML = `
    <header class="hud">
      <span class="chip">BÊTA</span>
      <div class="hud-resources">
        <button type="button" class="resource resource-oyster" data-screen="oyster" aria-label="Huîtres disponibles">
          ${ICONS.oyster}<b class="resource-value"></b><small class="resource-sub"></small>
        </button>
        <button type="button" class="resource resource-dust" data-screen="collection" aria-label="Poussière d’or">
          <span class="resource-star" aria-hidden="true">✦</span><b class="resource-value"></b>
        </button>
        <button type="button" class="hud-gear" data-screen="tuning" aria-label="Réglages">${ICONS.gear}</button>
      </div>
    </header>
    <main class="screen-host"></main>
    <nav class="tabbar" aria-label="Écrans">
      <span class="tabbar-pill" aria-hidden="true"></span>
      <button type="button" data-screen="oyster">${ICONS.oyster}<span>Pêche</span></button>
      <button type="button" data-screen="ecrin"><span class="tab-icon">${ICONS.ecrin}</span><span>Écrins</span><span class="badge" hidden></span></button>
      <button type="button" data-screen="collection">${ICONS.collection}<span>Collection</span><span class="badge badge-new" hidden></span></button>
    </nav>
    <p class="toast" role="status" hidden></p>
  `;
  const q = <T extends HTMLElement>(selector: string) => app.querySelector<T>(selector)!;
  const host = q('.screen-host');
  const ecrinTab = q('.tabbar [data-screen="ecrin"]');
  const ecrinBadge = q('.tabbar [data-screen="ecrin"] .badge');
  const newBadge = q('.tabbar [data-screen="collection"] .badge');
  const oysterRes = q('.resource-oyster');
  const dustRes = q('.resource-dust');
  const toastEl = q('.toast');
  let active: ScreenName = 'oyster';
  let last: { oysters?: number; dust?: number; unlocked?: boolean } = {};
  let toastTimer = 0;

  /** Petit rebond quand une valeur monte (gain visible). */
  const bump = (el: HTMLElement) => {
    el.classList.remove('bump');
    void el.offsetWidth;
    el.classList.add('bump');
  };

  function update({ player, tuning, settings }: ShellState): void {
    const now = Date.now();
    // Huîtres : offertes pendant le tutoriel, donc pas de compteur.
    const tutorial = isInTutorial(player.oystersOpened);
    oysterRes.hidden = tutorial;
    const stock = refreshStock(player.stock, now, tuning);
    const wait = nextRefillIn(player.stock, now, tuning);
    oysterRes.querySelector('.resource-value')!.textContent = `${stock.count}/${tuning.oysterStockMax}`;
    oysterRes.querySelector('.resource-sub')!.textContent = wait === null ? '' : formatWait(wait);
    oysterRes.classList.toggle('empty', stock.count === 0);
    if (!tutorial && last.oysters !== undefined && stock.count > last.oysters) bump(oysterRes);
    last.oysters = stock.count;

    // Poussière d'or : affichée dès qu'on en a eu.
    dustRes.hidden = player.dust === 0 && tutorial;
    dustRes.querySelector('.resource-value')!.textContent = String(player.dust);
    if (last.dust !== undefined && player.dust > last.dust) bump(dustRes);
    last.dust = player.dust;

    // Écrins : verrouillé jusqu'au premier écrin, puis pastille du nombre à ouvrir.
    const unlocked = isEcrinUnlocked(player);
    ecrinTab.classList.toggle('locked', !unlocked);
    ecrinTab.querySelector('.tab-icon')!.innerHTML = unlocked ? ICONS.ecrin : ICONS.lock;
    if (last.unlocked === false && unlocked) ecrinTab.classList.add('just-unlocked');
    last.unlocked = unlocked;
    const ecrins = player.ecrins + (player.currentEcrin ? 1 : 0);
    ecrinBadge.hidden = ecrins === 0;
    ecrinBadge.textContent = String(ecrins);

    // Collection : nouvelles cartes depuis la dernière visite (pas pendant qu'on la regarde).
    const fresh = active === 'collection' ? 0 : newCardsSince(player, settings.seenSerial);
    newBadge.hidden = fresh === 0;
    newBadge.textContent = fresh > 9 ? '9+' : String(fresh);
  }

  function setActive(name: ScreenName): -1 | 0 | 1 {
    const direction = Math.sign(ORDER.indexOf(name) - ORDER.indexOf(active)) as -1 | 0 | 1;
    active = name;
    const tabs = [...app.querySelectorAll<HTMLButtonElement>('.tabbar [data-screen]')];
    tabs.forEach((b) => {
      b.classList.toggle('active', b.dataset.screen === name);
      b.setAttribute('aria-current', b.dataset.screen === name ? 'page' : 'false');
    });
    const index = tabs.findIndex((b) => b.dataset.screen === name);
    app.querySelector<HTMLElement>('.tabbar')!.style.setProperty('--tab-index', String(Math.max(0, index)));
    app.querySelector('.tabbar')!.classList.toggle('no-active', index < 0);
    q('.hud-gear').classList.toggle('active', name === 'tuning');
    if (name === 'ecrin') ecrinTab.classList.remove('just-unlocked');
    update(getState());
    return direction;
  }

  function toast(text: string): void {
    toastEl.textContent = text;
    toastEl.hidden = false;
    toastEl.classList.remove('show');
    void toastEl.offsetWidth;
    toastEl.classList.add('show');
    clearTimeout(toastTimer);
    toastTimer = window.setTimeout(() => (toastEl.hidden = true), 2600);
  }

  app.addEventListener('click', (event) => {
    const button = (event.target as HTMLElement).closest<HTMLElement>('.tabbar [data-screen], .hud [data-screen]');
    if (!button) return;
    const name = button.dataset.screen as ScreenName;
    if (name === 'ecrin' && button.classList.contains('locked')) {
      toast('Les écrins se débloquent après tes premières huîtres.');
      return;
    }
    if (name !== active) onNavigate(name);
  });

  // Le minuteur de recharge tourne en haut de l'écran.
  window.setInterval(() => update(getState()), 1000);

  return { host, update, setActive, toast };
}
