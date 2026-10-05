// Comptoir de la poussière d'or : fondre les doublons, acheter une pièce manquante ou un écrin.
// La vue affiche et transmet ; les règles sont dans core/dust.ts.
import { jewelCanvas } from '../../art/jewel';
import { pearlCanvas } from '../../art/pearl';
import { pearlById } from '../../core/catalog';
import {
  buyEcrin,
  buyPiece,
  canMelt,
  meltCard,
  meltOrdinaryDuplicates,
  meltValueOfCard,
  missingPieces,
  ordinaryDuplicates,
  ordinaryDuplicatesValue,
  piecePrice,
  type Piece,
  type PieceKind,
} from '../../core/dust';
import { jewelOfRarity, jewelRarity } from '../../core/jewels';
import type { JewelCard, PearlCard } from '../../core/player';
import { seededRng } from '../../core/rng';
import { track } from '../../platform/analytics';
import { chimeNotes, ding } from '../../platform/audio';
import { hapticTick } from '../../platform/haptics';
import type { AppContext } from '../context';

/** « 42 ✦ » */
export const dustLabel = (amount: number) => `${amount} ✦`;

const stop = (el: HTMLElement) => {
  for (const type of ['pointerdown', 'pointerup'] as const) el.addEventListener(type, (event) => event.stopPropagation());
};

function pieceName(piece: Piece): { name: string; rarity: string } {
  if (piece.kind === 'pearl') {
    const pearl = pearlById(piece.id);
    return { name: pearl.name, rarity: pearl.rarity };
  }
  const rarity = jewelRarity(piece.id);
  return { name: `Bijou ${rarity.label.toLowerCase()}`, rarity: rarity.rarity };
}

function pieceArt(piece: Piece): HTMLCanvasElement {
  if (piece.kind === 'pearl') return pearlCanvas(pearlById(piece.id), 40, false, 0.3);
  const rarity = jewelRarity(piece.id);
  // Un exemplaire d'illustration, toujours le même (le vrai bijou est tiré à l'achat).
  return jewelCanvas(jewelOfRarity(rarity, seededRng(1)), rarity.glow, 40);
}

/**
 * Bouton « Fondre » d'une carte en double, ou null si c'est le dernier exemplaire.
 * Deux touchers : la fonte est définitive.
 */
export function meltButton(ctx: AppContext, card: PearlCard | JewelCard, onMelted: () => void): HTMLButtonElement | null {
  if (!canMelt(ctx.player, card.serial)) return null;
  const gain = meltValueOfCard(ctx.player, card.serial, ctx.tuning);
  const button = document.createElement('button');
  button.type = 'button';
  button.className = 'share-button melt-button';
  const idle = `Fondre · +${dustLabel(gain)}`;
  button.textContent = idle;
  let armed = false;
  let timer = 0;
  stop(button);
  button.addEventListener('click', (event) => {
    event.stopPropagation();
    if (!armed) {
      armed = true;
      button.classList.add('armed');
      button.textContent = 'Confirmer la fonte';
      timer = window.setTimeout(() => {
        armed = false;
        button.classList.remove('armed');
        button.textContent = idle;
      }, 3000);
      return;
    }
    clearTimeout(timer);
    const kind: PieceKind = 'pearlId' in card ? 'pearl' : 'jewel';
    ctx.setPlayer(meltCard(ctx.player, card.serial, ctx.tuning));
    track('dust_melted', { kind, entry: 'pearlId' in card ? card.pearlId : card.jewel.rarityId, dust: gain, bulk: false });
    hapticTick();
    ding();
    onMelted();
  });
  return button;
}

export interface DustShopCallbacks {
  /** La collection a changé (fonte) : la redessiner. */
  onChanged(): void;
  /** Une pièce vient d'être achetée : la montrer. */
  onPieceBought(card: PearlCard | JewelCard, kind: PieceKind): void;
}

