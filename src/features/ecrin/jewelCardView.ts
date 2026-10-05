import { serialLabel } from '../../art/cardStyle';
import { jewelCanvas } from '../../art/jewel';
import { jewelRarity } from '../../core/jewels';
import type { JewelCard } from '../../core/player';

/** Cadre selon le niveau de rareté du bijou (0 toc … 5 légende), repris du prototype Duo. */
const FRAMES: { colors: [string, string]; dark: boolean }[] = [
  { colors: ['#c9cfcf', '#7d8889'], dark: false },
  { colors: ['#f1edf4', '#bdb5c9'], dark: false },
  { colors: ['#e6defa', '#a698cf'], dark: false },
  { colors: ['#5b5f86', '#1d2033'], dark: true },
  { colors: ['#f7dc8c', '#b07d1c'], dark: false },
  { colors: ['#ffd6f0', '#7fd6ff'], dark: false },
];

const euros = (value: number) =>
  new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'EUR', minimumFractionDigits: value < 10 ? 2 : 0, maximumFractionDigits: value < 10 ? 2 : 0 }).format(value);

export function jewelCardElement(card: JewelCard, size: 'large' | 'small'): HTMLElement {
  const { jewel } = card;
  const rarity = jewelRarity(jewel.rarityId);
  const frame = FRAMES[rarity.tier];
  const el = document.createElement('article');
  el.className = `card card-${size}${frame.dark ? ' card-dark' : ''}${rarity.tier >= 3 || card.perfect ? ' card-holo' : ''}`;
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
      <div><dt>Carats</dt><dd>${jewel.carats ? `${jewel.carats.toFixed(2).replace('.', ',')} ct` : '—'}</dd></div>
      <div><dt>Estimation</dt><dd>${euros(card.value)}</dd></div>
      <div><dt>N°</dt><dd>${serialLabel(card.serial)}</dd></div>
    </dl>
    ${size === 'large' && jewel.flavor ? `<p class="card-flavor">${jewel.flavor}</p>` : ''}
    ${card.perfect ? '<p class="card-flag card-flag-gold">Éclat parfait : valeur ×1,5</p>' : ''}
    ${size === 'large' ? '<p class="card-fine">Estimation fictive</p>' : ''}
  `;
  el.querySelector('.card-art')!.append(jewelCanvas(jewel, rarity.glow, size === 'large' ? 190 : 100));
  return el;
}
