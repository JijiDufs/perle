import type { PearlId } from '../core/catalog';

/** Cadre des cartes selon la perle : [haut-gauche, bas-droite], et texte clair (dark) ou foncé. */
export const CARD_FRAMES: Record<PearlId, { colors: [string, string]; dark: boolean }> = {
  empty: { colors: ['#c9cfcf', '#7d8889'], dark: false },
  white: { colors: ['#f1edf4', '#bdb5c9'], dark: false },
  rose: { colors: ['#f1edf4', '#bdb5c9'], dark: false },
  baroque: { colors: ['#e6defa', '#a698cf'], dark: false },
  black: { colors: ['#5b5f86', '#1d2033'], dark: true },
  golden: { colors: ['#f7dc8c', '#b07d1c'], dark: false },
  giant: { colors: ['#ffd6f0', '#7fd6ff'], dark: false },
  cursed: { colors: ['#5a1238', '#12030b'], dark: true },
};

export const SERIF = '"Young Serif", Georgia, serif';
export const SANS = '"Figtree", system-ui, -apple-system, sans-serif';

export function serialLabel(serial: number): string {
  return `#${String(serial).padStart(6, '0')}`;
}
