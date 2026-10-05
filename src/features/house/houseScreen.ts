// La Maison (cahier §8) : la cabane de grand-mère Rose, qui se restaure lettre après lettre.
import { drawHouse } from '../../art/house';
import { jewelCanvas } from '../../art/jewel';
import { pearlCanvas } from '../../art/pearl';
import { pearlById } from '../../core/catalog';
import { CHAPTERS, houseStageName, isChapterUnlocked, NEXT_CHAPTER_LEVEL, readChapter, restoredFeatures, type Chapter, type HouseFeature } from '../../core/house';
import { jewelRarity, jewelVariant, withVariant } from '../../core/jewels';
import { levelFromXp, rankForLevel } from '../../core/levels';
import { track } from '../../platform/analytics';
import { chimeNotes } from '../../platform/audio';
import { hapticBurst } from '../../platform/haptics';
import { isAtelierUnlocked } from '../../core/atelier';
import { openAtelier } from '../atelier/atelierScreen';
import { craftedJewel } from '../atelier/craftedView';
import type { AppContext } from '../context';

/** Durée de l'éclat quand un élément est restauré (ms). */
const APPEAR_MS = 1600;

/** La plus belle pièce du joueur, dessinée pour la vitrine. */
function showcase(ctx: AppContext): HTMLCanvasElement | null {
  const crafted = [...ctx.player.craftedCards].sort((a, b) => b.value - a.value)[0];
  const bestJewel = [...ctx.player.jewelCards].sort((a, b) => b.value - a.value)[0];
  if (crafted && (!bestJewel || crafted.value >= bestJewel.value)) {
    return jewelCanvas(craftedJewel({ name: crafted.name, type: crafted.type, metal: crafted.metal }, crafted.pearlColors), '#fff1d6', 160);
  }
  const jewel = [...ctx.player.jewelCards].sort((a, b) => b.value - a.value)[0];
  if (jewel) {
    const glow = jewel.variant ? jewelVariant(jewel.variant).glow : jewelRarity(jewel.jewel.rarityId).glow;
    return jewelCanvas(withVariant(jewel.jewel, jewel.variant), glow, 160);
  }
  const pearl = [...ctx.player.cards].sort((a, b) => b.value - a.value)[0];
  return pearl ? pearlCanvas(pearlById(pearl.pearlId), 160, pearl.cracked, 0.3) : null;
}

