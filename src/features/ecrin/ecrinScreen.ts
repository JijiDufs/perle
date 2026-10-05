// Écran d'ouverture d'un écrin (cahier §7). Vue de dessus : le couvercle pivote autour de la charnière
// du haut et se relève dans le sens du pouce. Chercher l'angle d'éclat, puis tenir : éclat parfait.
// Aucune règle de jeu ici (AGENTS.md, invariant 7) : tout vient de GlintEngine et de player.ts.
import { smoothstep } from '../../art/color';
import { renderEcrinArt, roundRectPath, VELVETS, type EcrinArt } from '../../art/ecrin';
import { drawJewel, drawSparkles, drawStar } from '../../art/jewel';
import { drawGlow } from '../../art/pearl';
import { buyEcrin } from '../../core/dust';
import { GlintEngine, type GlintEvent } from '../../core/glint';
import { JEWEL_RARITIES, jewelRarity, jewelVariant, withVariant, type Jewel, type JewelRarity, type JewelVariant } from '../../core/jewels';
import { ensureEcrin, recordEcrin, type JewelCard } from '../../core/player';
import { isInTutorial } from '../../core/tutorial';
import { ThumbInput } from '../../input/thumb';
import { track } from '../../platform/analytics';
import { chimeNotes, ding, noise, pouet, setMuted, unlockAudio } from '../../platform/audio';
import { hapticBurst, hapticTick } from '../../platform/haptics';
import { revealSuspenseMs } from '../../tuning';
import type { AppContext } from '../context';
import { dustLabel } from '../dust/dustShop';
import { expertiseButton } from '../expertise/expertiseButton';
import { jewelShareButton } from '../share/shareButton';
import { jewelCardElement } from './jewelCardView';

/** Niveau de mise en scène (0…3) selon la rareté du bijou (0…5). */
const REVEAL_TIER = [0, 0, 1, 2, 3, 3] as const;

const TEMPLATE = `
  <canvas class="scene" aria-label="Écrin. Glisse le pouce vers le haut pour l'ouvrir, et arrête-toi quand le bijou scintille."></canvas>
  <button type="button" class="odds-button">Probabilités</button>
  <p class="coach" aria-live="polite" hidden></p>
  <div class="ecrin-empty" hidden>
    <h2>Pas d’écrin pour l’instant</h2>
    <p class="ecrin-empty-text"></p>
    <div class="ecrin-progress" aria-hidden="true"></div>
    <button type="button" class="tide-button">Aller pêcher</button>
    <button type="button" class="dust-buy-ecrin"></button>
  </div>
  <div class="oyster-dock">
    <p class="message" aria-live="polite"></p>
    <div class="gauge gauge-glint" hidden>
      <span class="gauge-angle"></span>
      <span class="gauge-state"></span>
      <div class="gauge-speed"><i></i></div>
    </div>
  </div>
  <div class="card-overlay" hidden></div>
  <div class="odds-sheet" role="dialog" aria-label="Probabilités des écrins" hidden></div>
`;

