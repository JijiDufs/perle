// Textes anglais du contenu du jeu (perles, trouvailles, traits, coquilles, produits), pour l'app iOS
// (AGENTS.md §6, 2026-10-19). Repérés par identifiant : les catalogues français restent la source,
// cette table ne change aucune règle. Exportée avec le catalogue par `npm run ios:export`.
// Clins d'œil : comme en français, jamais de nom d'œuvre, de personnage ni de marque.
import type { PearlId } from './catalog';
import type { FindAlbumId } from './finds';
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
  },
};
