# App iOS : feuille de route des mises à jour

> Cahier des charges des mises à jour de Pearl Inc. sur l'App Store, après la 1.0 (envoyée le 2026-10-20, tag `v1.0-build4`).
> But : amener **petit à petit** dans l'app iOS tout ce que la webapp sait faire (écrins, niveaux, missions, Maison, atelier, collection), **dans la direction artistique de l'app** (lagon lumineux, verre clair, cartes aux couleurs des perles), puis des contenus nouveaux (les lagons).
> Une mise à jour = un lot. Un lot n'est envoyé à Apple qu'une fois testé sur iPhone classique **et** sur iPhone Duo.

## 1. Principes

1. **Petit et complet.** Chaque lot est jouable seul, sans écran « à venir » ni bouton mort (règle Apple 2.1, `duo-gadget.md` §5). On ne montre pas ce qui n'existe pas encore : pas de déblocages « à venir », pas de destinations grisées sur la carte.
2. **La webapp est la référence des règles, pas du rendu.** On reprend la logique de `src/core/` (déjà testée), on redessine les écrans en SwiftUI avec la DA de l'app. Les écrans de la webapp servent de maquette fonctionnelle, pas visuelle.
3. **Une seule source de vérité.** Catalogues, réglages et barèmes restent dans `src/` (TypeScript) ; `npm run ios:export` les envoie vers `PearlCore`. Les montants **propres à l'app** (économie lente) vont dans `src/core/appEconomy.ts`, jamais copiés tels quels de la webapp.
4. **Les fonctions arrivent une à une pour le joueur aussi** (cahier §15) : à partir du lot 1.1, chaque nouveauté se débloque à un niveau. Un joueur de la 1.0 qui met à jour découvre les nouveautés dans l'ordre, pas toutes d'un coup.
5. **Aucune partie perdue.** Chaque lot charge une sauvegarde des versions précédentes (champs nouveaux avec une valeur par défaut au décodage). Test obligatoire avec une sauvegarde 1.0.
6. **Le Duo n'est pas une option.** Chaque nouveau geste se demande : « et avec la charnière ? ». Chaque nouvel écran se demande : « et coupé par le pli ? ».

## 2. Les lots, dans l'ordre

Durée indicative : 1 à 2 semaines par lot, revue d'Apple comprise. Une seule version peut être en revue à la fois : on ne prépare l'envoi du lot suivant qu'une fois le précédent accepté.

| Version | Lot | Ce que le joueur voit | Repris de la webapp |
|---|---|---|---|
| **1.0.1** | Lancement | Vraies pubs AdMob ; réglages de la charnière d'après les retours TestFlight Duo ; corrections des premiers avis | — |
| **1.1** | Niveaux et réputation | Anneau de niveau dans la barre du haut, « +N » à chaque gain, célébration de montée de niveau avec récompenses, rangs (Pêcheur → …), fiche « Ma progression » | `core/levels.ts`, `features/progress/` |
| **1.2** | Collection enrichie | Encyclopédie (toucher une perle filtre ses cartes), tri rareté / récentes / valeur, carte agrandie, carnet des variantes (formes, reflets, marques), album des trouvailles | `core/collection.ts`, `core/pearlTraits.ts`, `features/collection/` |
| **1.3** | Succès, titres, missions enrichies | Succès bronze / argent / or (dont secrets), titre porté sous le rang, bannière au moment calme ; nouvelles sortes de missions du jour | `core/achievements.ts`, `core/quests.ts`, `core/progression.ts` |
| **1.4** | Écrins et bijoux | Onglet Écrins (salon de joaillier), écrin en cuir qui s'ouvre au pouce **ou à la charnière**, angle d'éclat, éclat parfait, variantes Aurore / Nuit / Givre, garantie ★, probabilités avant ouverture, volet Bijoux de la collection | `core/glint.ts`, `core/jewels.ts`, `art/ecrin3d.ts`, `art/salon.ts`, `features/ecrin/` |
| **1.5** | Expertise à la loupe | Loupe au-dessus du doigt sur les pierres précieuses, inclusions, certificat Excellent / Bon | `core/expertise.ts`, `features/expertise/` |
| **1.6** | La Maison de Rose | 4e onglet : maison de poupée vue en coupe, lettres de grand-mère Rose débloquées par niveau, pièces qui se rallument, maison qui grandit avec le rang | `core/house.ts`, `art/house*.ts`, `features/house/` |
| **1.7** | L'Atelier | Carnet de recettes, établi, **sertissage** (pincer deux doigts ; sur le Duo, refermer le téléphone), étoiles, volet Créations, vitrine de la Maison | `core/atelier.ts`, `core/setting.ts`, `input/pinch.ts`, `features/atelier/` |
| **1.8** | Les lagons (1) | Carte des marées ; La Crique (le lagon actuel) + **le Jardin d'algues** débloqué par niveau, avec ses perles et trouvailles propres | idée de `features/map/` (concept seulement, voir §4) |
| **1.9** | Les lagons (2) | L'Épave des échos | idem |
| **1.10** | Les lagons (3) | La Faille d'azur | idem |

