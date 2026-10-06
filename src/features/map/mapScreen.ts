// Aperçu de la suite du voyage : destinations et trouvailles proposées, sans tirage ni déblocage.
import { atlasFindIllustration } from '../../art/atlasFind';
import { drawWorldMap } from '../../art/worldMap';
import { pearlCanvas } from '../../art/pearl';
import { PEARLS } from '../../core/catalog';
import { houseBrandName } from '../../core/house';
import { levelFromXp } from '../../core/levels';
import { track } from '../../platform/analytics';
import type { AppContext } from '../context';
import { RUMOR_FINDS, type DestinationId, type FindKind, type RumorFind } from './finds';

interface Destination {
  id: DestinationId;
  name: string;
  status: string;
  finds: string;
  description: string;
}

const DESTINATIONS: readonly Destination[] = [
  { id: 'cove', name: 'La Crique', status: 'Ponton ouvert', finds: 'Perle baroque · Perle noire', description: 'Le premier rivage. Une crique familière, pleine de petites choses rejetées par le courant.' },
  { id: 'garden', name: 'Le Jardin d’algues', status: 'À venir', finds: 'Bouton de scaphandre · Perle feuille-de-lune', description: 'Une forêt mouvante où les algues gardent les objets venus de bien plus haut.' },
  { id: 'wreck', name: 'L’Épave des échos', status: 'À venir', finds: 'Jeton « Continue ? » · Coquillage-radio', description: 'Un vieux navire répond encore aux sons. Personne ne sait qui l’écoute.' },
  { id: 'rift', name: 'La Faille d’azur', status: 'À venir', finds: 'Perle comète · Géode-lanterne', description: 'Sous la dernière ligne de lumière, l’eau garde des formes qu’on ne trouve nulle part ailleurs.' },
];

