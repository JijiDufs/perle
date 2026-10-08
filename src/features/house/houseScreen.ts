// La Maison (cahier §8) : la cabane de grand-mère Rose, qui se restaure lettre après lettre.
import { drawHouse, HOUSE_SKY_TOP } from '../../art/house';
import { craftedType } from '../../core/atelier';
import { jewelCanvas } from '../../art/jewel';
import { pearlCanvas } from '../../art/pearl';
import { pearlById } from '../../core/catalog';
import { traitsOf } from '../../core/pearlTraits';
import { CHAPTERS, houseBrand, houseStage, houseStageName, isChapterUnlocked, NEXT_CHAPTER_LEVEL, readChapter, restoredFeatures, unreadChapters, type Chapter, type HouseFeature } from '../../core/house';
import { jewelRarity, jewelVariant, withVariant } from '../../core/jewels';
import { levelFromXp, rankForLevel, xpToNext } from '../../core/levels';
import { track } from '../../platform/analytics';
import { chimeNotes } from '../../platform/audio';
import { hapticBurst } from '../../platform/haptics';
import { isAtelierUnlocked } from '../../core/atelier';
import { openAtelier } from '../atelier/atelierScreen';
import { craftedJewel } from '../atelier/craftedView';
import type { AppContext } from '../context';

/** Durée de l'éclat quand un élément est restauré (ms). */
const APPEAR_MS = 1600;

interface ShowcasePiece {
  art: HTMLCanvasElement | null;
  title: string;
  detail: string;
}

/** La plus belle pièce du joueur, dessinée pour la vitrine et sa fiche. */
function showcase(ctx: AppContext): ShowcasePiece {
  const crafted = [...ctx.player.craftedCards].sort((a, b) => b.value - a.value)[0];
  const bestJewel = [...ctx.player.jewelCards].sort((a, b) => b.value - a.value)[0];
  if (crafted && (!bestJewel || crafted.value >= bestJewel.value)) {
    return {
      art: jewelCanvas(craftedJewel({ name: crafted.name, type: craftedType(crafted), metal: crafted.metal }, crafted.pearlColors), '#fff1d6', 160),
      title: crafted.name,
      detail: `Création maison · ${'★'.repeat(crafted.stars)}${'☆'.repeat(5 - crafted.stars)}`,
    };
  }
  const jewel = [...ctx.player.jewelCards].sort((a, b) => b.value - a.value)[0];
  if (jewel) {
    const glow = jewel.variant ? jewelVariant(jewel.variant).glow : jewelRarity(jewel.jewel.rarityId).glow;
    const variant = jewel.variant ? ` · ${jewelVariant(jewel.variant).label}` : '';
    return {
      art: jewelCanvas(withVariant(jewel.jewel, jewel.variant), glow, 160),
      title: jewel.jewel.name,
      detail: `${jewelRarity(jewel.jewel.rarityId).label}${variant} · n° ${String(jewel.serial).padStart(4, '0')}`,
    };
  }
  const pearl = [...ctx.player.cards].sort((a, b) => b.value - a.value)[0];
  return pearl
    ? { art: pearlCanvas(pearlById(pearl.pearlId), 160, pearl.cracked, 0.3, traitsOf(pearl)), title: pearlById(pearl.pearlId).name, detail: `Perle n° ${String(pearl.serial).padStart(4, '0')} · ${pearl.sizeMm.toFixed(1)} mm` }
    : { art: null, title: 'Ta première trouvaille', detail: 'Elle attend sa place dans la vitrine.' };
}

