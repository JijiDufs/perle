import { serialLabel } from '../../art/cardStyle';
import { renderStoryImage } from '../../art/storyImage';
import { pearlById } from '../../core/catalog';
import type { PearlCard } from '../../core/player';
import { track } from '../../platform/analytics';
import { prepareShare, shareFile } from '../../platform/share';

/** Bouton « Partager » d'une carte. L'image est préparée dès la création du bouton. */
export function shareButton(card: PearlCard): HTMLButtonElement {
  const pearl = pearlById(card.pearlId);
  const prepared = prepareShare(() => renderStoryImage(card), `perle-${card.pearlId}-${card.serial}.png`);
  const button = document.createElement('button');
  button.className = 'share-button';
  button.type = 'button';
  button.textContent = 'Partager';
  // Le toucher ne doit pas atteindre l'écran derrière (huître suivante, fermeture du zoom).
  for (const type of ['pointerdown', 'pointerup'] as const) button.addEventListener(type, (event) => event.stopPropagation());
  button.addEventListener('click', async (event) => {
    event.stopPropagation();
    const outcome = await shareFile(prepared, `J'ai pêché une ${pearl.name.toLowerCase()} ${pearl.rarity} (${serialLabel(card.serial)}) dans Perle.`);
    track('card_shared', { pearlId: card.pearlId, outcome });
  });
  return button;
}
