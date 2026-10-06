// La Maison (cahier §8) : le fil narratif. Les lettres de grand-mère Rose se débloquent avec les niveaux ;
// chaque lettre lue restaure un morceau de la Maison. Textes et prénom : provisoires (AGENTS.md §6).
import type { Tuning } from '../tuning';
import { gainReputation, levelFromXp, RANKS } from './levels';
import type { PlayerState } from './player';
import { isInTutorial } from './tutorial';

/** Élément de la Maison restauré par une lettre (dessiné par art/house.ts). */
export type HouseFeature = 'door' | 'lantern' | 'sign' | 'notebook' | 'workbench' | 'vitrine' | 'box';

export interface Chapter {
  id: string;
  number: number;
  title: string;
  level: number;
  restores: HouseFeature;
  /** Ce que la lettre restaure, dit simplement. */
  restoresLabel: string;
  paragraphs: readonly string[];
  /** Fonction du jeu annoncée par la lettre, pas encore disponible. */
  teaser?: string;
}

export const CHAPTERS: readonly Chapter[] = [
  {
    id: 'cle',
    number: 1,
    title: 'La clé sous le coquillage',
    level: 1,
    restores: 'door',
    restoresLabel: 'La porte',
    paragraphs: [
      'Mon petit,',
      'Si tu lis ceci, c’est que le notaire t’a remis la clé, et que tu as déjà ouvert tes premières huîtres. Je le savais : on a ça dans le sang.',
      'La Maison n’est plus qu’une cabane qui grince au bout du ponton. Ne te fie pas aux planches. Autrefois, on venait de loin pour nos perles.',
      'Pousse la porte. Le reste viendra.',
    ],
  },
  {
    id: 'lanterne',
    number: 2,
    title: 'La lanterne',
    level: 3,
    restores: 'lantern',
    restoresLabel: 'La lanterne',
    paragraphs: [
      'La lanterne au-dessus de la porte, c’est ton grand-père qui l’a accrochée, le soir où j’ai trouvé ma première perle noire. Il disait qu’une Maison éteinte, c’est une Maison qu’on oublie.',
      'Rallume-la. Les pêcheurs du port verront qu’il y a de nouveau quelqu’un.',
    ],
  },
  {
    id: 'enseigne',
    number: 3,
    title: 'L’enseigne',
    level: 4,
    restores: 'sign',
    restoresLabel: 'L’enseigne',
    paragraphs: [
      'Sous la poussière, l’enseigne dit encore « Maison Rose, perles fines ». J’ai toujours trouvé ça un peu prétentieux pour une cabane. Ta mère disait que c’était justement le but.',
      'Repeins-la. Un jour, elle sera vraie.',
    ],
  },
  {
    id: 'carnet',
    number: 4,
    title: 'Le carnet aux pages arrachées',
    level: 5,
    restores: 'notebook',
    restoresLabel: 'La fenêtre et le carnet',
    teaser: 'Les pages retrouvées du carnet sont les recettes de l’atelier, sous la cabane.',
    paragraphs: [
      'Dans le tiroir de gauche, il y a mon carnet. Mes colliers, mes montages, mes petits secrets. Il manque des pages : j’en ai donné, j’en ai perdu, et une ou deux… je préfère ne pas en parler.',
      'Retrouve-les. Elles t’apprendront à faire des bijoux de tes perles.',
    ],
  },
  {
    id: 'etabli',
    number: 5,
    title: 'L’établi',
    level: 6,
    restores: 'workbench',
    restoresLabel: 'L’établi',
    teaser: 'L’atelier s’ouvre depuis la Maison.',
    paragraphs: [
      'Te voilà perlier. Je suis fière de toi.',
      'L’établi est sous la bâche, au fond. Les outils ont rouillé, mais une pince, ça se dérouille. Bientôt, tu y enfileras tes propres colliers.',
    ],
  },
  {
    id: 'vitrine',
    number: 6,
    title: 'La vitrine',
    level: 8,
    restores: 'vitrine',
    restoresLabel: 'La vitrine, avec ta plus belle pièce',
    paragraphs: [
      'Une Maison de perles sans vitrine, c’est un coffre fermé.',
      'Nettoie le carreau, poses-y ta plus belle pièce, et regarde les passants ralentir. Ils ne s’arrêteront pas tout de suite. Mais ils ralentiront.',
    ],
  },
  {
    id: 'tiroir',
    number: 7,
    title: 'Ce qui dort au fond du tiroir',
    level: 10,
    restores: 'box',
    restoresLabel: 'Une boîte qui n’aurait pas dû briller',
    paragraphs: [
      'Il y a une chose que je ne t’ai pas dite.',
      'Au fond du dernier tiroir, il y a une boîte que je n’ai jamais ouverte. Ma mère non plus. Elle était là avant nous.',
      'Si un jour une perle te paraît trop sombre, trop lourde, et qu’elle chauffe un peu la paume… ne la vends pas. Garde-la près de la boîte. Et attends ma prochaine lettre.',
    ],
  },
];

