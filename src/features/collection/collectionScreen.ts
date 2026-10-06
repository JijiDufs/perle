// Collection : volets Perles, Bijoux, Créations et Trouvailles (ce dernier après la première trouvaille),
// avec encyclopédie (toucher filtre), tri et carte agrandie.
import { jewelCanvas } from '../../art/jewel';
import { pearlCanvas } from '../../art/pearl';
import { PEARLS } from '../../core/catalog';
import { jewelRarityRank, rarityRank, sortCards, sortJewelCards, type CardSort } from '../../core/collection';
import { albumProgress, FIND_ALBUMS, FINDS, findRarity, type FindCard } from '../../core/finds';
import { findCanvas } from '../../art/finds';
import { GEM_CUTS, gemCutsFor, JEWEL_RARITIES, JEWEL_TYPE_LABELS, jewelTypesFor, jewelVariant, withVariant, type JewelRarityId } from '../../core/jewels';
import { MARKS, OVERTONES, overtonesOf, SHAPES, shapesOf, traitsOf, type PearlMark, type PearlTraits } from '../../core/pearlTraits';
import type { PearlId } from '../../core/catalog';
import type { JewelCard, PearlCard } from '../../core/player';
import { track } from '../../platform/analytics';
import type { AppContext } from '../context';
import { jewelCardElement } from '../ecrin/jewelCardView';
import { dustLabel, meltButton, openDustShop } from '../dust/dustShop';
import { expertiseButton } from '../expertise/expertiseButton';
import { craftedShareButton, findShareButton, jewelShareButton, pearlShareButton } from '../share/shareButton';
import { cardElement } from './cardView';
import { findCardElement } from './findCardView';
import { RECIPES, type CraftedCard } from '../../core/atelier';
import { craftedCardElement, craftedJewel } from '../atelier/craftedView';

const SORTS: { id: CardSort; label: string }[] = [
  { id: 'rarity', label: 'Rareté' },
  { id: 'recent', label: 'Récentes' },
  { id: 'value', label: 'Valeur' },
];

type Kind = 'pearls' | 'jewels' | 'crafted' | 'finds';
type AnyCard = PearlCard | JewelCard | CraftedCard | FindCard;

/** « 1 huître ouverte », « 3 huîtres ouvertes ». */
const plural = (n: number, singular: string, pluralForm: string) => `${n} ${n > 1 ? pluralForm : singular}`;

/** Une étagère de la collection : ce qui change entre perles et bijoux. */
interface Shelf<C extends { serial: number }> {
  title: string;
  subtitle: string;
  emptyText: string;
  /** `group` : intertitre (album) affiché avant la première case du groupe. */
  entries: { id: string; name: string; rarity: string; count: number; art: () => HTMLElement; group?: string }[];
  cards: C[];
  entryOf(card: C): string;
  sort(cards: C[], sort: CardSort): C[];
  element(card: C, size: 'large' | 'small'): HTMLElement;
  zoomExtras(card: C, onChanged: () => void): HTMLElement[];
  /** Carnet des variantes d'une case : ce qui a été trouvé (formes, reflets, types, tailles…). */
  variants?(entryId: string): VariantGroup[];
}

interface VariantGroup {
  title: string;
  chips: { label: string; found: boolean; color?: string }[];
}

/** Boutons sous la carte agrandie, sur une ligne. */
function actions(...buttons: (HTMLElement | null)[]): HTMLElement[] {
  const present = buttons.filter((b): b is HTMLElement => b !== null);
  if (!present.length) return [];
  const row = document.createElement('div');
  row.className = 'card-actions';
  row.append(...present);
  return [row];
}

function pearlShelf(ctx: AppContext): Shelf<PearlCard> {
  const cards = ctx.player.cards;
  const findable = PEARLS.filter((p) => p.id !== 'empty').sort((a, b) => rarityRank(a.id) - rarityRank(b.id));
  const countOf = (id: string) => cards.filter((c) => c.pearlId === id).length;
  return {
    title: 'La Crique',
    subtitle: `${findable.filter((p) => countOf(p.id) > 0).length} sur ${findable.length} perles découvertes · ${plural(ctx.player.oystersOpened, 'huître ouverte', 'huîtres ouvertes')}`,
    emptyText: 'Aucune perle pour l’instant. Va ouvrir ta première huître.',
    entries: findable.map((p) => ({ id: p.id, name: p.name, rarity: p.rarity, count: countOf(p.id), art: () => pearlCanvas(p, 52, false, 0.3) })),
    cards,
    entryOf: (card) => card.pearlId,
    sort: sortCards,
    element: (card, size) => cardElement(card.pearlId, card, size),
    zoomExtras: (card, onChanged) => actions(pearlShareButton(card), meltButton(ctx, card, onChanged)),
    variants: (id) => {
      const pearlId = id as Exclude<PearlId, 'empty'>;
      const mine = cards.filter((c) => c.pearlId === id).map(traitsOf).filter((t): t is PearlTraits => t !== null);
      return [
        { title: 'Formes', chips: shapesOf(pearlId).map((shape) => ({ label: SHAPES[shape].label, found: mine.some((t) => t.shape === shape) })) },
        { title: 'Reflets', chips: overtonesOf(pearlId).map((tone) => ({ label: OVERTONES[tone].label, found: mine.some((t) => t.overtone === tone), color: OVERTONES[tone].color })) },
        { title: 'Marques rares', chips: (Object.keys(MARKS) as PearlMark[]).map((mark) => ({ label: MARKS[mark].label, found: mine.some((t) => t.mark === mark) })) },
      ];
    },
  };
}

