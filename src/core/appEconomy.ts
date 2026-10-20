// Économie de l'app iOS (docs/duo-gadget.md §6 bis à §6 quater) : poussière d'or lente, missions du jour,
// skins et produits de la boutique. Données seulement : la webapp ne s'en sert pas, elles sont
// exportées vers ios/ par `npm run ios:export`. Montants provisoires (AGENTS.md §6).

/** Poussière d'or d'un doublon revendu, selon sa rareté (— ◆ ◆◆ ◆◆◆ ★ ★★). Plus bas que la webapp. */
export const APP_SELL_DUST_BY_TIER: readonly number[] = [0, 1, 2, 5, 15, 40];

export const APP_ECONOMY = {
  /** Une huître achetée avec la poussière d'or (quand le stock est vide). */
  oysterDustPrice: 20,
  /** Poussière d'or de la trouvaille « pièce d'or engloutie ». */
  goldCoinDust: 5,
  /** Missions du jour : combien, récompense de chacune, bonus quand toutes sont récupérées. */
  missionsPerDay: 3,
  missionRewardDust: 5,
  missionBonusDust: 10,
  /** Pub récompensée (choix de Jules, 2026-10-13) : huîtres par pub regardée, et pubs par jour. */
  rewardedAdOysters: 3,
  rewardedAdsPerDay: 3,
  /** Calendrier de connexion : le joker rattrape un jour manqué s'il n'a pas servi depuis ce nombre de jours (comme la webapp). */
  calendarJokerDays: 7,
} as const;

/**
 * Calendrier de connexion de l'app (docs/duo-gadget.md §6 quater) : une case par jour où l'on vient,
 * on recommence après la 7e. Des huîtres, et 10 à 25 ✦ certains jours : moins que la webapp
 * (src/core/daily.ts), qui donne aussi un écrin le 7e jour (pas d'écrin dans l'app).
 */
export const APP_CALENDAR: readonly { oysters: number; dust: number }[] = [
  { oysters: 3, dust: 0 },
  { oysters: 0, dust: 10 },
  { oysters: 5, dust: 0 },
  { oysters: 0, dust: 15 },
  { oysters: 5, dust: 0 },
  { oysters: 0, dust: 20 },
  { oysters: 10, dust: 25 },
];

/**
 * Niveaux et réputation de l'app (lot 1.1, docs/ios-feuille-de-route.md §4) : mêmes gains de réputation que la
 * webapp (src/tuning.ts), mais les 10 premiers niveaux vont plus vite, et les récompenses suivent l'économie lente
 * (surtout des huîtres, peu de poussière d'or, pas d'écrin). **Provisoire, à valider avec Mathys.**
 */
export const APP_LEVELS = {
  /** Niveau 1 : moitié de la réputation de la webapp ; l'écart se referme jusqu'au niveau 10 (voir `xpToNext`). */
  fastStart: { levels: 10, factor: 0.5 },
  /** À chaque niveau (huîtres au-delà du maximum si besoin). */
  rewardOysters: 5,
  rewardDust: 5,
  /** En plus, en arrivant à un nouveau rang (Perlier, Artisan…). */
  rankRewardOysters: 10,
  rankRewardDust: 20,
  /** Réputation d'une mission du jour récupérée, et de la case du calendrier (comme la webapp). */
  missionReputation: 30,
  calendarReputation: 15,
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
 * `style` donne la silhouette (huître ou bénitier) ; les couleurs vivent avec le dessin
 * (ios/PearlInc/Art/SkinLook.swift), et ne touchent jamais la lumière de la perle.
 */
export interface AppSkin {
  id: string;
  name: string;
  description: string;
  style: 'oyster' | 'clam';
  /** Prix en poussière d'or ; null = pas à vendre en poussière. */
  dustPrice: number | null;
  /** Produit de la boutique Apple ; null = pas à vendre. Le prix affiché vient de StoreKit. */
  productId: string | null;
  /** Comment l'obtenir autrement : offert au départ, ou réservé aux inscrits de la page. */
  grant: 'start' | 'signup' | null;
}

export const APP_SKINS: readonly AppSkin[] = [
  {
    id: 'lagon', name: 'Huître du lagon', description: 'Celle de grand-mère Rose. Rugueuse, fidèle, increvable.',
    style: 'oyster', dustPrice: null, productId: null, grant: 'start',
  },
  {
    id: 'benitier', name: 'Bénitier', description: 'Le coquillage géant des lagons chauds. Il se referme sans prévenir.',
    style: 'clam', dustPrice: 2000, productId: 'app.pearlinc.skin.benitier', grant: null,
  },
  {
    id: 'premiere-maree', name: 'Première marée', description: 'Pour celles et ceux qui étaient là avant tout le monde.',
    style: 'oyster', dustPrice: null, productId: null, grant: 'signup',
  },
  {
    id: 'or', name: 'Huître d’or', description: 'Or martelé, nacre champagne. Elle ne passe pas inaperçue, c’est le but.',
    style: 'oyster', dustPrice: null, productId: 'app.pearlinc.skin.or', grant: null,
  },
];

/**
 * Le poisson voleur (choix de Jules, 2026-10-20) : de temps en temps, juste après la révélation, un poisson
 * fond sur la perle et l'emporte. Seulement les perles ordinaires (◆ au plus) sans marque rare, jamais pendant
 * le tutoriel. Le toucher pendant sa fuite la rend (avec un peu de poussière d'or pour la peine) ; sinon elle est
 * perdue. Affiché dans les probabilités de la collection. **Provisoire, à valider avec Mathys.**
 */
export const APP_FISH_THIEF = {
  /** Chance qu'une perle qui peut être volée le soit (≈ 6 % des huîtres : blanches et rosées font 60 %). */
  chance: 0.1,
  /** Rareté maximale (niveau, 1 = ◆) d'une perle qu'un poisson peut voler. */
  maxTier: 1,
  /** Poussière d'or quand on rattrape le poisson. */
  catchBonusDust: 2,
  /** Le poisson arrive sur la perle (ms), puis s'enfuit avec : le temps pour le toucher (ms). */
  arriveMs: 750,
  fleeMs: 2800,
  /** Tolérance autour du poisson pour le toucher, en part de la taille de l'huître. */
  hitRadius: 0.2,
} as const;

/** Produits consommables de la boutique Apple (le prix affiché vient de StoreKit). */
export const APP_CONSUMABLES: readonly { id: string; name: string; oysters: number; dust: number }[] = [
  { id: 'app.pearlinc.oysters.10', name: 'Marée haute', oysters: 10, dust: 0 },
  { id: 'app.pearlinc.oysters.30', name: 'Grande marée', oysters: 30, dust: 0 },
  { id: 'app.pearlinc.dust.400', name: 'Bourse de poussière d’or', oysters: 0, dust: 400 },
  { id: 'app.pearlinc.dust.1200', name: 'Coffret de poussière d’or', oysters: 0, dust: 1200 },
  { id: 'app.pearlinc.dust.3000', name: 'Malle de poussière d’or', oysters: 0, dust: 3000 },
];
