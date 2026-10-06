// Pistes de contenu visuelles pour les destinations futures ; aucune n'est tirée en jeu.
export type DestinationId = 'cove' | 'garden' | 'wreck' | 'rift';
export type FindKind = 'perle' | 'bijou' | 'objet';

export interface RumorFind {
  id: string;
  destination: Exclude<DestinationId, 'cove'>;
  name: string;
  kind: FindKind;
  note: string;
  color: string;
  accent: string;
  icon: string;
}

export const RUMOR_FINDS: readonly RumorFind[] = [
  { id: 'moon-leaf', destination: 'garden', name: 'Perle feuille-de-lune', kind: 'perle', note: 'Sa tache claire ressemble à une feuille vue depuis le fond.', color: '#c3e1bd', accent: '#f5e2a5', icon: 'moon-pearl' },
  { id: 'kelp-bracelet', destination: 'garden', name: 'Bracelet Liane', kind: 'bijou', note: 'Une algue tressée qui ne sèche jamais.', color: '#7baf87', accent: '#d1e79e', icon: 'bracelet' },
  { id: 'diver-button', destination: 'garden', name: 'Bouton de scaphandre', kind: 'objet', note: 'Trop petit pour une combinaison. Beaucoup trop lourd pour un jouet.', color: '#c39b5e', accent: '#f2d99c', icon: 'scuba-button' },
  { id: 'pollen-stone', destination: 'garden', name: 'Galet-pollen', kind: 'objet', note: 'Il laisse des étincelles vertes sur les doigts.', color: '#a9c89c', accent: '#f5d987', icon: 'pollen-stone' },
  { id: 'maze-nacre', destination: 'garden', name: 'Nacre-labyrinthe', kind: 'perle', note: 'On jurerait qu’un chemin bouge sous sa surface.', color: '#91c6c0', accent: '#edd4a0', icon: 'maze-shell' },
  { id: 'radio-shell', destination: 'wreck', name: 'Coquillage-radio', kind: 'objet', note: 'Une seule station. Elle annonce la marée depuis 1978.', color: '#afd1c1', accent: '#f1d69c', icon: 'radio-shell' },
  { id: 'continue-token', destination: 'wreck', name: 'Jeton « Continue ? »', kind: 'objet', note: 'La partie est finie depuis longtemps. Le compteur tourne encore.', color: '#bd9558', accent: '#f5dc8a', icon: 'continue-token' },
  { id: 'captain-ring', destination: 'wreck', name: 'Bague du capitaine', kind: 'bijou', note: 'Gravée au nom d’un navire qui n’apparaît sur aucune carte.', color: '#bf9a5d', accent: '#e6b6a1', icon: 'captain-ring' },
  { id: 'sonar-pearl', destination: 'wreck', name: 'Perle sonar', kind: 'perle', note: 'Elle renvoie un écho quand la cale est silencieuse.', color: '#7bb6b4', accent: '#d8e7bd', icon: 'sonar-pearl' },
  { id: 'reverse-postcard', destination: 'wreck', name: 'Carte postale à l’envers', kind: 'objet', note: 'Au recto : une plage. Au verso : la même plage, de nuit.', color: '#d4ba85', accent: '#719e9b', icon: 'reverse-postcard' },
  { id: 'comet-pearl', destination: 'rift', name: 'Perle comète', kind: 'perle', note: 'Une traînée lumineuse semble tourner dans sa nacre.', color: '#d7d1f1', accent: '#8de4dc', icon: 'comet-pearl' },
  { id: 'homing-compass', destination: 'rift', name: 'Boussole qui revient vers toi', kind: 'objet', note: 'Quelle que soit la direction, l’aiguille finit par pointer ici.', color: '#c5a56c', accent: '#f0e0ae', icon: 'homing-compass' },
  { id: 'last-tide-crown', destination: 'rift', name: 'Diadème de la dernière marée', kind: 'bijou', note: 'Ses petites pierres brillent une par une, comme des fenêtres.', color: '#d9c17e', accent: '#94d3cd', icon: 'coral-diadem' },
  { id: 'tide-hourglass', destination: 'rift', name: 'Sablier de marée', kind: 'objet', note: 'Le sable remonte quand la lune disparaît.', color: '#82bfc3', accent: '#efdca4', icon: 'tide-hourglass' },
  { id: 'lantern-geode', destination: 'rift', name: 'Géode-lanterne', kind: 'perle', note: 'Une petite lumière veille au cœur de la pierre.', color: '#657d9e', accent: '#83f0df', icon: 'lantern-geode' },
];
