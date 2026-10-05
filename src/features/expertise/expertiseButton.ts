import { canExpertise } from '../../core/expertise';
import type { JewelCard } from '../../core/player';
import type { AppContext } from '../context';
import { openExpertise } from './expertiseOverlay';

/** Bouton « Expertiser à la loupe », ou null si la carte ne peut pas (ou plus) être expertisée. */
export function expertiseButton(ctx: AppContext, card: JewelCard, onDone: (card: JewelCard) => void): HTMLButtonElement | null {
  if (!canExpertise(card)) return null;
  const button = document.createElement('button');
  button.type = 'button';
  button.className = 'share-button expertise-button';
  button.textContent = 'Expertiser à la loupe';
  for (const type of ['pointerdown', 'pointerup'] as const) button.addEventListener(type, (event) => event.stopPropagation());
  button.addEventListener('click', (event) => {
    event.stopPropagation();
    openExpertise(ctx, card, onDone);
  });
  return button;
}
