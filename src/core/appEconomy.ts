// Économie de l'app iOS (docs/duo-gadget.md §6 bis à §6 quater) : poussière d'or lente, missions du jour,
// skins et produits de la boutique. Données seulement : la webapp ne s'en sert pas, elles sont
// exportées vers ios/ par `npm run ios:export`. Montants provisoires (AGENTS.md §6).

/** Poussière d'or d'un doublon revendu, selon sa rareté (— ◆ ◆◆ ◆◆◆ ★ ★★). Plus bas que la webapp. */
export const APP_SELL_DUST_BY_TIER: readonly number[] = [0, 1, 2, 5, 15, 40];

/**
 * Prix d'une perle manquante en poussière d'or, selon sa rareté.
 * null : pas à vendre (les ★ et ★★ restent à pêcher, la garantie est là pour ça).
 */
export const APP_MISSING_PEARL_PRICE_BY_TIER: readonly (number | null)[] = [null, 5, 10, 25, null, null];

export const APP_ECONOMY = {
  /** Une huître achetée avec la poussière d'or (quand le stock est vide). */
  oysterDustPrice: 20,
  /** Poussière d'or de la trouvaille « pièce d'or engloutie ». */
  goldCoinDust: 5,
  /** Missions du jour : combien, récompense de chacune, bonus quand toutes sont récupérées. */
  missionsPerDay: 3,
  missionRewardDust: 5,
  missionBonusDust: 10,
  /** Une perle achetée à la poussière d'or est une perle ordinaire. */
  boughtPearlLustre: 'B',
} as const;

export type AppMissionKind = 'open' | 'lustreA' | 'lustreS' | 'rare' | 'noCrack' | 'sell' | 'share';

/** Les missions possibles ; chaque jour en tire `missionsPerDay`, avec un objectif parmi `goals`. */
export const APP_MISSIONS: readonly { kind: AppMissionKind; goals: readonly number[] }[] = [
  { kind: 'open', goals: [5, 8] },
  { kind: 'lustreA', goals: [2, 3] },
  { kind: 'lustreS', goals: [1] },
  { kind: 'rare', goals: [1] },
  { kind: 'noCrack', goals: [3, 5] },
  { kind: 'sell', goals: [1, 3] },
  { kind: 'share', goals: [1] },
];

/** Rareté minimale (niveau, 2 = ◆◆) d'une perle pour la mission « rare ». */
export const APP_RARE_MISSION_TIER = 2;

/**
 * Les skins d'huître : purement cosmétiques, ils ne changent aucune règle (docs/duo-gadget.md §6 bis).
 * `style` choisit la silhouette dessinée ; les couleurs habillent la coquille et la nacre,
 * jamais la lumière de la perle.
 */
export interface AppSkin {
  id: string;
  name: string;
  description: string;
  style: 'oyster' | 'clam' | 'gold';
  /** Prix en poussière d'or ; null = pas à vendre en poussière. */
  dustPrice: number | null;
  /** Produit de la boutique Apple ; null = pas à vendre. Le prix affiché vient de StoreKit. */
  productId: string | null;
  /** Comment l'obtenir autrement : offert au départ, ou réservé aux inscrits de la page. */
  grant: 'start' | 'signup' | null;
  shellLight: string;
  shellDark: string;
  nacreLight: string;
  nacreShade: string;
  /** Liseré du bord (argent, or) ; null = aucun. */
  rim: string | null;
}

export const APP_SKINS: readonly AppSkin[] = [
  {
    id: 'lagon', name: 'Huître du lagon', description: 'Celle de grand-mère Rose. Rugueuse, fidèle, increvable.',
    style: 'oyster', dustPrice: null, productId: null, grant: 'start',
    shellLight: '#8C806C', shellDark: '#4A4237', nacreLight: '#FBF7F2', nacreShade: '#D6CCE6', rim: null,
  },
  {
    id: 'benitier', name: 'Bénitier', description: 'Le coquillage géant des lagons chauds. Il se referme sans prévenir.',
    style: 'clam', dustPrice: 2000, productId: 'app.pearlinc.skin.benitier', grant: null,
    shellLight: '#F1EBDD', shellDark: '#B9AE97', nacreLight: '#7FE3D6', nacreShade: '#1E6F86', rim: null,
  },
  {
    id: 'premiere-maree', name: 'Première marée', description: 'Pour celles et ceux qui étaient là avant tout le monde.',
    style: 'oyster', dustPrice: null, productId: null, grant: 'signup',
    shellLight: '#E9DDC3', shellDark: '#A8977A', nacreLight: '#FFFFFF', nacreShade: '#CFE6EE', rim: '#D9E2EA',
  },
  {
    id: 'or', name: 'Huître d’or', description: 'Or martelé, nacre champagne. Elle ne passe pas inaperçue, c’est le but.',
    style: 'gold', dustPrice: null, productId: 'app.pearlinc.skin.or', grant: null,
    shellLight: '#F6D77A', shellDark: '#A8771F', nacreLight: '#FFF6DF', nacreShade: '#E7CF9F', rim: '#FFE9A8',
  },
];

/** Produits consommables de la boutique Apple (le prix affiché vient de StoreKit). */
export const APP_CONSUMABLES: readonly { id: string; name: string; oysters: number; dust: number }[] = [
  { id: 'app.pearlinc.oysters.10', name: 'Marée haute', oysters: 10, dust: 0 },
  { id: 'app.pearlinc.oysters.30', name: 'Grande marée', oysters: 30, dust: 0 },
  { id: 'app.pearlinc.dust.400', name: 'Bourse de poussière d’or', oysters: 0, dust: 400 },
  { id: 'app.pearlinc.dust.1200', name: 'Coffret de poussière d’or', oysters: 0, dust: 1200 },
  { id: 'app.pearlinc.dust.3000', name: 'Malle de poussière d’or', oysters: 0, dust: 3000 },
];
