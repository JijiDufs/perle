// Les trouvailles (cahier §5) : ce que certaines huîtres cachent à la place d'une perle.
// Humour du quotidien et clins d'œil à la pop culture, sans jamais nommer d'œuvre ni de marque
// (règles de l'App Store). Liste, textes, raretés, valeurs et couleurs : provisoires (AGENTS.md §6).
import type { RevealTier } from './catalog';
import { RARITY_SYMBOLS } from './jewels';
import type { Rng } from './rng';

export type FindAlbumId = 'port' | 'clins' | 'tresors';

/** Ce que la trouvaille fait en plus d'entrer dans la collection. */
export type FindEffect = 'dust' | 'ecrin' | 'message';

export interface FindAlbum {
  id: FindAlbumId;
  name: string;
  description: string;
}

export interface FindType {
  id: string;
  album: FindAlbumId;
  name: string;
  /** 1 (◆) à 5 (★★), comme les perles. */
  tier: number;
  flavor: string;
  /** Valeur en monnaie fictive, à l'échelle des perles. */
  value: number;
  /** Couleur de la lumière qui filtre à l'ouverture. */
  glow: string;
  effect?: FindEffect;
}

export const FIND_ALBUMS: readonly FindAlbum[] = [
  { id: 'port', name: 'Le bric-à-brac du port', description: 'Tout ce que les touristes perdent, la mer le rend un jour.' },
  { id: 'clins', name: 'Clins d’œil', description: 'Des objets qui rappellent quelque chose. Sûrement une coïncidence.' },
  { id: 'tresors', name: 'Trésors engloutis', description: 'Ils servent à quelque chose. Enfin, pour la plupart.' },
];

/**
 * Poids de tirage d'une trouvaille selon sa rareté, entre trouvailles.
 * La part totale des trouvailles parmi les huîtres est dans catalog.ts (FIND_PROBABILITY).
 */
export const FIND_TIER_WEIGHTS: Readonly<Record<number, number>> = { 1: 40, 2: 18, 3: 12, 4: 5, 5: 2 };

export const FINDS: readonly FindType[] = [
  // Le bric-à-brac du port : l'humour du quotidien.
  { id: 'tong', album: 'port', name: 'Tong orpheline', tier: 1, value: 6, glow: '#7fd8ff', flavor: 'La gauche. La droite a refait sa vie au large.' },
  { id: 'ticket', album: 'port', name: 'Ticket de manège', tier: 1, value: 5, glow: '#ffb070', flavor: 'Valable pour un tour. Le manège, lui, a coulé.' },
  { id: 'cadenas', album: 'port', name: 'Cadenas d’amoureux', tier: 1, value: 8, glow: '#ff9fb6', flavor: '« J + M pour toujours ». La clé est quelque part au fond.' },
  { id: 'canard', album: 'port', name: 'Canard de bain', tier: 1, value: 7, glow: '#ffe066', flavor: 'Il a fait le tour du monde. Il ne s’en vante pas.' },
  { id: 'lunettes', album: 'port', name: 'Lunettes en cœur', tier: 2, value: 22, glow: '#ff6fa8', flavor: 'Un seul verre. L’autre a vu trop de soleil.' },
  { id: 'clapet', album: 'port', name: 'Téléphone à clapet', tier: 2, value: 28, glow: '#9fe7c4', flavor: 'Un téléphone qui se plie en deux. Ça ne prendra jamais.' },
  { id: 'dentier', album: 'port', name: 'Dentier', tier: 2, value: 25, glow: '#fff4e0', flavor: 'Il sourit encore. Plus que toi ce matin.' },
  { id: 'usb', album: 'port', name: 'Clé « NE PAS OUVRIR »', tier: 3, value: 70, glow: '#7dffb2', flavor: 'Tu ne l’ouvriras pas. Hein ?' },
  { id: 'nain', album: 'port', name: 'Nain de jardin', tier: 3, value: 85, glow: '#ff6b5e', flavor: 'Il a beaucoup voyagé. Il ne dira pas où.' },

  // Clins d'œil : la pop culture, sans la nommer.
  { id: 'poisson-clown', album: 'clins', name: 'Petit poisson-clown', tier: 1, value: 9, glow: '#ff9a3c', flavor: 'Toute une famille le cherchait. Le voilà.' },
  { id: 'fourchette', album: 'clins', name: 'Fourchette', tier: 1, value: 6, glow: '#c9f0ff', flavor: 'Certaines s’en servent pour se coiffer. Personne ne les contredit.' },
  { id: 'cube', album: 'clins', name: 'Cube à six couleurs', tier: 1, value: 10, glow: '#ffd23f', flavor: 'Une face est presque finie. Presque.' },
  { id: 'jeton', album: 'clins', name: 'Jeton « Continue ? »', tier: 2, value: 30, glow: '#ffd76a', flavor: '10… 9… 8… Insère une huître pour continuer.' },
  { id: 'champignon', album: 'clins', name: 'Champignon à pois', tier: 2, value: 32, glow: '#ff4d4d', flavor: 'Il paraît qu’en manger fait grandir. Ne pas essayer.' },
  { id: 'ballon', album: 'clins', name: 'Ballon avec un visage', tier: 2, value: 35, glow: '#ffe2b8', flavor: 'Il écoute pendant des heures. Il ne répond jamais.' },
  { id: 'chapeau', album: 'clins', name: 'Chapeau de paille', tier: 2, value: 30, glow: '#ffcf6b', flavor: 'Son propriétaire est parti devenir roi de quelque chose.' },
  { id: 'aileron', album: 'clins', name: 'Aileron en caoutchouc', tier: 3, value: 80, glow: '#8fb8d8', flavor: 'Il va falloir un plus gros bateau.' },
  { id: 'cartouche', album: 'clins', name: 'Cartouche de jeu', tier: 3, value: 90, glow: '#b48cff', flavor: 'Souffle dedans. Ça ne sert à rien, mais souffle quand même.' },
  { id: 'boussole', album: 'clins', name: 'Boussole capricieuse', tier: 4, value: 220, glow: '#ffb347', flavor: 'Elle n’indique pas le nord. Elle indique ce que tu veux le plus.' },
  { id: 'anneau', album: 'clins', name: 'Anneau qui murmure', tier: 4, value: 260, glow: '#ffdf6b', flavor: 'Un simple anneau d’or. Tu le reposes. Doucement.' },
  { id: 'coeur-ocean', album: 'clins', name: 'Le grand diamant bleu', tier: 5, value: 950, glow: '#4fa8ff', flavor: 'Une vieille dame l’a jeté par-dessus bord. Personne n’a jamais compris pourquoi.' },

  // Trésors engloutis (cahier §5) : ils servent tout de suite.
  { id: 'piece-or', album: 'tresors', name: 'Pièce d’or engloutie', tier: 2, value: 40, glow: '#ffcb47', effect: 'dust', flavor: 'Frappée pour un roi dont personne ne se souvient. Elle fond très bien.' },
  { id: 'bouteille', album: 'tresors', name: 'Bouteille à la mer', tier: 2, value: 20, glow: '#7fe0a8', effect: 'message', flavor: 'Il y a un message dedans. Évidemment.' },
  { id: 'pierre-brute', album: 'tresors', name: 'Pierre brute', tier: 3, value: 75, glow: '#c07cff', flavor: 'Une gemme, sous la croûte. Il faudra apprendre à la tailler.' },
  { id: 'cle-epave', album: 'tresors', name: 'Clé d’épave', tier: 4, value: 180, glow: '#d9a35b', effect: 'ecrin', flavor: 'Elle ouvrait un coffre. Le coffre t’attend dans l’onglet Écrins.' },
];