export function mountHouseScreen(root: HTMLElement, ctx: AppContext): () => void {
  root.className = 'screen house-screen';
  root.innerHTML = `
    <section class="house-scene">
      <canvas aria-label="La Maison de grand-mère Rose"></canvas>
      <div class="house-title"><p class="house-kicker"></p><h2></h2></div>
    </section>
    <section class="house-atelier"></section>
    <section class="house-letters">
      <h3 class="section-title">Le carnet de grand-mère Rose</h3>
      <p class="muted house-intro">Chaque lettre lue redonne vie à un coin de la Maison.</p>
      <ol class="chapter-list"></ol>
    </section>
  `;
  const canvas = root.querySelector('canvas')!;
  const c = canvas.getContext('2d')!;
  let appearing: { feature: HouseFeature; start: number } | null = null;
  let art = showcase(ctx);
  let frame = 0;

  function resize(): void {
    const dpr = Math.min(window.devicePixelRatio || 1, 3);
    const { width, height } = canvas.getBoundingClientRect();
    canvas.width = Math.round(width * dpr);
    canvas.height = Math.round(height * dpr);
    c.setTransform(dpr, 0, 0, dpr, 0, 0);
  }

  function loop(now: number): void {
    const { width, height } = canvas.getBoundingClientRect();
    let appear = null;
    if (appearing) {
      const progress = (now - appearing.start) / APPEAR_MS;
      if (progress >= 1) appearing = null;
      else appear = { feature: appearing.feature, progress };
    }
    // Pendant l'éclat, l'élément restauré apparaît déjà (il est dans l'état).
    drawHouse(c, width, height, { restored: restoredFeatures(ctx.player), showcase: art, appearing: appear }, now);
    frame = requestAnimationFrame(loop);
  }

  function renderHeader(): void {
    const level = levelFromXp(ctx.player.reputation, ctx.tuning).level;
    root.querySelector('.house-kicker')!.textContent = `${rankForLevel(level).title} · niveau ${level}`;
    root.querySelector('.house-title h2')!.textContent = houseStageName(level);
  }

  function renderLetters(): void {
    const list = root.querySelector('.chapter-list')!;
    const rows = CHAPTERS.map((chapter) => {
      const unlocked = isChapterUnlocked(chapter, ctx.player, ctx.tuning);
      const read = ctx.player.chaptersRead.includes(chapter.id);
      if (!unlocked) {
        return `<li class="chapter locked"><span class="chapter-number">${chapter.number}</span><span class="chapter-text"><b>Lettre scellée</b><small>Niveau ${chapter.level}</small></span></li>`;
      }
      return `<li class="chapter ${read ? 'read' : 'new'}">
        <button type="button" data-chapter="${chapter.id}">
          <span class="chapter-number">${chapter.number}</span>
          <span class="chapter-text"><b>${chapter.title}</b><small>${read ? `✓ ${chapter.restoresLabel}` : 'Nouvelle lettre'}</small></span>
          <span class="chapter-action">${read ? 'Relire' : 'Lire'}</span>
        </button></li>`;
    });
    rows.push(`<li class="chapter locked"><span class="chapter-number">${CHAPTERS.length + 1}</span><span class="chapter-text"><b>La suite…</b><small>Niveau ${NEXT_CHAPTER_LEVEL} · bientôt dans le jeu</small></span></li>`);
    list.innerHTML = rows.join('');
  }

  /** L'entrée de l'atelier (cahier §6 : niveau 5). */
  function renderAtelier(): void {
    const open = isAtelierUnlocked(ctx.player, ctx.tuning);
    root.querySelector('.house-atelier')!.innerHTML = open
      ? `<button type="button" class="atelier-door" data-action="atelier"><span class="atelier-icon" aria-hidden="true">⚒</span><span><b>L’atelier</b><small>Transforme tes perles en bijoux · ${ctx.player.craftedCards.length ? `${ctx.player.craftedCards.length} création${ctx.player.craftedCards.length > 1 ? 's' : ''}` : 'aucune création pour l’instant'}</small></span><span class="chapter-action">Entrer</span></button>`
      : `<div class="atelier-door locked"><span class="atelier-icon" aria-hidden="true">⚒</span><span><b>L’atelier</b><small>S’ouvre au niveau ${ctx.tuning.atelierLevel}</small></span></div>`;
  }

  function openLetter(chapter: Chapter): void {
    const firstRead = !ctx.player.chaptersRead.includes(chapter.id);
    const overlay = document.createElement('div');
    overlay.className = 'letter-overlay';
    overlay.setAttribute('role', 'dialog');
    overlay.setAttribute('aria-label', chapter.title);
    overlay.innerHTML = `
      <article class="letter">
        <p class="letter-kicker">Lettre ${chapter.number}</p>
        <h2>${chapter.title}</h2>
        ${chapter.paragraphs.map((p) => `<p>${p}</p>`).join('')}
        <p class="letter-signature">Rose</p>
        ${chapter.teaser ? `<p class="letter-teaser">${chapter.teaser}</p>` : ''}
      </article>
      <button type="button" class="levelup-button letter-button">${firstRead ? `Ranger la lettre · +${ctx.tuning.chapterRewardDust} ✦` : 'Fermer'}</button>`;
    for (const type of ['pointerdown', 'pointerup', 'click'] as const) overlay.addEventListener(type, (event) => event.stopPropagation());
    overlay.querySelector('.letter-button')!.addEventListener('click', () => {
      overlay.classList.add('closing');
      window.setTimeout(() => overlay.remove(), 220);
      if (!firstRead) return;
      ctx.setPlayer(readChapter(ctx.player, chapter.id, ctx.tuning));
      track('chapter_read', { chapter: chapter.id });
      art = showcase(ctx);
      appearing = { feature: chapter.restores, start: performance.now() };
      root.scrollTo({ top: 0, behavior: 'smooth' });
      chimeNotes('normal', 2);
      hapticBurst(3, 90);
      renderHeader();
      renderLetters();
      window.setTimeout(() => ctx.showRewards(), APPEAR_MS);
    });
    document.body.append(overlay);
    track('chapter_opened', { chapter: chapter.id, first: firstRead });
  }

  root.addEventListener('click', (event) => {
    if ((event.target as HTMLElement).closest('[data-action="atelier"]')) {
      openAtelier(ctx, () => {
        art = showcase(ctx);
        renderAtelier();
        renderLetters();
        renderHeader();
      });
      return;
    }
    const button = (event.target as HTMLElement).closest<HTMLElement>('[data-chapter]');
    const chapter = CHAPTERS.find((c) => c.id === button?.dataset.chapter);
    if (chapter) openLetter(chapter);
  });

  const observer = new ResizeObserver(resize);
  observer.observe(canvas);
  resize();
  renderHeader();
  renderAtelier();
  renderLetters();
  frame = requestAnimationFrame(loop);
  return () => {
    cancelAnimationFrame(frame);
    observer.disconnect();
    document.querySelectorAll('.letter-overlay, .atelier').forEach((el) => el.remove());
  };
}
