// Collection : deux volets, Perles et Bijoux, avec encyclopédie (toucher filtre), tri et carte agrandie.
import { jewelCanvas } from '../../art/jewel';
import { pearlCanvas } from '../../art/pearl';
import { PEARLS } from '../../core/catalog';
import { jewelRarityRank, rarityRank, sortCards, sortJewelCards, type CardSort } from '../../core/collection';
import { JEWEL_RARITIES, jewelVariant, withVariant } from '../../core/jewels';
import type { JewelCard, PearlCard } from '../../core/player';
import { track } from '../../platform/analytics';
import type { AppContext } from '../context';
import { jewelCardElement } from '../ecrin/jewelCardView';
import { jewelShareButton, pearlShareButton } from '../share/shareButton';
import { cardElement } from './cardView';

const SORTS: { id: CardSort; label: string }[] = [
  { id: 'rarity', label: 'Rareté' },
  { id: 'recent', label: 'Récentes' },
  { id: 'value', label: 'Valeur' },
];

type Kind = 'pearls' | 'jewels';

/** Une étagère de la collection : ce qui change entre perles et bijoux. */
interface Shelf<C extends { serial: number }> {
  title: string;
  subtitle: string;
  emptyText: string;
  entries: { id: string; name: string; rarity: string; count: number; art: () => HTMLElement }[];
  cards: C[];
  entryOf(card: C): string;
  sort(cards: C[], sort: CardSort): C[];
  element(card: C, size: 'large' | 'small'): HTMLElement;
  zoomExtras(card: C): HTMLElement[];
}

function pearlShelf(ctx: AppContext): Shelf<PearlCard> {
  const cards = ctx.player.cards;
  const findable = PEARLS.filter((p) => p.id !== 'empty').sort((a, b) => rarityRank(a.id) - rarityRank(b.id));
  const countOf = (id: string) => cards.filter((c) => c.pearlId === id).length;
  return {
    title: 'La Crique',
    subtitle: `${findable.filter((p) => countOf(p.id) > 0).length} sur ${findable.length} perles découvertes · ${ctx.player.oystersOpened} huîtres ouvertes`,
    emptyText: 'Aucune perle pour l’instant. Va ouvrir ta première huître.',
    entries: findable.map((p) => ({ id: p.id, name: p.name, rarity: p.rarity, count: countOf(p.id), art: () => pearlCanvas(p, 52, false, 0.3) })),
    cards,
    entryOf: (card) => card.pearlId,
    sort: sortCards,
    element: (card, size) => cardElement(card.pearlId, card, size),
    zoomExtras: (card) => [pearlShareButton(card)],
  };
}

function jewelShelf(ctx: AppContext): Shelf<JewelCard> {
  const cards = ctx.player.jewelCards;
  const rarities = [...JEWEL_RARITIES].sort((a, b) => jewelRarityRank(a.id) - jewelRarityRank(b.id));
  const ofRarity = (id: string) => cards.filter((c) => c.jewel.rarityId === id);
  return {
    title: 'Les bijoux',
    subtitle: `${rarities.filter((j) => ofRarity(j.id).length > 0).length} sur ${rarities.length} raretés découvertes · ${cards.length} écrins ouverts${(() => {
      const variants = cards.filter((c) => c.variant).length;
      return variants ? ` · ${variants} variante${variants > 1 ? 's' : ''} rare${variants > 1 ? 's' : ''}` : '';
    })()}`,
    emptyText: 'Aucun bijou pour l’instant. Ouvre un écrin dans l’onglet Écrin.',
    entries: rarities.map((j) => ({
      id: j.id,
      name: j.label,
      rarity: j.rarity,
      count: ofRarity(j.id).length,
      // La plus belle pièce obtenue de cette rareté (cahier §10).
      art: () => {
        const best = [...ofRarity(j.id)].sort((a, b) => b.value - a.value)[0];
        return jewelCanvas(withVariant(best.jewel, best.variant), best.variant ? jewelVariant(best.variant).glow : j.glow, 52);
      },
    })),
    cards,
    entryOf: (card) => card.jewel.rarityId,
    sort: sortJewelCards,
    element: jewelCardElement,
    zoomExtras: (card) => [jewelShareButton(card)],
  };
}

