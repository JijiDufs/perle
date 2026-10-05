// Mini-jeu d'expertise à la loupe (cahier §7). Affichage et geste seulement : les inclusions,
// la détection et la note viennent de src/core/expertise.ts.
import { formatEuros } from '../../art/cardStyle';
import { drawGem } from '../../art/jewel';
import { GRADE_LABELS, inclusionAt, inclusionsFor, recordExpertise, type Inclusion } from '../../core/expertise';
import { jewelVariant } from '../../core/jewels';
import type { JewelCard } from '../../core/player';
import { track } from '../../platform/analytics';
import { ding, noise, unlockAudio } from '../../platform/audio';
import { hapticBurst, hapticTick } from '../../platform/haptics';
import type { AppContext } from '../context';

/** La loupe s'affiche au-dessus du doigt pour que le pouce ne cache pas la pierre. */
const LOUPE_OFFSET_Y = 96;
const ZOOM = 2.2;

const TEMPLATE = `
  <header class="expertise-head">
    <div>
      <h2>Expertise à la loupe</h2>
      <p class="expertise-name"></p>
    </div>
    <button type="button" class="expertise-close" aria-label="Fermer">✕</button>
  </header>
  <div class="expertise-hud" hidden>
    <span class="expertise-found"></span>
    <div class="expertise-time"><i></i></div>
  </div>
  <canvas class="expertise-scene" aria-label="Pierre à expertiser. Promène la loupe et garde le viseur sur chaque inclusion."></canvas>
  <div class="expertise-intro">
    <p>Promène la loupe sur la pierre. Les inclusions n’apparaissent qu’à travers elle : garde le viseur dessus un instant pour les noter.</p>
    <p class="muted"></p>
    <button type="button" class="share-button expertise-start">Commencer</button>
  </div>
  <div class="expertise-result" hidden></div>
`;

