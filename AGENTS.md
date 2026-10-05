# Perle — Règles communes du projet

> **À lire en entier avant toute modification**, par un humain ou par une IA (Claude Code, ChatGPT, Codex, Cursor…).
> Ce fichier est la source de vérité du projet. `CLAUDE.md` ne fait que pointer ici.
> Si une règle gêne, on la change **ici, explicitement**, on ne la contourne pas dans le code.

## 1. Le projet en 30 secondes

Perle est un jeu où l'on ouvre des huîtres pour révéler des perles. **Le geste d'ouverture est le jeu.**
Sur iPhone Duo (pliable), l'angle de la charnière pilotera l'ouverture ; sur iPhone classique, c'est un geste tactile.
Les deux appareils jouent **exactement le même jeu** : seule la source du geste change.

**Phase actuelle : prototype web** (installable sur l'écran d'accueil) pour valider l'UX. Le produit final passera sur l'App Store, soit en emballant ce code avec Capacitor (+ modules natifs pour l'haptique et la charnière), soit en réécrivant en SwiftUI. Ce choix sera fait après validation du geste.

- Cahier des charges complet : [docs/cahier-des-charges.md](docs/cahier-des-charges.md) (vision long terme, **pas** le périmètre actuel).
- Journal des passes entre associés : [docs/JOURNAL.md](docs/JOURNAL.md).

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
- Partage d'une carte (perle ou bijou) en image story 1080×1920 (feuille de partage iOS, ou téléchargement).
- **Écrin (V1.1, cahier §7)** : même geste que l'huître, sans fêlure ; angle d'éclat caché (55°–125°), le tenir immobile 0,9 s = éclat parfait (valeur ×1,5, carte holo), avec 12 % de chance de variante rare (Aurore, Nuit, Givre : valeur ×2, le bijou se transforme à l'écran). 10 raretés de bijoux du toc à la légende, garantie ★ après 20 écrins, probabilités affichées avant ouverture. Premier écrin offert à la fin du tutoriel (guidé), puis 1 toutes les 8 huîtres. Collection en deux volets : Perles / Bijoux.
- Stock d'huîtres : 10 maximum, 1 qui revient toutes les 20 min (bêta) ; écran « La marée remonte… » avec compte à rebours quand il est vide.
- Icône provisoire (huître ouverte + perle), installation sur l'écran d'accueil (aide affichée sur iPhone après le tutoriel), mode hors ligne.

**Hors V1 — ne pas coder sans décision dans §6**
Atelier, Maison, monnaies, écrins autres que Velours (Vintage, Saison, Couronne…), expertise et poussière d'or, pubs récompensées, bourriche, social, 3D, assets graphiques, sons définitifs, charnière Duo (préparée par l'architecture, pas implémentée), framework UI (React, etc.).

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
  input/            Sources du geste → produisent des OpeningSample
    thumb.ts        Pouce vers le haut (iPhone classique)
  art/              Dessin procédural (Canvas 2D) : coquille, nacre, perle, halo, bijoux, écrin, image story. Aucune règle de jeu
  platform/         Ce qui touche au navigateur : haptique, sons générés, sauvegarde, partage, mesure d'usage (analytics.ts)
  features/         Écrans : oyster/ (dont coach.ts, textes du tutoriel), ecrin/, collection/, tuning/, share/ (bouton Partager)
  main.ts           Point d'entrée, navigation entre écrans
tests/              Tests du Core et des entrées
public/
  sw.js             Service worker : mode hors ligne (build de production uniquement)
  icons/            Icônes générées par scripts/make-icons.py (ne pas éditer à la main)
  manifest.webmanifest
scripts/            Outils (génération des icônes, macOS)
```

### Les invariants — ne jamais casser

1. **Core est pur.** Rien dans `src/core/` ne touche au DOM, à `window`, `document`, `navigator` ou `localStorage`, et rien n'y importe `platform/`, `features/` ou `input/`. Un test vérifie automatiquement cette règle (`tests/core-purity.test.ts`).
2. **Une seule interface de geste.** Toute source de geste (pouce, charnière, autre) produit des `OpeningSample { angle: number /* degrés, 0…180 */, time: number /* ms */ }`. Le moteur calcule lui-même la vitesse. Aucune vue ne décide d'une règle de jeu.
3. **Aucun nombre magique.** Probabilités, seuils, angles, vitesses, durées : uniquement dans `src/tuning.ts` ou `src/core/catalog.ts`. Les valeurs viennent du cahier des charges ; si on s'en écarte, on le note dans §6.
4. **Hasard injectable.** Le tirage reçoit un générateur aléatoire en paramètre (graine fixe dans les tests). Le temps (`now`) est aussi passé en paramètre.
5. **La perle est tirée à la création de l'huître** et sauvegardée avec l'état du joueur : recharger la page ne relance pas le tirage.
6. **`npm test` et `npm run build` passent avant chaque passe.** Pas de test cassé laissé à l'associé.
7. **Les vues ne contiennent pas de règles.** Une vue affiche un état et transmet des gestes, c'est tout.
8. **Mesure d'usage centralisée.** Les écrans appellent seulement `track()` de `src/platform/analytics.ts`. L'outil d'analytics se branche dans ce seul fichier.

### Machine à états de l'ouverture

`closed → resisting → opening → revealed`
Événements émis : `pop` (passage resisting → opening), `crack` (fêlure en zone fragile), `reveal` (avec le lustre).
Relâcher pendant `resisting` → retour à `closed` (la coquille se referme). Relâcher pendant `opening` → la coquille reste entrouverte.

| Paramètre (`src/tuning.ts`) | Valeur de départ | Source |
|---|---|---|
| Angle du « pop » | 15° | à régler |
| Distance de pouce avant le pop | 90 pt | à régler |
| Distance de pouce du pop à 180° | 380 pt | à régler |
| Zone fragile | 20° – 110° | cahier §5 |
| Vitesse max sans fêlure dans la zone fragile | 260 °/s | à régler |
| Angle de révélation | 140° | à régler |
| Suspense avant la carte, par rareté | 250 / 700 / 1200 / 2000 ms | à régler (note de Mathys : révélation à la FUT / Clash Royale) |
| Garantie perle dorée+ | 25 huîtres | cahier §5 |
| Stock d'huîtres maximum | 10 | cahier §5 |
| Recharge d'une huître | 20 min | cahier §5 dit 30 ; 20 pendant la bêta (§6) |
| Écrin : plage de l'angle d'éclat | 55° – 125° | prototype Duo |
| Écrin : tolérance / temps à tenir / vitesse « immobile » | 6° / 900 ms / 30 °/s | prototype Duo (cahier §7 : « une seconde ») |
| Écrin : éclat parfait | valeur ×1,5 | cahier §7 |
| Écrin : variante rare sur éclat parfait | 12 % de chance, valeur ×2 | proposition (§6) |
| Garantie bijou ★ ou mieux | 20 écrins | cahier §7 |
| Huîtres pour gagner un écrin | 8 | bêta (§6) |

## 4. Conventions

- **Langue :** code (types, fonctions, variables) en anglais ; commentaires, textes du jeu et documentation en français.
- TypeScript strict. Pas de nouvelle dépendance npm sans décision dans §6.
- Un fichier = une responsabilité. Noms explicites, pas d'abréviations.
- Ne pas renommer ni déplacer de fichiers dans `src/core/` sans le noter dans le journal.
- Petites modifications ciblées : ne pas « nettoyer » ou reformater du code qui n'a rien à voir avec la tâche.
- Commandes : `npm install`, `npm run dev` (ouvre aussi l'adresse réseau pour tester sur iPhone), `npm test`, `npm run build`, `npm start` (build + version de production sur le port 4173, avec le mode hors ligne), `npm run icons` (régénère les icônes).
- Toute modification de `public/sw.js` qui change la façon de mettre en cache : incrémenter `CACHE_VERSION`.

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
| 2026-10-05 | Pas de mise en ligne pour l'instant : tout est construit et testé en local | Choix de Jules |

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