export function mountEcrinScreen(root: HTMLElement, ctx: AppContext): () => void {
  root.className = 'screen oyster-screen ecrin-screen';
  root.innerHTML = TEMPLATE;
  const canvas = root.querySelector<HTMLCanvasElement>('.scene')!;
  const c = canvas.getContext('2d')!;
  const q = <T extends HTMLElement>(selector: string) => root.querySelector<T>(selector)!;
  const message = q('.message');
  const gauge = q('.gauge');
  const gaugeAngle = q('.gauge-angle');
  const gaugeState = q('.gauge-state');
  const gaugeBar = q('.gauge-speed i');
  const overlay = q('.card-overlay');
  const coach = q('.coach');
  const empty = q('.ecrin-empty');
  const oddsButton = q('.odds-button');
  const oddsSheet = q('.odds-sheet');
  setMuted(!ctx.settings.sound);

  let engine: GlintEngine | null = null;
  let rarity: JewelRarity = JEWEL_RARITIES[0];
  let art: EcrinArt | null = null;
  let artKey = '';
  let velvet = VELVETS[0];
  let busy = false;
  let firstEcrin = false;
  let gestureStart = 0;
  let lastTick = 0;
  let revealStartedAt = 0;
  let suspenseMs = 0;
  let perfectAt = 0;
  /** Bijou affiché : gardé localement car l'écrin en cours est vidé dès l'enregistrement de la carte. */
  let shownJewel: Jewel | null = null;
  /** Variante promise par cet écrin en cas d'éclat parfait, et si elle vient d'apparaître. */
  let pendingVariant: JewelVariant | null = null;
  let variantRevealed = false;
  let frame = 0;
  const timers: number[] = [];

  // ---------- Geste ----------

  const input = new ThumbInput(root, () => ctx.tuning, {
    onSample(sample, distance) {
      if (busy || !engine) return;
      if (engine.phase === 'closed' && sample.angle > 0) {
        gestureStart = sample.time;
        lastTick = 0;
      }
      if (engine.phase === 'closed' || engine.phase === 'resisting') {
        const tick = Math.floor(distance / ctx.tuning.resistanceTickDistance);
        if (tick > lastTick) {
          hapticTick();
          noise(0.025, 1200 + tick * 50, 0.08);
        }
        lastTick = tick;
      }
      handle(engine.push(sample), sample.time);
    },
    autoOpenFrom: () =>
      engine?.phase === 'opening' ? Math.max(ctx.tuning.autoOpenFromAngle, ctx.tuning.glintMaxAngle + ctx.tuning.glintTolerance) : null,
    onRelease() {
      if (busy || !engine) return;
      const wasResisting = engine.phase === 'resisting';
      engine.release();
      if (wasResisting) input.reset();
    },
  });
  root.addEventListener('pointerdown', unlockAudio);

  for (const el of [overlay, empty, oddsButton, oddsSheet]) {
    for (const type of ['pointerdown', 'pointerup'] as const) el.addEventListener(type, (event) => event.stopPropagation());
  }
  q('.ecrin-empty .tide-button').addEventListener('click', () => ctx.goTo('oyster'));
  q('.dust-buy-ecrin').addEventListener('click', () => {
    const after = buyEcrin(ctx.player, ctx.tuning);
    if (!after) return;
    ctx.setPlayer(after);
    track('dust_ecrin_bought', { price: ctx.tuning.dustEcrinPrice, from: 'ecrin' });
    nextEcrin();
  });
  oddsButton.addEventListener('click', () => {
    oddsSheet.hidden = false;
    track('ecrin_odds_viewed', {});
  });
  oddsSheet.addEventListener('click', () => (oddsSheet.hidden = true));
  oddsSheet.innerHTML = `
    <div class="odds-panel">
      <h2>Ce que contient un écrin</h2>
      <table>${JEWEL_RARITIES.map((j) => `<tr><td>${j.label}</td><td>${j.rarity}</td><td>${(j.probability * 100).toLocaleString('fr-FR')} %</td></tr>`).join('')}</table>
      <p class="muted">Un bijou ★ ou mieux est garanti après ${ctx.tuning.ecrinPityThreshold} écrins sans. Éclat parfait : valeur ×${ctx.tuning.glintPerfectMultiplier.toLocaleString('fr-FR')}, et ${Math.round(ctx.tuning.glintRareVariantChance * 100)} % de chance d’une variante rare (Aurore, Nuit ou Givre) : valeur ×${ctx.tuning.glintRareVariantMultiplier}.</p>
      <p class="tap-hint">Touche pour fermer</p>
    </div>`;
  overlay.addEventListener('pointerup', () => {
    track('card_dismissed', { jewel: rarity.id });
    nextEcrin();
  });

  function handle(events: GlintEvent[], time: number): void {
    for (const event of events) {
      if (event.type === 'pop') {
        hapticTick();
        noise(0.07, 2200, 0.4);
        input.lockAfterPop();
      } else if (event.type === 'perfect') {
        perfectAt = performance.now();
        hapticBurst(2, 60);
        ding();
        track('ecrin_perfect', { jewel: rarity.id, msSinceStart: Math.round(time - gestureStart) });
        if (pendingVariant && shownJewel) {
          // Le bijou se transforme sous les yeux du joueur.
          variantRevealed = true;
          shownJewel = withVariant(shownJewel, pendingVariant.id);
          hapticBurst(4, 70);
          timers.push(window.setTimeout(ding, 180), window.setTimeout(ding, 360));
          track('ecrin_variant', { jewel: rarity.id, variant: pendingVariant.id });
        }
      } else if (event.type === 'reveal') {
        reveal(event.perfect, time);
      }
    }
  }

  function reveal(perfect: boolean, time: number): void {
    busy = true;
    const { state, card } = recordEcrin(ctx.player, { perfect }, Date.now(), ctx.tuning);
    ctx.setPlayer(state);
    const tier = variantRevealed ? 3 : REVEAL_TIER[rarity.tier];
    track('ecrin_reveal', { jewel: rarity.id, type: card.jewel.type, perfect, variant: card.variant ?? 'aucune', durationMs: Math.round(time - gestureStart), first: firstEcrin });
    revealStartedAt = performance.now();
    suspenseMs = revealSuspenseMs(ctx.tuning, tier);
    hapticBurst(tier + 1, 140);
    timers.push(
      window.setTimeout(() => {
        if (rarity.id === 'toc') pouet();
        else chimeNotes('normal', tier);
        showCard(card, perfect);
      }, suspenseMs),
    );
  }

  function showCard(card: JewelCard, perfect: boolean): void {
    overlay.replaceChildren();
    if (firstEcrin) {
      const tip = document.createElement('p');
      tip.className = 'coach coach-card';
      tip.textContent = perfect
        ? `Éclat parfait ! Le bijou vaut 50 % de plus. Tu gagneras un nouvel écrin toutes les ${ctx.tuning.oystersPerEcrin} huîtres.`
        : `Pas d’éclat parfait cette fois : arrête-toi pile quand ça brille le plus, et tiens une seconde. Prochain écrin dans ${ctx.tuning.oystersPerEcrin} huîtres.`;
      overlay.append(tip);
    }
    overlay.append(jewelCardElement(card, 'large'));
    const actions = document.createElement('div');
    actions.className = 'card-actions';
    const expertise = expertiseButton(ctx, card, (updated) => showCard(updated, perfect));
    if (expertise) actions.append(expertise);
    actions.append(jewelShareButton(card));
    overlay.append(actions);
    const hint = document.createElement('p');
    hint.className = 'tap-hint';
    hint.textContent = ctx.player.ecrins > 0 ? `Touche pour l’écrin suivant (${ctx.player.ecrins})` : 'Touche pour continuer';
    overlay.append(hint);
    overlay.hidden = false;
  }

  function nextEcrin(): void {
    overlay.hidden = true;
    firstEcrin = ctx.player.jewelCards.length === 0;
    ctx.setPlayer(ensureEcrin(ctx.player, ctx.rng, ctx.tuning));
    const pending = ctx.player.currentEcrin;
    if (!pending) {
      engine = null;
      busy = true;
      showEmpty();
      return;
    }
    empty.hidden = true;
    rarity = jewelRarity(pending.jewel.rarityId);
    shownJewel = pending.jewel;
    pendingVariant = pending.variantIfPerfect ? jewelVariant(pending.variantIfPerfect) : null;
    variantRevealed = false;
    velvet = VELVETS[Math.floor(Math.random() * VELVETS.length)];
    artKey = '';
    engine = new GlintEngine(ctx.tuning, pending.sweetAngle);
    input.reset();
    busy = false;
    perfectAt = 0;
    track('ecrin_shown', { jewel: rarity.id, first: firstEcrin });
  }

  function showEmpty(): void {
    const opened = ctx.player.oystersOpened;
    const text = q('.ecrin-empty-text');
    const progress = q('.ecrin-progress');
    if (isInTutorial(opened)) {
      text.textContent = 'Termine tes premières huîtres : le premier écrin t’attend au bout.';
      progress.innerHTML = '';
    } else {
      const left = ctx.tuning.oystersPerEcrin - ctx.player.oystersSinceEcrin;
      text.textContent = `Encore ${left} huître${left > 1 ? 's' : ''} à ouvrir pour gagner ton prochain écrin.`;
      progress.innerHTML = Array.from({ length: ctx.tuning.oystersPerEcrin }, (_, i) => `<i class="${i < ctx.player.oystersSinceEcrin ? 'on' : ''}"></i>`).join('');
    }
    // Hors tutoriel, un écrin s'achète aussi avec la poussière d'or.
    const buy = q<HTMLButtonElement>('.dust-buy-ecrin');
    buy.hidden = isInTutorial(opened);
    buy.disabled = ctx.player.dust < ctx.tuning.dustEcrinPrice;
    buy.textContent = buy.disabled
      ? `Ou ${dustLabel(ctx.tuning.dustEcrinPrice)} de poussière d’or (tu en as ${ctx.player.dust})`
      : `Acheter un écrin · ${dustLabel(ctx.tuning.dustEcrinPrice)}`;
    empty.hidden = false;
    message.textContent = '';
    gauge.hidden = true;
    coach.hidden = true;
  }

  // ---------- Rendu ----------

  function resize(): void {
    const dpr = Math.min(window.devicePixelRatio || 1, 3);
    const { width, height } = canvas.getBoundingClientRect();
    canvas.width = Math.round(width * dpr);
    canvas.height = Math.round(height * dpr);
    c.setTransform(dpr, 0, 0, dpr, 0, 0);
    artKey = '';
  }
  const observer = new ResizeObserver(resize);
  observer.observe(canvas);

  function draw(now: number): void {
    frame = requestAnimationFrame(draw);
    const t = now / 1000;
    const w = canvas.clientWidth;
    const h = canvas.clientHeight;

    const bg = c.createLinearGradient(0, 0, 0, h);
    bg.addColorStop(0, '#1a1520');
    bg.addColorStop(1, '#0b090e');
    c.fillStyle = bg;
    c.fillRect(0, 0, w, h);
    for (let i = 0; i < 4; i++) {
      const x = w * (0.5 + 0.45 * Math.sin(t * 0.11 + i * 1.9));
      const y = h * (0.5 + 0.4 * Math.cos(t * 0.09 + i * 2.1));
      const g = c.createRadialGradient(x, y, 0, x, y, w * 0.6);
      g.addColorStop(0, 'rgba(255,220,170,.05)');
      g.addColorStop(1, 'rgba(255,220,170,0)');
      c.fillStyle = g;
      c.fillRect(x - w * 0.6, y - w * 0.6, w * 1.2, w * 1.2);
    }
    if (!engine) return;

    const bw = Math.min(w * 0.78, h * 0.42);
    const bh = bw * 0.78;
    const bx = (w - bw) / 2;
    const hy = h * 0.4;
    const key = `${bw}|${velvet}`;
    if (key !== artKey) {
      art = renderEcrinArt(bw, bh, velvet, Math.min(window.devicePixelRatio || 1, 3));
      artKey = key;
    }
    const angle = engine.angle;
    const theta = (angle * Math.PI) / 180;
    handle(engine.tick(now), now);

    // Base et bijou.
    c.drawImage(art!.base, bx, hy, bw, bh);
    const jx = bx + bw / 2;
    const jy = hy + bh * 0.54;
    if (shownJewel) drawJewel(c, jx, jy, (bw / 560) * 1.15, shownJewel);

    // Ombre tant que l'écrin est peu ouvert.
    const dim = 1 - smoothstep(4, 140, angle);
    if (dim > 0.001) {
      c.save();
      roundRectPath(c, bx, hy, bw, bh, Math.min(bw, bh) * 0.08);
      c.fillStyle = `rgba(0,0,0,${dim * 0.94})`;
      c.fill();
      c.restore();
    }

    // Scintillement : plus on approche de l'angle d'éclat, plus ça brille.
    const sparkle = engine.perfect ? 1 : engine.closeness;
    const open = smoothstep(1, 25, angle);
    const suspense = busy ? smoothstep(0, Math.max(suspenseMs, 1), now - revealStartedAt) : 0;
    const glow = variantRevealed && pendingVariant ? pendingVariant.glow : rarity.glow;
    const sparkleTier = variantRevealed ? Math.max(rarity.tier, 5) : rarity.tier;
    if (glow) {
      drawGlow(c, jx, jy, bw * (0.45 + sparkleTier * 0.06), glow, open * (0.12 + 0.45 * sparkle) + suspense * 0.3);
      drawSparkles(c, jx, jy, sparkleTier, glow, t, open * (0.15 + 0.85 * sparkle) + suspense * 0.5, bw / 600);
    }
    if (perfectAt) {
      // Gerbe d'étoiles ; deux vagues et la couleur de la variante si elle apparaît.
      const waves = variantRevealed ? 2 : 1;
      for (let wave = 0; wave < waves; wave++) {
        const burst = 1 - smoothstep(0, 700 + wave * 400, now - perfectAt - wave * 250);
        if (burst <= 0 || now - perfectAt < wave * 250) continue;
        for (let i = 0; i < 14; i++) {
          const a = (i / 14) * Math.PI * 2 + wave * 0.22;
          const radius = (bw / 600) * (120 + (1 - burst) * (300 + wave * 120));
          drawStar(c, jx + Math.cos(a) * radius, jy + Math.sin(a) * radius * 0.8, (bw / 600) * (30 * burst + 8), burst, wave && glow ? glow : '#fff3c4');
        }
      }
    }

    // Couvercle : extérieur tant qu'il est rabattu, satin intérieur une fois relevé.
    const lift = Math.cos(theta);
    if (lift > 0.002) {
      c.drawImage(art!.lidOutside, bx, hy, bw, bh * lift);
      c.fillStyle = `rgba(0,0,0,${Math.sin(theta) * 0.35})`;
      c.fillRect(bx, hy, bw, bh * lift);
      // Un éclat filtre sous le couvercle des pièces ★ et plus.
      if (rarity.tier >= 4 && engine.phase === 'closed') {
        const p = ((t * 0.5) % 1.6) - 0.3;
        const g = c.createLinearGradient(bx, hy, bx + bw, hy + bh);
        const at = (v: number) => Math.min(1, Math.max(0, v));
        g.addColorStop(at(p - 0.1), 'rgba(255,240,180,0)');
        g.addColorStop(at(p), 'rgba(255,240,180,.55)');
        g.addColorStop(at(p + 0.1), 'rgba(255,240,180,0)');
        c.fillStyle = g;
        c.fillRect(bx, hy, bw, bh * lift);
      }
      const leak = smoothstep(0.5, 10, angle) * (1 - smoothstep(40, 95, angle));
      drawGlow(c, jx, hy + bh * lift, bw * 0.6, rarity.glow ?? '#fff1d6', leak * 0.6);
    } else if (lift < -0.002) {
      const height = bh * -lift;
      c.drawImage(art!.lidInside, bx, hy - height, bw, height);
      c.fillStyle = `rgba(0,0,0,${Math.sin(theta) * 0.25})`;
      c.fillRect(bx, hy - height, bw, height);
    }

    renderDock();
  }

  function renderDock(): void {
    if (!engine) return;
    const t = ctx.tuning;
    let text = '';
    let gold = false;
    const phase = engine.phase;
    if (busy) text = '';
    else if (phase === 'closed') text = rarity.tier >= 4 ? 'Un éclat filtre… Glisse le pouce vers le haut' : 'Ouvre l’écrin. Glisse le pouce vers le haut';
    else if (phase === 'resisting') text = 'Ouvre doucement…';
    else if (engine.perfect && variantRevealed && pendingVariant) [text, gold] = [`Variante rare : ${pendingVariant.label} ! Ouvre jusqu’au bout`, true];
    else if (engine.perfect) [text, gold] = ['Éclat parfait ! Ouvre jusqu’au bout', true];
    else if (engine.angle > t.fragileMinAngle && engine.angle < t.revealAngle) text = engine.closeness > 0.75 ? 'Ça scintille… ne bouge plus' : 'Cherche l’angle d’éclat';
    else text = 'Encore un peu…';
    if (message.textContent !== text) message.textContent = text;
    message.classList.toggle('gold', gold);
    message.classList.toggle('nudge', phase === 'closed' && !busy);

    const tip = busy || !firstEcrin ? null : phase === 'closed' || phase === 'resisting'
      ? 'Ton premier écrin ! Ouvre lentement : quelque part, le bijou se met à scintiller. Arrête-toi pile là et tiens une seconde.'
      : engine.perfect ? null : engine.closeness > 0.75 ? 'C’est là ! Ne bouge plus…' : 'Monte ou descends doucement jusqu’à ce que ça brille fort.';
    coach.hidden = !tip;
    if (tip && coach.textContent !== tip) coach.textContent = tip;
    oddsButton.hidden = busy || phase !== 'closed';

    // La jauge d'éclat est toujours visible pour le premier écrin (angle d'éclat guidé, cahier §15).
    gauge.hidden = busy || !(ctx.settings.showHud || firstEcrin);
    if (!gauge.hidden) {
      gaugeAngle.innerHTML = `${engine.angle.toFixed(0)}°<small>ouverture</small>`;
      gaugeState.textContent = engine.perfect ? 'Éclat parfait' : 'Éclat';
      gaugeState.classList.toggle('gold', engine.perfect);
      const fill = engine.perfect ? 1 : Math.max(engine.closeness * 0.6, engine.holdProgress);
      gaugeBar.style.width = `${fill * 100}%`;
      gaugeBar.classList.add('gold');
    }
  }

  nextEcrin();
  resize();
  frame = requestAnimationFrame(draw);
  return () => {
    cancelAnimationFrame(frame);
    observer.disconnect();
    timers.forEach(clearTimeout);
    input.destroy();
  };
}