export function mountMapScreen(root: HTMLElement, ctx: AppContext): () => void {
  root.className = 'screen world-map-screen';
  const possiblePearls = PEARLS.filter((pearl) => pearl.id !== 'empty');
  const foundIds = new Set(ctx.player.cards.map((card) => card.pearlId));
  const found = possiblePearls.filter((pearl) => foundIds.has(pearl.id)).length;
  const possible = possiblePearls.length;
  root.innerHTML = `
    <header class="map-heading">
      <button type="button" class="map-back" data-action="house" aria-label="Retour à la Maison"><span aria-hidden="true">‹</span> ${houseBrandName(levelFromXp(ctx.player.reputation, ctx.tuning).level)}</button>
      <p class="map-edition">Le carnet de voyage de Rose</p>
      <h1>La carte des marées</h1>
      <p class="map-deck">La Crique n’est que le premier rivage. Au-delà, l’océan garde ses propres curiosités.</p>
    </header>
    <section class="map-board" aria-label="Carte illustrée des destinations">
      <canvas aria-hidden="true"></canvas>
      <span class="map-cartouche">ARCHIPEL DES OUBLIÉS</span>
      <button type="button" class="map-pin cove active" data-destination="cove" aria-pressed="true"><span>⌁</span><b>La Crique</b></button>
      <button type="button" class="map-pin garden" data-destination="garden" aria-pressed="false"><span>✿</span><b>Jardin d’algues</b></button>
      <button type="button" class="map-pin wreck" data-destination="wreck" aria-pressed="false"><span>⌑</span><b>Épave des échos</b></button>
      <button type="button" class="map-pin rift" data-destination="rift" aria-pressed="false"><span>◌</span><b>Faille d’azur</b></button>
      <span class="map-coord coord-north">NORD · 44° 18′</span>
      <span class="map-coord coord-depth">EAU PROFONDE · −80 m</span>
    </section>
    <section class="map-destination-detail" aria-live="polite">
      <div class="map-detail-top"><span class="map-detail-state"></span><span class="map-detail-progress"></span></div>
      <h2 class="map-detail-title"></h2>
      <p class="map-detail-copy"></p>
      <div class="map-detail-finds"><span>On raconte qu’on y trouve</span><b></b></div>
      <button type="button" class="map-dive" data-action="dive">Retourner pêcher <span aria-hidden="true">↗</span></button>
    </section>
    <section class="atlas-shelf" aria-labelledby="atlas-title">
      <div class="atlas-heading"><div><p>Le carnet de Rose</p><h2 id="atlas-title">L’Atlas des trouvailles</h2></div><span class="atlas-count"></span></div>
      <p class="atlas-intro">Des perles connues aux rumeurs échouées sur les autres rivages.</p>
      <div class="atlas-filters" role="group" aria-label="Filtrer l’Atlas par destination">
        <button type="button" data-atlas-destination="cove" aria-pressed="true">La Crique</button>
        <button type="button" data-atlas-destination="garden" aria-pressed="false">Jardin d’algues</button>
        <button type="button" data-atlas-destination="wreck" aria-pressed="false">Épave des échos</button>
        <button type="button" data-atlas-destination="rift" aria-pressed="false">Faille d’azur</button>
      </div>
      <div class="atlas-grid" aria-live="polite"></div>
    </section>
  `;

  const canvas = root.querySelector('canvas')!;
  const context = canvas.getContext('2d')!;
  const resize = () => {
    const rect = canvas.getBoundingClientRect();
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    canvas.width = Math.round(rect.width * dpr);
    canvas.height = Math.round(rect.height * dpr);
    context.setTransform(dpr, 0, 0, dpr, 0, 0);
    drawWorldMap(context, rect.width, rect.height);
  };

  let selected: DestinationId = 'cove';

  function kindLabel(kind: FindKind): string {
    return kind === 'perle' ? 'PERLE' : kind === 'bijou' ? 'BIJOU' : 'OBJET';
  }

  function rumorCard(find: RumorFind): HTMLElement {
    const card = document.createElement('article');
    card.className = `atlas-find atlas-rumor atlas-${find.kind}`;
    const art = document.createElement('div');
    art.className = 'atlas-find-art';
    art.style.setProperty('--find-color', find.color);
    art.innerHTML = atlasFindIllustration(find);
    const copy = document.createElement('div');
    copy.className = 'atlas-find-copy';
    copy.innerHTML = `<span class="atlas-find-kind">${kindLabel(find.kind)}</span>`;
    const title = document.createElement('h3');
    title.textContent = find.name;
    const note = document.createElement('p');
    note.textContent = find.note;
    const status = document.createElement('small');
    status.className = 'atlas-find-state';
    status.textContent = 'Rumeur';
    copy.append(title, note, status);
    card.append(art, copy);
    return card;
  }

  function pearlCard(pearl: typeof possiblePearls[number]): HTMLElement {
    const count = ctx.player.cards.filter((card) => card.pearlId === pearl.id).length;
    const card = document.createElement('article');
    card.className = `atlas-find atlas-pearl ${count ? 'discovered' : 'unknown'}`;
    const art = document.createElement('div');
    art.className = 'atlas-find-art';
    if (count) art.append(pearlCanvas(pearl, 62, false, 0.33));
    else art.innerHTML = '<span class="atlas-pearl-silhouette" aria-hidden="true"></span>';
    const copy = document.createElement('div');
    copy.className = 'atlas-find-copy';
    copy.innerHTML = '<span class="atlas-find-kind">PERLE</span>';
    const title = document.createElement('h3');
    title.textContent = count ? pearl.name : 'Perle à découvrir';
    const note = document.createElement('p');
    note.textContent = count ? pearl.flavor : `Rareté ${pearl.rarity} · à trouver dans la Crique`;
    const status = document.createElement('small');
    status.className = `atlas-find-state${count ? ' found' : ''}`;
    status.textContent = count ? `Découverte · ×${count}` : 'Encore cachée';
    copy.append(title, note, status);
    card.append(art, copy);
    return card;
  }

  function renderAtlas(): void {
    root.querySelectorAll<HTMLButtonElement>('[data-atlas-destination]').forEach((button) => {
      const active = button.dataset.atlasDestination === selected;
      button.classList.toggle('active', active);
      button.setAttribute('aria-pressed', String(active));
    });
    const grid = root.querySelector<HTMLElement>('.atlas-grid')!;
    if (selected === 'cove') {
      const count = possiblePearls.filter((pearl) => foundIds.has(pearl.id)).length;
      root.querySelector('.atlas-count')!.textContent = `${count} / ${possible} découvertes`;
      grid.replaceChildren(...possiblePearls.map(pearlCard));
    } else {
      const finds = RUMOR_FINDS.filter((find) => find.destination === selected);
      root.querySelector('.atlas-count')!.textContent = `${finds.length} rumeurs`;
      grid.replaceChildren(...finds.map(rumorCard));
    }
  }

  function renderDestination(): void {
    const destination = DESTINATIONS.find((entry) => entry.id === selected)!;
    root.querySelector('.map-detail-state')!.textContent = destination.status;
    root.querySelector('.map-detail-progress')!.textContent = selected === 'cove' ? `${found} / ${possible} perles découvertes` : 'Nouvelle destination';
    root.querySelector('.map-detail-title')!.textContent = destination.name;
    root.querySelector('.map-detail-copy')!.textContent = destination.description;
    // La Crique : seulement les perles déjà trouvées (jamais celles qui restent à découvrir).
    const known = possiblePearls.filter((pearl) => foundIds.has(pearl.id)).reverse().slice(0, 2).map((pearl) => pearl.name);
    root.querySelector('.map-detail-finds b')!.textContent =
      selected === 'cove' ? (known.length ? `${known.join(' · ')}${found < possible ? ' · et d’autres encore cachées' : ''}` : 'Ouvre ta première huître pour le savoir') : destination.finds;
    const dive = root.querySelector<HTMLButtonElement>('.map-dive')!;
    dive.disabled = selected !== 'cove';
    dive.innerHTML = selected === 'cove' ? 'Retourner pêcher <span aria-hidden="true">↗</span>' : 'Destination à venir <span aria-hidden="true">✦</span>';
    root.querySelectorAll<HTMLButtonElement>('[data-destination]').forEach((button) => {
      const active = button.dataset.destination === selected;
      button.classList.toggle('active', active);
      button.setAttribute('aria-pressed', String(active));
    });
    renderAtlas();
  }

  root.addEventListener('click', (event) => {
    const target = event.target as HTMLElement;
    const pin = target.closest<HTMLButtonElement>('[data-destination]');
    if (pin) {
      selected = pin.dataset.destination as DestinationId;
      renderDestination();
      if (selected !== 'cove') track('map_destination_previewed', { destination: selected });
      return;
    }
    const atlasFilter = target.closest<HTMLButtonElement>('[data-atlas-destination]');
    if (atlasFilter) {
      selected = atlasFilter.dataset.atlasDestination as DestinationId;
      renderDestination();
      if (selected !== 'cove') track('map_destination_previewed', { destination: selected });
      return;
    }
    if (target.closest('[data-action="house"]')) {
      ctx.goTo('house');
      return;
    }
    if (target.closest('[data-action="dive"]') && selected === 'cove') ctx.goTo('oyster');
  });

  const observer = new ResizeObserver(resize);
  observer.observe(canvas);
  resize();
  renderDestination();
  track('map_viewed', { discoveredPearls: found });
  return () => observer.disconnect();
}
