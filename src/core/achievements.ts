// Succès et titres (cahier §10). Une première série ; le cahier en vise environ 150, dont des secrets.
// Textes et paliers : provisoires (AGENTS.md §6). Récompenses : src/tuning.ts.
import type { Tuning } from '../tuning';
import { PEARLS } from './catalog';
import { albumProgress, type FindAlbumId } from './finds';
import { GEM_CUTS, JEWEL_RARITIES, MAIN_JEWEL_TYPES, type GemCut } from './jewels';
import { SHAPES, traitsOf, type PearlShape, type PearlTraits } from './pearlTraits';
import type { PlayerState } from './player';

export type AchievementTier = 'bronze' | 'argent' | 'or';

export interface Achievement {
  id: string;
  name: string;
  description: string;
  tier: AchievementTier;
  /** Caché tant qu'il n'est pas obtenu. */
  secret?: boolean;
  /** Titre que l'on peut porter une fois le succès obtenu. */
  title?: string;
  /** Album de trouvailles complété : donne aussi un écrin (cahier §10). */
  album?: boolean;
  /** Avancement [fait, objectif]. */
  progress(state: PlayerState): [number, number];
}

const has = (state: PlayerState, pearlId: string) => (state.cards.some((c) => c.pearlId === pearlId) ? 1 : 0);
const hasJewel = (state: PlayerState, rarityId: string) => (state.jewelCards.some((c) => c.jewel.rarityId === rarityId) ? 1 : 0);
const count = (n: number, goal: number): [number, number] => [Math.min(n, goal), goal];
const pearlTraits = (state: PlayerState): PearlTraits[] => state.cards.map(traitsOf).filter((t): t is PearlTraits => t !== null);
const hasFind = (state: PlayerState, findId: string) => ((state.findCards ?? []).some((c) => c.findId === findId) ? 1 : 0);
const album = (state: PlayerState, id: FindAlbumId): [number, number] => albumProgress(state.findCards ?? [], id);

