// Coquille de l'application : barre de ressources en haut, onglets en bas (à portée de pouce),
// pastilles, onglets qui se débloquent au fil du jeu, transition entre écrans.
// Les règles (déblocage, nouvelles cartes, stock) viennent du Core ; ce fichier ne fait qu'afficher.
import { achievementById, achievementReward } from '../../core/achievements';
import { newCardsSince } from '../../core/collection';
import { levelFromXp } from '../../core/levels';
import type { PlayerState } from '../../core/player';
import { nextRefillIn, refreshStock } from '../../core/stock';
import { currentQuests } from '../../core/progression';
import { isClaimable, isComplete, questText } from '../../core/quests';
import { isEcrinUnlocked, isInTutorial } from '../../core/tutorial';
import { track } from '../../platform/analytics';
import { chimeNotes } from '../../platform/audio';
import { hapticBurst } from '../../platform/haptics';
import type { Settings } from '../../platform/storage';
import type { Tuning } from '../../tuning';
import { showLevelUp } from '../progress/levelUp';
import { openProgressSheet } from '../progress/progressSheet';
import { openQuestsSheet } from '../progress/questsSheet';
import type { AppContext } from '../context';
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
  /** Montre, à un moment calme, les succès, quêtes terminées et montées de niveau en attente (hors tutoriel). */
  showRewards(): void;
}

/** Une bannière en attente : succès obtenu ou quête terminée. */
interface Banner {
  kind: 'achievement' | 'quest';
  tier: string;
  kicker: string;
  title: string;
  detail: string;
}

const RING = 2 * Math.PI * 15;

const formatWait = (ms: number) => {
  const total = Math.ceil(ms / 1000);
  const minutes = Math.floor(total / 60);
  return `${minutes}:${String(total % 60).padStart(2, '0')}`;
};