function jewelShelf(ctx: AppContext, refresh: () => void): Shelf<JewelCard> {
  const cards = ctx.player.jewelCards;
  const rarities = [...JEWEL_RARITIES].sort((a, b) => jewelRarityRank(a.id) - jewelRarityRank(b.id));
  const ofRarity = (id: string) => cards.filter((c) => c.jewel.rarityId === id);
  return {
    title: 'Les bijoux',
    subtitle: `${rarities.filter((j) => ofRarity(j.id).length > 0).length} sur ${rarities.length} raretés découvertes · ${plural(cards.length, 'écrin ouvert', 'écrins ouverts')}${(() => {
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
    zoomExtras: (card, onChanged) => [...actions(expertiseButton(ctx, card, refresh), jewelShareButton(card)), ...actions(meltButton(ctx, card, onChanged))],
    variants: (id) => {
      const mine = ofRarity(id);
      const cuts = gemCutsFor(id as JewelRarityId);
      return [
        { title: 'Types', chips: jewelTypesFor(id as JewelRarityId).map((type) => ({ label: JEWEL_TYPE_LABELS[type], found: mine.some((c) => c.jewel.type === type) })) },
        ...(cuts.length ? [{ title: 'Tailles', chips: cuts.map((cut) => ({ label: GEM_CUTS[cut].label, found: mine.some((c) => c.jewel.cut === cut) })) }] : []),
      ];
    },
  };
}

function craftedShelf(ctx: AppContext): Shelf<CraftedCard> {
  const cards = ctx.player.craftedCards;
  const ofRecipe = (id: string) => cards.filter((c) => c.recipeId === id);
  return {
    title: 'Mes créations',
    subtitle: `${RECIPES.filter((r) => ofRecipe(r.id).length > 0).length} sur ${RECIPES.length} recettes réalisées · ${cards.filter((c) => c.stars >= 5).length} pièce${cards.filter((c) => c.stars >= 5).length > 1 ? 's' : ''} 5 étoiles`,
    emptyText: 'Aucune création pour l’instant. L’atelier s’ouvre dans la Maison, au niveau 5.',
    entries: RECIPES.map((r) => ({
      id: r.id,
      // « Première lueur » plutôt que « Bague « Première lueur » » : la case est petite.
      name: r.name.split('«')[1]?.replace('»', '').trim() ?? r.name,
      rarity: `niv. ${r.level}`,
      count: ofRecipe(r.id).length,
      art: () => {
        const best = [...ofRecipe(r.id)].sort((a, b) => b.stars - a.stars || b.value - a.value)[0];
        return jewelCanvas(craftedJewel(r, best.pearlColors), '#fff1d6', 52);
      },
    })),
    cards,
    entryOf: (card) => card.recipeId,
    sort: (list, sort) =>
      [...list].sort((a, b) =>
        sort === 'recent' ? b.serial - a.serial : sort === 'value' ? b.value - a.value || b.stars - a.stars : b.stars - a.stars || b.value - a.value,
      ),
    element: craftedCardElement,
    zoomExtras: (card) => actions(craftedShareButton(card)),
  };
}

function findShelf(ctx: AppContext): Shelf<FindCard> {
  const cards = ctx.player.findCards ?? [];
  const countOf = (id: string) => cards.filter((c) => c.findId === id).length;
  const complete = FIND_ALBUMS.filter((album) => {
    const [found, total] = albumProgress(cards, album.id);
    return found === total;
  }).length;
  const groupLabel = (albumId: (typeof FIND_ALBUMS)[number]['id']) => {
    const [found, total] = albumProgress(cards, albumId);
    return `${FIND_ALBUMS.find((a) => a.id === albumId)!.name} · ${found}/${total}`;
  };
  const tierOf = (card: FindCard) => FINDS.find((f) => f.id === card.findId)?.tier ?? 0;
  return {
    title: 'Les trouvailles',
    subtitle: `${FINDS.filter((f) => countOf(f.id) > 0).length} sur ${FINDS.length} trouvailles · ${plural(complete, 'album complet', 'albums complets')}`,
    emptyText: 'Aucune trouvaille pour l’instant. Certaines huîtres cachent autre chose qu’une perle…',
    entries: FIND_ALBUMS.flatMap((album) =>
      FINDS.filter((f) => f.album === album.id)
        .sort((a, b) => a.tier - b.tier)
        .map((f) => ({ id: f.id, name: f.name, rarity: findRarity(f), count: countOf(f.id), art: () => findCanvas(f, 52, 0.36), group: groupLabel(album.id) })),
    ),
    cards,
    entryOf: (card) => card.findId,
    sort: (list, sort) =>
      [...list].sort((a, b) => (sort === 'recent' ? b.serial - a.serial : sort === 'value' ? b.value - a.value || b.serial - a.serial : tierOf(b) - tierOf(a) || b.serial - a.serial)),
    element: (card, size) => findCardElement(card, size, ctx.tuning),
    zoomExtras: (card) => actions(findShareButton(card)),
  };
}

export function mountCollectionScreen(root: HTMLElement, ctx: AppContext): () => void {
  root.className = 'screen collection-screen';
  let kind: Kind = 'pearls';
  let filter: string | null = null;
  let closeShop = () => {};
  // Cartes arrivées depuis la dernière visite : marquées « Nouveau » pendant cette visite.
  const seenAtMount = ctx.settings.seenSerial;
  ctx.setSettings({ ...ctx.settings, seenSerial: ctx.player.nextSerial - 1 });
  const isNew = (serial: number) => serial > seenAtMount;

  function mount(): void {
    const shelf = currentShelf();
    const discovered = shelf.entries.filter((entry) => entry.count > 0).length;
    const missing = shelf.entries.length - discovered;
    const percent = shelf.entries.length ? Math.round((discovered / shelf.entries.length) * 100) : 0;
    const collectionTitle = kind === 'pearls' ? 'Carnet de la Crique' : kind === 'jewels' ? 'Galerie des écrins' : kind === 'finds' ? 'Albums des trouvailles' : 'Carnet de l’atelier';
    const returnLabel = kind === 'pearls' || kind === 'finds' ? 'Retourner pêcher' : kind === 'jewels' ? 'Ouvrir un écrin' : 'Revenir à la Maison';
    const hasFinds = (ctx.player.findCards ?? []).length > 0;
    root.innerHTML = `
      <div class="tabs kind-tabs" role="group" aria-label="Type de collection">
        <button data-kind="pearls">Perles</button>
        <button data-kind="jewels">Bijoux</button>
        <button data-kind="crafted">Créations</button>
        ${hasFinds ? '<button data-kind="finds">Trouvailles</button>' : ''}
      </div>
      <header class="collection-header">
        <h2>${shelf.title}</h2>
        <p>${shelf.subtitle}</p>
        <button type="button" class="dust-bar" data-action="dust">
          <span class="dust-amount">${dustLabel(ctx.player.dust)}</span> poussière d’or
          <span class="dust-cta">Fondre · Acheter</span>
        </button>
      </header>
      <section class="collection-journey" aria-label="Progression de la collection">
        <div class="collection-journey-copy"><p class="collection-kicker">${collectionTitle}</p><b>${discovered} <span>/ ${shelf.entries.length}</span></b><small>${missing ? `${missing} découverte${missing > 1 ? 's' : ''} encore cachée${missing > 1 ? 's' : ''}` : 'Collection complète'}</small></div>
        <div class="collection-journey-meter" role="progressbar" aria-label="Pièces de la collection découvertes" aria-valuemin="0" aria-valuemax="${shelf.entries.length}" aria-valuenow="${discovered}"><i style="width:${percent}%"></i></div>
        <button type="button" class="collection-return" data-action="continue-loop">${returnLabel}<span aria-hidden="true">→</span></button>
      </section>
      <div class="collection-section-label"><span>Atlas des découvertes</span><small>Touche une pièce pour filtrer</small></div>
      <section class="encyclopedia" aria-label="Encyclopédie"></section>
      <div class="cards-toolbar">
        <h3 class="section-title">Mes pièces <span class="cards-count"></span></h3>
        <div class="tabs sort-tabs" role="group" aria-label="Trier les cartes">
          ${SORTS.map((s) => `<button data-sort="${s.id}">${s.label}</button>`).join('')}
        </div>
      </div>
      <p class="filter-bar" hidden></p>
      <section class="variant-panel" aria-label="Carnet des variantes" hidden></section>
      <section class="card-grid"></section>
      <div class="zoom-overlay" hidden></div>
    `;
    root.querySelectorAll<HTMLButtonElement>('[data-kind]').forEach((b) => b.classList.toggle('active', b.dataset.kind === kind));
    // Point sur le volet qui contient des nouveautés.
    const freshPearls = ctx.player.cards.some((c) => isNew(c.serial));
    const freshJewels = ctx.player.jewelCards.some((c) => isNew(c.serial));
    root.querySelector('[data-kind="pearls"]')!.classList.toggle('has-new', freshPearls && kind !== 'pearls');
    root.querySelector('[data-kind="jewels"]')!.classList.toggle('has-new', freshJewels && kind !== 'jewels');
    const freshCrafted = ctx.player.craftedCards.some((c) => isNew(c.serial));
    root.querySelector('[data-kind="crafted"]')!.classList.toggle('has-new', freshCrafted && kind !== 'crafted');
    const freshFinds = (ctx.player.findCards ?? []).some((c) => isNew(c.serial));
    root.querySelector('[data-kind="finds"]')?.classList.toggle('has-new', freshFinds && kind !== 'finds');

    // Encyclopédie : une case par rareté, silhouette pour ce qui manque. Toucher filtre les cartes.
    const encyclopedia = root.querySelector<HTMLElement>('.encyclopedia')!;
    let group: string | undefined;
    for (const entry of shelf.entries) {
      if (entry.group && entry.group !== group) {
        group = entry.group;
        const heading = document.createElement('p');
        heading.className = 'encyclo-group';
        heading.textContent = group;
        encyclopedia.append(heading);
      }
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

  function render(shelf: Shelf<AnyCard>): void {
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

    const panel = root.querySelector<HTMLElement>('.variant-panel')!;
    const groups = filter && shelf.variants ? shelf.variants(filter) : [];
    panel.hidden = groups.length === 0;
    panel.innerHTML = groups
      .map((group) => {
        const found = group.chips.filter((chip) => chip.found).length;
        const chips = group.chips
          .map((chip) => `<span class="variant-chip${chip.found ? ' found' : ''}">${chip.color ? `<i style="background:${chip.color}"></i>` : ''}${chip.label}</span>`)
          .join('');
        return `<div class="variant-group"><p><b>${group.title}</b><small>${found}/${group.chips.length}</small></p><div class="variant-chips">${chips}</div></div>`;
      })
      .join('');

    const grid = root.querySelector<HTMLElement>('.card-grid')!;
    if (shelf.cards.length === 0) {
      grid.innerHTML = `<p class="empty-state">${shelf.emptyText}</p>`;
      return;
    }
    grid.replaceChildren(
      ...shown.map((card) => {
        const el = shelf.element(card, 'small');
        el.dataset.serial = String(card.serial);
        if (isNew(card.serial)) el.insertAdjacentHTML('beforeend', '<span class="card-new">Nouveau</span>');
        el.tabIndex = 0;
        el.setAttribute('role', 'button');
        return el;
      }),
    );
  }

  function currentShelf(): Shelf<AnyCard> {
    if (kind === 'pearls') return pearlShelf(ctx) as Shelf<AnyCard>;
    if (kind === 'jewels') return jewelShelf(ctx, () => mount()) as Shelf<AnyCard>;
    if (kind === 'finds') return findShelf(ctx) as Shelf<AnyCard>;
    return craftedShelf(ctx) as Shelf<AnyCard>;
  }

  function openCard(serial: number): void {
    const shelf = currentShelf();
    const card = shelf.cards.find((c) => c.serial === serial);
    if (!card) return;
    const zoom = root.querySelector<HTMLElement>('.zoom-overlay')!;
    zoom.replaceChildren(
      shelf.element(card, 'large'),
      ...shelf.zoomExtras(card, () => {
        zoom.hidden = true;
        mount();
      }),
    );
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
    } else if (target.closest('[data-action="dust"]')) {
      closeShop = openDustShop(document.body, ctx, {
        onChanged: () => mount(),
        onPieceBought: (card, pieceKind) => {
          kind = pieceKind === 'pearl' ? 'pearls' : 'jewels';
          filter = null;
          mount();
          openCard(card.serial);
        },
      });
      return;
    } else if (target.closest('[data-action="continue-loop"]')) {
      const screen = kind === 'pearls' || kind === 'finds' ? 'oyster' : kind === 'jewels' ? 'ecrin' : 'house';
      track('collection_continue_clicked', { kind, screen });
      ctx.goTo(screen);
      return;
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
  return () => {
    closeShop();
    ctx.setSettings({ ...ctx.settings, seenSerial: ctx.player.nextSerial - 1 });
  };
}