export function mountHouseScreen(root: HTMLElement, ctx: AppContext): () => void {
  root.className = 'screen house-screen';
  root.innerHTML = `
    <section class="house-scene">
      <canvas aria-label="La Maison de grand-mère Rose"></canvas>
      <div class="house-title"><p class="house-kicker"></p><h2></h2></div>
    </section>
    <button type="button" class="house-map-entry" data-action="map">
      <span class="house-map-thumbnail" aria-hidden="true"><i></i><b></b><em></em></span>
      <span class="house-map-copy"><small>LE VOYAGE CONTINUE</small><b>La carte des marées</b><span>Trois rivages encore inexplorés</span></span>
      <span class="house-map-open" aria-hidden="true">⌖</span>
    </button>
    <section class="house-return" aria-live="polite"></section>
    <section class="house-atelier"></section>
    <section class="house-showcase" hidden></section>
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
    const level = levelFromXp(ctx.player.reputation, ctx.tuning).level;
    // La scène commence sous le titre : il ne recouvre jamais le toit. Au-dessus, le haut du ciel.
    const title = root.querySelector<HTMLElement>('.house-title')!;
    const top = Math.min(height * 0.4, title.offsetTop + title.offsetHeight + 4);
    c.fillStyle = HOUSE_SKY_TOP;
    c.fillRect(0, 0, width, top + 1);
    c.save();
    c.translate(0, top);
    const scene = { restored: restoredFeatures(ctx.player), brand: houseBrand(level), stage: houseStage(level), showcase: art.art, appearing: appear };
    drawHouse(c, width, height - top, scene, now);
    c.restore();
    frame = requestAnimationFrame(loop);
  }

  function renderHeader(): void {
    const level = levelFromXp(ctx.player.reputation, ctx.tuning).level;
    root.querySelector('.house-kicker')!.textContent = `${rankForLevel(level).title} · niveau ${level}`;
    root.querySelector('.house-title h2')!.textContent = houseStageName(level);
  }

  function renderReturn(): void {
    const target = root.querySelector<HTMLElement>('.house-return')!;
    const level = levelFromXp(ctx.player.reputation, ctx.tuning).level;
    const unread = unreadChapters(ctx.player, ctx.tuning);
    const nextChapter = CHAPTERS.find((chapter) => !ctx.player.chaptersRead.includes(chapter.id));
    const readCount = CHAPTERS.filter((chapter) => ctx.player.chaptersRead.includes(chapter.id)).length;
    if (unread.length > 0) {
      const chapter = unread[0];
      target.innerHTML = `
        <article class="house-goal house-goal-ready">
          <div class="house-goal-copy"><p class="house-section-kicker">${unread.length > 1 ? `${unread.length} LETTRES À LIRE` : 'UNE LETTRE T’ATTEND'}</p>
            <h3>${chapter.title}</h3><p>${chapter.restoresLabel} reprend vie dans la Maison.</p></div>
          <button type="button" class="house-goal-action" data-chapter="${chapter.id}">Lire la lettre <span aria-hidden="true">↗</span></button>
          <small class="house-goal-progress">Carnet de Rose · ${readCount}/${CHAPTERS.length} souvenirs</small>
        </article>`;
      return;
    }

    const targetLevel = nextChapter?.level ?? NEXT_CHAPTER_LEVEL;
    const targetXp = Array.from({ length: Math.max(0, targetLevel - 1) }, (_, index) => xpToNext(index + 1, ctx.tuning)).reduce((sum, xp) => sum + xp, 0);
    const progress = targetXp ? Math.min(100, Math.round((ctx.player.reputation / targetXp) * 100)) : 100;
    const levelsLeft = Math.max(0, targetLevel - level);
    target.innerHTML = `
      <article class="house-goal">
        <div class="house-goal-copy"><p class="house-section-kicker">${nextChapter ? `PROCHAIN SOUVENIR · NIVEAU ${targetLevel}` : `LA SUITE · NIVEAU ${NEXT_CHAPTER_LEVEL}`}</p>
          <h3>${nextChapter?.title ?? 'La suite de l’histoire'}</h3>
          <p>${nextChapter ? `${nextChapter.restoresLabel} attend la prochaine lettre.` : 'Rose a laissé une dernière piste dans le carnet.'}</p></div>
        <div class="house-goal-meter" role="progressbar" aria-label="Progression vers la prochaine lettre" aria-valuemin="0" aria-valuemax="100" aria-valuenow="${progress}"><i style="width:${progress}%"></i></div>
        <small class="house-goal-progress">${levelsLeft ? `${levelsLeft} niveau${levelsLeft > 1 ? 'x' : ''} avant le prochain souvenir` : 'La prochaine lettre est presque là'} · ${readCount}/${CHAPTERS.length} lus</small>
      </article>`;
  }

  function renderShowcase(): void {
    const section = root.querySelector<HTMLElement>('.house-showcase')!;
    if (!restoredFeatures(ctx.player).has('vitrine')) {
      section.hidden = true;
      return;
    }
    section.hidden = false;
    section.innerHTML = `
      <div class="house-showcase-head"><p class="house-section-kicker">VITRINE DE LA MAISON</p><h3>Ta pièce maîtresse</h3>
        <p class="house-showcase-name">${art.title}</p><p>${art.detail}</p></div>
      <div class="house-showcase-piece" aria-label="${art.title}"></div>
      <button type="button" class="house-showcase-link" data-action="collection">Voir dans la collection <span aria-hidden="true">→</span></button>`;
    if (art.art) section.querySelector('.house-showcase-piece')!.append(art.art);
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
      renderReturn();
      renderShowcase();
      renderLetters();
      window.setTimeout(() => ctx.showRewards(), APPEAR_MS);
    });
    document.body.append(overlay);
    track('chapter_opened', { chapter: chapter.id, first: firstRead });
  }

  root.addEventListener('click', (event) => {
    if ((event.target as HTMLElement).closest('[data-action="map"]')) {
      ctx.goTo('map');
      return;
    }
    if ((event.target as HTMLElement).closest('[data-action="collection"]')) {
      track('house_showcase_opened', {});
      ctx.goTo('collection');
      return;
    }
    if ((event.target as HTMLElement).closest('[data-action="atelier"]')) {
      openAtelier(ctx, () => {
        art = showcase(ctx);
        renderShowcase();
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
  renderReturn();
  renderAtelier();
  renderShowcase();
  renderLetters();
  frame = requestAnimationFrame(loop);
  return () => {
    cancelAnimationFrame(frame);
    observer.disconnect();
    document.querySelectorAll('.letter-overlay, .atelier').forEach((el) => el.remove());
  };
}
