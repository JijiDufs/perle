import { serialLabel } from '../../art/cardStyle';
import { renderJewelStoryImage, renderStoryImage } from '../../art/storyImage';
import { pearlById } from '../../core/catalog';
import { jewelRarity, withVariant } from '../../core/jewels';
import type { JewelCard, PearlCard } from '../../core/player';
import { track, type TrackedEvent } from '../../platform/analytics';
import { prepareShare, shareFile } from '../../platform/share';

/** Bouton « Partager ». L'image est préparée dès la création du bouton (exigence iOS, voir platform/share.ts). */
function shareButton(render: () => Promise<Blob>, filename: string, text: string, props: TrackedEvent['props']): HTMLButtonElement {
  const prepared = prepareShare(render, filename);
  const button = document.createElement('button');
  button.className = 'share-button';
  button.type = 'button';
  button.textContent = 'Partager';
  // Le toucher ne doit pas atteindre l'écran derrière (carte suivante, fermeture du zoom).
  for (const type of ['pointerdown', 'pointerup'] as const) button.addEventListener(type, (event) => event.stopPropagation());
  button.addEventListener('click', async (event) => {
    event.stopPropagation();
    const outcome = await shareFile(prepared, text);
    track('card_shared', { ...props, outcome });
  });
  return button;
}

export function pearlShareButton(card: PearlCard): HTMLButtonElement {
  const pearl = pearlById(card.pearlId);
  return shareButton(
    () => renderStoryImage(card),
    `perle-${card.pearlId}-${card.serial}.png`,
    `J'ai pêché une ${pearl.name.toLowerCase()} ${pearl.rarity} (${serialLabel(card.serial)}) dans Perle.`,
    { kind: 'pearl', pearlId: card.pearlId },
  );
}

export function jewelShareButton(card: JewelCard): HTMLButtonElement {
  const rarity = jewelRarity(card.jewel.rarityId);
  const name = withVariant(card.jewel, card.variant).name;
  const perfect = card.variant ? ', variante rare' : card.perfect ? ', éclat parfait' : '';
  return shareButton(
    () => renderJewelStoryImage(card),
    `perle-bijou-${card.jewel.rarityId}-${card.serial}.png`,
    `J'ai trouvé : ${name} ${rarity.rarity}${perfect} (${serialLabel(card.serial)}) dans un écrin Perle.`,
    { kind: 'jewel', jewel: card.jewel.rarityId, perfect: card.perfect, variant: card.variant ?? 'aucune' },
  );
}
