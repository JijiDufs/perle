// Aperçu de la suite du voyage : destinations et trouvailles proposées, sans tirage ni déblocage.
import { drawWorldMap } from '../../art/worldMap';
import { PEARLS } from '../../core/catalog';
import { track } from '../../platform/analytics';
import type { AppContext } from '../context';

type DestinationId = 'cove' | 'garden' | 'wreck' | 'rift';

interface Destination {
  id: DestinationId;
  name: string;
  status: string;
  finds: string;
  description: string;
}

const DESTINATIONS: readonly Destination[] = [
  { id: 'cove', name: 'La Crique', status: 'Ponton ouvert', finds: 'Perle baroque · Verre de marée', description: 'Le premier rivage. Une crique familière, pleine de petites choses rejetées par le courant.' },
  { id: 'garden', name: 'Le Jardin d’algues', status: 'À venir', finds: 'Bouton de scaphandre · Perle feuille-de-lune', description: 'Une forêt mouvante où les algues gardent les objets venus de bien plus haut.' },
  { id: 'wreck', name: 'L’Épave des échos', status: 'À venir', finds: 'Jeton « Continue ? » · Coquillage-radio', description: 'Un vieux navire répond encore aux sons. Personne ne sait qui l’écoute.' },
  { id: 'rift', name: 'La Faille d’azur', status: 'À venir', finds: 'Perle comète · Galet de verre bleu', description: 'Sous la dernière ligne de lumière, l’eau garde des formes qu’on ne trouve nulle part ailleurs.' },
];

const CURIOSITIES = [
  { id: 'radio', name: 'Le coquillage-radio', note: 'Une seule station. Elle annonce la marée depuis 1978.', place: 'Épave des échos' },
  { id: 'token', name: 'Le jeton « Continue ? »', note: 'La partie est finie depuis longtemps. Le compteur, lui, tourne encore.', place: 'Épave des échos' },
  { id: 'button', name: 'Le bouton de scaphandre', note: 'Trop petit pour une combinaison normale. Beaucoup trop lourd pour un jouet.', place: 'Jardin d’algues' },
] as const;

function curiosityGlyph(id: typeof CURIOSITIES[number]['id']): string {
  if (id === 'radio') return `<svg viewBox="0 0 64 64" aria-hidden="true"><path d="M11 38c3-17 17-28 30-24 8 2 14 11 13 21-1 12-12 19-25 18-11-1-20-6-18-15Z" fill="#b5d5c6" stroke="#e4d0a1" stroke-width="2"/><path d="M17 37c6-9 23-14 34-5M19 43c9-7 22-9 30-4" fill="none" stroke="#588f86" stroke-width="2"/><path d="M29 28c-3 8-3 17 0 25M38 26c-2 9-2 18 1 26" fill="none" stroke="#e9f0dc" stroke-width="1.5"/><path d="M47 16c6-5 10-5 14-4m-11 10c5-2 8-2 11 0" fill="none" stroke="#f0ce82" stroke-linecap="round" stroke-width="2"/></svg>`;
  if (id === 'token') return `<svg viewBox="0 0 64 64" aria-hidden="true"><circle cx="32" cy="33" r="24" fill="#9d7541" stroke="#f3d78f" stroke-width="3"/><circle cx="32" cy="33" r="18" fill="none" stroke="#d8b66e" stroke-width="1.5" stroke-dasharray="2 2"/><path d="m32 17 4.7 10.1L48 29l-8 7.8 1.9 11.3L32 42.8l-9.9 5.3L24 36.8 16 29l11.3-1.9L32 17Z" fill="#f1dea6"/><path d="M24 33h16" stroke="#79572f" stroke-width="1.5"/></svg>`;
  return `<svg viewBox="0 0 64 64" aria-hidden="true"><circle cx="32" cy="34" r="23" fill="#bf9c60" stroke="#f2daa0" stroke-width="3"/><circle cx="32" cy="34" r="17" fill="#365b63" stroke="#c9b072" stroke-width="2"/><path d="M32 16v8m0 21v8M14 34h8m20 0h8" stroke="#eed394" stroke-width="2"/><circle cx="32" cy="34" r="5" fill="#f0dba4"/><path d="M32 2v10m-4-6 4-4 4 4" fill="none" stroke="#8ccabd" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"/></svg>`;
}

export function mountMapScreen(root: HTMLElement, ctx: AppContext): () => void {
  root.className = 'screen world-map-screen';
  const possiblePearls = PEARLS.filter((pearl) => pearl.id !== 'empty');
  const foundIds = new Set(ctx.player.cards.map((card) => card.pearlId));
  const found = possiblePearls.filter((pearl) => foundIds.has(pearl.id)).length;
  const possible = possiblePearls.length;
  root.innerHTML = `
    <header class="map-heading">
      <button type="button" class="map-back" data-action="house" aria-label="Retour à la Maison"><span aria-hidden="true">‹</span> Maison Rose</button>
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
    <section class="curiosity-shelf" aria-labelledby="curiosity-title">
      <div class="curiosity-heading"><div><p>Quelques rumeurs</p><h2 id="curiosity-title">Le cabinet des curiosités</h2></div><span>3 objets aperçus</span></div>
      <div class="curiosity-list">${CURIOSITIES.map((item) => `
        <article class="curiosity-item curiosity-${item.id}">
          <div class="curiosity-art">${curiosityGlyph(item.id)}</div>
          <div class="curiosity-copy"><h3>${item.name}</h3><p>${item.note}</p><small>${item.place}</small></div>
        </article>`).join('')}
      </div>
      <p class="map-concept-note">Pistes pour la suite · Ces objets et destinations sont un aperçu du monde à construire.</p>
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
  function renderDestination(): void {
    const destination = DESTINATIONS.find((entry) => entry.id === selected)!;
    root.querySelector('.map-detail-state')!.textContent = destination.status;
    root.querySelector('.map-detail-progress')!.textContent = selected === 'cove' ? `${found} / ${possible} perles découvertes` : 'Nouvelle destination';
    root.querySelector('.map-detail-title')!.textContent = destination.name;
    root.querySelector('.map-detail-copy')!.textContent = destination.description;
    root.querySelector('.map-detail-finds b')!.textContent = destination.finds;
    const dive = root.querySelector<HTMLButtonElement>('.map-dive')!;
    dive.disabled = selected !== 'cove';
    dive.innerHTML = selected === 'cove' ? 'Retourner pêcher <span aria-hidden="true">↗</span>' : 'Destination à venir <span aria-hidden="true">✦</span>';
    root.querySelectorAll<HTMLButtonElement>('[data-destination]').forEach((button) => {
      const active = button.dataset.destination === selected;
      button.classList.toggle('active', active);
      button.setAttribute('aria-pressed', String(active));
    });
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
