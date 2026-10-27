// Textes anglais du contenu du jeu (perles, trouvailles, traits, coquilles, produits), pour l'app iOS
// (AGENTS.md §6, 2026-10-19). Repérés par identifiant : les catalogues français restent la source,
// cette table ne change aucune règle. Exportée avec le catalogue par `npm run ios:export`.
// Clins d'œil : comme en français, jamais de nom d'œuvre, de personnage ni de marque.
import type { PearlId } from './catalog';
import type { FindAlbumId } from './finds';
import type { GemCut, JewelRarityId, JewelType, JewelVariantId, Ornament } from './jewels';
import type { PearlMark, PearlOvertone, PearlShape } from './pearlTraits';

export interface CatalogEnglish {
  pearls: Readonly<Record<PearlId, { name: string; flavor: string }>>;
  findAlbums: Readonly<Record<FindAlbumId, { name: string; description: string }>>;
  finds: Readonly<Record<string, { name: string; flavor: string }>>;
  /** Même ordre que BOTTLE_MESSAGES. */
  bottleMessages: readonly string[];
  shapes: Readonly<Record<PearlShape, string>>;
  overtones: Readonly<Record<PearlOvertone, string>>;
  marks: Readonly<Record<PearlMark, { label: string; description: string }>>;
  skins: Readonly<Record<string, { name: string; description: string }>>;
  consumables: Readonly<Record<string, string>>;
  /** Titres des rangs (src/core/levels.ts). */
  ranks: Readonly<Record<string, string>>;
  /** Succès de l'app (APP_ACHIEVEMENTS) ; `title` seulement pour ceux qui en donnent un. */
  achievements: Readonly<Record<string, { name: string; description: string; title?: string }>>;
  /** Les bijoux des écrins (src/core/jewels.ts) : mêmes clés, mêmes modèles de noms ({one}, {with}, {of}, {metal}). */
  jewels: {
    rarities: Readonly<Record<JewelRarityId, { label: string; flavor: string }>>;
    /** Même ordre que TOC_VARIANTS. */
    tocVariants: readonly { name: string; flavor: string }[];
    legendName: string;
    /** Par nom français du métal (raretés, METAL_OPTIONS, TOC_VARIANTS, variantes). */
    metals: Readonly<Record<string, string>>;
    types: Readonly<Record<JewelType, string>>;
    cuts: Readonly<Record<GemCut, string>>;
    gemWords: Readonly<Partial<Record<JewelRarityId, { one: string; with: string; of: string }>>>;
    names: Readonly<Record<Ornament, Readonly<Record<string, string>>>>;
    variants: Readonly<Record<JewelVariantId, { label: string; flavor: string }>>;
  };
}