/** Niveau du prochain chapitre, encore à écrire, affiché comme horizon. */
export const NEXT_CHAPTER_LEVEL = 15;

/** La Maison s'ouvre à la fin du tutoriel (cahier §15 : la boutique abandonnée donne un horizon). */
export function isHouseUnlocked(state: PlayerState): boolean {
  return !isInTutorial(state.oystersOpened);
}

export function isChapterUnlocked(chapter: Chapter, state: PlayerState, tuning: Tuning): boolean {
  return isHouseUnlocked(state) && levelFromXp(state.reputation, tuning).level >= chapter.level;
}

export function unreadChapters(state: PlayerState, tuning: Tuning): Chapter[] {
  return CHAPTERS.filter((c) => isChapterUnlocked(c, state, tuning) && !state.chaptersRead.includes(c.id));
}

/** Éléments restaurés : ceux des lettres lues. */
export function restoredFeatures(state: PlayerState): Set<HouseFeature> {
  return new Set(CHAPTERS.filter((c) => state.chaptersRead.includes(c.id)).map((c) => c.restores));
}

/** Lit une lettre débloquée : elle restaure son élément et rapporte une récompense, une seule fois. */
export function readChapter(state: PlayerState, id: string, tuning: Tuning): PlayerState {
  const chapter = CHAPTERS.find((c) => c.id === id);
  if (!chapter || !isChapterUnlocked(chapter, state, tuning) || state.chaptersRead.includes(id)) return state;
  const read = { ...state, chaptersRead: [...state.chaptersRead, id], dust: state.dust + tuning.chapterRewardDust };
  return gainReputation(read, tuning.chapterRewardReputation, tuning);
}

/** Enseigne de la Maison : celle de Rose, puis Pearl Inc. */
export type HouseBrand = 'rose' | 'pearl-inc';

/** La Maison de Rose devient Pearl Inc. quand le joueur passe Joaillier (AGENTS.md §6). */
const PEARL_INC_LEVEL = RANKS.find((rank) => rank.id === 'joaillier')!.level;

export function houseBrand(level: number): HouseBrand {
  return level >= PEARL_INC_LEVEL ? 'pearl-inc' : 'rose';
}

/** Nom de la Maison tel qu'on l'écrit dans les textes. */
export function houseBrandName(level: number): string {
  return houseBrand(level) === 'pearl-inc' ? 'Pearl Inc.' : 'Maison Rose';
}

/** Nom de la Maison selon le rang (de la cabane à la boutique de luxe, cahier §8). */
export function houseStageName(level: number): string {
  if (level >= 50) return 'Pearl Inc., haute joaillerie';
  if (level >= 35) return 'Pearl Inc., la maison des maîtres';
  if (houseBrand(level) === 'pearl-inc') return 'Pearl Inc.';
  if (level >= 10) return 'La petite boutique';
  if (level >= 5) return 'L’atelier de fortune';
  return 'La cabane du ponton';
}