/** Les messages des bouteilles à la mer (choisis par le numéro de série de la carte). */
export const BOTTLE_MESSAGES: readonly string[] = [
  'Si tu lis ceci, la poste maritime fonctionne encore.',
  'Liste de courses : pain, beurre, une perle géante.',
  'Je suis sur une île déserte avec un ballon de volley. On s’entend bien.',
  'Ne pas ouvrir la troisième huître en partant de la gauche. Trop tard ?',
  'Ceci n’est pas un message.',
  'Bonne année 1997 à celui qui trouvera cette bouteille !',
  'Si trouvée, merci de la rendre à la mer.',
  'Rose, la perle maudite n’est jamais sortie d’une huître. Elle y est entrée.',
];

export function findById(id: string): FindType {
  const find = FINDS.find((f) => f.id === id);
  if (!find) throw new Error(`Trouvaille inconnue : ${id}`);
  return find;
}

export function findAlbum(id: FindAlbumId): FindAlbum {
  return FIND_ALBUMS.find((a) => a.id === id)!;
}

/** Symbole de rareté affiché (◆ … ★★). */
export const findRarity = (find: FindType): string => RARITY_SYMBOLS[find.tier];

/** Ampleur de la révélation, sur la même échelle que les perles. */
export const findRevealTier = (find: FindType): RevealTier => Math.min(3, find.tier - 1) as RevealTier;

/** Les plus rares tremblent avant même d'être touchées, comme les perles ★. */
export const findTrembles = (find: FindType): boolean => find.tier >= 4;

/** Chance d'une trouvaille parmi toutes les trouvailles (0…1). */
export function findShare(find: FindType): number {
  const total = FINDS.reduce((sum, f) => sum + FIND_TIER_WEIGHTS[f.tier], 0);
  return FIND_TIER_WEIGHTS[find.tier] / total;
}

/** Tire une trouvaille, au prorata des poids de rareté. */
export function rollFind(rng: Rng): FindType {
  let roll = rng();
  for (const find of FINDS) {
    roll -= findShare(find);
    if (roll < 0) return find;
  }
  return FINDS[FINDS.length - 1];
}

export function bottleMessage(serial: number): string {
  return BOTTLE_MESSAGES[serial % BOTTLE_MESSAGES.length];
}

/** Une carte de trouvaille, créée à chaque trouvaille révélée. */
export interface FindCard {
  serial: number;
  findId: string;
  value: number;
  foundAt: number;
}

/** Avancement d'un album : trouvailles différentes trouvées / total. */
export function albumProgress(cards: readonly FindCard[], album: FindAlbumId): [number, number] {
  const inAlbum = FINDS.filter((f) => f.album === album);
  const found = inAlbum.filter((f) => cards.some((c) => c.findId === f.id)).length;
  return [found, inAlbum.length];
}
