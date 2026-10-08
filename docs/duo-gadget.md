# Pearl Inc. pour iPhone Duo : le premier jeu App Store

> **Statut : proposition, à valider entre associés (Jules, Mathys, Hugo).** Rien ici n'est encore une décision de AGENTS.md §6.
> Branche : `jules/duo-gadget`. Rédigé le 2026-10-08.
> S'appuie sur la page d'inscription « Pearl Inc. pour iPhone Duo » et sur le plan « Campagne Pearl Inc. — X & LinkedIn » (7 octobre).

## 1. L'idée en une phrase

Une app iOS native, petite et très soignée, appelée **Pearl Inc.**, où l'on **ouvre une huître en ouvrant son iPhone Duo** (ou du pouce sur un autre iPhone). C'est le premier produit du studio MJHstudio, et il sert à prouver qu'il y a un public avant de construire le jeu complet.

**Ce que ça n'est pas.** Ni une démo, ni une version au rabais : un jeu complet, réduit à son cœur, le geste d'ouverture.

## 2. Comment ça s'enchaîne avec la campagne

La campagne teste **l'envie** ; l'app teste **l'usage**. Elles ne se font pas en même temps :

| Dates | Ce qui se passe | Rôle de ce dépôt |
|---|---|---|
| 12 – 25 oct. | Campagne X et LinkedIn : semaine 1 l'huître, semaine 2 l'écrin ; page d'inscription + prototype navigateur (5 huîtres d'essai) | La webapp sert de prototype ; l'app native se **prépare** en coulisses (§9) |
| 16 oct. | Précommandes de l'iPhone Duo | — |
| 23 oct. | Sortie de l'iPhone Duo | Premiers essais de la charnière sur un vrai Duo |
| **25 oct.** | **Décision** : huître, écrin, ou l'huître d'abord puis la fusion | Le périmètre ci-dessous s'ajuste (§4) |
| Nov. | Construction et sortie de l'app | 1.0 sur l'App Store, puis mises à jour |

**Pourquoi pas le jour de la sortie du Duo ?** En 15 jours, il faudrait porter le jeu, passer l'examen d'Apple et mener la campagne, sans avoir jamais tenu un Duo en main pour régler la charnière. On risquerait de rater les trois. En sortant **3 à 4 semaines après le Duo**, on reste dans la fenêtre où l'App Store et la presse cherchent des apps qui exploitent la pliure. On arrive aussi avec un geste réglé sur le vrai appareil et une liste d'inscrits à prévenir.

## 3. Une seule app, qui grandira

- **Nom : Pearl Inc.**, sur l'App Store comme sur la page d'inscription. Le jeu complet arrivera **par mises à jour de la même app** : les joueurs, les notes et les collections sont gardés.
- **SwiftUI.** Cela tranche la question laissée ouverte en §1 de AGENTS.md (Capacitor ou SwiftUI). La charnière et Core Haptics sont natifs de toute façon, et c'est la recommandation du cahier §3.
- La webapp reste le **laboratoire** : on y essaie les nouvelles fonctions avant de les porter, et elle sert de prototype à la campagne.

## 4. Périmètre de la 1.0

### Le cœur (si l'huître l'emporte le 25 octobre)

Ce que promet la page d'inscription, ni plus ni moins :

