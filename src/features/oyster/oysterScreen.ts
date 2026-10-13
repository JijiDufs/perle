// Écran d'ouverture d'une huître. Affiche l'état du moteur et transmet les gestes :
// aucune règle de jeu ici (AGENTS.md, invariant 7).
// Vue de dessus : la valve du bas reste posée, le couvercle pivote autour de la charnière
// et se soulève vers le haut de l'écran, dans le sens du pouce.
import { smoothstep } from '../../art/color';
import { drawFind } from '../../art/finds';
import { drawGlow, drawPearl } from '../../art/pearl';
import { drawFlesh, drawNacre, drawShellExterior, randomPhases, shellOutline, tracePath, type Phases } from '../../art/shell';
import { pearlById, type PearlType } from '../../core/catalog';
import { findById, findRevealTier, findTrembles, type FindCard, type FindType } from '../../core/finds';
import type { PearlTraits } from '../../core/pearlTraits';
import { OpeningEngine, type OpeningEvent } from '../../core/opening';
import { ensureOyster, recordOpening, type PearlCard } from '../../core/player';
import { currentQuests } from '../../core/progression';
import { isClaimable, isComplete, dayKey, questText } from '../../core/quests';
import { nextRefillIn, refreshStock } from '../../core/stock';
import { isCrackProtected, isInTutorial } from '../../core/tutorial';
import { isIos, isStandalone } from '../../platform/offline';
import { ThumbInput } from '../../input/thumb';
import { track } from '../../platform/analytics';
import { chime, chimeNotes, noise, setMuted, unlockAudio } from '../../platform/audio';
import { hapticBurst, hapticTick } from '../../platform/haptics';
import { revealSuspenseMs } from '../../tuning';
import { cardElement } from '../collection/cardView';
import { findCardElement } from '../collection/findCardView';
import { Lagoon } from '../../art/lagoon';
import type { AppContext } from '../context';
import { visibleBand } from '../nav/insets';
import { findShareButton, pearlShareButton } from '../share/shareButton';
import { coachAfterReveal, coachDuringGesture } from './coach';
import { openQuestsSheet } from '../progress/questsSheet';

const DOWN = Math.PI / 2;
/** Intensité du halo selon le niveau de révélation. */
const GLOW_STRENGTH = [0.55, 0.7, 0.85, 1];
/** Après ce délai sans geste sur une huître fermée, la main fantôme remontre le geste. */
const IDLE_HINT_MS = 6000;

const TEMPLATE = `
  <canvas class="scene" aria-label="Huître. Glisse le pouce vers le haut pour l'ouvrir."></canvas>
  <p class="coach" aria-live="polite" hidden></p>
  <div class="ghost-thumb" aria-hidden="true" hidden>
    <svg viewBox="0 0 60 96" width="60" height="96">
      <defs>
        <linearGradient id="ghost-skin" x1="0" x2="1">
          <stop offset="0" stop-color="#fff4ea" /><stop offset="0.55" stop-color="#ffe6d2" /><stop offset="1" stop-color="#e9c3a6" />
        </linearGradient>
      </defs>
      <circle class="ghost-ripple" cx="30" cy="18" r="16" />
      <path class="ghost-finger" d="M18 96 V30 a12 12 0 0 1 24 0 V96 Z" fill="url(#ghost-skin)" />
      <path class="ghost-nail" d="M23 24 a7 7 0 0 1 14 0 v6 a7 5 0 0 1 -14 0 Z" />
    </svg>
  </div>
  <div class="install-hint" role="note" hidden>
    <p>Installe Pearl Inc. sur ton écran d'accueil : touche <strong>Partager</strong> <span aria-hidden="true">⬆︎</span> puis <strong>« Sur l'écran d'accueil »</strong>. Tu pourras jouer même sans réseau.</p>
    <button type="button">OK</button>
  </div>
  <button type="button" class="daily-peek" aria-label="Voir les quêtes du jour" hidden>
    <span class="daily-peek-top"><span>LE CAP DU JOUR</span><b class="daily-peek-count"></b></span>
    <span class="daily-peek-title"></span>
    <span class="daily-peek-track"><i></i></span>
    <span class="daily-peek-foot"><span>3 quêtes · un écrin en bonus</span><span>Voir ›</span></span>
  </button>
  <div class="tide" hidden>
    <h2>La marée remonte…</h2>
    <p class="tide-countdown" aria-live="polite"></p>
    <p class="tide-sub">avant ta prochaine huître</p>
    <button type="button" class="tide-button">Admirer ma collection</button>
  </div>
  <div class="oyster-dock">
    <p class="message" aria-live="polite"></p>
    <div class="gauge" hidden>
      <span class="gauge-angle"></span>
      <span class="gauge-state"></span>
      <div class="gauge-speed"><i></i></div>
    </div>
  </div>
  <div class="card-overlay" hidden></div>
`;