/** Ouvre le comptoir par-dessus l'écran. Renvoie la fonction qui le ferme. */
export function openDustShop(host: HTMLElement, ctx: AppContext, callbacks: DustShopCallbacks): () => void {
  const sheet = document.createElement('div');
  sheet.className = 'dust-sheet';
  sheet.setAttribute('role', 'dialog');
  sheet.setAttribute('aria-label', 'Poussière d’or');
  stop(sheet);
  host.append(sheet);
  let notice = '';
  const close = () => sheet.remove();
  track('dust_shop_viewed', { dust: ctx.player.dust });

  function render(): void {
    const { player, tuning } = ctx;
    const duplicates = ordinaryDuplicates(player).length;
    const duplicatesValue = ordinaryDuplicatesValue(player, tuning);
    const missing = missingPieces(player);
    const scroll = sheet.querySelector('.dust-panel')?.scrollTop ?? 0;
    sheet.innerHTML = `
      <div class="dust-panel">
        <button type="button" class="dust-close" aria-label="Fermer">✕</button>
        <h2>Poussière d’or</h2>
        <p class="dust-balance"><strong>${dustLabel(player.dust)}</strong></p>
        <p class="muted">Fonds tes doublons, puis choisis exactement la pièce qui te manque.</p>
        ${notice ? `<p class="dust-notice" aria-live="polite">${notice}</p>` : ''}

        <h3>Fondre</h3>
        <button type="button" class="dust-action" data-action="melt-all" ${duplicates ? '' : 'disabled'}>
          ${duplicates ? `Fondre ${duplicates} doublon${duplicates > 1 ? 's' : ''} ordinaire${duplicates > 1 ? 's' : ''} · +${dustLabel(duplicatesValue)}` : 'Aucun doublon ordinaire'}
        </button>
        <p class="dust-fine">On garde ton plus bel exemplaire de chaque pièce, et tous les bijoux à éclat parfait, variante ou certificat. Pour fondre une carte précise, touche-la dans ta collection.</p>

        <h3>Acheter</h3>
        <div class="dust-row">
          <span class="dust-row-art dust-row-ecrin" aria-hidden="true"></span>
          <span class="dust-row-name">Écrin Velours<small>Ouvert comme les autres, mêmes probabilités</small></span>
          <button type="button" class="dust-buy" data-action="ecrin" ${player.dust >= tuning.dustEcrinPrice ? '' : 'disabled'}>${dustLabel(tuning.dustEcrinPrice)}</button>
        </div>
        ${missing.length ? '<p class="dust-subtitle">Pièces manquantes</p>' : '<p class="dust-fine">Ta collection est complète : il ne manque aucune pièce.</p>'}
        <div class="dust-missing"></div>
      </div>`;
    // L'animation d'arrivée ne se joue qu'à l'ouverture, pas à chaque mise à jour.
    const panel = sheet.querySelector<HTMLElement>('.dust-panel')!;
    if (sheet.dataset.shown) panel.style.animation = 'none';
    sheet.dataset.shown = 'true';
    panel.scrollTop = scroll;
    const list = sheet.querySelector<HTMLElement>('.dust-missing')!;
    missing.forEach((piece, index) => {
      const { name, rarity } = pieceName(piece);
      const price = piecePrice(piece, tuning);
      const row = document.createElement('div');
      row.className = 'dust-row';
      row.innerHTML = `<span class="dust-row-art"></span><span class="dust-row-name">${name}<small>${rarity} · ${piece.kind === 'pearl' ? 'perle' : 'bijou'}</small></span>
        <button type="button" class="dust-buy" data-piece="${index}" ${player.dust >= price ? '' : 'disabled'}>${dustLabel(price)}</button>`;
      row.querySelector('.dust-row-art')!.append(pieceArt(piece));
      list.append(row);
    });

    sheet.querySelector('.dust-close')!.addEventListener('click', close);
    sheet.querySelector('[data-action="melt-all"]')!.addEventListener('click', () => {
      const count = ordinaryDuplicates(ctx.player).length;
      const gain = ordinaryDuplicatesValue(ctx.player, ctx.tuning);
      ctx.setPlayer(meltOrdinaryDuplicates(ctx.player, ctx.tuning));
      track('dust_melted', { kind: 'lot', entry: 'lot', dust: gain, bulk: true, count });
      hapticTick();
      ding();
      notice = `${count} doublon${count > 1 ? 's' : ''} fondu${count > 1 ? 's' : ''} : +${dustLabel(gain)}`;
      callbacks.onChanged();
      render();
    });
    sheet.querySelector('[data-action="ecrin"]')!.addEventListener('click', () => {
      const after = buyEcrin(ctx.player, ctx.tuning);
      if (!after) return;
      ctx.setPlayer(after);
      track('dust_ecrin_bought', { price: ctx.tuning.dustEcrinPrice });
      hapticTick();
      chimeNotes('normal', 1);
      notice = `Écrin ajouté. <button type="button" class="link" data-action="go-ecrin">L’ouvrir</button>`;
      callbacks.onChanged();
      render();
    });
    sheet.querySelector('[data-action="go-ecrin"]')?.addEventListener('click', () => {
      close();
      ctx.goTo('ecrin');
    });
    sheet.querySelectorAll<HTMLButtonElement>('[data-piece]').forEach((button) =>
      button.addEventListener('click', () => {
        const piece = missing[Number(button.dataset.piece)];
        const bought = buyPiece(ctx.player, piece, ctx.rng, Date.now(), ctx.tuning);
        if (!bought) return;
        ctx.setPlayer(bought.state);
        track('dust_piece_bought', { kind: piece.kind, entry: piece.id, price: piecePrice(piece, ctx.tuning) });
        hapticTick();
        chimeNotes('normal', 1);
        close();
        callbacks.onPieceBought(bought.card, piece.kind);
      }),
    );
  }

  sheet.addEventListener('click', (event) => {
    if (event.target === sheet) close();
    event.stopPropagation();
  });
  render();
  return close;
}
