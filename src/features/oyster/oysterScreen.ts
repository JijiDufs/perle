// Écran d'ouverture d'une huître. Affiche l'état du moteur et transmet les gestes :
// aucune règle de jeu ici (AGENTS.md, invariant 7).
// Vue de dessus : la valve du bas reste posée, le couvercle pivote autour de la charnière
// et se soulève vers le haut de l'écran, dans le sens du pouce.
import { smoothstep } from '../../art/color';
import { drawGlow, drawPearl } from '../../art/pearl';
import { drawFlesh, drawNacre, drawShellExterior, randomPhases, shellOutline, tracePath, type Phases } from '../../art/shell';
import { pearlById, type PearlType } from '../../core/catalog';
import { OpeningEngine, type OpeningEvent } from '../../core/opening';
import { ensureOyster, recordOpening, type PearlCard } from '../../core/player';
import { nextRefillIn, refreshStock } from '../../core/stock';
import { isCrackProtected, isInTutorial } from '../../core/tutorial';
import { isIos, isStandalone } from '../../platform/offline';
import { ThumbInput } from '../../input/thumb';
import { track } from '../../platform/analytics';
import { chime, noise, setMuted, unlockAudio } from '../../platform/audio';
import { hapticBurst, hapticTick } from '../../platform/haptics';
import { revealSuspenseMs } from '../../tuning';
import { cardElement } from '../collection/cardView';
import type { AppContext } from '../context';
import { pearlShareButton } from '../share/shareButton';
import { coachAfterReveal, coachDuringGesture } from './coach';

const DOWN = Math.PI / 2;
/** Intensité du halo selon le niveau de révélation. */
const GLOW_STRENGTH = [0.55, 0.7, 0.85, 1];
/** Après ce délai sans geste sur une huître fermée, la main fantôme remontre le geste. */
const IDLE_HINT_MS = 6000;

const TEMPLATE = `
  <canvas class="scene" aria-label="Huître. Glisse le pouce vers le haut pour l'ouvrir."></canvas>
  <p class="coach" aria-live="polite" hidden></p>
  <div class="ghost-thumb" aria-hidden="true" hidden></div>
  <div class="install-hint" role="note" hidden>
    <p>Installe Perle sur ton écran d'accueil : touche <strong>Partager</strong> <span aria-hidden="true">⬆︎</span> puis <strong>« Sur l'écran d'accueil »</strong>. Tu pourras jouer même sans réseau.</p>
    <button type="button">OK</button>
  </div>
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
  let sizeMm = 6;
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
    const { state, card, ecrinEarned } = recordOpening(ctx.player, { lustre, cracked }, Date.now(), ctx.tuning);
    if (ecrinEarned) track('ecrin_earned', { oystersOpened: state.oystersOpened });
    ctx.setPlayer(state);
    const tier = pearl.revealTier;
    track('reveal', {
      pearlId: pearl.id,
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
        chime(pearl);
        showCard(card, cracked && pearl.glow !== null, ecrinEarned);
      }, suspenseMs),
    );
  }

  function showCard(card: PearlCard | null, cracked: boolean, ecrinEarned: boolean): void {
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
    overlay.append(cardElement(pearl.id, card, 'large'));
    if (card) overlay.append(pearlShareButton(card));
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
    ctx.showLevelUps();
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

  function resize(): void {
    const dpr = Math.min(window.devicePixelRatio || 1, 3);
    const { width, height } = canvas.getBoundingClientRect();
    canvas.width = Math.round(width * dpr);
    canvas.height = Math.round(height * dpr);
    c.setTransform(dpr, 0, 0, dpr, 0, 0);
  }
  const observer = new ResizeObserver(resize);
  observer.observe(canvas);

  function draw(now: number): void {
    frame = requestAnimationFrame(draw);
    const t = now / 1000;
    const w = canvas.clientWidth;
    const h = canvas.clientHeight;
    const angle = engine.angle;
    const theta = (angle * Math.PI) / 180;
    const L = Math.min(w * 0.6, h * 0.34);
    let hx = w / 2;
    let hy = h * 0.41;

    // Fond : eau profonde et reflets qui dérivent.
    const bg = c.createLinearGradient(0, 0, 0, h);
    bg.addColorStop(0, '#0c3b45');
    bg.addColorStop(1, '#03161c');
    c.fillStyle = bg;
    c.fillRect(0, 0, w, h);
    for (let i = 0; i < 5; i++) {
      const x = w * (0.5 + 0.45 * Math.sin(t * 0.13 + i * 1.7));
      const y = h * (0.5 + 0.4 * Math.cos(t * 0.11 + i * 2.3));
      const g = c.createRadialGradient(x, y, 0, x, y, w * 0.6);
      g.addColorStop(0, 'rgba(170,240,235,.07)');
      g.addColorStop(1, 'rgba(170,240,235,0)');
      c.fillStyle = g;
      c.fillRect(x - w * 0.6, y - w * 0.6, w * 1.2, w * 1.2);
    }

    if (waiting) {
      // Marée basse : une coquille vide, à peine visible, en attendant le minuteur.
      c.globalAlpha = 0.18;
      drawShellExterior(c, hx, hy, DOWN, L, phases);
      c.globalAlpha = 1;
      renderDock();
      return;
    }

    // Tremblement des plus rares, petit choc au pop.
    if (pearl.trembles && engine.phase === 'closed' && !busy && t % 2.4 < 0.45) {
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
    let prad = L * (0.05 + sizeMm * 0.0055);
    const suspense = busy ? smoothstep(0, Math.max(suspenseMs, 1), now - revealStartedAt) : 0;
    const cursedPulse = pearl.id === 'cursed' ? 0.75 + 0.25 * Math.sin(t * 6) : 1;
    if (busy) prad *= 1 + 0.1 * suspense * Math.max(0, Math.sin(t * (6 + pearl.revealTier * 3)));
    drawPearl(c, px, py, prad, pearl, engine.cracked);

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
    const strength = GLOW_STRENGTH[pearl.revealTier] * cursedPulse * (engine.cracked ? 0.35 : 1);
    drawGlow(c, px, py, prad * (4 + pearl.revealTier * 0.8), pearl.glow, smoothstep(1, 25, angle) * strength, false);

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
      drawGlow(c, hx, hy + L * 0.98 * lift, L * 0.8, pearl.glow, leak * strength * 0.9);
    }

    // Révélation : le halo envahit l'écran, puis éclair blanc pour les ★.
    if (busy) drawGlow(c, px, py, L * (1.4 + pearl.revealTier * 0.5), pearl.glow, suspense * 0.5 * cursedPulse, false);
    const flash = flashAt ? 1 - smoothstep(0, 500, now - flashAt) : 0;
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

  function renderDock(): void {
    renderStock();
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
    else if (engine.phase === 'closed') text = pearl.trembles ? 'Elle tremble… Glisse le pouce vers le haut' : 'Ouvre-moi. Glisse le pouce vers le haut';
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

    gauge.hidden = !ctx.settings.showHud;
    if (!gauge.hidden) {
      gaugeAngle.innerHTML = `${engine.angle.toFixed(0)}°<small>ouverture</small>`;
      gaugeState.textContent = engine.cracked ? 'Perle fêlée' : engine.inFragileZone ? 'Zone fragile' : engine.phase === 'closed' ? 'Fermée' : engine.phase === 'resisting' ? 'Résistance' : engine.phase === 'revealed' ? 'Ouverte' : 'Ouverture';
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