| Élément | Détail | Repris de |
|---|---|---|
| **Téléphone fermé = l'huître** | L'écran extérieur montre la coquille posée sur le lagon ; les plus rares tremblent déjà | nouveau |
| **Ouvrir le téléphone = ouvrir l'huître** | Résistance (aimants + vibration), « pop », lumière de la couleur de la perle (noire si vide), zone fragile 20°–110°, lustre S/A/B/C | `core/opening.ts`, `core/lustre.ts`, `tuning.ts` |
| **Ouvert = la carte** | Taille, lustre, valeur, numéro de série ; révélation graduée selon la rareté ; badge « Pêché sur Duo » (cosmétique, cahier §3) | `features/oyster/` |
| **Refermer le téléphone = huître suivante** | Sur les autres iPhone : toucher la carte | nouveau |
| Pouce sur les autres iPhone | Glisser vers le haut, glissé freiné + vibration | `input/thumb.ts` |
| Haptique riche | Core Haptics : résistance qui monte, « pop » franc, craquement de fêlure, battement de cœur avant une perle rare | nouveau (le web n'a qu'un « tic ») |
| Les 8 perles, probabilités affichées | Table du cahier §5, garantie perle dorée ou mieux après 25 huîtres | `core/catalog.ts`, `core/draw.ts` |
| Perles uniques | Forme, reflet, marque rare | `core/pearlTraits.ts` |
| Collection | Encyclopédie des 8 perles + cartes triables | `core/collection.ts` |
| Premières minutes | Huîtres écrites à l'avance (rosée garantie en 1re), main fantôme | `core/tutorial.ts` |
| Stock d'huîtres | 10 max, 1 toutes les 20 min : la raison de revenir | `core/stock.ts` |
| **Perle de bienvenue** | Promise aux premiers inscrits (page d'inscription) : voir §6 | nouveau |
| Partage | Image story 1080×1920 via la feuille de partage iOS | `art/storyImage.ts` |
| Décor | Lagon turquoise animé, coquille et nacre dessinées par code | `art/lagoon.ts`, `art/shell.ts`, `art/pearl.ts` |
| Langues | Français et anglais (la campagne et la page sont bilingues) | nouveau (la webapp est en français seulement) |

### Si l'écrin l'emporte, ou pour la fusion

Le moteur est le même, la charnière et le pouce aussi (§7). Pour l'écrin, on remplace la coquille par l'écrin en cuir, la zone fragile par l'angle d'éclat, et les perles par les bijoux, repris de `core/glint.ts`, `core/jewels.ts` et `art/ecrin3d.ts`. L'architecture est pensée pour qu'aucun des deux choix ne fasse perdre de travail.

### Plus tard, par mises à jour (selon ce que disent les chiffres)

1. Écran extérieur enrichi et StandBy (vitrine de la plus belle perle), widget « huîtres disponibles ».
2. Trouvailles (les objets insolites), très partageables.
3. L'autre univers (écrin ou huître), puis niveaux, quêtes, rendez-vous quotidiens.
4. Atelier, Maison, et le reste du jeu complet.

### Exclu de la 1.0

Expertise, poussière d'or, atelier, Maison, niveaux, succès, quêtes, trouvailles, achats intégrés, pubs, compte, classement, bandeau « BÊTA ».

## 5. Règles Apple à respecter

| Règle | Ce qu'on fait |
|---|---|
| **4.2 Fonctionnalités minimales** (risque n° 1 pour un petit jeu) | Jeu complet : 8 raretés, collection, garantie, lustre, partage, rejouabilité quotidienne. Ne pas descendre en dessous. |
| **2.2 Pas de bêta sur l'App Store** | Pas de bandeau « BÊTA » ; les tests se font sur TestFlight. |
| **2.1 Complétude** | Aucun écran « à venir », aucun bouton mort, aucune mention des fonctions futures. |
| **3.1.1 Probabilités** | Rien de payant dans la 1.0. On affiche quand même les probabilités : c'est une promesse de la campagne (« toujours »). |
| **5.1 Vie privée** | Pas de compte, pas de suivi publicitaire, donc pas de fenêtre ATT. Étiquette de confidentialité de l'App Store remplie ; manifeste de confidentialité (`PrivacyInfo.xcprivacy`). |
| **Classification par âge** | Questionnaire rempli honnêtement : récompenses aléatoires, sans argent réel. |
| **Marques Apple** | Pas de « iPhone » ni « Duo » dans le nom ou l'icône. La description et la page peuvent dire que le jeu est conçu pour l'iPhone Duo, avec la mention de non-affiliation déjà présente sur la page. |

**Interface (Human Interface Guidelines)**
- **Zones sûres partout** : écran extérieur, écran intérieur, Dynamic Island, barre d'accueil ; passer d'un écran à l'autre sans perdre l'huître en cours.
- **Accessibilité** : Dynamic Type sur tous les textes ; VoiceOver avec une **action « Ouvrir l'huître »** (un jeu tout en geste doit offrir une autre façon de jouer) ; « Réduire les animations » respecté ; haptique coupée si l'utilisateur l'a désactivée.
- **Haptique** : Core Haptics quand l'appareil le permet, sinon les retours UIKit standard.
- Pas de texte ni de bouton dans les zones système, comme déjà dans la webapp.

## 6. La perle de bienvenue

La page promet que « les premiers inscrits auront une perle de bienvenue ». Sans compte ni serveur, la piste la plus simple :

- l'e-mail de lancement envoyé aux inscrits contient un **lien** (`pearlinc://bienvenue?code=…`, ou un lien universel) ;
- l'app vérifie le code **sans serveur**, puis offre une perle cosmétique exclusive (« Perle de la première marée ») qui n'entre ni dans les probabilités ni dans la garantie.

**À décider** : quelle perle exactement, un code commun ou un code par inscrit, et la date limite. Les codes d'offre d'Apple ne servent qu'aux achats intégrés, ils ne conviennent pas ici.

## 7. La charnière : ce qu'il faut vérifier

La page d'inscription fixe le comportement voulu : fermé, l'écran extérieur montre la coquille ; on ouvre, la lumière filtre ; ouvert, la carte se révèle ; on referme, l'huître suivante attend. Reste à savoir si iOS le permet. **À vérifier dès la sortie du SDK, puis sur un vrai Duo le 23 octobre :**

1. **L'API existe-t-elle, et dans quelle version d'iOS ?** Le cahier parle d'iOS 27.1.
2. **Que donne-t-elle ?** Un angle continu (idéal) ou seulement « plié / déplié » ? À quelle fréquence ? La zone fragile dépend de la vitesse : il faut au moins 30 mesures par seconde.
3. **Quel écran est allumé pendant l'ouverture ?** Si l'écran intérieur reste éteint jusqu'au bout, il faut tenir l'huître sur l'écran extérieur pendant le geste, puis faire passer la révélation à l'écran intérieur. **C'est la grande question d'UX.** Si l'angle n'est pas lisible pendant la pliure, il faudra un plan B (par exemple : déplier, puis finir l'ouverture au pouce).
4. **Plage d'angles réelle** (0–180° ?) et sens de la mesure.

Architecture : la charnière est **une source de geste de plus** (invariant n° 2), qui produit des `OpeningSample { angle, time }`. Le moteur ne sait pas d'où vient le geste. Si la charnière est absente, on bascule automatiquement sur le pouce (cahier §3).

## 8. Architecture

```
ios/
  PearlInc.xcodeproj
  PearlCore/          Swift Package, logique PURE (miroir de src/core) : aucun UIKit/SwiftUI
    Catalog, Random, Draw, Oyster, Opening, Lustre, Collection, Tutorial, Stock, PearlTraits
    (si besoin : Glint, Jewels pour l'écrin)
    Tuning            lit tuning.json (les mêmes valeurs que src/tuning.ts)
  PearlInc/
    Input/            GestureSource : ThumbSource, HingeSource → OpeningSample
    Art/              Lagon, coquille, nacre, perle, image story (SwiftUI Canvas)
    Platform/         Haptique (Core Haptics), sons, sauvegarde, partage, mesure d'usage
    Features/         Pêche, Carte, Collection, Premières minutes
    Localizable       Français, anglais
  PearlCoreTests/
```

- **Mêmes invariants que la webapp** : Core pur, une seule interface de geste, aucun nombre magique, hasard et temps injectés, perle tirée à la création de l'huître et sauvegardée.
- **Réglages partagés** : un script exporte `src/tuning.ts` et les catalogues en JSON. Les deux versions lisent les mêmes valeurs ; on règle à un seul endroit.
- **Tests de parité** : les tests TypeScript génèrent des cas de référence (même graine → même perle, même suite d'angles → même lustre et même fêlure). Les tests Swift doivent donner exactement les mêmes résultats.
- **À porter** : environ 600 lignes de Core et 1 300 lignes de dessin pour l'huître. C'est raisonnable.
- Pas de dépendance externe au départ.

## 9. Mesurer la traction

**Avant la sortie (campagne) :** le chiffre qui tranche, c'est **les inscriptions pour 1 000 impressions**, par univers et par réseau (voir le plan de campagne). Ce n'est pas le rôle de ce dépôt, sauf si le prototype de la page vient de la webapp.

**Après la sortie (l'app) :** est-ce que le geste fait revenir les gens et leur donne envie de partager ?

| Indicateur | Source | Seuil « ça marche » (proposition) |
|---|---|---|
| Inscrits qui installent (perle de bienvenue utilisée) | mesure d'usage | ≥ 30 % |
| Rétention J1 / J7 | App Store Connect (App Analytics) | ≥ 35 % / ≥ 12 % |
| Huîtres ouvertes par jour et par joueur | mesure d'usage | ≥ 8 |
| Part des perles ◆◆◆ et plus partagées | mesure d'usage | ≥ 10 % |
| Part des joueurs sur Duo | mesure d'usage | à observer |
| Fêlures et lustre S (équilibrage) | mesure d'usage | à observer |

La mesure d'usage reste centralisée dans un seul fichier (`Platform/Analytics`), comme `track()` dans la webapp. **Outil à choisir** : c'est une nouvelle dépendance, donc une décision en §6.

## 10. Calendrier proposé

| Dates | Étape |
|---|---|
| **12 – 22 oct.** (pendant la campagne) | Xcode, compte Apple Developer, nom réservé sur App Store Connect ; projet créé ; PearlCore porté avec les tests de parité ; ouverture au pouce jouable sans décor ; lecture de la documentation de la charnière |
| 23 – 25 oct. | Essais sur un vrai Duo (§7) ; **décision du 25** ; périmètre ajusté |
| 26 oct. – 6 nov. | Décor, révélation, haptique, sons, carte, collection, premières minutes, stock, partage, perle de bienvenue, anglais, accessibilité |
| 6 – 12 nov. | TestFlight (quelques inscrits volontaires) ; corrections ; fiche App Store (captures, vidéo du geste, textes FR/EN) ; dossier pour l'équipe éditoriale de l'App Store |
| ≈ 13 nov. | **Soumission** ; examen d'Apple (souvent 1 à 2 jours, sans garantie) |
| ≈ 17 – 20 nov. | **Sortie** ; e-mail aux inscrits avec la perle de bienvenue |

**Si on prend du retard**, on coupe dans cet ordre : perles uniques, anglais (en mise à jour), stock d'huîtres. On ne coupe ni le geste, ni l'haptique, ni la carte, ni le partage, ni la perle de bienvenue (c'est une promesse faite aux inscrits).

## 11. Ce qu'il faut avant de commencer

- [ ] **Xcode** (App Store, gratuit). Pour l'instant, seuls les outils en ligne de commande sont installés sur ce Mac.
- [ ] **Compte Apple Developer** (99 $/an) : au nom de qui ? Une personne, ou la société MJHstudio (il faut alors un numéro D-U-N-S, compter plusieurs jours). Cela décide du nom du vendeur affiché sur l'App Store.
- [ ] **Réserver le nom « Pearl Inc. »** sur App Store Connect dès que le compte existe, et vérifier qu'il ne pose pas de problème de marque.
- [ ] Un iPhone récent pour tester l'haptique ; un Duo dès sa sortie.
- [ ] **Accord entre associés** sur : SwiftUI, une seule app qui grandit, sortie en novembre plutôt que le 23 octobre, perle de bienvenue, seuils de traction. Ensuite, inscription en §6 de AGENTS.md.
