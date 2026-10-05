// L'Atelier (cahier §6), ouvert depuis la Maison : le carnet de recettes, puis l'établi où l'on sertit en pinçant.
import { drawWorkbench } from '../../art/atelier';
import { formatEuros } from '../../art/cardStyle';
import { drawJewel } from '../../art/jewel';
import { canCraft, craft, isRecipeUnlocked, metalById, pickPearls, RECIPES, type CraftedCard, type Recipe } from '../../core/atelier';
import { pearlById } from '../../core/catalog';
import { SettingEngine, type SettingResult } from '../../core/setting';
import { PinchInput } from '../../input/pinch';
import { track } from '../../platform/analytics';
import { chimeNotes, noise } from '../../platform/audio';
import { hapticBurst, hapticTick } from '../../platform/haptics';
import type { AppContext } from '../context';
import { craftedShareButton } from '../share/shareButton';
import { craftedCardElement, craftedJewel, starsLabel } from './craftedView';

function ingredientText(recipe: Recipe): string {
  if (!recipe.pearl) return `${recipe.count} × perle${recipe.count > 1 ? 's' : ''} au choix`;
  const name = pearlById(recipe.pearl).name.toLowerCase();
  // « perle rosée » → « perles rosées » : chaque mot prend la marque du pluriel.
  return `${recipe.count} × ${recipe.count > 1 ? name.split(' ').map((w) => `${w}s`).join(' ') : name}`;
}

