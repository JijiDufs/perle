# Pearl Inc. — Règles communes du projet

> **À lire en entier avant toute modification**, par un humain ou par une IA (Claude Code, ChatGPT, Codex, Cursor…).
> Ce fichier est la source de vérité du projet. `CLAUDE.md` ne fait que pointer ici.
> Si une règle gêne, on la change **ici, explicitement**, on ne la contourne pas dans le code.

## 1. Le projet en 30 secondes

Pearl Inc. (d'abord appelé « Perle ») est un jeu où l'on ouvre des huîtres pour révéler des perles. **Le geste d'ouverture est le jeu.**
Sur iPhone Duo (pliable), l'angle de la charnière pilotera l'ouverture ; sur iPhone classique, c'est un geste tactile.
Les deux appareils jouent **exactement le même jeu** : seule la source du geste change.

**Phase actuelle : prototype web** (installable sur l'écran d'accueil) pour valider l'UX. Le produit final passera sur l'App Store, soit en emballant ce code avec Capacitor (+ modules natifs pour l'haptique et la charnière), soit en réécrivant en SwiftUI. Ce choix sera fait après validation du geste.

- Cahier des charges complet : [docs/cahier-des-charges.md](docs/cahier-des-charges.md) (vision long terme, **pas** le périmètre actuel).
- Journal des passes entre associés : [docs/JOURNAL.md](docs/JOURNAL.md).
- Premier jeu App Store pour l'iPhone Duo (proposition, à valider) : [docs/duo-gadget.md](docs/duo-gadget.md).

## 2. Périmètre actuel : V1 « squelette »

Objectif : valider la **sensation** du geste. Le rendu reprend la direction visuelle du prototype Duo (voir §6), sans être le design final.

**Dans la V1**
- Une huître en 2D dessinée par code (Canvas), vue de dessus, ouverte en **glissant le pouce vers le haut** : le couvercle se soulève vers le haut de l'écran.
- Résistance au début, puis « pop » ; retour haptique (limité sur le web, voir §7).
- Lumière dans l'entrebâillement, de la couleur de la perle (noire si huître vide).
- Zone fragile : ouvrir trop vite entre 20° et 110° fêle la perle (valeur ÷ 2).
- Note de lustre S / A / B / C selon la régularité du geste.
- Tirage selon la table des 8 perles du cahier des charges (§5) + garantie : perle dorée ou mieux après 25 huîtres sans.
- Carte de révélation : nom, rareté, taille, valeur, numéro de série.
- Collection : encyclopédie (toucher une perle filtre ses cartes), cartes triables par rareté / récentes / valeur, carte agrandie au toucher.
- Écran de réglages (debug) pour ajuster en direct tous les paramètres du geste.
- Premières minutes (cahier §15) : 4 huîtres écrites à l'avance, bulles d'accompagnement, main fantôme qui montre le geste.
- Partage d'une carte (perle, bijou ou création) en image story 1080×1920 (feuille de partage iOS, ou téléchargement).
- **Écrin (V1.1, cahier §7)** : même geste que l'huître, sans fêlure ; angle d'éclat caché (55°–115°), le tenir immobile 0,9 s = éclat parfait (valeur ×1,5, carte holo), avec 12 % de chance de variante rare (Aurore, Nuit, Givre : valeur ×2, le bijou se transforme à l'écran). 10 raretés de bijoux du toc à la légende, garantie ★ après 20 écrins, probabilités affichées avant ouverture. Premier écrin offert à la fin du tutoriel (guidé), puis 1 toutes les 8 huîtres. Collection en deux volets : Perles / Bijoux.
- **Expertise à la loupe (cahier §7)** : sur les bijoux à pierre précieuse (saphir et mieux), promener une loupe (affichée au-dessus du doigt) sur la pierre ; les 3 à 5 inclusions ne se voient qu'à travers elle ; garder le viseur 0,35 s dessus pour les noter ; 20 s. Tout trouvé = certificat Excellent (+25 %), deux tiers = Bon (+12 %), sinon non concluant. Une seule tentative par bijou.
- **Poussière d'or (cahier §7)** : un doublon (perle ou bijou de même rareté déjà possédé) se fond en poussière d'or selon sa rareté (— 1, ◆ 2, ◆◆ 5, ◆◆◆ 12, ★ 40, ★★ 120 ✦) ; on garde toujours au moins un exemplaire. Fonte d'une carte (deux touchers) ou en lot (garde le plus bel exemplaire et tous les bijoux à éclat parfait, variante ou certificat). La poussière achète précisément une pièce manquante (prix = fonte × 5, carte marquée « poussière d'or », lustre B, sans toucher aux garanties) ou un écrin Velours (60 ✦). Comptoir dans la Collection, achat d'écrin aussi sur l'écran Écrin vide.
- Stock d'huîtres : 10 maximum, 1 qui revient toutes les 20 min (bêta) ; écran « La marée remonte… » avec compte à rebours quand il est vide.
- **Navigation** : onglets en bas, à portée de pouce (Pêche, Écrins, Collection), avec icônes, pastilles (écrins à ouvrir, nouvelles cartes) et transition dans le sens des onglets ; l'onglet Écrins est verrouillé jusqu'au premier écrin, puis s'illumine. Barre de ressources en haut : huîtres (avec le minuteur de recharge) et poussière d'or, qui rebondissent quand elles augmentent ; réglages derrière la roue dentée. Cartes « Nouveau » dans la collection jusqu'à la visite suivante.
- **Niveaux et réputation (cahier §8-9)** : chaque huître, écrin et certificat rapporte de la réputation (plus pour la rareté, le lustre S/A, les découvertes, l'éclat parfait). Anneau de niveau dans la barre du haut (« +N » à chaque gain). Montée de niveau : célébration plein écran avec récompenses (3 huîtres, au-delà du maximum possible ; 15 ✦ ; un écrin tous les 3 niveaux et à chaque rang) et prochain déblocage, montrée quand la carte est refermée (jamais pendant le tutoriel). Rangs du cahier (Pêcheur → Maison de haute joaillerie). Fiche « Ma progression » (toucher l'anneau) : niveau, statistiques, chemin des rangs, déblocages (ceux qui n'existent pas encore sont marqués « à venir »), barème de réputation.
- **Succès et titres (cahier §10)** : 24 succès bronze / argent / or (dont 2 secrets), avec poussière d'or et réputation ; certains donnent un titre à porter (affiché sous le rang). Bannière à l'obtention, au moment calme suivant ; volet « Succès » dans « Ma progression ».
- **Quêtes du jour (cahier §15)** : 3 quêtes tirées chaque jour (mêmes pour tous, renouvelées à minuit), pas pendant le tutoriel ; 10 ✦ + 30 de réputation chacune, un écrin quand les trois sont récupérées. Bouton dans la barre du haut (doré quand une récompense attend), bannière « Quête terminée ». Les réglages du prototype s'ouvrent depuis « Ma progression ».
- **La Maison (cahier §8), début du fil narratif** : 4e onglet, verrouillé pendant le tutoriel. La Maison de grand-mère Rose, sur pilotis au bout du ponton, en **maison de poupée vue en coupe de trois quarts** (on voit les pièces : boutique, atelier, bureau de Rose, grenier) ; chaque lettre rallume une pièce. Elle grandit avec le rang (étage, boutique repeinte, salon Pearl Inc., aile du musée, tour) et change de nom. 7 lettres débloquées par niveau (1 à 10) ; lire une lettre rapporte 20 ✦ + 20 de réputation et restaure un élément (porte, lanterne, enseigne, fenêtre et carnet, établi, vitrine avec ta plus belle pièce, boîte mystérieuse). Pastille sur l'onglet pour les lettres à lire, rappel dans la célébration de niveau. La 7e lettre amorce le mystère de la perle maudite ; la suite est annoncée au niveau 15.
- **Rendez-vous quotidiens (cahier §15)** : calendrier de connexion sur 7 jours (huîtres, poussière d'or, un écrin le 7e), ouvert tout seul une fois par jour (au lancement ou au retour dans l'app ; pas pendant la toute première séance) et depuis la fiche des quêtes. Série de jours consécutifs avec un joker par semaine (un jour manqué ne casse pas la série). Succès « Fidèle au ponton » (7 jours) et « La marée et moi » (30 jours).
- **L'Atelier (cahier §6), première version** : s'ouvre au niveau 5, depuis la Maison. Carnet de 8 recettes (pages retrouvées du niveau 5 au 12, dont le collier « Rivage » du cahier). Les perles viennent de la collection (les meilleures, en gardant si possible un exemplaire de chaque sorte) ; la monture se paie en poussière d'or. **Sertissage** : pincer deux doigts pour refermer les deux moitiés de l'établi (un doigt qui glisse vers le bas marche aussi) ; ni trop brusque ni trop hésitant. Note de 1 à 5 étoiles = qualité des perles (lustre, fêlure) × réussite du geste. Les créations ont leur volet dans la collection et peuvent prendre place dans la vitrine de la Maison.
- **Trouvailles (cahier §5)** : 5 % des huîtres cachent un objet à la place de la perle (pris sur l'huître vide et la perle blanche ; les perles rares ne bougent pas, la garantie non plus). 25 objets en 3 albums : « Le bric-à-brac du port » (humour du quotidien), « Clins d'œil » (pop culture, sans nommer d'œuvre ni de marque) et « Trésors engloutis » (pièce d'or → poussière d'or, clé d'épave → écrin, bouteille à la mer → un message, pierre brute). Lumière de la couleur de l'objet, qui vacille ; une trouvaille ne se fêle pas. Carte, partage, volet « Trouvailles » de la collection (visible après la première), un succès par album complété (titre + 1 écrin) et un succès secret.
- **Perles uniques et bijoux variés** : chaque perle a sa forme, son reflet et parfois une marque rare ; les bijoux ont 7 types, 22 modèles, plusieurs métaux et 8 tailles de pierre. Carnet des variantes dans la collection (toucher une case), succès associés.
- Icône provisoire (huître ouverte + perle), installation sur l'écran d'accueil (aide affichée sur iPhone après le tutoriel), mode hors ligne.

**Hors V1 — ne pas coder sans décision dans §6**
Atelier au-delà des recettes et du sertissage (création libre, parures, taille, fonte, polissage, gravure, temps de production, métaux et nacre), Maison au-delà des lettres et de la cabane (pièces, personnel, vitrine qui vend…), monnaies, écrins autres que Velours (Vintage, Saison, Couronne…), personnel (Expert), pubs récompensées, bourriche, social, 3D, assets graphiques, sons définitifs, charnière Duo (préparée par l'architecture, pas implémentée), framework UI (React, etc.).

## 3. Architecture (à respecter)

Stack : **TypeScript + Vite**, sans framework UI. Tests : **Vitest**.

```
src/
  tuning.ts         TOUS les paramètres réglables du geste et du tirage (un seul endroit)
  core/             Logique de jeu PURE : aucun accès au DOM, window, navigator, localStorage
    catalog.ts      Les perles : noms, raretés, probabilités, couleurs, valeurs
    rng.ts          Générateurs aléatoires (dont une version à graine pour les tests)
    draw.ts         Tirage + compteur de garantie
    oyster.ts       Création d'une huître (perle décidée AVANT l'ouverture)
    opening.ts      Moteur d'ouverture : machine à états, vitesse, zone fragile
    lustre.ts       Note de lustre
    player.ts       État du joueur : huître en cours, collection, numéros de série
    collection.ts   Tri (rareté, récentes, valeur) et filtre des cartes
    tutorial.ts     Premières huîtres écrites à l'avance, protection de la 1re perle
    stock.ts        Stock d'huîtres (énergie) : recharge dans le temps
    jewels.ts       Bijoux des écrins : raretés, probabilités, tirage + garantie
    glint.ts        Moteur de l'écrin : ouverture + angle d'éclat (éclat parfait)
    expertise.ts    Expertise à la loupe : inclusions, détection, note, certificat
    achievements.ts Succès, paliers, titres
    quests.ts       Quêtes du jour : tirage par jour, avancement
    progression.ts  Après chaque action : statistiques, quêtes, succès (appelé par le Core lui-même)
    daily.ts        Calendrier de connexion sur 7 jours, série de jours et joker
    atelier.ts      L'atelier : recettes, montures, choix des perles, fabrication, étoiles
    setting.ts      Moteur du sertissage : fermeture, durée, régularité, verdict
    house.ts        La Maison : lettres de grand-mère, déblocage, restauration
    levels.ts       Niveaux, réputation, rangs de prestige, récompenses de niveau, déblocages
    dust.ts         Poussière d'or : fonte des doublons, achat d'une pièce manquante ou d'un écrin
    finds.ts        Trouvailles : objets à la place de la perle, albums, tirage, messages des bouteilles
    pearlTraits.ts  Ce qui rend chaque perle unique : forme, reflet, marque rare
    appEconomy.ts   Économie de l'app iOS seulement : barème de revente, missions du jour, skins, produits de la boutique
  input/            Sources du geste → produisent des OpeningSample
    thumb.ts        Pouce vers le haut (iPhone classique)
    pinch.ts        Pincer deux doigts (sertissage), ou un doigt vers le bas
  art/              Dessin procédural (Canvas 2D) : décors (lagon, salon, Maison), coquille, nacre, perle, halo, bijoux, trouvailles en relief (finds.ts), écrin plat en cuir en 3D (ecrin3d.ts), établi, image story. Aucune règle de jeu
  platform/         Ce qui touche au navigateur : haptique, sons générés, sauvegarde, partage, mesure d'usage (analytics.ts)
  features/         Écrans : nav/ (onglets du bas, barre de ressources, icônes), progress/ (montée de niveau, « Ma progression », quêtes), house/ (La Maison), atelier/ (carnet, établi, cartes de création), oyster/ (dont coach.ts, textes du tutoriel), ecrin/, expertise/ (mini-jeu), dust/ (comptoir de la poussière d'or), collection/, tuning/, share/ (bouton Partager)
  main.ts           Point d'entrée, navigation entre écrans
tests/              Tests du Core et des entrées
public/
  sw.js             Service worker : mode hors ligne (build de production uniquement)
  icons/            Icônes générées par scripts/make-icons.py (ne pas éditer à la main)
  manifest.webmanifest
scripts/            Outils (génération des icônes, aperçu des liens, planche des skins `make-skin-sheet.sh` → docs/skins.png ; macOS)
site/               Page d'inscription pearl-inc.app (HTML autonome, prototype de 5 huîtres) : hors de la build Vite
ios/                App iOS native (SwiftUI) : PearlCore (Swift Package, logique pure, miroir de src/core) + PearlInc (l'app).
                    Catalogues et réglages exportés depuis src/ par `npm run ios:export` (voir docs/duo-gadget.md §8)
```

### Les invariants — ne jamais casser

1. **Core est pur.** Rien dans `src/core/` ne touche au DOM, à `window`, `document`, `navigator` ou `localStorage`, et rien n'y importe `platform/`, `features/` ou `input/`. Un test vérifie automatiquement cette règle (`tests/core-purity.test.ts`).
2. **Une seule interface de geste.** Toute source de geste (pouce, charnière, autre) produit des `OpeningSample { angle: number /* degrés, 0…180 */, time: number /* ms */ }`. Le moteur calcule lui-même la vitesse. Aucune vue ne décide d'une règle de jeu.
3. **Aucun nombre magique.** Probabilités, seuils, angles, vitesses, durées : uniquement dans `src/tuning.ts` ou les catalogues du Core (`catalog.ts`, `jewels.ts`, `finds.ts`, `pearlTraits.ts`, `appEconomy.ts`). Les valeurs viennent du cahier des charges ; si on s'en écarte, on le note dans §6.
4. **Hasard injectable.** Le tirage reçoit un générateur aléatoire en paramètre (graine fixe dans les tests). Le temps (`now`) est aussi passé en paramètre.
5. **La perle est tirée à la création de l'huître** et sauvegardée avec l'état du joueur : recharger la page ne relance pas le tirage.
6. **`npm test` et `npm run build` passent avant chaque passe** (et `swift test` dans `ios/PearlCore` si on touche à l'app iOS ou aux catalogues). Pas de test cassé laissé à l'associé. Après un changement de catalogue ou de réglage : `npm run ios:export`.
7. **Les vues ne contiennent pas de règles.** Une vue affiche un état et transmet des gestes, c'est tout.
8. **Mesure d'usage centralisée.** Les écrans appellent seulement `track()` de `src/platform/analytics.ts`. L'outil d'analytics se branche dans ce seul fichier.

### Machine à états de l'ouverture

`closed → resisting → opening → revealed`
Événements émis : `pop` (passage resisting → opening), `crack` (fêlure en zone fragile), `reveal` (avec le lustre).
Relâcher pendant `resisting` → retour à `closed` (la coquille se referme). Relâcher pendant `opening` → la coquille reste entrouverte.

| Paramètre (`src/tuning.ts`) | Valeur de départ | Source |
|---|---|---|
| Angle du « pop » | 15° | à régler |
| Distance de pouce avant le pop | 70 pt | réglé pour une main (§6) |
| Distance de pouce du pop à 180° | 260 pt | réglé pour une main (§6) |
| Zone fragile | 20° – 110° | cahier §5 |
| Vitesse max sans fêlure dans la zone fragile | 380 °/s | relevée avec la course raccourcie (§6) |
| Angle de révélation | 140° | à régler |
| Ouverture automatique en lâchant au-delà de | 115° (écrin : 121°) | une main (§6) |
| Suspense avant la carte, par rareté | 250 / 700 / 1200 / 2000 ms | à régler (note de Mathys : révélation à la FUT / Clash Royale) |
| Garantie perle dorée+ | 25 huîtres | cahier §5 |
| Stock d'huîtres maximum | 10 | cahier §5 |
| Recharge d'une huître | 20 min | cahier §5 dit 30 ; 20 pendant la bêta (§6) |
| Écrin : plage de l'angle d'éclat | 55° – 115° | resserrée pour une main (§6) |
| Écrin : tolérance / temps à tenir / vitesse « immobile » | 6° / 900 ms / 45 °/s | prototype Duo (cahier §7 : « une seconde ») |
| Écrin : éclat parfait | valeur ×1,5 | cahier §7 |
| Écrin : variante rare sur éclat parfait | 12 % de chance, valeur ×2 | proposition (§6) |
| Garantie bijou ★ ou mieux | 20 écrins | cahier §7 |
| Huîtres pour gagner un écrin | 8 | bêta (§6) |
| Expertise : durée / temps sur une inclusion / tolérance | 20 s / 350 ms / 0,09 × rayon | proposition (§6) |
| Expertise : bonus Excellent / Bon | +25 % / +12 % | proposition (§6) |
| Poussière d'or par doublon fondu (— ◆ ◆◆ ◆◆◆ ★ ★★) | 1 / 2 / 5 / 12 / 40 / 120 ✦ | proposition (§6) |
| Prix d'une pièce manquante | fonte × 5 | proposition (§6) |
| Prix d'un écrin en poussière d'or | 60 ✦ | proposition (§6) |
| Réputation : huître / par niveau de rareté / lustre S, A / découverte | 10 / 5 / 10, 5 / 30 | proposition (§6) |
| Réputation : écrin / éclat parfait / certificat | 25 / 15 / 20 | proposition (§6) |
| Réputation pour passer du niveau n à n+1 | 60 + 15 × n^1,5 | vise le niveau 50 en 4 à 6 mois (cahier §9) |
| Récompense de niveau | 3 huîtres, 15 ✦ ; 1 écrin tous les 3 niveaux et à chaque rang | proposition (§6) |
| Succès bronze / argent / or | 10 / 30 / 80 ✦, + 40 de réputation | proposition (§6) |
| Calendrier de connexion (jours 1 à 7) | 3 huîtres · 20 ✦ · 5 huîtres · 30 ✦ · 5 huîtres · 50 ✦ · 1 écrin + 30 ✦ ; + 15 de réputation par jour | cahier §15 (écrin le 7e) ; montants : proposition (§6) |
| Sertissage : durée idéale / régularité / parfait à partir de | 350 – 1000 ms / CV ≤ 1,2 / score 0,85 | à régler sur iPhone |
| Sertissage : écart des doigts à refermer | 140 pt | à régler sur iPhone |
| Atelier : montures (argent / or / or rose / platine) | 10 / 25 / 30 / 60 ✦ | proposition (§6) |
| Atelier : étoiles | 1 + 4 × (0,4 × matériaux + 0,6 × geste) | cahier §6 (« matériaux × réussite du geste ») |
| Lettre de la Maison lue | 20 ✦ + 20 de réputation | proposition (§6) |
| Quêtes du jour | 3 par jour ; 10 ✦ + 30 de réputation chacune ; les trois = 1 écrin | cahier §15 (« trois quêtes du jour ») |
| App iOS : pub récompensée | 3 huîtres par pub, 3 pubs par jour | choix de Jules (§6) |
| Trouvailles : part des huîtres | 5 % (huître vide 12 → 9 %, perle blanche 40 → 38 %) | choix de Jules (§6) |
| Trouvailles : poids par rareté (◆ ◆◆ ◆◆◆ ★ ★★) | 40 / 18 / 12 / 5 / 2 | proposition (§6) |
| Pièce d'or / clé d'épave / album complété | 15 ✦ / 1 écrin / 1 écrin | proposition (§6) |

## 4. Conventions

- **Langue :** code (types, fonctions, variables) en anglais ; commentaires, textes du jeu et documentation en français.
- TypeScript strict. Pas de nouvelle dépendance npm sans décision dans §6.
- Un fichier = une responsabilité. Noms explicites, pas d'abréviations.
- Ne pas renommer ni déplacer de fichiers dans `src/core/` sans le noter dans le journal.
- Petites modifications ciblées : ne pas « nettoyer » ou reformater du code qui n'a rien à voir avec la tâche.
- Commandes : `npm install`, `npm run dev` (ouvre aussi l'adresse réseau pour tester sur iPhone), `npm test`, `npm run build`, `npm start` (build + version de production sur le port 4173, avec le mode hors ligne), `npm run icons` (régénère les icônes), `npm run ios:export` (exporte catalogues, réglages et cas de référence vers `ios/`), `swift test` dans `ios/PearlCore` (moteur Swift).
- Toute modification de `public/sw.js` qui change la façon de mettre en cache : incrémenter `CACHE_VERSION`.
- **Barre d'état, Dynamic Island, barre d'accueil** (jeu installé sur l'écran d'accueil, iPhone) : rien d'interactif ni de texte dans ces zones. En CSS, toujours `var(--safe-top|bottom|left|right)`, `--hud-h` et `--tab-h` (définis sur `:root`), jamais `env(safe-area-inset-*)` directement : les variables se simulent dans le navigateur pour tester (ex. `--safe-top: 59px; --safe-bottom: 34px` pour un iPhone 15 Pro). Toute nouvelle fenêtre plein écran prévoit ces marges.
- Transitions : pas de fondu entre deux contenus opaques (on lit les deux superposés). Les écrans glissent (`main.ts`), les panneaux plein écran montent depuis le bas.

## 5. Protocole de passe (entre associés et entre IA)

**Avant de commencer**
1. Lire ce fichier + la dernière entrée de [docs/JOURNAL.md](docs/JOURNAL.md).
2. Récupérer la dernière version (`git pull`) et travailler sur une branche dédiée (`jules/…`, `associe/…`).

**Avant de rendre la main**
1. `npm test` et `npm run build` passent.
2. Ajouter une entrée en haut de `docs/JOURNAL.md` : ce qui a changé, ce qui reste à faire, ce qui est fragile.
3. Si une décision a été prise, l'ajouter dans §6 ci-dessous.
4. Commit + push de la branche ; fusion dans `main` seulement si tout est vert.

**Pour l'IA qui travaille sur le projet :** si une demande contredit ce fichier, le signaler et demander avant d'agir, au lieu de casser une règle en silence.

## 6. Décisions prises

Ne pas revenir sur une décision sans en discuter entre associés. Ajouter les nouvelles en bas.

| Date | Décision | Pourquoi |
|---|---|---|
| 2026-10-05 | V1 = huître seule, l'écrin viendra en V1.1 | Valider d'abord une seule sensation, parfaitement |
| 2026-10-05 | Geste iPhone classique = pouce vers le haut | Une main, évoque un couvercle qu'on soulève ; le pincement est gardé pour le sertissage (atelier) |
| 2026-10-05 | Rendu V1 en 2D, pas de 3D | Itérer vite sur l'UX ; 3D après validation du geste |
| 2026-10-05 | UX d'abord, design / textures / UI dans une phase 2 | Si le geste n'est pas bon en formes grises, aucun visuel ne le sauvera |
| 2026-10-05 | Les perles seront rendues par shader paramétrique (phase 2), pas en images | Couleur, irisation, forme, fêlure, lustre = paramètres → variantes infinies |
| 2026-10-05 | Prototype en **webapp** (TypeScript + Vite, sans framework), installable sur l'écran d'accueil | Pas besoin de Mac/Xcode, test par simple lien, itération rapide ; la logique et les réglages validés se transposent à l'app native |
| 2026-10-05 | Garantie : après 25 huîtres d'affilée sans perle dorée ou mieux, la 26e est tirée parmi dorée / géante / maudite, au prorata de leurs probabilités | Interprétation du cahier §5, à confirmer |
| 2026-10-05 | Valeurs et tailles des perles provisoires (monnaie fictive), le cahier ne les précise pas | À équilibrer plus tard |
| 2026-10-05 | Révélation graduée en 4 niveaux (`revealTier` dans le catalogue) : plus la perle est rare, plus le suspense est long (pulsations, éclat, vibrations) | Note de Mathys : animations « inoubliables et addictives » façon FUT / Clash Royale |
| 2026-10-05 | Bandeau « BÊTA » visible en permanence | Note de Mathys : annoncer la bêta |
| 2026-10-05 | Direction visuelle provisoire = celle du prototype Duo de Jules (`docs/reference/prototype-duo.html`) : eau profonde, Young Serif + Figtree, coquille et nacre dessinées par code, sons générés. Remplace les « formes grises » | Les formes grises étaient trop pauvres pour juger le frisson de l'ouverture |
| 2026-10-05 | Couleurs, halos, tailles, valeurs et textes d'ambiance des perles repris du prototype Duo | Travail déjà fait et validé par Jules |
| 2026-10-05 | Tutoriel : huîtres 1 à 4 = rosée, blanche, vide, baroque ; la 1re ne peut pas se fêler ; la zone fragile est expliquée sur la 2e | Cahier §15 : première perle rosée garantie, une huître vide pour le hasard, zone fragile par l'exemple. La baroque finit le tutoriel sur une note ◆◆ |
| 2026-10-05 | Stock : 10 huîtres max, recharge **20 min** pendant la bêta (cahier : 30) ; les 4 huîtres du tutoriel sont offertes | Sans atelier, écrins ni pubs, il n'y a rien d'autre à faire quand le stock est vide : 30 min (5 h pour un plein) ferait fuir les bêta-testeurs. 20 min = un plein en 3 h 20, soit 3 à 5 sessions par jour comme visé au cahier §2. Repasser à 30 min quand l'atelier et les pubs arrivent ; abonnement = moitié du temps gratuit |
| 2026-10-05 | Écrins Velours gagnés : le 1er à la fin du tutoriel, puis 1 toutes les **8 huîtres** | Le cahier les lie aux niveaux, commandes et coffre quotidien, absents de la V1. 8 huîtres ≈ une session, soit « 5 à 10 huîtres, 1 écrin » (cahier §4) ; le 1er écrin guidé suit la chronologie du cahier §15 |
| 2026-10-05 | Raretés, probabilités, noms, métaux, valeurs et textes des bijoux repris du prototype Duo ; estimations en euros avec la mention « Estimation fictive » | Cahier §17 |
| 2026-10-05 | Les bijoux se classent par niveau (toc 0 … légende 5), pas par probabilité | Le toc (14 %) est plus rare que l'argent (20 %) mais ne vaut rien |
| 2026-10-05 | Pas de fausse demande pour l'instant | App compagnon séparée (cahier §12) |
| 2026-10-05 | **Variante rare** (cahier §7, non détaillée) = 3 variantes cosmétiques Aurore / Nuit / Givre (métal, pierre, cadre, texte), 12 % de chance sur un éclat parfait, valeur ×2 au lieu de ×1,5. Tirée à l'ouverture de l'écrin et sauvegardée ; affichée dans « Probabilités ». **Provisoire, à valider avec Mathys** | Un moment rare et visible (le bijou se transforme) qui récompense la précision, sans toucher aux probabilités des raretés |
| 2026-10-05 | **Expertise à la loupe** : seulement les pierres précieuses (saphir, émeraude, rubis, diamant, légende) ; inclusions fixes par carte (graine = n° de série) ; repérage en tenant le viseur (pas de faux clic pénalisant) ; une seule tentative, et fermer en cours de route termine l'expertise. **Provisoire, à valider avec Mathys** | Cahier §7 ne détaille pas ; même logique « tenir immobile » que l'écrin ; empêcher de relancer jusqu'à réussir |
| 2026-10-05 | **Ouverture à une main** (retour de test iPhone de Jules) : course du pouce raccourcie (révélation à 267 pt au lieu de 378) et, lâché au-delà de 115° (écrin : après la zone de l'angle d'éclat), le couvercle finit seul. Vitesses rapportées à la nouvelle course ; angle d'éclat resserré à 55–115° ; lustre mesuré dans la zone fragile seulement ; réglages sauvegardés sous une nouvelle clé (`perle.tuning.v2`) | On ne pouvait pas ouvrir d'une traite en tenant le téléphone d'une main ; passé la zone fragile il n'y a plus rien à jouer |
| 2026-10-05 | **Poussière d'or** : une « pièce » = une case de l'encyclopédie (sorte de perle, ou rareté de bijou). On ne fond que des doublons (jamais le dernier exemplaire) ; on n'achète que des pièces jamais obtenues. Barème par rareté, prix = fonte × 5, carte achetée ordinaire (lustre B, pas d'éclat parfait) et marquée. **La poussière achète aussi des écrins (60 ✦)** : écart au cahier §7, demandé par Jules. **Barème provisoire, à valider avec Mathys** | Cahier §7 et §9 : « personne ne reste bloqué ». ≈ 6 ✦ par huître en moyenne si tout est en double : un écrin ≈ 10 huîtres de doublons (le gratuit reste plus rapide, 8 huîtres), une perle dorée manquante 200 ✦ ≈ 30 huîtres, une maudite 600 ✦. Fondre les bijoux d'un écrin rapporte ≈ 7 ✦ : on ne peut pas enchaîner les écrins en fondant |
| 2026-10-05 | **Navigation** : onglets en bas plutôt qu'en haut ; ressources (huîtres, poussière) en haut, sur tous les écrans ; fonctions débloquées une à une (Écrins après le tutoriel). Le compteur d'huîtres sous la coquille est remplacé par celui du haut | Retour de Jules : on ne sentait pas l'évolution du jeu. Jeu à une main : le pouce atteint le bas, pas le haut. Cahier §15 : les fonctions arrivent une à une |
| 2026-10-05 | **Niveaux et réputation** avant l'atelier : la réputation vient des huîtres, écrins et expertises ; le niveau se déduit de la réputation, les récompenses sont données une seule fois (`rewardedLevel`). Les rangs et déblocages du cahier s'affichent, ceux qui n'existent pas encore marqués « à venir ». Les huîtres gagnées en montant de niveau peuvent dépasser le maximum. Les joueurs existants repartent du niveau 1. **Barème provisoire, à valider avec Mathys** | Retour de Jules : sentir l'évolution dès la bêta. Courbe : ≈ 200 de réputation par session, 4 sessions par jour, ≈ 100 000 pour le niveau 50, soit 4 à 6 mois (cahier §9). Montrer l'horizon (cahier §15) |
| 2026-10-05 | **Succès et quêtes du jour.** Statistiques, quêtes et succès sont mis à jour dans le Core après chaque action (`progression.ts`). Quêtes tirées avec une graine = la date (heure locale du téléphone). Les célébrations (succès, quête terminée, niveau) attendent un moment calme, jamais pendant la révélation ni le tutoriel. Une ancienne sauvegarde reçoit ses succès déjà remplis au chargement, sans bannière. La roue des réglages quitte la barre du haut pour « Ma progression ». **Liste et barème provisoires, à valider avec Mathys** | Retour de Jules : sentir l'évolution ; raison de revenir chaque jour (cahier §15) ; ne pas gâcher la surprise de la carte |
| 2026-10-05 | **La Maison en 4e onglet**, début du fil narratif : la grand-mère s'appelle **Rose** (clin d'œil à la première perle, rosée) et la Maison « Maison Rose, perles fines ». Lettres débloquées par niveau, chacune restaure un élément de la cabane. Les fonctions annoncées (atelier, recettes) sont marquées « prochaine version ». **Prénom, textes et rythme provisoires, à valider avec Mathys** | Choix de Jules : commencer le fil narratif tout de suite. Cahier §8 (carnet incomplet, boutique à l'abandon, mystère de la perle maudite) et §15 (horizon de la boutique abandonnée) |
| 2026-10-05 | **Calendrier de connexion** : une case par jour où l'on vient (pas forcément consécutifs), on recommence après la 7e. **Série** : jours consécutifs ; un seul jour manqué est rattrapé par le joker s'il n'a pas servi dans les 7 derniers jours. Le jour suit l'heure du téléphone, comme les quêtes. **Montants provisoires, à valider avec Mathys** | Cahier §15 : « calendrier de connexion sur 7 jours, avec un écrin le 7e jour » et « série de jours consécutifs, avec un joker par semaine » |
| 2026-10-05 | **Atelier V1** : dans la Maison plutôt qu'en 5e onglet. Recettes seulement (la création libre viendra). En attendant les métaux, la nacre et les coquillages, **les montures se paient en poussière d'or**. Le sertissage est une nouvelle source de geste (`input/pinch.ts`, `SettingSample`), prête pour la charnière du Duo. Fabriquer consomme les perles, mais garde si possible un exemplaire de chaque sorte (sinon un avertissement). **Recettes, prix et réglages provisoires, à valider avec Mathys** | Choix de Jules : continuer avec l'atelier. Cahier §6 : l'établi, la pliure, le pincement sur iPhone classique, les étoiles ; garder le geste au centre |
| 2026-10-05 | **Écrans plein cadre** : le fond de chaque écran passe sous la barre du haut et les onglets ; le contenu se décale avec `--hud-h` / `--tab-h`, les scènes dessinées se centrent dans `visibleBand()`. Cible : iOS 16.4+ (`:has()`, requêtes de conteneur) | Retour de Jules : fond coupé derrière les onglets ; tenir aussi sur iPhone SE |
| 2026-10-05 | **Refonte visuelle, direction « lagon lumineux + luxe »**, tout en code (pas d'images) : la Pêche se passe dans un lagon turquoise animé (`art/lagoon.ts`), les écrins dans un salon de joaillier (`art/salon.ts`), l'écrin est un étui plat de joaillier en cuir dessiné en 3D, dont le couvercle s'ouvre avec le geste (`art/ecrin3d.ts`, piste choisie par Jules) ; collection, fenêtres et cartes prennent un style « maison de joaillerie » (bleu nuit, or, nacre, motif d'écailles). Lève la règle « design en phase 2 » pour l'ambiance | Retour de Jules : le jeu était terne. Choix de Jules : tout en code animé (léger, hors ligne, réglable) ; ambiance lagon pour la pêche, luxe pour le reste |
| 2026-10-05 | Pas de mise en ligne pour l'instant : tout est construit et testé en local | Choix de Jules |
| 2026-10-06 | **UX de rétention et rendu des objets/Maison** : mettre en avant la quête active à la Pêche, la progression de l'encyclopédie et la prochaine lettre / pièce maîtresse de la Maison. Enrichir les matières des perles, les tailles de gemmes et les détails de la cabane en dessin procédural. Garder la DA « lagon lumineux + luxe » et les règles / probabilités actuelles. | Choix de Jules : retravailler toute l'UX et la rétention, les objets et la Maison, en conservant la DA existante |
| 2026-10-06 | **Carte des marées (concept)** : montrer La Crique puis le Jardin d’algues, l’Épave des échos et la Faille d’azur comme destinations à venir. Les objets insolites illustrent le catalogue futur uniquement ; ils ne sont ni tirés ni déblocables en V1. Aucun changement aux probabilités ou aux règles sans décision séparée. | Choix de Jules : rendre l’évolution du jeu visible par une carte et des trouvailles possibles |
| 2026-10-06 | **Le jeu s'appelle Pearl Inc.** (nom de l'app, de l'icône, partage, dorures des écrins). La Maison de grand-mère Rose garde son enseigne « Maison Rose, perles fines » jusqu'au rang de **Joaillier** (niveau 20), puis devient **Pearl Inc.**, la maison de joaillerie du joueur. Les clés de sauvegarde (`perle.*`) ne changent pas, pour ne perdre aucune partie | Choix de Jules ; le nouveau nom devient une récompense de progression |
| 2026-10-06 | **Trouvailles à la place de la perle** (cahier §5) : 5 % des huîtres, pris sur l'huître vide (12 → 9 %) et la perle blanche (40 → 38 %) ; les perles ◆◆ et plus, et la garantie perle dorée, ne changent pas (pas de trouvaille sous garantie). Ton : humour du quotidien et clins d'œil à la pop culture, **jamais de nom d'œuvre, de personnage ni de marque** (App Store). Une trouvaille ne se fêle pas. Un album complété donne un écrin (cahier §10). **Probabilités, liste et textes provisoires, à valider avec Mathys** | Choix de Jules : « des easter eggs en référence à la pop culture pour avoir du fun », rares quand même. Écart au cahier §5 (probabilités des perles) |
| 2026-10-06 | **Perles uniques** : chaque perle tire une forme (ronde, presque ronde, goutte, bouton, cerclée, baroque), un reflet (argenté, crème, rose… vert paon, arc-en-ciel) et, 4 % du temps, une marque rare (jumelle, étoilée, lunaire, en cœur) ; ils changent la valeur, pas la rareté. **Bijoux variés** : 7 types (pendentif et broche ajoutés, diadème dès le rubis), 22 modèles, plusieurs métaux par rareté, 8 tailles de pierre. Une perle marquée n'est jamais fondue en lot. Tables dans `core/pearlTraits.ts` et `core/jewels.ts`. **Listes et poids provisoires, à valider avec Mathys** | Choix de Jules : « plus de possibilités perles / bijoux » ; cahier §5 (« variantes infinies ») et §7 (type × métal × poids) |
| 2026-10-06 | **Transitions** : les écrans glissent latéralement dans le sens des onglets (l'ancien part pendant que le nouveau arrive), les panneaux plein écran (atelier, expertise) montent depuis le bas. Plus de fondu : il superposait deux écrans | Retour de Jules : « le fondu enchaîné est un peu buggé » |
| 2026-10-06 | **Jauge de réglage masquée par défaut** (angle, vitesse) : outil du prototype, réactivable dans les réglages. Le message sous la coquille donne déjà « Zone fragile » et « Trop vite ! » | Chasse aux détails qui font « cheap » (retour de Jules) |
| 2026-10-08 | **La Maison en maison de poupée** (vue en coupe de trois quarts, dessinée par code) : boutique (porte, vitrine) et atelier (établi) au rez-de-chaussée, bureau de Rose (fenêtre, carnet) et grenier (la boîte) à l'étage ; une pièce dort (pénombre, draps, toiles d'araignée) jusqu'à sa lettre. **Elle grandit avec le rang** (`houseStage`) : l'étage à Perlier, la boutique repeinte à Artisan, le salon Pearl Inc. à Joaillier, l'aile du musée à Maître joaillier, la tour à Maison de haute joaillerie. Les pièces au-delà des lettres (salon, musée) sont du décor : elles n'ouvrent aucune fonction pour l'instant | Choix de Jules : « maison de poupée en 3/4 » qui grandit jusqu'à Pearl Inc. ; cahier §8 (« chaque chapitre débloque une pièce de la Maison ») |
| 2026-10-08 | **Mise en ligne de la page d'inscription** (`site/`) sur Vercel, domaine **pearl-inc.app**, pour la campagne X / LinkedIn du 12 au 25 octobre. Inscriptions par Tally, seulement après les 5 huîtres d'essai (ou sur demande). Remplace « pas de mise en ligne pour l'instant » pour cette page ; le jeu (webapp) reste en local | Choix de Jules : teaser du lancement et mesure de l'intérêt avant de construire l'app (voir `docs/duo-gadget.md`, `docs/tally-formulaire.md`) |
| 2026-10-08 | **App iOS en SwiftUI** dans `ios/` : `PearlCore` (Swift Package, logique pure) + `PearlInc` (l'app, iOS 18+). Les catalogues et réglages restent définis dans `src/` et sont exportés en JSON (`npm run ios:export`) ; des cas de référence garantissent que le Swift donne exactement les mêmes résultats que le TypeScript. Tranche « Capacitor ou SwiftUI » (§1) | Choix de Jules : préparer l'app de l'App Store pendant la campagne. Charnière (`DeviceHinge`, iOS 27.1) et Core Haptics sont natifs ; une seule source de vérité pour l'équilibrage |
| 2026-10-08 | **Périmètre de la 1.0 App Store** : l'huître et les 8 perles, les trouvailles (easter eggs), la poussière d'or (revente des doublons), les skins **bénitier** et **huître d'or**, et une **boutique payante** : recharge d'huîtres, poussière d'or, skins (détail : `docs/duo-gadget.md` §4, §6 bis, §6 ter). Lève « monnaies » et « boutique payante » hors V1 pour l'app iOS seulement. **Prix et garde-fous (probabilités avant achat, Belgique, pièces ★ non achetables) à valider entre associés** | Choix de Jules : un jeu court mais complet, qui prouve la traction et le revenu |
| 2026-10-08 | **Poussière d'or lente dans l'app iOS** : barème de revente plus bas que la webapp (◆ 1 … ★★ 40 ✦), **3 missions du jour** à 5 ✦ (+ 10 ✦ les trois), bénitier à **2 000 ✦** (≈ 3 semaines de jeu régulier) ou 2,99 €, packs de poussière moins avantageux que l'achat direct du skin (détail : `docs/duo-gadget.md` §6 quater). La webapp garde son barème. **Montants provisoires, à ajuster avec les chiffres de la bêta** | Choix de Jules : ne pas gagner la poussière trop vite, pour que payer un skin ait du sens ; les missions donnent une raison de revenir chaque jour |
| 2026-10-13 | **Comptes joueurs dans l'app iOS avec Supabase** (paquet Swift `supabase-swift`) : Sign in with Apple, code par e-mail, ou partie sans compte (anonyme, liable plus tard). Écran de connexion avant le jeu. La webapp ne change pas. **Hébergement UE, synchronisation de la progression et lien avec les inscrits à valider** | Code de Jules ; §8 proposait Supabase EU pour relier un bêta-testeur à son futur compte |
| 2026-10-13 | **App iOS : direction artistique du prototype de pearl-inc.app** (lagon de `src/art/lagoon.ts` porté en Swift : sable, caustiques, récif, algues, poissons, bulles ; verre clair ; cartes aux couleurs de chaque perle ; collection en cases comme le prototype). **Bénitier redessiné vu de dessus** (éventail à gros plis écailleux, porcelaine, manteau bleu-vert tacheté), il s'ouvre comme l'huître. Correction : pendant le suspense, l'écran montrait déjà la perle de l'huître suivante | Retour de Jules : « l'app fait cheap », « la perle change au dernier moment », bénitier pas dans le ton |
| 2026-10-13 | **App iOS : la poussière d'or n'achète plus de perles** (skins et huîtres seulement). **Pub récompensée** : 3 huîtres par pub, 3 par jour, sur l'écran « La marée remonte… » et dans la boutique ; **pub simulée** tant que la régie n'est pas choisie (`Platform/RewardedAds.swift`). **Achats intégrés StoreKit 2** branchés (consommables, skins, restauration ; fichier de test `ios/PearlInc.storekit`). Lève « pubs récompensées » hors V1, pour l'app iOS seulement. **Montants provisoires** | Choix de Jules : on pêche ses perles, on ne les achète pas ; la pub donne une autre façon de continuer quand la marée est basse |

## 7. Limites connues du prototype web

- **Haptique :** Safari iOS ne permet pas la vibration officiellement. On utilise une astuce non officielle (interrupteur `<input switch>`, iOS 18+) qui ne donne qu'un « tic » simple. Les vibrations riches viendront avec l'app native.
- **HTTPS obligatoire** pour le mode hors ligne (service worker) et la feuille de partage : ils marchent sur `localhost` mais PAS sur `http://192.168.x.x` depuis un iPhone. Pour les tester sur téléphone, il faudra une adresse HTTPS (mise en ligne ou tunnel).
- **Charnière Duo :** illisible depuis une page web. Viendra avec l'app native (module Capacitor ou SwiftUI) en implémentant une nouvelle source dans `input/`.

## 8. Notes de Mathys (cahier des charges, surlignées en vert) — suivi

| Note | Statut |
|---|---|
| Rendre chaque animation inoubliable et addictive (FUT, Clash Royale…) | **V1 : structure en place** (révélation graduée par rareté). Le spectacle visuel viendra en phase 2. |
| Une perle encore plus rare, à 0,1 % | **À décider** : nom, et quelle perle cède ces 0,1 % (la somme doit rester 100 %). |
| Chaque décor doit être ultra beau | Phase 2 (design). |
| Classement « nombre d'huîtres ouvertes » | Après la bêta : demande un serveur et des comptes. |
| Vidéo d'ouverture avec réaction caméra : voir si Apple est d'accord | Plus tard. À vérifier dans les règles App Store au moment de l'app native. |
| Boutique payante (cosmétiques) | Hors V1. |
| Communauté X / tech à ne pas négliger ; tweet du compte certifié de Mathys | **Bêta** : il faut une URL publique et un bel aperçu de lien (image Open Graph). |
| Lancer des tests web cette semaine | **En cours** : prototype jouable, reste à le mettre en ligne. |
| Suivre le comportement des joueurs | **V1 : `track()` en place, stockage local.** Reste à choisir l'outil (PostHog EU proposé) et à ajouter le consentement RGPD. |
| Icône d'app avec une mascotte (pêcheur…), faite avec ChatGPT | **Icône provisoire en place** (huître + perle, `scripts/make-icons.py`). Pour la mascotte : déposer un PNG carré 1024×1024 sans transparence, puis remplacer les fichiers de `public/icons/` (180, 192, 512, 32). |
| V1 = j'ouvre, je stocke, on observe ; bêta avec bonus pour l'app finale ; portail de connexion | Ouvrir + stocker : **fait**. Bonus et connexion : **à décider**, il faut un serveur pour relier un bêta-testeur à son futur compte (Supabase EU proposé). |
