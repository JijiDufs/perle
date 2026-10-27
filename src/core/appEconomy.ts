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

/**
 * Écrins de l'app (lot 1.4, choix de Jules 2026-10-21, docs/ios-feuille-de-route.md §4) : aux montées de niveau (un
 * tous les `levelEvery` niveaux, un de plus à chaque rang, comme la webapp), contre de la poussière d'or au comptoir,
 * et en achat intégré comme les huîtres (choix de Jules 2026-10-27, voir `APP_CONSUMABLES`). Prix : 10 huîtres de
 * poussière, la même ancre que « Marée haute » (10 huîtres = 200 ✦ = 0,99 €). Pas de mission « ouvrir un écrin » : on
 * n'en a pas tous les jours. **Provisoire, à valider avec Mathys.**
 */
export const APP_ECRINS = {
  levelEvery: 3,
  rankEcrins: 1,
  dustPrice: 200,
} as const;

export type AppMissionKind = 'open' | 'lustreA' | 'lustreS' | 'rare' | 'noCrack' | 'sell' | 'share' | 'find' | 'fish';

/** Les missions possibles ; chaque jour en tire `missionsPerDay`, avec un objectif parmi `goals`. */
export const APP_MISSIONS: readonly { kind: AppMissionKind; goals: readonly number[] }[] = [
  { kind: 'open', goals: [5, 8] },
  { kind: 'lustreA', goals: [2, 3] },
  { kind: 'lustreS', goals: [1] },
  { kind: 'rare', goals: [1] },
  { kind: 'noCrack', goals: [3, 5] },
  { kind: 'sell', goals: [1, 3] },
  { kind: 'share', goals: [1] },
  // Lot 1.3 : une trouvaille (≈ 4 chances sur 5 en 30 huîtres), rattraper le poisson voleur (≈ 6 % des huîtres).
  { kind: 'find', goals: [1] },
  { kind: 'fish', goals: [1] },
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

/**
 * Produits consommables de la boutique Apple (le prix affiché vient de StoreKit). Écrins depuis le 2026-10-27 (choix de
 * Jules) : un écrin acheté n'est jamais moins cher que ses 200 ✦ achetés en pack (un test le vérifie avec
 * `ios/PearlInc.storekit`), il compte pour la garantie ★ comme les autres, et ses probabilités sont affichées à côté du
 * bouton d'achat.
 */
export const APP_CONSUMABLES: readonly { id: string; name: string; oysters: number; dust: number; ecrins: number }[] = [
  { id: 'app.pearlinc.oysters.10', name: 'Marée haute', oysters: 10, dust: 0, ecrins: 0 },
  { id: 'app.pearlinc.oysters.30', name: 'Grande marée', oysters: 30, dust: 0, ecrins: 0 },
  { id: 'app.pearlinc.dust.400', name: 'Bourse de poussière d’or', oysters: 0, dust: 400, ecrins: 0 },
  { id: 'app.pearlinc.dust.1200', name: 'Coffret de poussière d’or', oysters: 0, dust: 1200, ecrins: 0 },
  { id: 'app.pearlinc.dust.3000', name: 'Malle de poussière d’or', oysters: 0, dust: 3000, ecrins: 0 },
  { id: 'app.pearlinc.ecrin.1', name: 'Écrin de velours', oysters: 0, dust: 0, ecrins: 1 },
  { id: 'app.pearlinc.ecrin.5', name: 'Coffret de 5 écrins', oysters: 0, dust: 0, ecrins: 5 },
];

/**
 * Succès de l'app (lot 1.3, cahier §10) : ceux de la webapp (src/core/achievements.ts) qu'on peut obtenir dans l'app,
 * mêmes identifiants et mêmes objectifs (un test le vérifie), plus quelques-uns propres à l'app (missions, niveaux,
 * poisson voleur). Écrins et bijoux depuis le lot 1.4 (sauf « Huit tailles » : 1 chance sur 250 environ pour la taille
 * princesse, sans carnet pour suivre les tailles). Rien sur l'expertise, la Maison ou l'atelier : ils viendront avec
 * leurs lots (règle Apple 2.1). `measure` dit ce qui est compté (voir ios/PearlCore Achievements.swift), `target` la perle, trouvaille,
 * marque, reflet ou album visé. Textes anglais : catalogEnglish.ts. **Liste et textes provisoires, à valider avec Mathys.**
 */
export type AppAchievementMeasure =
  | 'oysters' // huîtres ouvertes
  | 'emptyOysters' // huîtres vides (pas les trouvailles)
  | 'pearlKinds' // sortes de perles dans la collection
  | 'pearl' // une perle de cette sorte
  | 'finds' // cartes de trouvailles
  | 'find' // cette trouvaille
  | 'album' // trouvailles différentes de cet album
  | 'mark' // une perle à cette marque rare
  | 'overtone' // une perle à ce reflet
  | 'shapes' // formes différentes
  | 'lustreS' // lustres S sans fêlure
  | 'crackFreeStreak' // meilleure série d'huîtres sans fêlure
  | 'loginStreak' // meilleure série de jours
  | 'sold' // doublons revendus
  | 'missions' // missions du jour récupérées
  | 'level' // niveau atteint
  | 'fishCaught' // poissons voleurs rattrapés
  | 'jewels' // cartes de bijoux
  | 'jewel' // un bijou de cette rareté
  | 'jewelRarities' // raretés de bijoux différentes
  | 'jewelTypes' // types de bijoux différents parmi MAIN_JEWEL_TYPES
  | 'perfectGlints' // éclats parfaits
  | 'variants'; // variantes rares révélées

export type AppAchievementTier = 'bronze' | 'argent' | 'or';

export interface AppAchievement {
  id: string;
  name: string;
  description: string;
  tier: AppAchievementTier;
  measure: AppAchievementMeasure;
  target?: string;
  goal: number;
  /** Caché tant qu'il n'est pas obtenu. */
  secret?: boolean;
  /** Titre que l'on peut porter une fois le succès obtenu. */
  title?: string;
  /** Album de trouvailles complété : la webapp donne un écrin, l'app des huîtres (`APP_ACHIEVEMENT_REWARDS.albumOysters`). */
  album?: boolean;
}

export const APP_ACHIEVEMENTS: readonly AppAchievement[] = [
  // La pêche
  { id: 'premiere-perle', name: 'Première perle', description: 'Trouver ta première perle.', tier: 'bronze', measure: 'pearlKinds', goal: 1 },
  { id: 'dix-huitres', name: 'Les mains dans l’eau', description: 'Ouvrir 10 huîtres.', tier: 'bronze', measure: 'oysters', goal: 10 },
  { id: 'cent-huitres', name: 'Pêcheur assidu', description: 'Ouvrir 100 huîtres.', tier: 'argent', measure: 'oysters', goal: 100, title: 'Pêcheur assidu' },
  { id: 'cinq-cents-huitres', name: 'Loup de mer', description: 'Ouvrir 500 huîtres.', tier: 'or', measure: 'oysters', goal: 500, title: 'Loup de mer' },
  { id: 'huitres-vides', name: 'Patience', description: 'Tomber sur 5 huîtres vides.', tier: 'bronze', measure: 'emptyOysters', goal: 5 },
  { id: 'perle-noire', name: 'Les connaisseurs se taisent', description: 'Trouver une perle noire.', tier: 'bronze', measure: 'pearl', target: 'black', goal: 1 },
  { id: 'perle-doree', name: 'De l’or dans la paume', description: 'Trouver une perle dorée.', tier: 'argent', measure: 'pearl', target: 'golden', goal: 1 },
  { id: 'perle-geante', name: 'Trop grande pour la main', description: 'Trouver une perle géante.', tier: 'or', measure: 'pearl', target: 'giant', goal: 1, title: 'Chasseur de géantes' },
  { id: 'perle-maudite', name: 'Ce qui dormait', description: 'Trouver la perle maudite.', tier: 'or', measure: 'pearl', target: 'cursed', goal: 1, secret: true, title: 'Porteur de la maudite' },
  // « La Crique » dans la webapp : l'app n'a pas encore de carte des lagons.
  { id: 'crique-complete', name: 'Plus de secrets', description: 'Trouver les 7 sortes de perles.', tier: 'or', measure: 'pearlKinds', goal: 7, title: 'Gardien du lagon' },
  // Les trouvailles
  { id: 'premiere-trouvaille', name: 'Ce n’est pas une perle', description: 'Trouver ta première trouvaille.', tier: 'bronze', measure: 'finds', goal: 1 },
  { id: 'album-port', name: 'Brocante des marées', description: 'Compléter l’album « Le bric-à-brac du port ».', tier: 'argent', measure: 'album', target: 'port', goal: 9, album: true, title: 'Brocanteur des marées' },
  { id: 'album-clins', name: 'Ça me rappelle quelque chose', description: 'Compléter l’album « Clins d’œil ».', tier: 'or', measure: 'album', target: 'clins', goal: 12, album: true, title: 'Cinéphile des abysses' },
  { id: 'album-tresors', name: 'Chasseur d’épaves', description: 'Compléter l’album « Trésors engloutis ».', tier: 'or', measure: 'album', target: 'tresors', goal: 4, album: true, title: 'Chasseur d’épaves' },
  { id: 'grand-bateau', name: 'Il était une fois un grand bateau', description: 'Trouver le grand diamant bleu.', tier: 'or', measure: 'find', target: 'coeur-ocean', goal: 1, secret: true },
  // Les perles uniques
  { id: 'perle-jumelle', name: 'Deux pour le prix d’une', description: 'Trouver une perle jumelle.', tier: 'argent', measure: 'mark', target: 'jumelle', goal: 1 },
  { id: 'perle-coeur', name: 'Coup de cœur', description: 'Trouver une perle en cœur.', tier: 'or', measure: 'mark', target: 'coeur', goal: 1, title: 'Cœur de nacre' },
  { id: 'arc-en-ciel', name: 'Toutes les couleurs', description: 'Trouver une perle au reflet arc-en-ciel.', tier: 'argent', measure: 'overtone', target: 'arc-en-ciel', goal: 1 },
  { id: 'six-formes', name: 'Six formes', description: 'Trouver une perle de chaque forme.', tier: 'argent', measure: 'shapes', goal: 6 },
  // Le geste
  { id: 'lustre-s', name: 'Geste parfait', description: 'Obtenir un lustre S.', tier: 'bronze', measure: 'lustreS', goal: 1 },
  { id: 'lustre-s-10', name: 'Virtuose', description: 'Obtenir 10 lustres S.', tier: 'argent', measure: 'lustreS', goal: 10, title: 'Virtuose' },
  { id: 'sans-felure-10', name: 'Main de velours', description: 'Ouvrir 10 huîtres d’affilée sans fêlure.', tier: 'argent', measure: 'crackFreeStreak', goal: 10, title: 'Main de velours' },
  { id: 'sans-felure-50', name: 'Main de chirurgien', description: 'Ouvrir 50 huîtres d’affilée sans fêlure.', tier: 'or', measure: 'crackFreeStreak', goal: 50, title: 'Main de chirurgien' },
  // La fidélité
  { id: 'serie-7', name: 'Fidèle au ponton', description: 'Venir 7 jours d’affilée.', tier: 'argent', measure: 'loginStreak', goal: 7, title: 'Habitué du port' },
  { id: 'serie-30', name: 'La marée et moi', description: 'Venir 30 jours d’affilée.', tier: 'or', measure: 'loginStreak', goal: 30, title: 'Enfant des marées' },
  { id: 'missions-10', name: 'Au rapport', description: 'Récupérer 10 missions du jour.', tier: 'bronze', measure: 'missions', goal: 10 },
  { id: 'missions-60', name: 'Toujours partant', description: 'Récupérer 60 missions du jour.', tier: 'argent', measure: 'missions', goal: 60, title: 'Toujours partant' },
  // La réputation
  { id: 'niveau-5', name: 'Le métier rentre', description: 'Atteindre le niveau 5.', tier: 'bronze', measure: 'level', goal: 5 },
  { id: 'niveau-10', name: 'On parle de toi au port', description: 'Atteindre le niveau 10.', tier: 'argent', measure: 'level', goal: 10 },
  { id: 'niveau-20', name: 'Une signature', description: 'Atteindre le niveau 20.', tier: 'or', measure: 'level', goal: 20, title: 'Signature du lagon' },
  // La poussière d'or et le poisson voleur
  { id: 'alchimiste', name: 'Alchimiste', description: 'Revendre 20 doublons au comptoir.', tier: 'argent', measure: 'sold', goal: 20, title: 'Alchimiste' },
  { id: 'poisson', name: 'Pas si vite !', description: 'Rattraper le poisson voleur.', tier: 'bronze', measure: 'fishCaught', goal: 1 },
  // Les écrins (lot 1.4)
  { id: 'premier-bijou', name: 'Premier bijou', description: 'Ouvrir ton premier écrin.', tier: 'bronze', measure: 'jewels', goal: 1 },
  { id: 'toc', name: 'Ça valait deux tickets', description: 'Trouver un bijou en toc.', tier: 'bronze', measure: 'jewel', target: 'toc', goal: 1 },
  { id: 'eclat-parfait', name: 'Œil de lynx', description: 'Réussir un éclat parfait.', tier: 'bronze', measure: 'perfectGlints', goal: 1 },
  { id: 'eclat-parfait-10', name: 'Regard de joaillier', description: 'Réussir 10 éclats parfaits.', tier: 'argent', measure: 'perfectGlints', goal: 10, title: 'Œil de lynx' },
  { id: 'variante', name: 'Une lumière rare', description: 'Révéler une variante rare.', tier: 'argent', measure: 'variants', goal: 1 },
  { id: 'diamant', name: 'Pour toujours', description: 'Trouver un bijou en diamant.', tier: 'argent', measure: 'jewel', target: 'diamant', goal: 1 },
  { id: 'legende', name: 'Venu des Abysses', description: 'Trouver le bijou légendaire.', tier: 'or', measure: 'jewel', target: 'legende', goal: 1, secret: true, title: 'Légende des Abysses' },
  { id: 'ecrin-complet', name: 'Écrin complet', description: 'Posséder un bijou de chaque rareté.', tier: 'or', measure: 'jewelRarities', goal: 10, title: 'Grand collectionneur' },
  { id: 'types-bijoux', name: 'Écrin bien rangé', description: 'Posséder une bague, un collier, un bracelet, des boucles, un pendentif et une broche.', tier: 'argent', measure: 'jewelTypes', goal: 6 },
];

/**
 * Récompenses des succès dans l'app (économie lente, docs/duo-gadget.md §6 quater) : surtout des huîtres, un peu
 * de poussière d'or (la webapp donne 10 / 30 / 80 ✦ + 40 de réputation). Un album complété donne des huîtres en plus
 * (la webapp : un écrin). **Montants provisoires, à valider avec Mathys.**
 */
export const APP_ACHIEVEMENT_REWARDS = {
  bronze: { oysters: 3, dust: 5, reputation: 15 },
  argent: { oysters: 5, dust: 10, reputation: 30 },
  or: { oysters: 10, dust: 25, reputation: 60 },
  albumOysters: 10,
} as const;