export function openAtelier(ctx: AppContext, onClose: () => void): void {
  const root = document.createElement('div');
  root.className = 'atelier';
  root.setAttribute('role', 'dialog');
  root.setAttribute('aria-label', 'L’atelier');
  document.body.append(root);
  for (const type of ['pointerdown', 'pointerup', 'click'] as const) root.addEventListener(type, (event) => event.stopPropagation());
  track('atelier_opened', {});
  let cleanup = () => {};

  function close(): void {
    cleanup();
    root.remove();
    onClose();
    ctx.showRewards();
  }

  // ---------- Le carnet de recettes ----------
  function showRecipes(): void {
    cleanup();
    cleanup = () => {};
    root.innerHTML = `
      <header class="atelier-head">
        <button type="button" class="dust-close" data-action="close" aria-label="Fermer">✕</button>
        <p class="house-kicker">La Maison Rose</p>
        <h2>L’atelier</h2>
        <p class="muted">Choisis une page du carnet, pose les perles sur l’établi, et sertis. Montures payées en poussière d’or (<b class="gold">${ctx.player.dust} ✦</b>).</p>
      </header>
      <ul class="recipe-list"></ul>`;
    const list = root.querySelector('.recipe-list')!;
    for (const recipe of RECIPES) {
      const li = document.createElement('li');
      const unlocked = isRecipeUnlocked(recipe, ctx.player, ctx.tuning);
      if (!unlocked) {
        li.className = 'recipe locked';
        li.innerHTML = `<span class="recipe-art"></span><span class="recipe-text"><b>Page manquante</b><small>Retrouvée au niveau ${recipe.level}</small></span>`;
        list.append(li);
        continue;
      }
      const pick = pickPearls(ctx.player, recipe);
      const metal = metalById(recipe.metal);
      const have = recipe.count - pick.missing;
      const ok = canCraft(ctx.player, recipe, ctx.tuning);
      li.className = `recipe${ok ? ' ready' : ''}`;
      li.innerHTML = `
        <span class="recipe-art"></span>
        <span class="recipe-text">
          <b>${recipe.name}</b>
          <small class="${pick.missing ? 'short' : ''}">${ingredientText(recipe)} · ${have}/${recipe.count}</small>
          <small class="${ctx.player.dust < metal.price ? 'short' : ''}">Monture ${metal.name.toLowerCase()} · ${metal.price} ✦</small>
          ${ok && pick.lastCopy ? '<small class="warn">Utilise ton dernier exemplaire de cette perle</small>' : ''}
        </span>
        <button type="button" class="dust-buy" data-recipe="${recipe.id}" ${ok ? '' : 'disabled'}>Fabriquer</button>`;
      const colors = pick.cards.length ? pick.cards.map((c) => pearlById(c.pearlId).color) : [recipe.pearl ? pearlById(recipe.pearl).color : '#f2ece4'];
      const art = document.createElement('canvas');
      art.width = art.height = 112;
      art.style.width = art.style.height = '56px';
      const c = art.getContext('2d')!;
      c.translate(56, 56);
      drawJewel(c, 0, recipe.type === 'collier' ? 14 : 0, 0.22, craftedJewel(recipe, colors));
      li.querySelector('.recipe-art')!.append(art);
      list.append(li);
    }
    root.querySelector('[data-action="close"]')!.addEventListener('click', close);
    root.querySelectorAll<HTMLElement>('[data-recipe]').forEach((b) =>
      b.addEventListener('click', () => showBench(RECIPES.find((r) => r.id === b.dataset.recipe)!)),
    );
  }

  // ---------- L'établi ----------
  function showBench(recipe: Recipe): void {
    cleanup();
    const pick = pickPearls(ctx.player, recipe);
    const jewel = craftedJewel(recipe, pick.cards.map((c) => pearlById(c.pearlId).color));
    root.innerHTML = `
      <header class="atelier-head atelier-head-bench">
        <button type="button" class="dust-close" data-action="back" aria-label="Retour au carnet">←</button>
        <p class="house-kicker">L’établi</p>
        <h2>${recipe.name}</h2>
      </header>
      <div class="bench">
        <canvas aria-label="L’établi. Pince deux doigts pour refermer les deux moitiés et sertir le bijou."></canvas>
        <p class="bench-hint">Pince deux doigts pour sertir<small>ni trop vite, ni trop lentement · ou glisse un doigt vers le bas</small></p>
        <div class="bench-gauge"><i></i></div>
      </div>`;
    const canvas = root.querySelector('canvas')!;
    const c = canvas.getContext('2d')!;
    const bench = root.querySelector<HTMLElement>('.bench')!;
    const hint = root.querySelector<HTMLElement>('.bench-hint')!;
    const gauge = root.querySelector<HTMLElement>('.bench-gauge i')!;
    const engine = new SettingEngine(ctx.tuning);
    let doneAt: number | null = null;
    let lastTick = 0;
    let frame = 0;

    const resize = () => {
      const dpr = Math.min(window.devicePixelRatio || 1, 3);
      const { width, height } = canvas.getBoundingClientRect();
      canvas.width = Math.round(width * dpr);
      canvas.height = Math.round(height * dpr);
      c.setTransform(dpr, 0, 0, dpr, 0, 0);
    };
    const loop = (now: number) => {
      const { width, height } = canvas.getBoundingClientRect();
      drawWorkbench(c, width, height, { jewel, closure: engine.closure, doneAt, glow: '#fff1d6' }, now);
      gauge.style.width = `${Math.round(engine.closure * 100)}%`;
      frame = requestAnimationFrame(loop);
    };

    const input = new PinchInput(bench, () => ctx.tuning, {
      onSample(sample) {
        if (engine.done) return;
        const result = engine.push(sample);
        // Un petit tic à chaque quart refermé.
        const quarter = Math.floor(engine.closure * 4);
        if (quarter > lastTick) {
          lastTick = quarter;
          hapticTick();
        }
        if (result) finish(result);
      },
      onRelease() {
        if (engine.done) return;
        if (engine.closure > 0) hint.innerHTML = 'Referme jusqu’au bout, d’un seul geste<small>les deux moitiés doivent se toucher</small>';
        engine.release();
        lastTick = 0;
      },
    });

    function finish(result: SettingResult): void {
      doneAt = performance.now();
      hint.hidden = true;
      noise(0.08, 3200, 0.35);
      hapticBurst(result.verdict === 'parfait' ? 4 : 2, 80);
      const crafted = craft(ctx.player, recipe.id, result, Date.now(), ctx.tuning);
      if (!crafted) return;
      ctx.setPlayer(crafted.state);
      track('crafted', { recipe: recipe.id, stars: crafted.card.stars, verdict: result.verdict, ms: result.durationMs });
      window.setTimeout(() => showResult(crafted.card, result), 900);
    }

    const observer = new ResizeObserver(resize);
    observer.observe(canvas);
    resize();
    frame = requestAnimationFrame(loop);
    cleanup = () => {
      cancelAnimationFrame(frame);
      observer.disconnect();
      input.destroy();
    };
    root.querySelector('[data-action="back"]')!.addEventListener('click', showRecipes);
    track('craft_started', { recipe: recipe.id });
  }

  // ---------- Le résultat ----------
  function showResult(card: CraftedCard, result: SettingResult): void {
    cleanup();
    cleanup = () => {};
    const verdict =
      result.verdict === 'parfait'
        ? 'Sertissage parfait !'
        : result.verdict === 'brusque'
          ? 'Un peu brusque : referme plus doucement.'
          : result.verdict === 'hesitant'
            ? 'Un peu hésitant : referme d’un seul geste.'
            : 'Joli sertissage.';
    root.innerHTML = `
      <div class="atelier-result">
        <p class="levelup-kicker">${verdict}</p>
        <p class="result-stars" aria-label="${card.stars} étoiles">${starsLabel(card.stars)
          .split('')
          .map((star, i) => `<span style="--i:${i}" class="${star === '★' ? 'on' : ''}">${star}</span>`)
          .join('')}</p>
        <div class="result-card"></div>
        <p class="muted">Estimation ${formatEuros(card.value)} · rangé dans ta collection (Créations)</p>
        <div class="card-actions result-actions"></div>
        <button type="button" class="levelup-button" data-action="again">Retour au carnet</button>
      </div>`;
    root.querySelector('.result-card')!.append(craftedCardElement(card, 'large'));
    root.querySelector('.result-actions')!.append(craftedShareButton(card));
    chimeNotes('normal', Math.min(3, card.stars - 1));
    root.querySelector('[data-action="again"]')!.addEventListener('click', showRecipes);
  }

  showRecipes();
}
