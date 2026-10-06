import { JEWEL_FRAMES, serialLabel } from '../../art/cardStyle';
import { findCanvas } from '../../art/finds';
import { bottleMessage, findAlbum, findById, findRarity, type FindCard } from '../../core/finds';
import type { Tuning } from '../../tuning';

/** Ce que la trouvaille a rapporté en plus, dit simplement (null : rien de plus). */
export function findEffectText(card: FindCard, tuning: Tuning): string | null {
  const effect = findById(card.findId).effect;
  if (effect === 'dust') return `Fondue en ${tuning.findCoinDust} ✦ poussière d’or`;
  if (effect === 'ecrin') return `+${tuning.findKeyEcrins} écrin à ouvrir`;
  return null;
}

/** Carte d'une trouvaille : même cadre que les autres cartes, selon la rareté. */
export function findCardElement(card: FindCard, size: 'large' | 'small', tuning: Tuning): HTMLElement {
  const find = findById(card.findId);
  const frame = JEWEL_FRAMES[find.tier];
  const effect = findEffectText(card, tuning);
  const el = document.createElement('article');
  el.className = `card card-${size} card-find${frame.dark ? ' card-dark' : ''}${find.tier >= 3 ? ' card-holo' : ''}`;
  el.style.setProperty('--frame-a', frame.colors[0]);
  el.style.setProperty('--frame-b', frame.colors[1]);
  el.innerHTML = `
    <header class="card-head">
      <h3 class="card-title"></h3>
      <span class="card-rarity">${findRarity(find)}</span>
    </header>
    <div class="card-art card-art-find"></div>
    <dl class="card-stats">
      <div><dt>Album</dt><dd>${findAlbum(find.album).name.replace(/^Le |^Les /, '')}</dd></div>
      <div><dt>Valeur</dt><dd>${card.value}</dd></div>
      <div><dt>N°</dt><dd>${serialLabel(card.serial)}</dd></div>
    </dl>
    ${size === 'large' ? '<p class="card-flavor"></p>' : ''}
    ${size === 'large' && find.effect === 'message' ? '<blockquote class="card-message"></blockquote>' : ''}
    ${size === 'large' && effect ? `<p class="card-flag card-flag-gold">${effect}</p>` : ''}
  `;
  el.querySelector('.card-title')!.textContent = find.name;
  const flavor = el.querySelector('.card-flavor');
  if (flavor) flavor.textContent = find.flavor;
  const message = el.querySelector('.card-message');
  if (message) message.textContent = `« ${bottleMessage(card.serial)} »`;
  el.querySelector('.card-art')!.append(findCanvas(find, size === 'large' ? 180 : 96, 0.34));
  return el;
}
