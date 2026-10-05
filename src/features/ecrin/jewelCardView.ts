import { formatCarats, formatEuros, JEWEL_FRAMES, serialLabel } from '../../art/cardStyle';
import { jewelCanvas } from '../../art/jewel';
import { jewelRarity, jewelVariant, withVariant } from '../../core/jewels';
import type { JewelCard } from '../../core/player';

export function jewelCardElement(card: JewelCard, size: 'large' | 'small'): HTMLElement {
  const variant = card.variant ? jewelVariant(card.variant) : null;
  const jewel = withVariant(card.jewel, card.variant);
  const rarity = jewelRarity(jewel.rarityId);
  const frame = variant?.frame ?? JEWEL_FRAMES[rarity.tier];
  const el = document.createElement('article');
  el.className = `card card-${size}${frame.dark ? ' card-dark' : ''}${rarity.tier >= 3 || card.perfect ? ' card-holo' : ''}${variant ? ' card-variant' : ''}`;
  el.style.setProperty('--frame-a', frame.colors[0]);
  el.style.setProperty('--frame-b', frame.colors[1]);
  el.innerHTML = `
    <header class="card-head">
      <h3 class="card-title">${jewel.name}</h3>
      <span class="card-rarity">${rarity.rarity}</span>
    </header>
    <div class="card-art card-art-velvet"></div>
    <dl class="card-stats">
      <div><dt>Métal</dt><dd>${jewel.metalName}</dd></div>
      <div><dt>Carats</dt><dd>${formatCarats(jewel.carats)}</dd></div>
      <div><dt>Estimation</dt><dd>${formatEuros(card.value)}</dd></div>
      <div><dt>N°</dt><dd>${serialLabel(card.serial)}</dd></div>
    </dl>
    ${size === 'large' && jewel.flavor ? `<p class="card-flavor">${jewel.flavor}</p>` : ''}
    ${variant ? `<p class="card-flag card-flag-gold">Variante rare ${variant.label} : valeur ×2</p>` : card.perfect ? '<p class="card-flag card-flag-gold">Éclat parfait : valeur ×1,5</p>' : ''}
    ${size === 'large' ? '<p class="card-fine">Estimation fictive</p>' : ''}
  `;
  el.querySelector('.card-art')!.append(jewelCanvas(jewel, variant?.glow ?? rarity.glow, size === 'large' ? 190 : 100));
  return el;
}
