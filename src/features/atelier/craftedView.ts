import { formatEuros, JEWEL_FRAMES, serialLabel } from '../../art/cardStyle';
import { jewelCanvas } from '../../art/jewel';
import { metalById, RECIPES, type CraftedCard, type Recipe } from '../../core/atelier';
import type { Jewel } from '../../core/jewels';

/** Le bijou à dessiner pour une recette, avec les couleurs des perles utilisées. */
export function craftedJewel(recipe: Pick<Recipe, 'name' | 'type' | 'metal'>, pearlColors: string[]): Jewel {
  const metal = metalById(recipe.metal);
  return {
    rarityId: 'perles',
    type: recipe.type,
    name: recipe.name,
    metal: metal.color,
    metalName: metal.name,
    gem: null,
    candy: false,
    pearls: true,
    carats: 0,
    value: 0,
    flavor: '',
    pearlColors,
  };
}

export const starsLabel = (stars: number) => '★'.repeat(stars) + '☆'.repeat(5 - stars);

const VERDICT_LABEL: Record<CraftedCard['setting'], string> = {
  parfait: 'Sertissage parfait',
  bien: 'Sertissage soigné',
  brusque: 'Sertissage un peu brusque',
  hesitant: 'Sertissage un peu hésitant',
};

export function craftedCardElement(card: CraftedCard, size: 'large' | 'small'): HTMLElement {
  const recipe = RECIPES.find((r) => r.id === card.recipeId);
  const frame = JEWEL_FRAMES[Math.min(JEWEL_FRAMES.length - 1, card.stars)];
  const el = document.createElement('article');
  el.className = `card card-${size}${frame.dark ? ' card-dark' : ''}${card.stars >= 4 ? ' card-holo' : ''}`;
  el.style.setProperty('--frame-a', frame.colors[0]);
  el.style.setProperty('--frame-b', frame.colors[1]);
  el.innerHTML = `
    <header class="card-head">
      <h3 class="card-title">${card.name}</h3>
      <span class="card-rarity card-stars" aria-label="${card.stars} étoiles">${size === 'large' ? starsLabel(card.stars) : `${card.stars}★`}</span>
    </header>
    <div class="card-art card-art-velvet"></div>
    <dl class="card-stats">
      <div><dt>Métal</dt><dd>${metalById(card.metal).name}</dd></div>
      <div><dt>Perles</dt><dd>${card.pearlIds.length}</dd></div>
      <div><dt>Estimation</dt><dd>${formatEuros(card.value)}</dd></div>
      <div><dt>N°</dt><dd>${serialLabel(card.serial)}</dd></div>
    </dl>
    ${size === 'large' && recipe ? `<p class="card-flavor">${recipe.flavor}</p>` : ''}
    <p class="card-flag card-flag-gold">Fait main · ${VERDICT_LABEL[card.setting]}</p>
    ${size === 'large' ? '<p class="card-fine">Estimation fictive</p>' : ''}
  `;
  el.querySelector('.card-art')!.append(jewelCanvas(craftedJewel({ name: card.name, type: card.type, metal: card.metal }, card.pearlColors), '#fff1d6', size === 'large' ? 190 : 100));
  return el;
}