export const ACHIEVEMENTS: readonly Achievement[] = [
  // La pêche
  { id: 'premiere-perle', name: 'Première perle', description: 'Trouver ta première perle.', tier: 'bronze', progress: (s) => count(s.cards.length > 0 ? 1 : 0, 1) },
  { id: 'dix-huitres', name: 'Les mains dans l’eau', description: 'Ouvrir 10 huîtres.', tier: 'bronze', progress: (s) => count(s.oystersOpened, 10) },
  { id: 'cent-huitres', name: 'Pêcheur assidu', description: 'Ouvrir 100 huîtres.', tier: 'argent', title: 'Pêcheur assidu', progress: (s) => count(s.oystersOpened, 100) },
  { id: 'cinq-cents-huitres', name: 'Loup de mer', description: 'Ouvrir 500 huîtres.', tier: 'or', title: 'Loup de mer', progress: (s) => count(s.oystersOpened, 500) },
  { id: 'huitres-vides', name: 'Patience', description: 'Tomber sur 5 huîtres vides.', tier: 'bronze', progress: (s) => count(s.stats.emptyOysters, 5) },
  { id: 'perle-noire', name: 'Les connaisseurs se taisent', description: 'Trouver une perle noire.', tier: 'bronze', progress: (s) => count(has(s, 'black'), 1) },
  { id: 'perle-doree', name: 'De l’or dans la paume', description: 'Trouver une perle dorée.', tier: 'argent', progress: (s) => count(has(s, 'golden'), 1) },
  { id: 'perle-geante', name: 'Trop grande pour la main', description: 'Trouver une perle géante.', tier: 'or', title: 'Chasseur de géantes', progress: (s) => count(has(s, 'giant'), 1) },
  { id: 'perle-maudite', name: 'Ce qui dormait', description: 'Trouver la perle maudite.', tier: 'or', secret: true, title: 'Porteur de la maudite', progress: (s) => count(has(s, 'cursed'), 1) },
  {
    id: 'crique-complete',
    name: 'La Crique n’a plus de secrets',
    description: 'Trouver toutes les perles de La Crique.',
    tier: 'or',
    title: 'Gardien de la Crique',
    progress: (s) => {
      const findable = PEARLS.filter((p) => p.id !== 'empty');
      return count(findable.filter((p) => has(s, p.id)).length, findable.length);
    },
  },
  // Les trouvailles
  { id: 'premiere-trouvaille', name: 'Ce n’est pas une perle', description: 'Trouver ta première trouvaille.', tier: 'bronze', progress: (s) => count((s.findCards ?? []).length > 0 ? 1 : 0, 1) },
  { id: 'album-port', name: 'Brocante des marées', description: 'Compléter l’album « Le bric-à-brac du port ».', tier: 'argent', album: true, title: 'Brocanteur des marées', progress: (s) => album(s, 'port') },
  { id: 'album-clins', name: 'Ça me rappelle quelque chose', description: 'Compléter l’album « Clins d’œil ».', tier: 'or', album: true, title: 'Cinéphile des abysses', progress: (s) => album(s, 'clins') },
  { id: 'album-tresors', name: 'Chasseur d’épaves', description: 'Compléter l’album « Trésors engloutis ».', tier: 'or', album: true, title: 'Chasseur d’épaves', progress: (s) => album(s, 'tresors') },
  { id: 'grand-bateau', name: 'Il était une fois un grand bateau', description: 'Trouver le grand diamant bleu.', tier: 'or', secret: true, progress: (s) => count(hasFind(s, 'coeur-ocean'), 1) },
  // Les perles uniques
  { id: 'perle-jumelle', name: 'Deux pour le prix d’une', description: 'Trouver une perle jumelle.', tier: 'argent', progress: (s) => count(pearlTraits(s).some((t) => t.mark === 'jumelle') ? 1 : 0, 1) },
  { id: 'perle-coeur', name: 'Coup de cœur', description: 'Trouver une perle en cœur.', tier: 'or', title: 'Cœur de nacre', progress: (s) => count(pearlTraits(s).some((t) => t.mark === 'coeur') ? 1 : 0, 1) },
  { id: 'arc-en-ciel', name: 'Toutes les couleurs', description: 'Trouver une perle au reflet arc-en-ciel.', tier: 'argent', progress: (s) => count(pearlTraits(s).some((t) => t.overtone === 'arc-en-ciel') ? 1 : 0, 1) },
  {
    id: 'six-formes',
    name: 'Six formes',
    description: 'Trouver une perle de chaque forme.',
    tier: 'argent',
    progress: (s) => {
      const shapes = Object.keys(SHAPES) as PearlShape[];
      return count(shapes.filter((shape) => pearlTraits(s).some((t) => t.shape === shape)).length, shapes.length);
    },
  },
  // Le geste
  { id: 'lustre-s', name: 'Geste parfait', description: 'Obtenir un lustre S.', tier: 'bronze', progress: (s) => count(s.stats.lustreS, 1) },
  { id: 'lustre-s-10', name: 'Virtuose', description: 'Obtenir 10 lustres S.', tier: 'argent', title: 'Virtuose', progress: (s) => count(s.stats.lustreS, 10) },
  { id: 'sans-felure-10', name: 'Main de velours', description: 'Ouvrir 10 huîtres d’affilée sans fêlure.', tier: 'argent', title: 'Main de velours', progress: (s) => count(s.stats.bestCrackFreeStreak, 10) },
  { id: 'sans-felure-50', name: 'Main de chirurgien', description: 'Ouvrir 50 huîtres d’affilée sans fêlure.', tier: 'or', title: 'Main de chirurgien', progress: (s) => count(s.stats.bestCrackFreeStreak, 50) },
  // Les écrins
  { id: 'premier-bijou', name: 'Premier bijou', description: 'Ouvrir ton premier écrin.', tier: 'bronze', progress: (s) => count(s.jewelCards.length > 0 ? 1 : 0, 1) },
  { id: 'toc', name: 'Ça valait deux tickets', description: 'Trouver un bijou en toc.', tier: 'bronze', progress: (s) => count(hasJewel(s, 'toc'), 1) },
  { id: 'eclat-parfait', name: 'Œil de lynx', description: 'Réussir un éclat parfait.', tier: 'bronze', progress: (s) => count(s.stats.perfectGlints, 1) },
  { id: 'eclat-parfait-10', name: 'Regard de joaillier', description: 'Réussir 10 éclats parfaits.', tier: 'argent', title: 'Œil de lynx', progress: (s) => count(s.stats.perfectGlints, 10) },
  { id: 'variante', name: 'Une lumière rare', description: 'Révéler une variante rare.', tier: 'argent', progress: (s) => count(s.stats.variants, 1) },
  { id: 'diamant', name: 'Pour toujours', description: 'Trouver un bijou en diamant.', tier: 'argent', progress: (s) => count(hasJewel(s, 'diamant'), 1) },
  { id: 'legende', name: 'Venu des Abysses', description: 'Trouver le bijou légendaire.', tier: 'or', secret: true, title: 'Légende des Abysses', progress: (s) => count(hasJewel(s, 'legende'), 1) },
  {
    id: 'ecrin-complet',
    name: 'Écrin complet',
    description: 'Posséder un bijou de chaque rareté.',
    tier: 'or',
    title: 'Grand collectionneur',
    progress: (s) => count(JEWEL_RARITIES.filter((j) => hasJewel(s, j.id)).length, JEWEL_RARITIES.length),
  },
  {
    id: 'types-bijoux',
    name: 'Écrin bien rangé',
    description: 'Posséder une bague, un collier, un bracelet, des boucles, un pendentif et une broche.',
    tier: 'argent',
    progress: (s) => count(MAIN_JEWEL_TYPES.filter((type) => s.jewelCards.some((c) => c.jewel.type === type)).length, MAIN_JEWEL_TYPES.length),
  },
  {
    id: 'huit-tailles',
    name: 'Huit tailles',
    description: 'Posséder une pierre de chaque taille.',
    tier: 'or',
    title: 'Lapidaire',
    progress: (s) => {
      const cuts = Object.keys(GEM_CUTS) as GemCut[];
      return count(cuts.filter((cut) => s.jewelCards.some((c) => c.jewel.cut === cut)).length, cuts.length);
    },
  },
  // L'atelier
  { id: 'fait-main', name: 'Fait main', description: 'Fabriquer ton premier bijou à l’atelier.', tier: 'bronze', progress: (s) => count(s.stats.crafted ?? 0, 1) },
  { id: 'sertissage-parfait', name: 'Doigts de fée', description: 'Réussir un sertissage parfait.', tier: 'argent', progress: (s) => count(s.stats.perfectSettings ?? 0, 1) },
  { id: 'cinq-etoiles', name: 'Pièce de maître', description: 'Créer un bijou 5 étoiles.', tier: 'or', title: 'Maître sertisseur', progress: (s) => count(s.stats.fiveStars ?? 0, 1) },
  { id: 'rivage', name: 'La recette de toujours', description: 'Fabriquer le collier « Rivage ».', tier: 'argent', progress: (s) => count((s.craftedCards ?? []).some((c) => c.recipeId === 'rivage') ? 1 : 0, 1) },
  // La fidélité
  { id: 'serie-7', name: 'Fidèle au ponton', description: 'Venir 7 jours d’affilée.', tier: 'argent', title: 'Habitué du port', progress: (s) => count(s.login.bestStreak, 7) },
  { id: 'serie-30', name: 'La marée et moi', description: 'Venir 30 jours d’affilée.', tier: 'or', title: 'Enfant des marées', progress: (s) => count(s.login.bestStreak, 30) },
  // L'expertise et la poussière d'or
  { id: 'expert', name: 'Expert', description: 'Obtenir un certificat Excellent.', tier: 'argent', title: 'Expert', progress: (s) => count(s.stats.excellentCertificates, 1) },
  { id: 'alchimiste', name: 'Alchimiste', description: 'Fondre 20 doublons en poussière d’or.', tier: 'argent', title: 'Alchimiste', progress: (s) => count(s.stats.melted, 20) },
];