**Pourquoi cet ordre**
- **Niveaux d'abord** : c'est la colonne vertébrale. Tout ce qui suit se débloque par niveau, et le joueur sent enfin qu'il avance.
- **Collection ensuite** : petit lot, sans économie nouvelle, qui rode la façon de travailler ; et il prépare les volets Bijoux et Créations.
- **Succès avant les écrins** : ils donnent des objectifs avec le contenu actuel, et les écrins y ajouteront les leurs.
- **Écrins en 1.4**, le plus gros lot : il touche le geste, la charnière, l'économie et un nouvel onglet. S'il est trop gros, on le coupe en deux (écrin et bijoux ; puis variantes rares).
- **Les lagons en dernier** : c'est du contenu nouveau, qui n'existe pas dans la webapp et demande des décisions (§4).

**Missions** : l'app a déjà 3 missions du jour. Chaque lot ajoute ses sortes de missions (ouvrir un écrin, lire une lettre, sertir…) dans `MissionKind`, sans en changer le nombre.

## 3. Ce que chaque lot doit cocher (définition de « fini »)

**Logique**
- [ ] Règles portées de `src/core/` vers `PearlCore` (Swift pur, aucun SwiftUI), données exportées par `npm run ios:export`.
- [ ] Cas de référence ajoutés dans `parity.json` : le Swift donne les mêmes résultats que le TypeScript.
- [ ] Aucun nombre magique : tout dans `src/tuning.ts`, les catalogues ou `appEconomy.ts`.
- [ ] Hasard et temps injectés ; tout tirage décidé avant le geste et sauvegardé.

**Économie**
- [ ] Montants de l'app relus pour l'économie lente (`duo-gadget.md` §6 quater) : combien de ✦ et de réputation par jour avec ce lot ?
- [ ] Rien d'aléatoire n'est vendu contre de l'argent réel sans décision en §6 de `AGENTS.md`.
- [ ] Probabilités affichées pour chaque nouveau tirage (écrins, lagons), dans l'écran concerné et dans Réglages → Probabilités.

**Sauvegarde**
- [ ] Une sauvegarde de la version précédente se charge sans rien perdre (test dans `PearlCore`).

