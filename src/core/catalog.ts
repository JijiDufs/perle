// Les perles de La Crique, d'après le cahier des charges §5.
// Probabilités : cahier. Couleurs, tailles, valeurs et textes : repris du prototype Duo
// (docs/reference/prototype-duo.html), provisoires (AGENTS.md §6).

export type PearlId = 'empty' | 'white' | 'rose' | 'baroque' | 'black' | 'golden' | 'giant' | 'cursed';

export interface PearlType {
  id: PearlId;
  name: string;
  /** Symbole de rareté du cahier : —, ◆, ◆◆, ◆◆◆, ★, ★★. */
  rarity: string;
  /** Probabilité de tirage (0…1). La somme fait 1. */
  probability: number;
  /** Couleur de la perle elle-même. */
  color: string;
  /** Couleur de la lumière qui filtre à l'ouverture ; null = huître vide, reste noire. */
  glow: string | null;
  /** Forme : ronde, ou bosselée pour la baroque. */
  shape: 'round' | 'baroque';
  /** Texte d'ambiance de la carte. */
  flavor: string;
  /** Valeur de base, en monnaie fictive, pour une perle de taille moyenne. */
  baseValue: number;
  /** Taille possible en mm [min, max]. */
  sizeMm: readonly [number, number];
  /** Les plus rares tremblent avant même d'être touchées. */
  trembles: boolean;
  /** Compte pour la garantie « perle dorée ou mieux ». */
  goldenOrBetter: boolean;
  /** Ampleur de la mise en scène de la révélation : 0 (courante) à 3 (légendaire). */
  revealTier: RevealTier;
}

export type RevealTier = 0 | 1 | 2 | 3;

export const PEARLS: readonly PearlType[] = [
  { id: 'empty', name: 'Huître vide', rarity: '—', probability: 0.12, color: '#5b6b6b', glow: null, shape: 'round', flavor: 'Rien. Elle te regarde, tu la regardes.', baseValue: 0, sizeMm: [0, 0], trembles: false, goldenOrBetter: false, revealTier: 0 },
  { id: 'white', name: 'Perle blanche', rarity: '◆', probability: 0.4, color: '#F3F0EA', glow: '#fff1d6', shape: 'round', flavor: 'La classique. Ronde, sage, impeccable.', baseValue: 10, sizeMm: [5, 7.5], trembles: false, goldenOrBetter: false, revealTier: 0 },
  { id: 'rose', name: 'Perle rosée', rarity: '◆', probability: 0.22, color: '#F2C4CC', glow: '#ffb3c6', shape: 'round', flavor: "Un reflet rose qu'on ne voit qu'à la bonne lumière.", baseValue: 18, sizeMm: [6, 8.5], trembles: false, goldenOrBetter: false, revealTier: 0 },
  { id: 'baroque', name: 'Perle baroque', rarity: '◆◆', probability: 0.12, color: '#C9C4D8', glow: '#c9bcff', shape: 'baroque', flavor: "Bosselée et unique. Personne n'en a une pareille.", baseValue: 30, sizeMm: [7, 11], trembles: false, goldenOrBetter: false, revealTier: 1 },
  { id: 'black', name: 'Perle noire', rarity: '◆◆◆', probability: 0.08, color: '#33374a', glow: '#7f8cff', shape: 'round', flavor: 'Reflets aubergine et vert paon. Les connaisseurs se taisent.', baseValue: 60, sizeMm: [9, 13], trembles: false, goldenOrBetter: false, revealTier: 2 },
  { id: 'golden', name: 'Perle dorée', rarity: '★', probability: 0.045, color: '#E2B04A', glow: '#ffc845', shape: 'round', flavor: 'Elle chauffe un peu la paume. Sûrement une impression.', baseValue: 120, sizeMm: [10, 14], trembles: true, goldenOrBetter: true, revealTier: 3 },
  { id: 'giant', name: 'Perle géante', rarity: '★★', probability: 0.012, color: '#F6F2FF', glow: '#aef4ff', shape: 'round', flavor: "L'huître n'a pas fermé l'œil depuis des années.", baseValue: 300, sizeMm: [18, 26], trembles: true, goldenOrBetter: true, revealTier: 3 },
  { id: 'cursed', name: 'Perle maudite', rarity: '★★', probability: 0.003, color: '#3a0f2a', glow: '#ff2f72', shape: 'round', flavor: "Elle était là avant l'huître.", baseValue: 666, sizeMm: [13, 13], trembles: true, goldenOrBetter: true, revealTier: 3 },
];

export function pearlById(id: PearlId): PearlType {
  const pearl = PEARLS.find((p) => p.id === id);
  if (!pearl) throw new Error(`Perle inconnue : ${id}`);
  return pearl;
}