export function mountOysterScreen(root: HTMLElement, ctx: AppContext): () => void {
  root.className = 'screen oyster-screen';
  root.innerHTML = TEMPLATE;
  const canvas = root.querySelector<HTMLCanvasElement>('.scene')!;
  const c = canvas.getContext('2d')!;
  const message = root.querySelector<HTMLElement>('.message')!;
  const gauge = root.querySelector<HTMLElement>('.gauge')!;
  const gaugeAngle = root.querySelector<HTMLElement>('.gauge-angle')!;
  const gaugeState = root.querySelector<HTMLElement>('.gauge-state')!;
  const gaugeSpeed = root.querySelector<HTMLElement>('.gauge-speed i')!;
  const overlay = root.querySelector<HTMLElement>('.card-overlay')!;
  const coach = root.querySelector<HTMLElement>('.coach')!;
  const ghost = root.querySelector<HTMLElement>('.ghost-thumb')!;
  const installHint = root.querySelector<HTMLElement>('.install-hint')!;
  const dailyPeek = root.querySelector<HTMLButtonElement>('.daily-peek')!;
  const tide = root.querySelector<HTMLElement>('.tide')!;
  const tideCountdown = root.querySelector<HTMLElement>('.tide-countdown')!;
  /** Stock vide : on attend la marée. */
  let waiting = false;
  for (const type of ['pointerdown', 'pointerup'] as const) tide.addEventListener(type, (event) => event.stopPropagation());
  tide.querySelector('button')!.addEventListener('click', () => ctx.goTo('collection'));
  let installHintTracked = false;
  for (const type of ['pointerdown', 'pointerup'] as const) installHint.addEventListener(type, (event) => event.stopPropagation());
  installHint.querySelector('button')!.addEventListener('click', () => {
    ctx.setSettings({ ...ctx.settings, installHintDismissed: true });
    track('install_hint_dismissed', {});
  });
  setMuted(!ctx.settings.sound);

  let engine = new OpeningEngine(ctx.tuning);
  let pearl: PearlType = pearlById('white');
  /** Trouvaille cachée à la place de la perle (pearl est alors l'huître vide). */
  let find: FindType | null = null;
  let traits: PearlTraits | null = null;
  let sizeMm = 6;
  // Ce qui se voit de l'extérieur : la lumière, l'ampleur de la révélation, le tremblement.
  const glowColor = () => (find ? find.glow : pearl.glow);
  const revealTier = () => (find ? findRevealTier(find) : pearl.revealTier);
  const trembles = () => (find ? findTrembles(find) : pearl.trembles);
  let phases: Phases = randomPhases(Math.random);
  let gestureStart = 0;
  let lastTick = 0;
  let busy = false; // suspense ou carte affichée
  let revealStartedAt = 0;
  let suspenseMs = 0;
  let popShakeUntil = 0;
  let flashAt = 0;
  let frame = 0;
  /** Nombre d'huîtres déjà ouvertes quand celle-ci est apparue (étape du tutoriel). */
  let step = 0;
  let lastInteraction = performance.now();
  const timers: number[] = [];
  let questPeekPlayer = ctx.player;
  let questPeekDay = '';
  let questPeekHidden: boolean | null = null;

  for (const type of ['pointerdown', 'pointerup'] as const) dailyPeek.addEventListener(type, (event) => event.stopPropagation());
  dailyPeek.addEventListener('click', (event) => {
    event.stopPropagation();
    openQuestsSheet(ctx);
  });

  // ---------- Geste ----------

  const input = new ThumbInput(root, () => ctx.tuning, {
    onSample(sample, distance) {
      if (busy) return;
      if (engine.phase === 'closed' && sample.angle > 0) {
        gestureStart = sample.time;
        lastTick = 0;
        track('gesture_start', { pearlId: pearl.id });
      }
      if (engine.phase === 'closed' || engine.phase === 'resisting') {
        const tick = Math.floor(distance / ctx.tuning.resistanceTickDistance);
        if (tick > lastTick) {
          hapticTick();
          noise(0.03, 700 + tick * 60, 0.12);
        }
        lastTick = tick;
      }
      handle(engine.push(sample), sample.time);
    },
    autoOpenFrom: () => (engine.phase === 'opening' ? ctx.tuning.autoOpenFromAngle : null),
    onRelease() {
      if (busy) return;
      const wasResisting = engine.phase === 'resisting';
      engine.release();
      if (wasResisting) {
        input.reset();
        track('released_before_pop', { pearlId: pearl.id });
      }
    },
  });
  root.addEventListener('pointerdown', () => {
    unlockAudio();
    lastInteraction = performance.now();
  });

  function handle(events: OpeningEvent[], time: number): void {
    for (const event of events) {
      if (event.type === 'pop') {
        hapticTick();
        noise(0.09, 1400, 0.6);
        popShakeUntil = performance.now() + 160;
        input.lockAfterPop();
        track('pop', { pearlId: pearl.id, msSinceStart: Math.round(time - gestureStart) });
      } else if (event.type === 'crack') {
        if (pearl.glow) {
          hapticBurst(3, 40);
          noise(0.15, 3200, 0.5);
        }
        track('crack', { pearlId: pearl.id });
      } else if (event.type === 'reveal') {
        reveal(event.lustre, event.cracked, time);
      }
    }
  }

  function reveal(lustre: 'S' | 'A' | 'B' | 'C', cracked: boolean, time: number): void {
    busy = true;
    const { state, card, find: findCard, ecrinEarned } = recordOpening(ctx.player, { lustre, cracked }, Date.now(), ctx.tuning);
    if (ecrinEarned) track('ecrin_earned', { oystersOpened: state.oystersOpened });
    ctx.setPlayer(state);
    const tier = revealTier();
    track('reveal', {
      pearlId: pearl.id,
      findId: find?.id ?? 'aucune',
      tier,
      lustre,
      cracked: cracked && pearl.glow !== null,
      durationMs: Math.round(time - gestureStart),
      oystersOpened: state.oystersOpened,
    });
    if (isInTutorial(step)) track('tutorial_step', { step, pearlId: pearl.id, cracked });
    if (isInTutorial(step) && !isInTutorial(step + 1)) track('tutorial_completed', {});
    revealStartedAt = performance.now();
    suspenseMs = revealSuspenseMs(ctx.tuning, tier);
    hapticBurst(tier + 1, 140);
    noise(0.4, 600, 0.12);
    timers.push(
      window.setTimeout(() => {
        if (tier === 3) flashAt = performance.now();
        if (find) chimeNotes('find', tier);
        else chime(pearl);
        showCard(card, findCard, cracked && pearl.glow !== null, ecrinEarned);
      }, suspenseMs),
    );
  }

  function showCard(card: PearlCard | null, findCard: FindCard | null, cracked: boolean, ecrinEarned: boolean): void {
    overlay.replaceChildren();
    if (ecrinEarned) {
      const banner = document.createElement('button');
      banner.type = 'button';
      banner.className = 'ecrin-earned';
      banner.innerHTML = '<strong>Écrin gagné !</strong> Ouvre-le dans l’onglet Écrin →';
      for (const type of ['pointerdown', 'pointerup'] as const) banner.addEventListener(type, (event) => event.stopPropagation());
      banner.addEventListener('click', () => ctx.goTo('ecrin'));
      overlay.append(banner);
    }
    const tip = coachAfterReveal(step, cracked);
    if (tip) {
      const p = document.createElement('p');
      p.className = 'coach coach-card';
      p.textContent = tip;
      overlay.append(p);
    }
    if (findCard) {
      const kicker = document.createElement('p');
      kicker.className = 'find-kicker';
      const first = ctx.player.findCards.filter((c) => c.findId === findCard.findId).length === 1;
      kicker.textContent = first ? 'Ce n’est pas une perle… Nouvelle trouvaille !' : 'Ce n’est pas une perle…';
      overlay.append(kicker, findCardElement(findCard, 'large', ctx.tuning), findShareButton(findCard));
    } else {
      overlay.append(cardElement(pearl.id, card, 'large'));
      if (card) overlay.append(pearlShareButton(card));
    }
    const tap = document.createElement('p');
    tap.className = 'tap-hint';
    tap.textContent = 'Touche pour la prochaine huître';
    overlay.append(tap);
    overlay.hidden = false;
  }

  overlay.addEventListener('pointerdown', (event) => event.stopPropagation());
  overlay.addEventListener('pointerup', (event) => {
    event.stopPropagation();
    track('card_dismissed', { pearlId: pearl.id });
    nextOyster();
    ctx.showRewards();
  });

  function nextOyster(): void {
    ctx.setPlayer(ensureOyster(ctx.player, ctx.rng, ctx.tuning, Date.now()));
    const oyster = ctx.player.currentOyster;
    overlay.hidden = true;
    if (!oyster) {
      if (!waiting) track('stock_empty', { oystersOpened: ctx.player.oystersOpened });
      waiting = true;
      busy = true;
      tide.hidden = false;
      return;
    }
    if (waiting) chime(pearlById('white'));
    waiting = false;
    tide.hidden = true;
    pearl = pearlById(oyster.pearlId);
    find = oyster.findId ? findById(oyster.findId) : null;
    traits = oyster.traits ?? null;
    sizeMm = oyster.sizeMm;
    phases = randomPhases(Math.random);
    step = ctx.player.oystersOpened;
    engine = new OpeningEngine(ctx.tuning, isCrackProtected(step));
    lastInteraction = performance.now();
    input.reset();
    busy = false;
    track('oyster_shown', { pearlId: pearl.id, oystersOpened: ctx.player.oystersOpened });
  }

  // ---------- Rendu ----------

  // Bande visible entre la barre du haut et les onglets : le sujet s'y centre, le fond déborde dessous.
  let band = { top: 0, bottom: 0 };
  const lagoon = new Lagoon();

  function resize(): void {
    band = visibleBand(canvas, root.querySelector('.oyster-dock'));
    const dpr = Math.min(window.devicePixelRatio || 1, 3);
    const { width, height } = canvas.getBoundingClientRect();
    canvas.width = Math.round(width * dpr);
    canvas.height = Math.round(height * dpr);
    c.setTransform(dpr, 0, 0, dpr, 0, 0);
  }
  const observer = new ResizeObserver(resize);
  observer.observe(canvas);
  // Le pied (message, jauge) peut changer de taille : la scène se recentre au-dessus.
  observer.observe(root.querySelector('.oyster-dock')!);

  function draw(now: number): void {
    frame = requestAnimationFrame(draw);
    const t = now / 1000;
    const w = canvas.clientWidth;
    const h = canvas.clientHeight;
    const angle = engine.angle;
    const theta = (angle * Math.PI) / 180;
    const vh = h - band.top - band.bottom;
    // Le couvercle s'ouvre vers le haut : l'huître est un peu sous le milieu de la bande libre.
    const L = Math.min(w * 0.6, vh * 0.42);
    let hx = w / 2;
    let hy = band.top + vh * 0.52;

    // Le lagon : eau, rayons, sable et reflets, algues, bulles (art/lagoon.ts).
    lagoon.draw(c, w, h, t, { x: hx, y: hy, size: L });

    if (waiting) {
      // Marée basse : une coquille vide, à peine visible, en attendant le minuteur.
      c.globalAlpha = 0.18;
      drawShellExterior(c, hx, hy, DOWN, L, phases);
      c.globalAlpha = 1;
      lagoon.drawOverlay(c, w, h);
      renderDock();
      return;
    }

    // Tremblement des plus rares, petit choc au pop.
    if (trembles() && engine.phase === 'closed' && !busy && t % 2.4 < 0.45) {
      hx += (Math.random() - 0.5) * 6;
      hy += (Math.random() - 0.5) * 4;
    }
    if (now < popShakeUntil) hy += (Math.random() - 0.5) * 5;

    // Valve du bas : extérieur, nacre, chair, perle.
    drawShellExterior(c, hx, hy, DOWN, L, phases);
    drawNacre(c, hx, hy, DOWN, L * 0.88, phases, t);
    drawFlesh(c, hx, hy, DOWN, L, phases);

    const px = hx;
    const py = hy + L * 0.5;
    const tier = revealTier();
    const glow = glowColor();
    let prad = find ? L * 0.12 : L * (0.05 + sizeMm * 0.0055);
    const suspense = busy ? smoothstep(0, Math.max(suspenseMs, 1), now - revealStartedAt) : 0;
    // La perle maudite palpite ; une trouvaille vacille, comme une lumière qui n'est pas celle d'une perle.
    const cursedPulse = pearl.id === 'cursed' ? 0.75 + 0.25 * Math.sin(t * 6) : find ? 0.8 + 0.2 * Math.sin(t * 9) * Math.sin(t * 2.3) : 1;
    const pulse = busy ? 1 + 0.1 * suspense * Math.max(0, Math.sin(t * (6 + tier * 3))) : 1;
    prad *= pulse;
    if (find) drawFind(c, px, py, L * 0.2 * pulse, find, t);
    else drawPearl(c, px, py, prad, pearl, engine.cracked, traits);

    // L'intérieur reste dans l'ombre tant que la coquille est peu ouverte.
    const dim = 1 - smoothstep(4, 140, angle);
    if (dim > 0.001) {
      c.save();
      tracePath(c, shellOutline(hx, hy, DOWN, L * 0.88, phases, 0));
      c.fillStyle = `rgba(0,6,8,${dim * 0.94})`;
      c.fill();
      c.restore();
    }

    // Halo de la perle, puis couvercle par-dessus.
    const strength = GLOW_STRENGTH[tier] * cursedPulse * (engine.cracked && !find ? 0.35 : 1);
    drawGlow(c, px, py, prad * (4 + tier * 0.8), glow, smoothstep(1, 25, angle) * strength, false);

    const lift = Math.cos(theta);
    c.save();
    c.translate(hx, hy);
    c.scale(1, lift);
    c.translate(-hx, -hy);
    if (lift > 0) {
      drawShellExterior(c, hx, hy, DOWN, L * 0.98, phases);
      // Le couvercle s'assombrit en se redressant.
      tracePath(c, shellOutline(hx, hy, DOWN, L * 0.98, phases, 0.045));
      c.fillStyle = `rgba(0,0,0,${Math.sin(theta) * 0.35})`;
      c.fill();
    } else {
      drawShellExterior(c, hx, hy, DOWN, L * 0.98, phases);
      drawNacre(c, hx, hy, DOWN, L * 0.98 * 0.88, phases, t);
    }
    c.restore();

    // La lumière filtre par l'entrebâillement, au bord du couvercle.
    if (lift > 0) {
      const leak = smoothstep(0.5, 10, angle) * (1 - smoothstep(40, 95, angle));
      drawGlow(c, hx, hy + L * 0.98 * lift, L * 0.8, glow, leak * strength * 0.9);
    }

    lagoon.drawOverlay(c, w, h);

    // Révélation : le halo envahit l'écran, puis éclair blanc pour les ★.
    if (busy) drawGlow(c, px, py, L * (1.4 + tier * 0.5), glow, suspense * 0.5 * cursedPulse, false);
    const flash = flashAt ? 1 - smoothstep(0, ctx.tuning.revealFlashMs, now - flashAt) : 0;
    if (flash > 0) {
      c.fillStyle = `rgba(255,250,235,${flash * 0.7})`;
      c.fillRect(0, 0, w, h);
    }

    renderDock();
  }

  function formatDuration(ms: number): string {
    const total = Math.ceil(ms / 1000);
    return `${Math.floor(total / 60)}:${String(total % 60).padStart(2, '0')}`;
  }

  function renderStock(): void {
    const now = Date.now();
    // Le stock s'affiche dans la barre du haut (features/nav) ; ici, seulement l'attente de la marée.
    if (!waiting) return;
    const stock = refreshStock(ctx.player.stock, now, ctx.tuning);
    const wait = nextRefillIn(ctx.player.stock, now, ctx.tuning);
    if (stock.count > 0) nextOyster();
    else tideCountdown.textContent = wait === null ? '' : formatDuration(wait);
  }

  function renderQuestPeek(): void {
    // Une seule chose en haut de l'écran : l'aide à l'installation passe avant le cap du jour.
    const hidden = waiting || busy || engine.phase !== 'closed' || isInTutorial(step) || !installHint.hidden;
    if (hidden) {
      if (questPeekHidden !== true) dailyPeek.hidden = true;
      questPeekHidden = true;
      return;
    }
    const now = Date.now();
    const day = dayKey(now);
    if (questPeekHidden === false && questPeekPlayer === ctx.player && questPeekDay === day) return;
    const daily = currentQuests(ctx.player, now, ctx.tuning);
    if (!daily) {
      dailyPeek.hidden = true;
      questPeekPlayer = ctx.player;
      questPeekDay = day;
      questPeekHidden = true;
      return;
    }
    const claimable = daily.quests.find(isClaimable);
    const next = claimable ?? daily.quests.find((quest) => !quest.claimed) ?? null;
    const completed = daily.quests.filter((quest) => quest.claimed || isComplete(quest)).length;
    const title = daily.quests.every((quest) => quest.claimed)
      ? 'Toutes les récompenses sont récupérées'
      : claimable
        ? `Récompense prête · ${questText(claimable)}`
        : next
          ? questText(next)
          : 'Tes trois quêtes sont terminées';
    const progress = next ? Math.round((next.progress / next.goal) * 100) : 100;
    dailyPeek.querySelector('.daily-peek-count')!.textContent = `${completed}/${daily.quests.length}`;
    dailyPeek.querySelector('.daily-peek-title')!.textContent = title;
    dailyPeek.querySelector<HTMLElement>('.daily-peek-track i')!.style.width = `${progress}%`;
    dailyPeek.classList.toggle('ready', Boolean(claimable));
    dailyPeek.hidden = false;
    questPeekPlayer = ctx.player;
    questPeekDay = day;
    questPeekHidden = false;
  }

  function renderDock(): void {
    renderStock();
    renderQuestPeek();
    if (waiting) {
      message.textContent = '';
      coach.hidden = true;
      ghost.hidden = true;
      installHint.hidden = true;
      gauge.hidden = true;
      message.classList.remove('nudge');
      return;
    }
    const t = ctx.tuning;
    let text = '';
    let danger = false;
    if (busy) text = '';
    else if (engine.phase === 'closed') text = trembles() ? 'Elle tremble… Glisse le pouce vers le haut' : 'Ouvre-moi. Glisse le pouce vers le haut';
    else if (engine.phase === 'resisting') text = 'Ouvre doucement…';
    else if (engine.cracked && pearl.glow) [text, danger] = ['Crac. La perle est fêlée.', true];
    else if (engine.inFragileZone && engine.velocity > t.maxSafeVelocity * 0.6) [text, danger] = ['Trop vite !', true];
    else if (engine.inFragileZone) text = 'Zone fragile';
    else if (engine.angle >= t.fragileMaxAngle) text = 'Encore un peu…';
    else text = 'Ouvre doucement…';
    const tip = busy ? null : coachDuringGesture(step, engine.phase);
    if (tip && !danger) text = ''; // la bulle du tutoriel suffit
    if (message.textContent !== text) message.textContent = text;
    message.classList.toggle('danger', danger);
    message.classList.toggle('nudge', engine.phase === 'closed' && !busy);

    coach.hidden = !tip;
    if (tip && coach.textContent !== tip) coach.textContent = tip;
    const showInstall = engine.phase === 'closed' && !busy && !isInTutorial(step) && !ctx.settings.installHintDismissed && isIos() && !isStandalone();
    installHint.hidden = !showInstall;
    if (showInstall && !installHintTracked) {
      installHintTracked = true;
      track('install_hint_shown', {});
    }
    ghost.hidden = !(engine.phase === 'closed' && !busy && (step === 0 || performance.now() - lastInteraction > IDLE_HINT_MS));

    gauge.hidden = !ctx.settings.showGauge;
    if (!gauge.hidden) {
      gaugeAngle.innerHTML = `${engine.angle.toFixed(0)}°<small>ouverture</small>`;
      gaugeState.textContent = engine.cracked && pearl.glow ? 'Perle fêlée' : engine.inFragileZone ? 'Zone fragile' : engine.phase === 'closed' ? 'Fermée' : engine.phase === 'resisting' ? 'Résistance' : engine.phase === 'revealed' ? 'Ouverte' : 'Ouverture';
      gaugeState.classList.toggle('warn', engine.inFragileZone || engine.cracked);
      const ratio = Math.min(1, Math.max(0, engine.velocity) / t.maxSafeVelocity);
      gaugeSpeed.style.width = `${ratio * 100}%`;
      gaugeSpeed.classList.toggle('hot', engine.inFragileZone && ratio > 0.6);
    }
  }

  nextOyster();
  resize();
  frame = requestAnimationFrame(draw);
  return () => {
    cancelAnimationFrame(frame);
    observer.disconnect();
    timers.forEach(clearTimeout);
    input.destroy();
  };
}