export const CATALOG_ENGLISH: CatalogEnglish = {
  pearls: {
    empty: { name: 'Empty oyster', flavor: 'Nothing. It stares at you, you stare back.' },
    white: { name: 'White pearl', flavor: 'The classic. Round, calm, flawless.' },
    rose: { name: 'Rosé pearl', flavor: 'A pink glow you only see in the right light.' },
    baroque: { name: 'Baroque pearl', flavor: 'Lumpy and one of a kind. Nobody has one like it.' },
    black: { name: 'Black pearl', flavor: 'Aubergine and peacock-green glints. Connoisseurs fall silent.' },
    golden: { name: 'Golden pearl', flavor: 'It feels a little warm in your palm. Probably just you.' },
    giant: { name: 'Giant pearl', flavor: 'That oyster hasn’t slept a wink in years.' },
    cursed: { name: 'Cursed pearl', flavor: 'It was there before the oyster.' },
  },
  findAlbums: {
    port: { name: 'Harbour odds and ends', description: 'Whatever tourists lose, the sea gives back one day.' },
    clins: { name: 'Nods and winks', description: 'Objects that remind you of something. Surely a coincidence.' },
    tresors: { name: 'Sunken treasures', description: 'They’re good for something. Well, most of them.' },
  },
  finds: {
    tong: { name: 'Orphan flip-flop', flavor: 'The left one. The right one started a new life out at sea.' },
    ticket: { name: 'Fairground ticket', flavor: 'Good for one ride. The ride itself sank.' },
    cadenas: { name: 'Love padlock', flavor: '“J + M forever”. The key is somewhere on the seabed.' },
    canard: { name: 'Rubber duck', flavor: 'It sailed around the world. It doesn’t brag about it.' },
    lunettes: { name: 'Heart-shaped sunglasses', flavor: 'One lens left. The other one saw too much sun.' },
    clapet: { name: 'Flip phone', flavor: 'A phone that folds in half. It’ll never catch on.' },
    dentier: { name: 'False teeth', flavor: 'Still smiling. More than you this morning.' },
    usb: { name: '“DO NOT OPEN” USB stick', flavor: 'You won’t open it. Right?' },
    nain: { name: 'Garden gnome', flavor: 'He has travelled a lot. He won’t say where.' },
    'poisson-clown': { name: 'Little clownfish', flavor: 'A whole family was looking for him. Here he is.' },
    fourchette: { name: 'Fork', flavor: 'Some people comb their hair with it. Nobody corrects them.' },
    cube: { name: 'Six-colour cube', flavor: 'One side is almost done. Almost.' },
    jeton: { name: '“Continue?” token', flavor: '10… 9… 8… Insert an oyster to continue.' },
    champignon: { name: 'Spotted mushroom', flavor: 'They say eating one makes you grow. Don’t try it.' },
    ballon: { name: 'Ball with a face', flavor: 'It listens for hours. It never answers.' },
    chapeau: { name: 'Straw hat', flavor: 'Its owner left to become king of something.' },
    aileron: { name: 'Rubber fin', flavor: 'You’re going to need a bigger boat.' },
    cartouche: { name: 'Game cartridge', flavor: 'Blow into it. It does nothing, but blow anyway.' },
    boussole: { name: 'Fickle compass', flavor: 'It doesn’t point north. It points to what you want most.' },
    anneau: { name: 'Whispering ring', flavor: 'A plain gold ring. You put it down. Gently.' },
    'coeur-ocean': { name: 'The great blue diamond', flavor: 'An old lady threw it overboard. Nobody ever understood why.' },
    'piece-or': { name: 'Sunken gold coin', flavor: 'Struck for a king nobody remembers. It melts down beautifully.' },
    bouteille: { name: 'Message in a bottle', flavor: 'There’s a message inside. Obviously.' },
    'pierre-brute': { name: 'Rough stone', flavor: 'A gem, under the crust. You’ll have to learn to cut it.' },
    'cle-epave': { name: 'Shipwreck key', flavor: 'It opened a chest. The chest is waiting for you in the Cases tab.' },
  },
  bottleMessages: [
    'If you’re reading this, sea mail still works.',
    'Shopping list: bread, butter, one giant pearl.',
    'I’m on a desert island with a volleyball. We get along fine.',
    'Don’t open the third oyster from the left. Too late?',
    'This is not a message.',
    'Happy New Year 1997 to whoever finds this bottle!',
    'If found, please return to the sea.',
    'Rose, the cursed pearl never came out of an oyster. It went in.',
  ],
  shapes: {
    ronde: 'Round',
    'presque-ronde': 'Near-round',
    goutte: 'Drop',
    bouton: 'Button',
    cerclee: 'Circled',
    baroque: 'Baroque',
  },
  overtones: {
    argente: 'silver',
    creme: 'cream',
    rose: 'pink',
    lavande: 'lavender',
    bleute: 'blue',
    'vert-paon': 'peacock green',
    aubergine: 'aubergine',
    dore: 'gold',
    cuivre: 'copper',
    sang: 'blood red',
    'arc-en-ciel': 'rainbow',
  },
  marks: {
    jumelle: { label: 'Twin', description: 'Two pearls fused in the same nacre.' },
    etoile: { label: 'Starry', description: 'A star-shaped glint, sharp as a spark.' },
    lune: { label: 'Lunar', description: 'A pale, crescent-moon spot.' },
    coeur: { label: 'Heart', description: 'The nacre took the shape of a heart.' },
  },
  skins: {
    lagon: { name: 'Lagoon oyster', description: 'Grandma Rose’s own. Rough, loyal, indestructible.' },
    benitier: { name: 'Giant clam', description: 'The giant shell of warm lagoons. It snaps shut without warning.' },
    'premiere-maree': { name: 'First Tide', description: 'For those who were here before everyone else.' },
    or: { name: 'Golden oyster', description: 'Hammered gold, champagne nacre. It doesn’t go unnoticed, and that’s the point.' },
  },
  consumables: {
    'app.pearlinc.oysters.10': 'High tide',
    'app.pearlinc.oysters.30': 'Spring tide',
    'app.pearlinc.dust.400': 'Pouch of gold dust',
    'app.pearlinc.dust.1200': 'Casket of gold dust',
    'app.pearlinc.dust.3000': 'Trunk of gold dust',
    'app.pearlinc.ecrin.1': 'Velvet jewel case',
    'app.pearlinc.ecrin.5': 'Set of 5 jewel cases',
  },
  ranks: {
    pecheur: 'Fisher',
    perlier: 'Pearler',
    artisan: 'Artisan',
    joaillier: 'Jeweller',
    maitre: 'Master jeweller',
    maison: 'High jewellery house',
  },
  achievements: {
    'premiere-perle': { name: 'First pearl', description: 'Find your first pearl.' },
    'dix-huitres': { name: 'Hands in the water', description: 'Open 10 oysters.' },
    'cent-huitres': { name: 'Dedicated fisher', description: 'Open 100 oysters.', title: 'Dedicated fisher' },
    'cinq-cents-huitres': { name: 'Old salt', description: 'Open 500 oysters.', title: 'Old salt' },
    'huitres-vides': { name: 'Patience', description: 'Come across 5 empty oysters.' },
    'perle-noire': { name: 'Connoisseurs fall silent', description: 'Find a black pearl.' },
    'perle-doree': { name: 'Gold in your palm', description: 'Find a golden pearl.' },
    'perle-geante': { name: 'Too big for one hand', description: 'Find a giant pearl.', title: 'Giant hunter' },
    'perle-maudite': { name: 'What was sleeping', description: 'Find the cursed pearl.', title: 'Bearer of the cursed pearl' },
    'crique-complete': { name: 'No more secrets', description: 'Find all 7 kinds of pearl.', title: 'Keeper of the lagoon' },
    'premiere-trouvaille': { name: 'This is not a pearl', description: 'Make your first find.' },
    'album-port': { name: 'Tidal flea market', description: 'Complete the “Harbour odds and ends” album.', title: 'Tidal bargain hunter' },
    'album-clins': { name: 'That rings a bell', description: 'Complete the “Nods and winks” album.', title: 'Deep-sea film buff' },
    'album-tresors': { name: 'Wreck hunter', description: 'Complete the “Sunken treasures” album.', title: 'Wreck hunter' },
    'grand-bateau': { name: 'Once upon a time, a great ship', description: 'Find the great blue diamond.' },
    'perle-jumelle': { name: 'Two for the price of one', description: 'Find a twin pearl.' },
    'perle-coeur': { name: 'Love at first sight', description: 'Find a heart pearl.', title: 'Heart of nacre' },
    'arc-en-ciel': { name: 'Every colour', description: 'Find a pearl with a rainbow overtone.' },
    'six-formes': { name: 'Six shapes', description: 'Find a pearl of every shape.' },
    'lustre-s': { name: 'Perfect touch', description: 'Get an S lustre.' },
    'lustre-s-10': { name: 'Virtuoso', description: 'Get 10 S lustres.', title: 'Virtuoso' },
    'sans-felure-10': { name: 'Velvet hands', description: 'Open 10 oysters in a row without a crack.', title: 'Velvet hands' },
    'sans-felure-50': { name: 'Surgeon’s hands', description: 'Open 50 oysters in a row without a crack.', title: 'Surgeon’s hands' },
    'serie-7': { name: 'Faithful to the pier', description: 'Come 7 days in a row.', title: 'Harbour regular' },
    'serie-30': { name: 'The tide and me', description: 'Come 30 days in a row.', title: 'Child of the tides' },
    'missions-10': { name: 'Reporting for duty', description: 'Claim 10 daily missions.' },
    'missions-60': { name: 'Always up for it', description: 'Claim 60 daily missions.', title: 'Always up for it' },
    'niveau-5': { name: 'Getting the hang of it', description: 'Reach level 5.' },
    'niveau-10': { name: 'The talk of the harbour', description: 'Reach level 10.' },
    'niveau-20': { name: 'A signature', description: 'Reach level 20.', title: 'Signature of the lagoon' },
    alchimiste: { name: 'Alchemist', description: 'Sell 20 duplicates at the counter.', title: 'Alchemist' },
    poisson: { name: 'Not so fast!', description: 'Catch the thief fish.' },
    'premier-bijou': { name: 'First jewel', description: 'Open your first jewellery case.' },
    toc: { name: 'Worth two tickets', description: 'Find a costume jewel.' },
    'eclat-parfait': { name: 'Eagle eye', description: 'Get a perfect glint.' },
    'eclat-parfait-10': { name: 'Jeweller’s eye', description: 'Get 10 perfect glints.', title: 'Eagle eye' },
    variante: { name: 'A rare light', description: 'Reveal a rare variant.' },
    diamant: { name: 'Forever', description: 'Find a diamond jewel.' },
    legende: { name: 'Out of the Abyss', description: 'Find the legendary jewel.', title: 'Legend of the Abyss' },
    'ecrin-complet': { name: 'Full case', description: 'Own a jewel of every rarity.', title: 'Grand collector' },
    'types-bijoux': { name: 'Tidy case', description: 'Own a ring, a necklace, a bracelet, earrings, a pendant and a brooch.' },
  },
  jewels: {
    rarities: {
      toc: { label: 'Costume', flavor: '' },
      fantaisie: { label: 'Fancy', flavor: 'It sparkles just like the real thing. From afar, at night.' },
      argent: { label: 'Silver', flavor: 'Understated, elegant, given with no ulterior motive.' },
      or: { label: 'Gold', flavor: 'The reassuring weight of 18-carat gold.' },
      perles: { label: 'Pearls', flavor: 'Every pearl came out of an oyster. Someone opened a lot of them.' },
      saphir: { label: 'Sapphire', flavor: 'A deep midnight blue, cut to last.' },
      emeraude: { label: 'Emerald', flavor: 'Green as a promise, and just as fragile.' },
      rubis: { label: 'Ruby', flavor: 'The stone of declarations you never take back.' },
      diamant: { label: 'Diamond', flavor: 'Forever. Or at least until the next case.' },
      legende: { label: 'Legend', flavor: 'No register says where it came from.' },
    },
    tocVariants: [
      { name: 'Candy ring', flavor: 'It tastes of strawberry. Don’t keep it on too long.' },
      { name: 'Funfair ring', flavor: 'Won at the coconut shy. Well worth two tickets.' },
      { name: 'Ring that turns green', flavor: 'Your finger is going to change colour. That’s normal.' },
    ],
    legendName: 'Tiara of the Abyss',
    metals: {
      Plastique: 'Plastic',
      Laiton: 'Brass',
      'Métal argenté': 'Silver-plated metal',
      'Argent 925': 'Sterling silver',
      Vermeil: 'Vermeil',
      'Or 18 ct': '18 ct gold',
      'Or jaune': 'Yellow gold',
      'Or rose': 'Rose gold',
      'Or blanc': 'White gold',
      Platine: 'Platinum',
      'Métal ?': 'Metal?',
      'Or aurore': 'Dawn gold',
      'Or noir': 'Black gold',
      'Platine givré': 'Frosted platinum',
    },
    types: { bague: 'Ring', collier: 'Necklace', bracelet: 'Bracelet', boucles: 'Earrings', pendentif: 'Pendant', broche: 'Brooch', diademe: 'Tiara' },
    cuts: { rond: 'Round brilliant', ovale: 'Oval', poire: 'Pear', coussin: 'Cushion', emeraude: 'Emerald', princesse: 'Princess', coeur: 'Heart', marquise: 'Marquise' },
    gemWords: {
      fantaisie: { one: 'rhinestone', with: 'rhinestone', of: 'rhinestone' },
      saphir: { one: 'sapphire', with: 'sapphire', of: 'sapphire' },
      emeraude: { one: 'emerald', with: 'emerald', of: 'emerald' },
      rubis: { one: 'ruby', with: 'ruby', of: 'ruby' },
      diamant: { one: 'diamond', with: 'diamond', of: 'diamond' },
    },
    names: {
      pearls: {
        'rang.bracelet': 'Pearl bracelet',
        rang: 'Pearl necklace',
        sautoir: 'Pearl sautoir',
        puces: 'Pearl stud earrings',
        pendants: 'Pearl drop earrings',
        goutte: 'Pearl pendant',
      },
      metal: {
        'jonc.bague': '{metal} band ring',
        jonc: '{metal} bangle',
        chevaliere: '{metal} signet ring',
        chaine: '{metal} chain',
        gourmette: '{metal} curb bracelet',
        creoles: '{metal} hoop earrings',
        medaille: '{metal} medal',
        coquillage: '{metal} shell pendant',
        fleur: '{metal} flower brooch',
        libellule: '{metal} dragonfly brooch',
        etoile: '{metal} starfish brooch',
      },
      gem: {
        'solitaire.bague': '{one} solitaire',
        solitaire: '{one} necklace',
        trilogie: '{with} trilogy ring',
        cocktail: '{one} cocktail ring',
        riviere: '{of} rivière',
        tennis: '{of} tennis bracelet',
        jonc: '{of}-set bangle',
        puces: '{one} stud earrings',
        pendants: '{one} drop earrings',
        creoles: '{of}-set hoop earrings',
        goutte: '{one} teardrop pendant',
        coeur: '{one} heart pendant',
        fleur: '{with} flower brooch',
        libellule: '{with} dragonfly brooch',
        etoile: '{with} starfish brooch',
        classique: '{of} tiara',
      },
    },
    variants: {
      aurore: { label: 'Dawn', flavor: 'It kept the colour of the first ray of morning.' },
      nuit: { label: 'Night', flavor: 'Cut at midnight, it only shines for those who know how to look.' },
      givre: { label: 'Frost', flavor: 'Cold to the touch, even in high summer.' },
    },
  },
};