export function createShell(app: HTMLElement, onNavigate: (name: ScreenName) => void, getState: () => ShellState, getCtx: () => AppContext): Shell {
  app.innerHTML = `
    <header class="hud">
      <div class="hud-left">
        <span class="chip">BÊTA</span>
        <button type="button" class="level-ring" aria-label="Ma progression">
          <svg viewBox="0 0 36 36" aria-hidden="true"><circle class="ring-track" cx="18" cy="18" r="15"/><circle class="ring-fill" cx="18" cy="18" r="15" stroke-dasharray="${RING}" stroke-dashoffset="${RING}"/></svg>
          <b class="level-number">1</b>
          <span class="rep-floater" aria-hidden="true"></span>
        </button>
      </div>
      <div class="hud-resources">
        <button type="button" class="resource resource-oyster" data-screen="oyster" aria-label="Huîtres disponibles">
          ${ICONS.oyster}<b class="resource-value"></b><small class="resource-sub"></small>
        </button>
        <button type="button" class="resource resource-dust" data-screen="collection" aria-label="Poussière d’or">
          <span class="resource-star" aria-hidden="true">✦</span><b class="resource-value"></b>
        </button>
        <button type="button" class="hud-quests" aria-label="Quêtes du jour" hidden>${ICONS.quests}<span class="badge" hidden></span></button>
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
    <div class="banner-host" aria-live="polite"></div>
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
  let last: {
    oysters?: number;
    dust?: number;
    unlocked?: boolean;
    reputation?: number;
    rewardedLevel?: number;
    achievements?: Set<string>;
    questsDone?: Set<string>;
  } = {};
  const questsButton = q('.hud-quests');
  const banners: Banner[] = [];
  let showingBanners = false;
  const levelRing = q('.level-ring');
  /** Niveaux gagnés pas encore célébrés : [depuis, jusqu'à]. */
  let pendingLevels: [number, number] | null = null;
  let celebrating = false;
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
    // Au-delà du maximum (récompenses de niveau) : en doré.
    oysterRes.classList.toggle('bonus', stock.count > tuning.oysterStockMax);
    if (!tutorial && last.oysters !== undefined && stock.count > last.oysters) bump(oysterRes);
    last.oysters = stock.count;

    // Poussière d'or : affichée dès qu'on en a eu.
    dustRes.hidden = player.dust === 0 && tutorial;
    dustRes.querySelector('.resource-value')!.textContent = String(player.dust);
    if (last.dust !== undefined && player.dust > last.dust) bump(dustRes);
    last.dust = player.dust;

    // Niveau : anneau de progression, « +N » quand la réputation monte, célébration mise de côté.
    const progress = levelFromXp(player.reputation, tuning);
    levelRing.querySelector('.level-number')!.textContent = String(progress.level);
    const ratio = progress.needed ? progress.into / progress.needed : 1;
    levelRing.querySelector<SVGCircleElement>('.ring-fill')!.style.strokeDashoffset = String(RING * (1 - ratio));
    if (last.reputation !== undefined && player.reputation > last.reputation) {
      const floater = levelRing.querySelector<HTMLElement>('.rep-floater')!;
      floater.textContent = `+${player.reputation - last.reputation}`;
      floater.classList.remove('show');
      void floater.offsetWidth;
      floater.classList.add('show');
      bump(levelRing);
    }
    last.reputation = player.reputation;
    if (last.rewardedLevel !== undefined && player.rewardedLevel > last.rewardedLevel) {
      pendingLevels = [pendingLevels?.[0] ?? last.rewardedLevel, player.rewardedLevel];
    }
    last.rewardedLevel = player.rewardedLevel;

    // Succès obtenus et quêtes terminées depuis la dernière fois : bannières mises de côté.
    const achieved = new Set(Object.keys(player.achievements));
    if (last.achievements) {
      for (const id of achieved) {
        if (last.achievements.has(id)) continue;
        const achievement = achievementById(id);
        if (!achievement) continue;
        const reward = achievementReward(achievement.tier, tuning);
        banners.push({ kind: 'achievement', tier: achievement.tier, kicker: 'Succès débloqué', title: achievement.name, detail: `+${reward.dust} ✦ · +${reward.reputation} réputation${achievement.title ? ` · titre « ${achievement.title} »` : ''}` });
        track('achievement_unlocked', { id, tier: achievement.tier });
      }
    }
    last.achievements = achieved;
    const daily = currentQuests(player, now, tuning);
    questsButton.hidden = !daily;
    const doneKeys = new Set((daily?.quests ?? []).flatMap((quest, i) => (isComplete(quest) ? [`${daily!.day}:${i}`] : [])));
    if (last.questsDone && daily) {
      daily.quests.forEach((quest, i) => {
        if (isComplete(quest) && !quest.claimed && !last.questsDone!.has(`${daily.day}:${i}`)) {
          banners.push({ kind: 'quest', tier: 'quest', kicker: 'Quête terminée', title: questText(quest), detail: 'Récupère ta récompense dans les quêtes du jour' });
        }
      });
    }
    last.questsDone = doneKeys;
    const claimable = daily ? daily.quests.filter(isClaimable).length : 0;
    const questBadge = questsButton.querySelector<HTMLElement>('.badge')!;
    questBadge.hidden = claimable === 0;
    questBadge.textContent = String(claimable);
    questsButton.classList.toggle('ready', claimable > 0);

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
    if (name === 'ecrin') ecrinTab.classList.remove('just-unlocked');
    update(getState());
    return direction;
  }

  /** Bannières une à une, puis la montée de niveau. */
  function showRewards(): void {
    const { player, tuning } = getState();
    if (celebrating || showingBanners || isInTutorial(player.oystersOpened)) return;
    const banner = banners.shift();
    if (banner) {
      showingBanners = true;
      showBanner(banner, () => {
        showingBanners = false;
        showRewards();
      });
      return;
    }
    if (!pendingLevels) return;
    const [from, to] = pendingLevels;
    pendingLevels = null;
    celebrating = true;
    track('level_up', { level: to });
    showLevelUp(from, to, tuning, () => (celebrating = false));
  }

  function showBanner(banner: Banner, done: () => void): void {
    const el = document.createElement('button');
    el.type = 'button';
    el.className = `banner banner-${banner.tier}`;
    el.innerHTML = `<span class="banner-medal" aria-hidden="true">${banner.kind === 'quest' ? '✓' : '★'}</span><span><small>${banner.kicker}</small><b>${banner.title}</b><em>${banner.detail}</em></span>`;
    q('.banner-host').append(el);
    if (banner.kind === 'achievement') {
      chimeNotes('normal', banner.tier === 'or' ? 3 : banner.tier === 'argent' ? 2 : 1);
      hapticBurst(banner.tier === 'or' ? 4 : 2, 90);
    }
    let finished = false;
    const finish = () => {
      if (finished) return;
      finished = true;
      el.classList.add('leaving');
      window.setTimeout(() => {
        el.remove();
        done();
      }, 250);
    };
    // Toucher la bannière : vers les succès ou les quêtes.
    el.addEventListener('click', () => {
      finish();
      if (banner.kind === 'quest') openQuestsSheet(getCtx());
      else openProgressSheet(getCtx(), 'achievements');
    });
    window.setTimeout(finish, 2800);
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

  levelRing.addEventListener('click', () => openProgressSheet(getCtx(), 'progress'));
  questsButton.addEventListener('click', () => openQuestsSheet(getCtx()));

  app.addEventListener('click', (event) => {
    const button = (event.target as HTMLElement).closest<HTMLElement>('.tabbar [data-screen], .hud [data-screen]');
    if (!button) return;
    const name = button.dataset.screen as ScreenName;
    if (name === 'ecrin' && button.classList.contains('locked')) {
      toast('Les écrins se débloquent après tes premières huîtres.');
      return;
    }
    if (name !== active) onNavigate(name);
    showRewards();
  });

  // Le minuteur de recharge tourne en haut de l'écran.
  window.setInterval(() => update(getState()), 1000);

  return { host, update, setActive, toast, showRewards };
}