export function achievementById(id: string): Achievement | undefined {
  return ACHIEVEMENTS.find((a) => a.id === id);
}

export function isDone(achievement: Achievement, state: PlayerState): boolean {
  const [done, goal] = achievement.progress(state);
  return done >= goal;
}

export function achievementReward(achievement: Pick<Achievement, 'tier' | 'album'>, tuning: Tuning): { dust: number; reputation: number; ecrins: number } {
  const { tier } = achievement;
  const dust = tier === 'or' ? tuning.achievementDustGold : tier === 'argent' ? tuning.achievementDustSilver : tuning.achievementDustBronze;
  return { dust, reputation: tuning.achievementReputation, ecrins: achievement.album ? tuning.albumRewardEcrins : 0 };
}

/** Titres que le joueur peut porter (succès obtenus qui en donnent un). */
export function earnedTitles(state: PlayerState): string[] {
  return ACHIEVEMENTS.filter((a) => a.title && state.achievements[a.id] !== undefined).map((a) => a.title!);
}

/** Porte un titre gagné (null : aucun). Sans effet si le titre n'est pas gagné. */
export function wearTitle(state: PlayerState, title: string | null): PlayerState {
  if (title !== null && !earnedTitles(state).includes(title)) return state;
  return { ...state, title };
}