**Langues et accessibilité**
- [ ] Français et anglais : `Localizable.xcstrings` et `catalogEnglish.ts` (un test échoue s'il manque un texte).
- [ ] Chaque nouveau geste a une action VoiceOver ; Dynamic Type ; « Réduire les animations » respecté.

**iPhone Duo**
- [ ] Rien sur le pli ; cartes et fenêtres sur une moitié quand le téléphone est à moitié ouvert ; grilles en nombre pair de colonnes.
- [ ] Si le lot ajoute un geste d'ouverture ou de fermeture : il marche aussi à la charnière, avec la même règle d'armement que l'huître (`Hinge.swift`).
- [ ] Écran extérieur rempli (pas de bandes), caméra du coin évitée.

**Tests**
- [ ] `npm test`, `npm run build`, `swift test` (dans `ios/PearlCore`) verts.
- [ ] Simulateur : iPhone 17 Pro, petit iPhone (17e), Duo simulé (`-SimulatedHinge -SimulatedFold`) fermé, à moitié ouvert, grand ouvert.
- [ ] Parcours complet du lot, et un parcours 1.0 (tutoriel, huître, carte, collection, boutique, pub) pour vérifier qu'on n'a rien cassé.
- [ ] Sur l'iPhone de Jules (build Xcode), puis TestFlight pour les inscrits équipés d'un Duo.

**Envoi**
- [ ] Numéro de version et de build montés ; texte « Nouveautés » FR / EN ; notes de revue mises à jour si un nouveau geste, achat ou tirage apparaît.
- [ ] Entrée dans `docs/JOURNAL.md`, décisions dans `AGENTS.md` §6, graphe graphify mis à jour.
- [ ] Fusion dans `main` quand tout est vert, tag `v1.x` sur le commit envoyé à Apple.

## 4. Décisions à prendre avant certains lots

| Avant | Question | Proposition |
|---|---|---|
| 1.1 | Barème de réputation de l'app : le même que la webapp ? | **Tranché (Jules, 2026-10-20) : plus rapide au début.** Les 10 premiers niveaux vont plus vite pour accrocher, puis la courbe rejoint celle de la webapp (niveau 50 en 4 à 6 mois). Récompenses de niveau en économie lente (surtout des huîtres, peu de ✦) |
| 1.1 | Joueurs de la 1.0 : repartent du niveau 1, ou réputation rétroactive d'après leur collection ? | **Tranché (Jules, 2026-10-20) : rétroactive**, calculée d'après la collection, avec une seule fenêtre « Tu es niveau N » (pas de célébrations en rafale) |
| 1.4 | D'où viennent les écrins dans l'app ? | **Tranché (Jules, 2026-10-21) : deux sources pour commencer**, les montées de niveau (tous les 3 niveaux et à chaque rang) et la poussière d'or au comptoir (prix à caler sur l'économie lente, §6 quater). Calendrier, missions ou « 1 toutes les X huîtres » seulement si les chiffres montrent que les joueurs en manquent : trop d'écrins, et l'écrin perd sa valeur. **Jamais vendus contre de l'argent réel** (tirage payant, cf. la Belgique). **Prix (lot 1.4) : 200 ✦** (10 huîtres de poussière) ; ≈ 4 écrins la 1re semaine, puis ≈ 1 par semaine par les niveaux |
| 1.4 | La charnière ouvre l'écrin comme l'huître ? | Oui : tenir le téléphone immobile dans l'angle d'éclat, c'est le geste le plus naturel du Duo |
| 1.6 | Textes des lettres de Rose en anglais | Traduction relue par un anglophone |
| 1.7 | Sertissage sur le Duo | Refermer le téléphone = refermer l'établi (`SettingSample` est déjà prêt pour ça) |
| 1.8 | Les lagons : tables de tirage propres, ou mêmes perles avec d'autres trouvailles ? | Mêmes 8 perles et même garantie partout ; chaque lagon a ses trouvailles et une perle « signature » un peu plus fréquente. Débloqués par niveau, choisis sur la carte avant de pêcher. Les pistes de `features/map/finds.ts` servent de point de départ |
| 1.8 | Coût en huîtres d'un lagon lointain ? | Non : même huître partout, sinon on vend du hasard plus cher |

Les montants et textes restent **provisoires, à valider avec Mathys**, comme dans la webapp.

## 5. Comment on travaille un lot

1. **Ici, dans la session « pilote »** : on choisit le lot, on tranche ses questions du §4, et on lance **une session dédiée** au lot, avec un brief court. Le contexte de la session pilote reste léger.
2. **La session du lot** travaille sur sa branche (`jules/ios-1.x-…`) :
   - lit `AGENTS.md`, ce document (son lot et le §3), la dernière entrée du journal ;
   - cherche dans le code **par graphify** (`graphify query "…"`) plutôt qu'en lisant des dossiers entiers ; si le graphe est plus ancien que le dernier commit, `/graphify . --update` d'abord ;
   - fait le lot, coche le §3, lance les tests et le simulateur (iPhone et Duo) ;
   - finit par le journal, `/graphify . --update`, commit et push.
3. **Retour à la session pilote** : on relit le résultat, Jules teste sur son iPhone, TestFlight pour le Duo, puis envoi à Apple (Xcode → Archive, App Store Connect), fait par Jules.
4. Si un lot est trop gros pour une session, on le coupe (ex. 1.4a écrin et bijoux, 1.4b variantes et garantie).