/** Ouvre l'expertise d'une carte. `onDone` reçoit la carte mise à jour (ou inchangée si on ferme avant de commencer). */
export function openExpertise(ctx: AppContext, card: JewelCard, onDone: (card: JewelCard) => void): void {
  const inclusions = inclusionsFor(card);
  const t = ctx.tuning;
  const gemColor = (card.variant ? jewelVariant(card.variant).gem : card.jewel.gem) ?? '#f2fbff';

  const root = document.createElement('div');
  root.className = 'expertise-overlay';
  root.setAttribute('role', 'dialog');
  root.innerHTML = TEMPLATE;
  document.body.append(root);
  const q = <T extends HTMLElement>(selector: string) => root.querySelector<T>(selector)!;
  const canvas = q<HTMLCanvasElement>('.expertise-scene');
  const c = canvas.getContext('2d')!;
  q('.expertise-name').textContent = card.jewel.name;
  q('.expertise-intro .muted').textContent = `${inclusions.length} inclusions cachées · ${Math.round(t.expertiseDurationMs / 1000)} secondes · une seule tentative`;

  let started = false;
  let finished = false;
  let startAt = 0;
  const found = new Set<number>();
  let dwellIndex = -1;
  let dwellSince = 0;
  let pointer: { x: number; y: number } | null = null;
  let frame = 0;
  let lastTickSecond = -1;

  // Le toucher ne traverse pas vers l'écran derrière.
  for (const type of ['pointerdown', 'pointerup', 'click'] as const) root.addEventListener(type, (event) => event.stopPropagation());

  const close = (result: JewelCard) => {
    cancelAnimationFrame(frame);
    root.remove();
    onDone(result);
  };
  q('.expertise-close').addEventListener('click', () => {
    // Fermer en cours de route termine l'expertise avec ce qui a été trouvé : pas de relance gratuite.
    if (started && !finished) finish();
    else close(ctx.player.jewelCards.find((x) => x.serial === card.serial) ?? card);
  });
  q('.expertise-start').addEventListener('click', () => {
    unlockAudio();
    started = true;
    startAt = performance.now();
    q('.expertise-intro').hidden = true;
    q('.expertise-hud').hidden = false;
    track('expertise_started', { jewel: card.jewel.rarityId, inclusions: inclusions.length });
  });

  // Position du doigt dans la toile, calculée depuis l'écran (offsetX n'est pas fiable partout).
  const toCanvas = (event: PointerEvent) => {
    const rect = canvas.getBoundingClientRect();
    return { x: event.clientX - rect.left, y: event.clientY - rect.top };
  };
  canvas.addEventListener('pointerdown', (event) => {
    pointer = toCanvas(event);
    try {
      canvas.setPointerCapture(event.pointerId);
    } catch {
      // Capture impossible (appui simulé, navigateur ancien) : le geste marche quand même.
    }
  });
  canvas.addEventListener('pointermove', (event) => {
    if (pointer) pointer = toCanvas(event);
  });
  const release = () => {
    pointer = null;
    dwellIndex = -1;
  };
  canvas.addEventListener('pointerup', release);
  canvas.addEventListener('pointercancel', release);

  function geometry() {
    const w = canvas.clientWidth;
    const h = canvas.clientHeight;
    const R = Math.min(w * 0.4, h * 0.3);
    return { w, h, R, cx: w / 2, cy: h * 0.45, loupeR: R * 0.46 };
  }

  function finish(): void {
    if (finished) return;
    finished = true;
    const before = ctx.player.jewelCards.find((x) => x.serial === card.serial) ?? card;
    ctx.setPlayer(recordExpertise(ctx.player, card.serial, found.size, inclusions.length, Date.now(), t));
    const after = ctx.player.jewelCards.find((x) => x.serial === card.serial) ?? card;
    const record = after.expertise;
    track('expertise_finished', { jewel: card.jewel.rarityId, grade: record?.grade ?? 'aucune', found: found.size, total: inclusions.length, ms: Math.round(performance.now() - startAt) });
    if (record && record.bonus > 0) {
      ding();
      hapticBurst(3, 90);
    }
    const result = q('.expertise-result');
    result.innerHTML = `
      <div class="certificate${record && record.bonus > 0 ? '' : ' certificate-failed'}">
        <p class="certificate-kicker">${record && record.bonus > 0 ? 'Certificat d’expertise' : 'Expertise'}</p>
        <h3>${record ? GRADE_LABELS[record.grade] : '—'}</h3>
        <p>${found.size} inclusion${found.size > 1 ? 's' : ''} sur ${inclusions.length}</p>
        ${record && record.bonus > 0
          ? `<p class="certificate-value">${formatEuros(before.value)} → <strong>${formatEuros(after.value)}</strong> (+${Math.round(record.bonus * 100)} %)</p>`
          : '<p class="muted">Pas de certificat cette fois. La valeur ne change pas.</p>'}
      </div>
      <button type="button" class="share-button">Fermer</button>`;
    result.hidden = false;
    q('.expertise-hud').hidden = true;
    result.querySelector('button')!.addEventListener('click', () => close(after));
  }

  /** Dessine une inclusion (coordonnées écran, `scale` = taille d'un point). */
  function drawInclusion(inclusion: Inclusion, x: number, y: number, scale: number): void {
    c.save();
    c.translate(x, y);
    c.rotate(inclusion.angle);
    c.strokeStyle = 'rgba(25,20,30,.75)';
    c.fillStyle = 'rgba(25,20,30,.7)';
    c.lineCap = 'round';
    if (inclusion.kind === 'point') {
      c.beginPath();
      c.arc(0, 0, scale * 1.1, 0, Math.PI * 2);
      c.fill();
      c.fillStyle = 'rgba(255,255,255,.5)';
      c.beginPath();
      c.arc(-scale * 0.35, -scale * 0.35, scale * 0.35, 0, Math.PI * 2);
      c.fill();
    } else if (inclusion.kind === 'plume') {
      c.lineWidth = scale * 0.4;
      c.beginPath();
      c.moveTo(-scale * 3, 0);
      c.quadraticCurveTo(0, -scale * 1.6, scale * 3, 0);
      for (let i = -2; i <= 2; i++) {
        c.moveTo(i * scale, -scale * 0.7);
        c.lineTo(i * scale + scale * 0.6, -scale * 1.7);
      }
      c.stroke();
    } else {
      c.lineWidth = scale * 0.35;
      c.beginPath();
      c.moveTo(-scale * 3.5, 0);
      c.lineTo(scale * 3.5, 0);
      c.stroke();
    }
    c.restore();
  }

  function draw(now: number): void {
    frame = requestAnimationFrame(draw);
    const dpr = Math.min(window.devicePixelRatio || 1, 3);
    const { w, h, R, cx, cy, loupeR } = geometry();
    if (canvas.width !== Math.round(w * dpr)) {
      canvas.width = Math.round(w * dpr);
      canvas.height = Math.round(h * dpr);
    }
    c.setTransform(dpr, 0, 0, dpr, 0, 0);
    c.clearRect(0, 0, w, h);

    // Pierre vue à l'œil nu : les inclusions ne se voient pas.
    drawGem(c, cx, cy, R, gemColor);

    // Inclusions déjà repérées : cerclées d'or, visibles partout.
    for (const i of found) {
      const inc = inclusions[i];
      c.strokeStyle = '#e8be5a';
      c.lineWidth = 2;
      c.beginPath();
      c.arc(cx + inc.x * R, cy + inc.y * R, R * 0.07, 0, Math.PI * 2);
      c.stroke();
    }

    const elapsed = started ? now - startAt : 0;
    const left = Math.max(0, t.expertiseDurationMs - elapsed);
    if (started && !finished) {
      const second = Math.ceil(left / 1000);
      if (second <= 5 && second !== lastTickSecond) {
        lastTickSecond = second;
        noise(0.03, 2600, 0.15);
      }
      q('.expertise-found').textContent = `${found.size} / ${inclusions.length} inclusions`;
      const bar = q('.expertise-time i');
      bar.style.width = `${(left / t.expertiseDurationMs) * 100}%`;
      bar.classList.toggle('hot', left < 5000);
      if (left <= 0 || found.size === inclusions.length) finish();
    }

    // Loupe : au-dessus du doigt, ou posée au centre tant qu'on n'a pas touché l'écran.
    const lx = pointer ? pointer.x : cx;
    const ly = pointer ? pointer.y - LOUPE_OFFSET_Y : cy;
    const gx = (lx - cx) / R; // point visé, en coordonnées de la pierre
    const gy = (ly - cy) / R;
    c.save();
    c.beginPath();
    c.arc(lx, ly, loupeR, 0, Math.PI * 2);
    c.clip();
    c.fillStyle = '#0b090e';
    c.fillRect(lx - loupeR, ly - loupeR, loupeR * 2, loupeR * 2);
    // Vue agrandie centrée sur le point visé.
    c.translate(lx, ly);
    c.scale(ZOOM, ZOOM);
    c.translate(-(cx + gx * R), -(cy + gy * R));
    drawGem(c, cx, cy, R, gemColor);
    inclusions.forEach((inc, i) => {
      drawInclusion(inc, cx + inc.x * R, cy + inc.y * R, R * 0.018);
      if (found.has(i)) {
        c.strokeStyle = '#e8be5a';
        c.lineWidth = 1;
        c.beginPath();
        c.arc(cx + inc.x * R, cy + inc.y * R, R * 0.07, 0, Math.PI * 2);
        c.stroke();
      }
    });
    c.restore();

    // Monture de la loupe et viseur.
    c.lineWidth = 6;
    c.strokeStyle = '#b8862b';
    c.beginPath();
    c.arc(lx, ly, loupeR, 0, Math.PI * 2);
    c.stroke();
    c.lineWidth = 1.5;
    c.strokeStyle = 'rgba(255,255,255,.6)';
    c.beginPath();
    c.moveTo(lx - 10, ly);
    c.lineTo(lx + 10, ly);
    c.moveTo(lx, ly - 10);
    c.lineTo(lx, ly + 10);
    c.stroke();

    // Tenir le viseur sur une inclusion la repère.
    if (started && !finished && pointer) {
      const index = inclusionAt(inclusions, gx, gy, t);
      if (index !== dwellIndex) {
        dwellIndex = index;
        dwellSince = now;
      }
      if (index >= 0 && !found.has(index)) {
        const progress = Math.min(1, (now - dwellSince) / t.expertiseDwellMs);
        c.lineWidth = 3;
        c.strokeStyle = '#e8be5a';
        c.beginPath();
        c.arc(lx, ly, 16, -Math.PI / 2, -Math.PI / 2 + progress * Math.PI * 2);
        c.stroke();
        if (progress >= 1) {
          found.add(index);
          hapticTick();
          noise(0.05, 3000, 0.25);
        }
      }
    }
  }
  frame = requestAnimationFrame(draw);
}
