import { CARD_FRAMES, serialLabel } from '../../art/cardStyle';
import { pearlCanvas } from '../../art/pearl';
import { pearlById, type PearlId } from '../../core/catalog';
import type { PearlCard } from '../../core/player';

/** Carte à collectionner. `card` null = huître vide. */
export function cardElement(pearlId: PearlId, card: PearlCard | null, size: 'large' | 'small'): HTMLElement {
  const pearl = pearlById(pearlId);
  const frame = CARD_FRAMES[pearlId];
  const holo = pearl.revealTier >= 2 && card !== null && !card.cracked;
  const el = document.createElement('article');
  el.className = `card card-${size}${frame.dark ? ' card-dark' : ''}${holo ? ' card-holo' : ''}`;
  el.style.setProperty('--frame-a', frame.colors[0]);
  el.style.setProperty('--frame-b', frame.colors[1]);

  const stats = card
    ? `<dl class="card-stats">
        <div><dt>Taille</dt><dd>${card.sizeMm.toFixed(1)} mm</dd></div>
        <div><dt>Lustre</dt><dd>${card.lustre}</dd></div>
        <div><dt>Valeur</dt><dd>${card.value}</dd></div>
        <div><dt>N°</dt><dd>${serialLabel(card.serial)}</dd></div>
      </dl>`
    : '';
  el.innerHTML = `
    <header class="card-head">
      <h3 class="card-title">${pearl.name}${card?.cracked ? ' fêlée' : ''}</h3>
      <span class="card-rarity">${pearl.rarity}</span>
    </header>
    <div class="card-art"></div>
    ${stats}
    ${size === 'large' ? `<p class="card-flavor">${pearl.flavor}</p>` : ''}
    ${card?.cracked ? '<p class="card-flag">Fêlée : valeur divisée par deux</p>' : ''}
    ${card?.fromDust && size === 'large' ? '<p class="card-flag card-flag-dust">✦ Obtenue avec la poussière d’or</p>' : ''}
  `;
  const art = el.querySelector('.card-art')!;
  if (card) {
    const px = size === 'large' ? 170 : 96;
    art.append(pearlCanvas(pearl, px, card.cracked, pearlId === 'giant' ? 0.36 : 0.26));
  } else {
    art.innerHTML = '<div class="card-empty-ring"></div>';
  }
  return el;
}