export function mountCollectionScreen(root: HTMLElement, ctx: AppContext): () => void {
  root.className = 'screen collection-screen';
  let kind: Kind = 'pearls';
  let filter: string | null = null;

  function mount(): void {
    const shelf = (kind === 'pearls' ? pearlShelf(ctx) : jewelShelf(ctx)) as Shelf<PearlCard | JewelCard>;
    root.innerHTML = `
      <div class="tabs kind-tabs" role="group" aria-label="Type de collection">
        <button data-kind="pearls">Perles</button>
        <button data-kind="jewels">Bijoux</button>
      </div>
      <header class="collection-header">
        <h2>${shelf.title}</h2>
        <p>${shelf.subtitle}</p>
      </header>
      <section class="encyclopedia" aria-label="Encyclopédie"></section>
      <div class="cards-toolbar">
        <h3 class="section-title">Mes cartes <span class="cards-count"></span></h3>
        <div class="tabs sort-tabs" role="group" aria-label="Trier les cartes">
          ${SORTS.map((s) => `<button data-sort="${s.id}">${s.label}</button>`).join('')}
        </div>
      </div>
      <p class="filter-bar" hidden></p>
      <section class="card-grid"></section>
      <div class="zoom-overlay" hidden></div>
    `;
    root.querySelectorAll<HTMLButtonElement>('[data-kind]').forEach((b) => b.classList.toggle('active', b.dataset.kind === kind));

    // Encyclopédie : une case par rareté, silhouette pour ce qui manque. Toucher filtre les cartes.
    const encyclopedia = root.querySelector<HTMLElement>('.encyclopedia')!;
    for (const entry of shelf.entries) {
      const item = document.createElement('button');
      item.className = `encyclo-item${entry.count ? '' : ' missing'}`;
      item.dataset.entry = entry.id;
      item.disabled = entry.count === 0;
      item.append(entry.count ? entry.art() : Object.assign(document.createElement('div'), { className: 'encyclo-silhouette' }));
      item.insertAdjacentHTML('beforeend', `<div class="encyclo-name">${entry.count ? entry.name : '???'}</div><div class="encyclo-count">${entry.count ? `×${entry.count}` : entry.rarity}</div>`);
      encyclopedia.append(item);
    }
    render(shelf);
  }

  function render(shelf: Shelf<PearlCard | JewelCard>): void {
    const sort = ctx.settings.collectionSort;
    root.querySelectorAll<HTMLButtonElement>('[data-sort]').forEach((b) => {
      b.classList.toggle('active', b.dataset.sort === sort);
      b.setAttribute('aria-pressed', String(b.dataset.sort === sort));
    });
    root.querySelectorAll<HTMLButtonElement>('.encyclo-item').forEach((b) => b.classList.toggle('selected', b.dataset.entry === filter));

    const filtered = filter ? shelf.cards.filter((c) => shelf.entryOf(c) === filter) : shelf.cards;
    const shown = shelf.sort(filtered, sort);
    root.querySelector('.cards-count')!.textContent = filter ? `${shown.length} sur ${shelf.cards.length}` : String(shelf.cards.length);
    const filterBar = root.querySelector<HTMLElement>('.filter-bar')!;
    filterBar.hidden = !filter;
    if (filter) {
      const name = shelf.entries.find((e) => e.id === filter)?.name ?? '';
      filterBar.innerHTML = `${name} seulement · <button class="link" data-action="clear-filter">Tout afficher</button>`;
    }

    const grid = root.querySelector<HTMLElement>('.card-grid')!;
    if (shelf.cards.length === 0) {
      grid.innerHTML = `<p class="empty-state">${shelf.emptyText}</p>`;
      return;
    }
    grid.replaceChildren(
      ...shown.map((card) => {
        const el = shelf.element(card, 'small');
        el.dataset.serial = String(card.serial);
        el.tabIndex = 0;
        el.setAttribute('role', 'button');
        return el;
      }),
    );
  }

  const currentShelf = () => (kind === 'pearls' ? pearlShelf(ctx) : jewelShelf(ctx)) as Shelf<PearlCard | JewelCard>;

  function openCard(serial: number): void {
    const shelf = currentShelf();
    const card = shelf.cards.find((c) => c.serial === serial);
    if (!card) return;
    const zoom = root.querySelector<HTMLElement>('.zoom-overlay')!;
    zoom.replaceChildren(shelf.element(card, 'large'), ...shelf.zoomExtras(card));
    zoom.insertAdjacentHTML('beforeend', '<p class="tap-hint">Touche pour fermer</p>');
    zoom.hidden = false;
    track('card_zoomed', { kind, entry: shelf.entryOf(card) });
  }

  root.addEventListener('click', (event) => {
    const target = event.target as HTMLElement;
    const zoom = root.querySelector<HTMLElement>('.zoom-overlay')!;
    if (!zoom.hidden) {
      zoom.hidden = true;
      return;
    }
    const kindButton = target.closest<HTMLElement>('[data-kind]');
    const sortButton = target.closest<HTMLElement>('[data-sort]');
    const entryButton = target.closest<HTMLElement>('.encyclo-item');
    const cardEl = target.closest<HTMLElement>('.card[data-serial]');
    if (kindButton) {
      kind = kindButton.dataset.kind as Kind;
      filter = null;
      mount();
      return;
    }
    if (sortButton) {
      ctx.setSettings({ ...ctx.settings, collectionSort: sortButton.dataset.sort as CardSort });
      track('collection_sorted', { kind, sort: sortButton.dataset.sort! });
    } else if (entryButton) {
      const id = entryButton.dataset.entry!;
      filter = filter === id ? null : id;
      if (filter) track('collection_filtered', { kind, entry: filter });
    } else if (target.closest('[data-action="clear-filter"]')) {
      filter = null;
    } else if (cardEl) {
      openCard(Number(cardEl.dataset.serial));
      return;
    } else {
      return;
    }
    render(currentShelf());
  });
  root.addEventListener('keydown', (event) => {
    const cardEl = (event.target as HTMLElement).closest<HTMLElement>('.card[data-serial]');
    if (cardEl && (event.key === 'Enter' || event.key === ' ')) {
      event.preventDefault();
      openCard(Number(cardEl.dataset.serial));
    } else if (event.key === 'Escape') {
      root.querySelector<HTMLElement>('.zoom-overlay')!.hidden = true;
    }
  });

  mount();
  return () => {};
}
