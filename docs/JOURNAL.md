# Journal des passes

Entrée la plus récente en haut. Format : date · qui · avec quel outil.

---

## 2026-10-20 (revue) · Jules · Claude Code · branche `jules/ios-app`

Revue complète de l'app au simulateur, iPhone classique (17 Pro, 17e) et iPhone Duo (charnière et pli simulés `-SimulatedHinge -SimulatedFold` ; le simulateur iPhone Duo iOS 27.1 a figé le service des simulateurs, à refaire sur un vrai Duo). Fusion de la passe précédente dans `main`.

**Vu et bon** : connexion, consentement Google, tutoriel complet (bulles, main fantôme), arrivée des onglets et compteurs, collection, comptoir, missions, réglages, probabilités (ligne du poisson), boutique, pub de test AdMob jusqu'à la récompense (+ 3 huîtres), achat d'une huître en poussière, poisson voleur (fuite et capture), charnière : ouvrir = huître, refermer = suivante.

**Corrigé**
- Écrans qui défilent (collection, boutique) : le texte passait sous l'heure et la Dynamic Island → voile d'eau profonde sous la barre d'état (`statusBarFade`, `Glass.swift`).
- Bulle « Tes huîtres sont en haut… » visible derrière le panneau « La marée remonte… » → masquée à marée basse.
- Badge « Nouvelle ! » qui mordait sur la bulle du tutoriel (petit écran) → place réservée au-dessus de la carte.
- Écran blanc au lancement → écran de lancement couleur lagon (`LaunchBackground`).
- Le calendrier pouvait s'ouvrir tout seul le jour de la toute première séance si l'app était relancée → le jour est mémorisé.
- **Duo, écran intérieur** : la carte (300 pt) était coupée par la moitié d'écran → elle prend la largeur disponible ; « Referme le téléphone… » sur plusieurs lignes ; panneau « La marée remonte… » posé sur le pli (interdit, `duo-gadget.md` §5) → à droite du pli, version compacte (boutons sur plusieurs lignes, `buttonLabelWraps`, libellé « Pub · + 3 huîtres »).

**À faire**
- Sur un vrai iPhone Duo (inscrits TestFlight) : l'écran intérieur, la moitié fait ≈ 233 pt (201 au simulateur).

**Fragile**
- Au simulateur, les touchers très brefs (outil d'automatisation) ne changent pas d'onglet : un vrai doigt, si. Ne pas le prendre pour un bug.
- Un build incrémental corrompu a fait planter la collection (`swift_retain`) ; un build propre non. En cas de plantage inexpliqué : supprimer DerivedData.

## 2026-10-20 (suite) · Jules · Claude Code · branche `jules/ios-app`

Visuels paysage de la page produit App Store (« Informations de la page produit » : en-tête et résultats de recherche), qui mettent en avant l'iPhone Duo (demande de Jules).

**Fait**
- `docs/app-store/visuels/{fr,en}/bannieres/` : en-tête `entete-5244x2950.png` et `entete-3840x1646.png` ; résultats de recherche `recherche-5244x2950.png`, `recherche-3840x2560.png`, `recherche-1920x1280.png`. Une seule ressource par emplacement : en choisir une de chaque.
- Le Duo est celui de la page pearl-inc.app (3D, `site/index.html`), à moitié ouvert à 118° sur une perle dorée ; perles par `art.swift`. Textes : « Conçu pour iPhone Duo · Ouvre ton iPhone. Ouvre l'huître. » (EN : « Designed for iPhone Duo · Open your iPhone. Open the oyster. »).
- Générateur : `sh scripts/app-store-visuels/render-bannieres.sh` (≈ 8 min), mise en page `banniere.html` (une seule, en vh / vw, pour les trois proportions).

**À faire**
- Charger dans App Store Connect (FR et EN), vérifier l'« Aperçu » : on ne connaît pas les zones que l'App Store recouvre (titre, bouton Obtenir) ; le texte est centré verticalement à gauche pour rester loin des bords.

**Fragile**
- `render-bannieres.sh` patche une copie du site par remplacements exacts (`roll()`, `yaw`, `?h=`, `glassPill`) : il s'arrête avec une erreur si ces lignes changent dans `site/index.html`.
- « iPhone Duo » est une marque d'Apple : utilisée seulement comme « Conçu pour… », comme le prévoit `docs/duo-gadget.md` §5.

## 2026-10-20 · Jules · Claude Code · branche `jules/ios-app`

Dernières touches de la 1.0 avant l'envoi en vérification (demande de Jules) : le poisson voleur, la carte qu'on fait jouer dans la lumière, et une vérification d'AdMob. **Build 4.**

**Fait**
- **Poisson voleur** (décision §6) : `APP_FISH_THIEF` dans `src/core/appEconomy.ts` (exporté, `Economy.fishThief`) ; Core : `PlayerState.reveal(…, thiefRng:)` décide du vol avec son propre générateur (les cas de référence des huîtres restent ceux de la webapp : un tirage partagé les décalait), `stolenCard` sauvegardé, `resolveTheft(caught:)` ; 7 tests Swift (`FishThiefTests`) et 1 test d'économie. App : étapes `.theft` / `.stolen` dans `GameModel` (le poisson arrive en 0,75 s, s'enfuit en 2,8 s ; toucher = `catchFish()`), dessin `Art/ThiefFishArt.swift` (poisson orange à rayures, perle dans la bouche, sillage de bulles, plouf), bulle « Un poisson ! Touche-le vite… », panneau `StolenView` s'il file, son `fishChime` (`APP_AUDIO`), ligne dans les probabilités (boutique, réglages, collection), action VoiceOver « Attraper le poisson ». Outil de test Debug : `-AlwaysFishThief`.
- **Carte qu'on fait jouer** (`Features/CardTilt.swift`) : rester appuyé et bouger le doigt incline la carte sous le doigt (reflet qui suit, holo des rares piloté par le doigt), elle reste au milieu et revient à plat avec un rebond ; toucher bref = huître suivante. Aussi sur la carte agrandie de la collection.
- **Arrivée de la carte** : gerbe d'étincelles de la couleur de la perle (`RevealBurst`, rayons dès ◆◆◆), badge « Nouvelle ! » (première de sa sorte), badge « Rattrapée au vol ! + 2 ✦ ».
- **AdMob vérifié** : App ID et bloc d'annonces du même éditeur (`pub-1299710250358184`) ; la build Release ne contient que le vrai bloc (pas celui de test) ; `app-ads.txt` en ligne (pearl-inc.app → www, 200) et identique à `site/app-ads.txt` ; 50 SKAdNetwork ; pas d'ATT (pubs non personnalisées). **Corrigé** : au lancement, le calendrier s'ouvrait avant le formulaire de consentement de Google, qui passait alors par-dessus (le retour au premier plan l'ouvrait sans attendre) ; il attend maintenant le consentement (`RewardedAds.consentAnswered`).
- Textes FR / EN dans `Localizable.xcstrings` ; notes de revue (`docs/app-store/fiche.md`) : le poisson voleur.
- Vérifié au simulateur (iPhone 17 Pro) : vol puis fuite (panneau), vol puis poisson touché (carte « Rattrapée », + 2 ✦), carte inclinée au doigt ; `npm test`, `npm run build`, `swift test`, builds Debug et Release.

**À faire**
- Archiver et envoyer le **build 4**, le choisir à la place du 3 dans la version 1.0, puis envoyer en vérification.
- App Store Connect, « Confidentialité de l'app » : vérifier que les données collectées par AdMob sont déclarées (identifiant de l'appareil, données publicitaires, interactions, diagnostics, position approximative ; « publicité tierce », non liées, pas de pistage).
- AdMob : tant que l'app n'est pas publiée et associée à sa fiche dans AdMob, les vraies pubs peuvent manquer (« Pub en préparation… », bouton grisé, pas de blocage).
- Essayer sur un vrai iPhone : la fenêtre pour toucher le poisson (2,8 s, tolérance 0,2 × la taille de l'huître), l'inclinaison de la carte (16°), le son du poisson.

**Fragile**
- Le vol ne doit jamais consommer le générateur des huîtres (`rng`) : sinon le test `memesPremieresHuitresQueLeWeb` casse.
- Le texte « Un poisson a filé avec ta … » suppose un nom de perle féminin (toutes les perles ◆ le sont).

## 2026-10-19 (suite 14) · Jules · Claude Code · branche `jules/ios-app`

App Store Connect rempli (dans le Chrome de Jules), **soumission prête mais pas envoyée** (choix de Jules).

**Fait**
- Supabase : fournisseur **Apple activé**, Client IDs = `app.pearlinc.PearlInc`, sans secret (inutile en natif). Vérifié : `apple: true`.
- **Build 2** archivé (20 h 01) et envoyé, attaché à la version 1.0. Il est antérieur à la musique et aux sons (suite 13) : **il ne les contient pas**.
- 7 achats intégrés : capture de revue (`docs/app-store/achats/`, 1320 × 2868 : Apple refuse les tailles qui ne sont pas celles d'un écran) et nom / description en anglais. Disponibilité qui manquait sur `dust.400` et `skin.or` : 174 pays, sans la Belgique.
- Version 1.0 : description FR à jour (Duo, rendez-vous du jour), notes de revue en anglais, contact de revue (Mathys), publication **manuelle** ; fiche **English (U.S.)** complète (sous-titre « Find the rare pearl », texte, mots-clés, URLs, politique `/en/privacy/`) ; 8 visuels FR et 8 EN en 1206 × 2622 (le seul format demandé, iPhone 6,3″).
- Brouillon de soumission : app 1.0 (2) + 7 achats. Il reste à cliquer « Envoyer pour vérification ».

**À savoir**
- Pour sortir avec la musique : build 3 (incrémenter `CURRENT_PROJECT_VERSION`), l'envoyer, le choisir à la place du 2 dans la version, puis envoyer.
- Prix réels dans App Store Connect (≠ `ios/PearlInc.storekit`, qui ne sert qu'aux tests Xcode) : poussière 1,99 / 3,99 / 8,99 $, huître d'or 8,99 $.
- Partage familial des skins non activé (irréversible une fois activé ; le fichier StoreKit le met à « oui »).
- Chrome remplit tout seul certains formulaires (Supabase, coordonnées) avec des identifiants enregistrés : relire avant d'enregistrer.

## 2026-10-19 (suite 13) · Jules · Claude Code · branche `jules/ios-app`

Musique d'ambiance et effets sonores dans l'app iOS (demande de Jules), **générés par code** comme la webapp (choix de Jules), sans aucun fichier audio.

**Fait**
- `src/tuning.ts` : `APP_AUDIO` (volumes, durées, fréquences, accords de la musique), exporté dans `catalog.json` (`audio`) ; `PearlCore/AudioTuning.swift` le lit (+ 2 tests). Les effets reprennent les sons de la webapp (`src/platform/audio.ts`) : mêmes fréquences, mêmes durées.
- `Platform/SoundSynth.swift` : bruit filtré (tic, pop, fêlure, couvercle), carillons, battement du suspense. `Platform/AmbientMusic.swift` : musique du lagon fabriquée en continu (nappe Do maj7 → La m7 → Fa maj7 → Sol 6, ressac, notes de carillon au hasard), oscillateurs à rotation (pas de `sin()` par échantillon). `Platform/Audio.swift` : session **ambient** (muet en mode silencieux, se mêle à la musique du joueur ; notre musique se tait si le joueur écoute déjà quelque chose), réverbération légère, relance après interruption ou changement d'écouteurs.
- Moments (`GameModel`, aux mêmes endroits que l'haptique) : tic de résistance (monte d'un ton à chaque tic), pop, fêlure (pas sur une huître vide), couvercle, battements du suspense gradués, carillon de révélation par rareté (maudite qui grince, vide qui descend, trouvaille qui sautille) ; poussière d'or (revente, mission), récompenses (calendrier, pub), achats, coquille équipée, changement d'onglet. La musique baisse pendant le suspense et se coupe pendant une pub. Le rythme des battements (`pulseEveryMs`, 350 ms) sert aussi à l'haptique (c'était un nombre écrit dans `GameModel`).
- Réglages : interrupteurs **Musique** et **Sons** (FR / EN), mémorisés (`pearlinc.settings.music`, `pearlinc.settings.sounds`), activés par défaut.
- Vérifié : rendu hors ligne des niveaux (musique ≈ moitié du carillon, rien ne sature) ; au simulateur iPhone 17 Pro, ouverture jusqu'à la carte sans erreur, Réglages ; processeur : ≈ +1 % pour la musique en Release (≈ +15 % en Debug, non optimisé) ; `npm test`, `npm run build`, `swift test`, build Xcode.

**À faire**
- **Écouter** sur un vrai iPhone (je n'entends pas le simulateur) : équilibre musique / effets, volume du ressac, battement du suspense. Tout se règle dans `APP_AUDIO` puis `npm run ios:export`.
- Webapp : pas de musique (inchangée).

**Fragile**
- Le rendu de la musique tourne sur le fil audio : ne rien y allouer ni appeler du fil principal (`AmbientMusic.render`).
- Une vraie pub AdMob peut changer la session audio : `setAdShowing(false)` la remet en « ambient » au retour.

---

## 2026-10-19 (suite 12) · Jules · Claude Code · branche `jules/ios-app`

Visuels de la fiche App Store, en français et en anglais.

**Fait**
- `docs/app-store/visuels/{fr,en}/` : 8 visuels 1320 × 2868 (iPhone 6,9 pouces, JPEG) : ouvre l'huître (héros), le geste, la perle maudite, les 7 perles et leurs probabilités, la collection, les trouvailles, les coquilles, chaque jour. Titres courts et gros pour être lisibles en vignette ; téléphones avec les vraies captures de l'app.
- `scripts/app-store-visuels/` : `seed.py` écrit une partie « vitrine » dans le simulateur (37 perles, 6 trouvailles, 1 240 ✦, et l'huître posée contient la perle voulue : maudite, dorée, une trouvaille…) ; `art.swift` dessine perles, objets et la scène du héros en haute définition avec le code de `ios/PearlInc/Art` ; `index.html` compose les visuels (textes FR / EN) ; `render.sh` fait le tout avec Chrome sans fenêtre.
- `docs/app-store/fiche.md` §6 : ordre et contenu des visuels.

**À faire**
- Fiche : l'en-tête (« l'app n'est qu'en français ») et le §5 (calendrier « pas dans la 1.0 ») sont dépassés ; à relire, et rédiger la fiche anglaise.
- Vidéo d'aperçu (le geste en mouvement) : pas faite.

**Fragile**
- Les captures brutes (`raw_*.png`) ne sont pas dans le dépôt (trop lourdes) : pour refaire les visuels, les reprendre au simulateur (iPhone 17 Pro, `xcrun simctl status_bar booted override --time 9:41`), voir l'en-tête de `render.sh`.
- Les probabilités du visuel 4 et « 3 chances sur 1 000 » sont écrites dans `index.html` : à changer si le catalogue change.
- Vu au simulateur : une ouverture lâchée au-delà de 115° est restée grande ouverte sans carte jusqu'au toucher suivant (une fois, avec un geste simulé ; pas reproduit ensuite).

---

## 2026-10-19 (suite 12) · Jules · Claude Code · branche `jules/ios-app`

Préparation de la soumission App Store.

**Fait**
- Pages de l'app remises dans `site/` (depuis `docs/pages-app/`, supprimé) : `/support/`, `/conditions/`, `/en/support/`, `/en/terms/`, et la **confidentialité complète** FR / EN (app + site) à la place de la version courte, avec la section du pixel X et X dans la liste des destinataires. Bannière de cookies (`consent.js`) et lien « Cookies » sur chaque page ; liens Aide et Conditions ajoutés au pied des mentions légales ; accueil anglais = `/en`.
- **Médiateur de la consommation retiré des conditions** (FR / EN) en attendant l'adhésion de Mathys (choix de Jules).
- `docs/app-store/fiche.md` : fiche anglaise complète, achats intégrés en deux langues, notes de revue à jour (app bilingue, tutoriel, charnière du Duo, notifications), iPhone Duo dans la description.
- Build iOS passé à 2.
- Vérifié en ligne : connexions anonymes Supabase activées ; `/support/` et `/conditions/` étaient en 404 sur pearl-inc.app.

**À faire (Jules, avant d'envoyer)**
- Supabase : activer le fournisseur **Apple** (aujourd'hui `apple: false` : « Se connecter avec Apple » échoue).
- Fusionner dans `main` et vérifier que les 4 pages répondent sur pearl-inc.app.
- Captures des achats intégrés **plein écran** (≥ 640 × 920) ; prix de l'huître d'or à confirmer (8,99 $ dans TestFlight, 9,99 dans `PearlInc.storekit`).
- Mathys : adhérer à un médiateur, puis remettre la phrase dans les conditions.

**Fragile**
- Suppression du compte : le jeton « Se connecter avec Apple » n'est pas révoqué (règle 5.1.1 v).

## 2026-10-19 (suite 11) · Jules · Claude Code · branche `jules/ios-app`

Retours de Jules sur l'écran extérieur du Duo et la bulle du stock.

**Fait**
- `Art/OysterArt.swift` (pose `cover`) : huître ≈ 10 % plus grande (L = min(0,99 × largeur, 0,68 × hauteur visible)) et plus basse (charnière à 53 % de la hauteur au lieu de 42 %) : elle ne passe plus sous la barre du haut.
- Bulle « Tes huîtres sont en haut… » (1re huître après le tutoriel) : elle s'efface toute seule au bout de `coachTipMs` (7 s, nouveau réglage dans `src/tuning.ts`, exporté) ; avant, elle restait jusqu'à ce qu'on ouvre l'huître.
- Vérifié au simulateur iPhone Duo (écran extérieur) ; `npm test`, `npm run build`, `swift test`.

- Corrigé : le calendrier se rouvrait à chaque lancement et à chaque retour tant que la case n'était pas prise. Il ne s'ouvre plus tout seul qu'une fois par jour (`pearlinc.calendar.offeredDay`) ; il reste dans les missions du jour.

- Calendrier sur l'écran extérieur du Duo : la fenêtre s'ouvrait à mi-hauteur et coupait « Récupérer » ; elle prend maintenant la hauteur de son contenu (`.height`, plafonnée par iOS), et le contenu se centre sous la barre d'état verticale du Duo au lieu d'être décalé à gauche. Debug : `-ShowCalendar` l'ouvre à chaque lancement. Vérifié sur le Duo ; pas revu sur iPhone classique (le simulateur ne prenait plus les touchers).

**Fragile**
- La bulle du stock réapparaît 7 s à chaque lancement tant que la 1re huître après le tutoriel n'est pas ouverte.

## 2026-10-19 (suite 10) · Jules · Claude Code · branche `jules/ios-app`

App iOS : huître fermée plus grande, et calendrier de connexion sur 7 jours.

**Fait**
- `Art/OysterArt.swift` (pose « pouce ») : l'huître fermée prend ≈ 85 % de la largeur (L = min(0,7 × largeur, 0,48 × hauteur visible)), centrée un peu sous le milieu. Vérifié sur iPhone 17 Pro, fermée et à mi-ouverture. Le Duo ne change pas.
- `src/core/appEconomy.ts` : `APP_CALENDAR` (7 cases, voir §6) et `calendarJokerDays` (7), exportés.
- `PearlCore/Daily.swift` : `LoginState` (série, joker, case suivante), miroir de `src/core/daily.ts` ; `PlayerState.claimDaily(day:)`, jamais pendant le tutoriel ; ancienne sauvegarde = calendrier vierge. Cas de référence `logins` (série, joker, changement d'année) produits par le TypeScript + `DailyTests`.
- `Features/CalendarView.swift` : « Rendez-vous du jour », 7 cases, série prévue, état du joker, « Récupérer » (la fenêtre se ferme toute seule). Ouverte tout seule au lancement (après le formulaire de consentement des pubs) et au retour dans l'app ; aussi depuis les missions du jour ; pastille dorée sur le bouton des missions quand une case attend. FR + EN (pluriels).
- Vérifié : `npm test`, `npm run build`, `swift test` (41), build Xcode ; au simulateur, ouverture automatique, récupération (+ 3 huîtres), case cochée.

**À faire**
- Non vérifié à l'écran : le passage au jour suivant et le joker (couverts par les tests).
- Reste de la 1.0 (`duo-gadget.md` §4) : image story pour le partage, Game Center, iCloud, skin Première marée, mesure d'usage.

**Fragile**
- `calendarJokerDays` (7) double la valeur écrite dans `src/core/daily.ts` (`jokerAvailable`) : changer les deux ensemble.
- Le jour de la toute première séance, le calendrier ne s'ouvre pas tout seul ; il reste accessible depuis les missions.

## 2026-10-19 (suite 9) · Jules · Claude Code · branche `jules/ios-app`

App iOS : sur l'iPhone Duo, l'huître est posée **dans le même sens que le prototype de pearl-inc.app** (demande de Jules).

**Fait**
- `Art/OysterArt.swift` : la scène prend une pose (`Pose`). **Au pouce** (iPhone classique) : rien ne change, vue de dessus, charnière en haut. **Écran extérieur du Duo** (`cover`) : couchée, charnière au bord gauche, coquille vers la droite, à 42 % de la hauteur (comme `drawCover` du prototype) ; le couvercle se replie vers la gauche en s'ouvrant. **Écran intérieur** (`fold`) : charnière de l'huître sur le pli, couvercle ouvert à plat sur la moitié gauche (nacre visible), fond, chair et perle sur la moitié droite (comme `drawInner`) ; c'est le téléphone qui soulève le couvercle, seule la lumière suit l'angle.
- `Input/HingeSource.swift` : lit le pli avec `reservedRegions(kind: .division, options: .includeInactive)` (iOS 27.1), à chaque mise en page et à chaque mesure de la charnière ; `GameModel.foldX`.
- Écran intérieur : carte, bulles et message se centrent sur la moitié droite (`besideFold`), rien sur le pli.
- Debug : `-SimulatedFold` simule un pli au milieu de l'écran.
- Vérifié au simulateur iPhone Duo : écran extérieur (couchée, charnière à gauche) et pli simulé ; comparé au prototype en ligne (écrans extérieur et intérieur).

**À faire**
- Vérifier sur un vrai Duo ou dans Device Hub : que la zone « division » est bien donnée sur l'écran intérieur (sinon l'app garde la pose de l'écran extérieur), sa position, et le passage d'un écran à l'autre pendant l'ouverture.
- Main fantôme : absente sur le Duo (elle montre le geste du pouce).

**Fragile**
- Le pli est converti dans les coordonnées de la fenêtre ; on suppose que la Pêche occupe toute la fenêtre (vrai aujourd'hui, onglets en surimpression).

## 2026-10-19 (suite 8) · Jules · Claude Code · branche `jules/ios-app`

App iOS : les premières minutes (cahier §15, `docs/duo-gadget.md` §4) et la notification « tes huîtres sont revenues ».

**Fait**
- `PearlCore/Tutorial.swift` : les 4 premières huîtres écrites à l'avance (rosée, blanche, vide, baroque), **exportées du TypeScript** (`tutorialPearls` dans `catalog.json`, depuis `src/core/tutorial.ts`). Offertes (le stock n'y touche pas), la 1re ne peut pas se fêler, elles comptent pour la garantie comme dans la webapp. Cas de référence `tutorialOysters` (parité avec le web) + `TutorialTests`.
- Écran : bulles d'accompagnement reprises de `coach.ts` (`Features/Coach.swift`), variantes iPhone Duo (« Ouvre doucement le téléphone… »), bulle au-dessus de la carte après chaque révélation ; **main fantôme** qui montre le geste sur la 1re huître (immobile avec « Réduire les animations », absente sur le Duo).
- Pendant le tutoriel, rien que l'huître : onglets, compteurs et missions masqués ; ils arrivent avec la 1re huître libre, accompagnés d'une bulle qui explique le stock (10 max, 1 toutes les 20 min, valeurs lues dans les réglages).
- `Platform/Notifications.swift` : une seule notification locale, « La marée est haute », programmée en quittant l'app pour l'heure où le stock sera plein, retirée en revenant. Proposée sur l'écran « La marée remonte… » (« Me prévenir quand elles reviennent ») et dans Réglages → « Huîtres revenues ». Jamais pendant le tutoriel. `fullStockIn` dans `Stock.swift` (testé).
- Textes FR + EN dans `Localizable.xcstrings`.
- Vérifié : `npm test` (163), `npm run build`, `swift test` (35), build Xcode ; parcours complet des 4 huîtres + arrivée des onglets dans le simulateur iPhone Duo (FR), bulle du stock en anglais.

**À faire**
- Non vérifié à l'écran : la notification elle-même (il faut vider le stock) et la main fantôme sur un iPhone sans charnière (le simulateur utilisé était le Duo).
- Reste de la liste 1.0 (`duo-gadget.md` §4) : image story pour le partage (aujourd'hui un texte), calendrier de connexion, Game Center, sauvegarde iCloud, skin Première marée des inscrits (comment le débloquer), mesure d'usage (outil à choisir).

**Fragile**
- Une sauvegarde d'avant cette version reprend le tutoriel là où elle en est (`oystersOpened` < 4) : bulles et huîtres offertes jusqu'à la 4e, avec l'huître déjà posée (invariant 5).
- Les missions avancent pendant le tutoriel (invisibles) : le joueur peut avoir une récompense qui l'attend dès la fin.

---

## 2026-10-19 (suite 7) · Jules · Claude Code · branche `jules/ios-app`

Tests qui échouaient par intermittence quand la machine est chargée (juste après un build Xcode).

**Cause confirmée** : le délai par défaut de Vitest (5 s), pas le hasard (graines fixes). Reproduit avec 160 processus `yes` + les simulateurs iOS ouverts : `Test timed out in 5000ms` sur `ecrin.test.ts` « respecte les probabilités (sans garantie) » et `variety.test.ts` « chaque rareté donne des bijoux nommés… » ; les autres tests lourds (≈ 50 à 200 ms d'habitude) montaient à 3 à 26 s. Lors d'un passage plus chargé, même un test de 22 ms (« offre le premier écrin… ») a dépassé 5 s : le processus est mis en attente, ce ne sont pas les calculs qui sont lents.

**Fait**
- `vitest.config.ts` (nouveau, seul réglage) : `testTimeout: 60_000` pour tous les tests. Un délai par test aurait laissé passer les tests légers privés de processeur. Aucune règle, probabilité ni réglage du jeu ne change ; nombre de tirages inchangé.
- Vérifié : `npm test` et `npm run build` passent ; sous la même charge, les 163 tests passent (jusqu'à 6,8 s pour un seul test).

**À faire**
- Rien.

**Fragile**
- Un vrai blocage dans un test met maintenant 60 s à être signalé au lieu de 5 s.
- `vitest.config.ts` est pris par Vitest seulement : la build Vite n'a toujours pas de fichier de configuration.

---

## 2026-10-19 (suite 6) · Jules · Claude Code · branche `jules/ios-app`

La page anglaise du site a sa propre adresse : **pearl-inc.app/en** (mesure de la campagne par langue).

**Fait**
- `site/en/index.html`, généré depuis `site/index.html` par `npm run site:en` (test `tests/site-english.test.ts`, qui échoue si elle n'est plus à jour) : seul l'en-tête change (langue, titre, description, adresse canonique, aperçu de lien X / LinkedIn en anglais).
- `site/index.html` : `/en` est toujours en anglais ; sur `/`, la langue choisie ou celle de l'iPhone, et l'adresse devient `/en` si la page s'affiche en anglais. Les boutons FR / EN changent l'adresse sans recharger, en gardant `utm_…`. Liens `hreflang`. La traduction se fait tout de suite (plus d'éclair de français en attendant three.js).
- Pages anglaises (confidentialité, mentions, merci) : le lien vers l'accueil pointe sur `/en` au lieu de `/?lang=en`.

**À faire**
- Après le déploiement : ouvrir `https://pearl-inc.app/en`, vérifier l'aperçu avec le Card Validator de X / Post Inspector de LinkedIn, et que Vercel Analytics compte bien `/en` à part.
- Annonces anglaises : pointer sur `https://pearl-inc.app/en?utm_source=…&utm_campaign=…`.

**Fragile**
- Ne jamais éditer `site/en/index.html` à la main : modifier `site/index.html`, puis `npm run site:en`.
- Un changement de langue par les boutons change l'adresse mais n'est sans doute pas compté comme une nouvelle visite : la mesure par langue repose sur la page d'arrivée.

---

## 2026-10-19 (suite 5) · Jules · Claude Code · branche `jules/ios-app`

Événement X « Inscription » sur pearl-inc.app.

**Fait**
- Pages de fin du formulaire `site/merci/` et `site/en/thanks/` (texte de remerciement de Tally, `noindex`). Leur `<body data-x-event="tw-rh65t-rhkic">` fait envoyer l'événement par `site/consent.js`, après « Accepter » seulement, une fois par visite.
- Confidentialité FR / EN : X apprend aussi qu'on s'est inscrit (jamais l'e-mail). Décision §6 complétée.

**À faire**
- Dans Tally, formulaires FR et EN : rediriger à la fin vers `https://pearl-inc.app/merci/` et `https://pearl-inc.app/en/thanks/` (réglage peut-être réservé à Tally Pro), puis publier.
- Après le déploiement : une inscription de test avec l'extension X Pixel Helper, et vérifier que l'événement apparaît dans l'Events Manager.

**Fragile**
- Sans la redirection Tally, l'événement ne part jamais. Seules les inscriptions de visiteurs qui ont accepté les cookies sont comptées.

---

## 2026-10-19 (suite 3) · Jules · Claude Code · branche `jules/ios-app`

La charnière de l'iPhone Duo dans l'app iOS.

**Fait**
- `PearlCore/Hinge.swift` : `HingeTracker` (armée après une fermeture, `closed` / `sample(angle)`), 6 tests ; réglage `hingeClosedAngle` (8°) dans `src/tuning.ts`, exporté.
- `PearlInc/Input/HingeSource.swift` : lecture par `UIHingeInteraction` (état de départ compris), modificateur `.hingeInput` sur la Pêche ; `GameModel.hingeChanged` : ouvrir le téléphone ouvre l'huître, le refermer passe à la suivante ; le pouce reste possible tant que la charnière ne pilote pas.
- Messages : « Ouvre le téléphone doucement », « Referme le téléphone, puis ouvre-le », « Referme le téléphone pour l’huître suivante » (FR/EN).
- Debug : `-SimulatedHinge` (argument de lancement) affiche un curseur 0–180° par-dessus la carte ; journal `app.pearlinc / charniere` des angles reçus.
- Vérifié : dans le simulateur Duo, l'app reçoit la vraie charnière (0°, fermé) et s'affiche sur l'écran extérieur ; parcours complet au curseur simulé sur iPhone 17 Pro.

**À faire**
- Régler sur de vrais Duo (inscrits équipés, TestFlight externe) : fréquence des angles, vitesse max sans fêlure à la charnière (peut-être un réglage à part), angle de bascule écran extérieur → intérieur, haptique pendant la résistance (aujourd'hui calée sur des points de pouce).
- Captures App Store spéciales Duo (obligatoires en avril 2027 pour le SDK 27.1).

**Fragile**
- Mac de Jules à 8 Go : un seul simulateur à la fois (deux Duo + Xcode ont saturé la mémoire et fait quitter l'app).
- DeviceHub n'affichait pas le Duo : on n'a pas pu bouger la vraie charnière du simulateur.

---

## 2026-10-19 (suite 4) · Jules · Claude Code · branche `jules/ios-app`

Pixel de conversion X sur le site pearl-inc.app (campagne X).

**Fait**
- `site/consent.js`, inclus avant `</head>` sur les 5 pages : bannière FR / EN (suit la langue de la page d'accueil), « Refuser » et « Accepter » au même niveau. Le code de base X (`twq('config','rh65t')`) ne se charge qu'après « Accepter ». Choix gardé 6 mois ; lien « Cookies » dans chaque pied de page pour le changer (retirer son accord recharge la page sans le pixel).
- Confidentialité FR / EN : section « Les cookies publicitaires (X) », fin de la mention « pas de cookie publicitaire ». Décision §6.

**À faire**
- Déployer sur Vercel, puis vérifier avec l'extension X Pixel Helper que `rh65t` se déclenche après « Accepter », et rien avant.
- API de conversion côté serveur (`X_PIXEL_TOKEN`) : pas faite. Il faudrait un webhook Tally → fonction Vercel ; choisir d'abord l'événement (`tw-rh65t-…`) dans l'Events Manager.

**Fragile**
- Seuls les visiteurs qui acceptent sont comptés : les chiffres X seront en dessous de la réalité.

---

## 2026-10-19 (suite 3) · Jules · Claude Code · branche `jules/ios-app`

La charnière de l'iPhone Duo dans l'app iOS (docs/duo-gadget.md §7).

**Fait**
- `PearlCore/Hinge.swift` : `HingeTracker` transforme l'angle du téléphone en `OpeningSample` (invariant n° 2). Il ne pilote l'huître qu'une fois « armé » (téléphone refermé depuis l'arrivée de l'huître) : un téléphone déjà ouvert n'ouvre rien d'un coup. Refermer = huître suivante sur la carte, coquille qui se referme pendant la résistance. Nouveau réglage `hingeClosedAngle` (8°) dans `src/tuning.ts`, exporté. 6 tests (`HingeTests`).
- `Input/HingeSource.swift` : `UIHingeInteraction` (iOS 27.1+, donne aussi l'état de départ), rien sur un iPhone sans charnière. En Debug, l'argument de lancement `-SimulatedHinge` affiche un curseur 0–180° sur la Pêche.
- Pêche et carte : messages « Referme le téléphone, puis ouvre-le », « Ouvre le téléphone doucement », « Referme le téléphone pour l'huître suivante » (FR + EN). Le pouce reste possible tant que la charnière n'a pas pris la main.
- Corrigé dans `GameModel` : tics de résistance espacés comme au pouce (angle ramené à la course équivalente) ; le pop ne verrouille plus le pouce quand c'est la charnière qui ouvre ; refermer le téléphone pendant l'ouverture laisse la main à la charnière (rouvrir reprend l'huître au lieu de la bloquer).
- `npm test`, `npm run build`, `swift test` (30 tests) et build Xcode 27.1 passent.

**À faire**
- Essayer dans le simulateur « iPhone Duo » (iOS 27.1) et avec `-SimulatedHinge` : non vérifié à l'écran (l'écran de connexion demande un compte ou une partie anonyme Supabase).
- Points ouverts de duo-gadget §7 : fréquence des mesures (≥ 30/s pour la zone fragile), passage écran extérieur → intérieur, plage réelle des angles, `hingeClosedAngle` à régler.

**Fragile**
- La règle « armer en refermant » est une proposition : à valider avec Mathys et sur un vrai Duo.

---

## 2026-10-19 (suite 2) · Jules · Claude Code · branche `jules/ios-app`

L'app iOS en anglais pour le premier build.

**Fait**
- Contenu du jeu : `src/core/catalogEnglish.ts` (8 perles, 3 albums, 25 trouvailles, messages en bouteille, formes, reflets, marques, coquilles, produits), exporté dans `catalog.json` ; `Catalog.localized("en")` dans PearlCore (textes seulement) ; tests TS (complétude) et Swift (traduction, règles inchangées).
- Interface : `ios/PearlInc/Localizable.xcstrings` (161 chaînes, pluriels « one/other » en français et en anglais) et `InfoPlist.xcstrings`. Textes composés réécrits (`Platform/AppLanguage.swift` : langue, n° de série, nom fêlé, traits, missions, compte à rebours) ; texte des missions sorti du Core ; pourcentages et tailles au format de la région de l'iPhone.
- Langue : suit l'iPhone ; anglais pour les autres langues (`developmentRegion = en` ; le français est écrit en clair dans le catalogue, sinon un iPhone français retombait sur l'anglais). Ligne « Langue » dans les Réglages (ouvre les réglages iOS de l'app). Liens confidentialité / conditions / aide / mentions vers `/en/…` en anglais.
- Vérifié dans le simulateur : français, anglais, et allemand (→ anglais) ; connexion, Pêche, carte, missions, collection, boutique, réglages.
- Build avec **Xcode 27.1** (RC, SDK iOS 27.1) désormais dans Applications ; simulateur iOS 27.0 supprimé (place disque).

**À faire**
- Relecture de l'anglais par un anglophone (trouvailles humoristiques surtout).
- Fiche App Store en anglais (localisation « English » dans App Store Connect) + captures anglaises ; noms et descriptions anglais des 7 achats intégrés.
- E-mail du code de connexion (modèle Supabase) : encore en français seulement.
- Pages `/en/terms/` et `/en/support/` : à mettre en ligne avec les pages françaises (médiateur).

**Fragile**
- Ajouter un texte d'interface : l'écrire en français dans le code, puis ajouter son anglais dans `Localizable.xcstrings` (Xcode le signale). Les textes construits en `String` doivent passer par `String(localized:)`.
- Ajouter un élément au catalogue (perle, trouvaille, skin, produit) : ajouter aussi son anglais dans `catalogEnglish.ts` (le test le rappelle), puis `npm run ios:export`.

---

## 2026-10-19 (suite) · Jules · Claude Code · branche `jules/ios-app`

Mesure d'audience du site avec Vercel Web Analytics.

**Fait**
- Script de Vercel ajouté à toutes les pages de `site/` (et de `docs/pages-app/`, pour quand elles seront mises en ligne).
- Confidentialité (site FR/EN et pages de l'app) : section « La mesure d'audience » (sans cookie, IP non conservée, chiffres globaux) à la place de « pas d'outil de mesure d'audience ».
- Xcode : Jules a un **Xcode 27.1** (build 27A9275, SDK iOS 27.1 avec `DeviceHinge`) dans Téléchargements ; le premier archivage a échoué faute d'équipe de signature (à choisir dans Signing & Capabilities). Pas d'iPhone Duo physique : la charnière se réglera au simulateur, puis avec des inscrits équipés d'un Duo (TestFlight externe).

**À faire**
- Vérifier dans le tableau de bord Vercel (Analytics) que les visites arrivent ; le plan Hobby ne permet pas les évènements personnalisés (clic « S'inscrire »).

---

## 2026-10-19 · Jules · Claude Code (Chrome) · branche `jules/ios-app`

Fiche App Store Connect remplie dans Chrome (app 6822782842, compte de Mathys).

**Fait**
- Informations sur l'app : sous-catégorie « Parties rapides » (au lieu de « Cartes »), secondaire « Divertissement », droits sur le contenu « oui » (pubs). Classification 9+, statut de commerçant, gratuit, sans Mac ni Vision Pro : déjà en place.
- Confidentialité publiée : e-mail **lié** à l'identité (corrigé), « Interaction avec le produit » ajoutée ; 9 types, aucun suivi.
- Achats intégrés : nom affiché et description FR pour les 7 ; prix vérifiés (0,99 / 2,99 / 1,99 / 4,99 / 9,99 / 2,99 / 9,99 €). Le prix de la Bourse (1,99 €) a été confirmé par Jules.
- Version 1.0 : texte promotionnel, description, mots-clés, URL, copyright, notes de revue (anglais), « Connexion requise » décochée, publication manuelle. Enregistrée.
- Disponibilité : **Belgique retirée** (174 pays).

**À faire**
- Jules : coordonnées de contact pour la revue (page de la version).
- Captures : la section n'apparaît pas encore sur la page de la version (sans doute après l'envoi d'un build). Les 5 JPEG sont dans `docs/app-store/captures/`.
- Captures de la Boutique pour la revue de chaque achat intégré (depuis TestFlight).
- Envoyer un build (Xcode → Archive), puis TestFlight ; pages légales complètes en ligne (médiateur) avant de soumettre.

---

## 2026-10-14 (suite) · Jules · Claude Code · branche `jules/ios-app`

Préparation de la fiche App Store Connect.

**Fait**
- Écran de connexion : « Ta collection te suit, sur tous tes iPhone » (promesse non tenue sans sauvegarde en ligne) remplacé par « Ouvre des huîtres, trouve la perle rare ».
- App en **version 1.0** (build 1).
- Pas à pas App Store Connect donné à Jules (compte au nom de Mathys, accords, identifiant, fiche, achats intégrés aux identifiants de `PearlInc.storekit`, TestFlight, captures 6,9 pouces).

**À faire**
- ~~Connexion anonyme~~ activée par Jules ; **captures App Store** faites : `docs/app-store/captures/` (5 JPEG 1320 × 2868, iPhone 17 Pro Max, barre d'état 9:41) : pêche, ouverture, révélation (perle rosée), collection, missions. Pas de capture de la Boutique : hors de Xcode les prix StoreKit sont « Indisponible » (à refaire depuis TestFlight).
- **Fiche App Store** rédigée : `docs/app-store/fiche.md` (nom, sous-titre, texte promotionnel, mots-clés, description, achats intégrés, notes pour la revue), d'après ce que contient vraiment l'app (pas de Duo, Game Center, iCloud, notifications ni anglais dans la 1.0).
- **AdMob vérifié de bout en bout** dans le simulateur : pub de test Google affichée, récompense comptée (« Encore 2 aujourd'hui »).
- Mathys : choisir un **médiateur de la consommation**. Ensuite seulement, mettre en ligne **ensemble** confidentialité, aide et conditions (`docs/pages-app/` → `site/`) : les pages d'aide renvoient vers `/conditions/`, qui ne doit pas sortir avec un champ « À compléter ».

**Fragile**
- Tant que ces pages ne sont pas en ligne, `/confidentialite/` reste la version courte (site seulement) : à remplacer avant toute soumission ou test TestFlight externe (Apple demande l'URL).

---

## 2026-10-14 · Jules · Claude Code · branche `jules/ios-app`

App iOS : la pub récompensée passe par **AdMob**, avec les identifiants de test de Google.

**Fait**
- Paquets Swift `GoogleMobileAds` (13.11) et `GoogleUserMessagingPlatform` (3.1) ajoutés au projet.
- `ios/PearlInc-Info.plist` (fusionné avec l'Info.plist généré) : `GADApplicationIdentifier` (App ID **de test**) et la liste `SKAdNetworkItems` de Google (50, relevée le 2026-10-14).
- `Platform/RewardedAds.swift` : consentement RGPD (UMP) à l'arrivée dans le jeu, démarrage d'AdMob, préchargement d'une pub récompensée (rechargée après chaque pub, après 1 h, ou 60 s après un échec), récompense seulement si la pub est regardée jusqu'au bout. En Debug, sans pub prête, la pub simulée prend le relais ; en Release, le bouton affiche « Pub en préparation… ».
- Réglages : « Confidentialité des pubs » (formulaire de Google) quand la loi l'exige.
- Builds Debug et Release OK ; l'app démarre dans le simulateur avec le SDK (Info.plist vérifié).

**À faire**
- ~~Compte AdMob~~ fait par Jules : App ID `…~7375419878` dans `PearlInc-Info.plist`, bloc « 3 huîtres » `…/7814403570` en Release (Debug garde le bloc de test). `site/app-ads.txt` prêt.
- Mettre `app-ads.txt` en ligne (déploiement de `site/`), publier le message RGPD dans AdMob, relier l'app à sa fiche App Store dans AdMob après la sortie.
- ~~Politique de confidentialité~~ fait : `docs/pages-app/confidentialite/` et `en/privacy/` (AdMob, formulaire de Google, préchargement au lancement, pas d'ATT, Google responsable indépendant) ; étiquette App Privacy détaillée dans `docs/app-store-juridique.md` §2. Pistage tranché par Jules : **pubs non personnalisées seulement** (réglage du SDK), étiquette « Pistage : Non », pas d'ATT.
- Décider si l'on demande le suivi (ATT) : meilleures recettes, mais déclaration de pistage.

**Fragile**
- Pas encore vu une vraie pub de test à l'écran : dans le simulateur, « Jouer sans compte » échoue (« La connexion n'a pas abouti », appel `/auth/v1/signup` de Supabase), sans rapport avec AdMob. À vérifier (connexion anonyme activée dans Supabase ?).
- Ne jamais cliquer sur ses propres vraies pubs (suspension du compte AdMob) : déclarer son iPhone comme appareil de test.

---

## 2026-10-13 (suite 9) · Jules · Claude Code · branche `jules/ios-app`

Site : pages légales réduites à ce que fait vraiment pearl-inc.app aujourd'hui (prototype + inscription), en attendant l'app.

**Fait**
- Confidentialité du site (`/confidentialite/`, `/en/privacy/`) réécrite en version courte : prototype sans collecte, inscription Tally (données, finalités, effacement 6 mois après la sortie, consentement), hébergement, droits et CNIL.
- Les pages propres à l'app (confidentialité complète, conditions d'utilisation, aide) sortent du site et sont gardées dans `docs/pages-app/` (même arborescence) : à remettre dans `site/` à la soumission App Store, avec les infos de l'éditeur. Liens du pied de page de l'accueil : Confidentialité · Mentions légales.
- Éditeur : MJHstudio n'existe pas encore ; ce sera la micro-entreprise de Mathys (EI), avec un nom commercial éventuel. Champs jaunes adaptés.

- Éditeur rempli partout (site et `docs/pages-app/`) : **Mathys Hosin EI**, sans nom commercial, 212 rue de Solférino, 59800 Lille (code postal du répertoire SIRENE), SIREN 994 477 008, RNE (activité 70.22Z, section M), TVA non applicable (art. 293 B du CGI). Seul le médiateur reste à compléter, dans les conditions de l'app.

**À faire**
- Activité de la micro de Mathys (70.22Z, conseil) : ajouter l'édition de jeux (58.21Z) avant de vendre des achats intégrés.
- Avant la soumission : remettre `docs/pages-app/` dans `site/`, éditeur = Mathys EI (et médiateur) ; l'app pointe déjà vers `/support/`, `/conditions/`, `/confidentialite/`.

**Fragile**
- Tant que `docs/pages-app/` n'est pas remis en ligne, les liens Aide et Conditions des Réglages de l'app mènent à une page introuvable (sans conséquence avant la sortie).

---

## 2026-10-13 (suite 8) · Jules · Claude Code · branche `jules/ios-app`

App iOS : suppression du compte et écran Réglages (exigences d'Apple).

**Fait**
- Supabase : fonction `public.delete_account()` (migration `supabase/migrations/20261013200000_delete_account.sql`, appliquée au projet) : supprime **seulement le compte de l'appelant** ; profils, sauvegardes, skins et droits partent en cascade. Exécutable par les joueurs connectés, pas par les visiteurs anonymes. Testé côté serveur (refus sans connexion, rien d'effacé pour un compte inexistant). L'avertissement de Supabase sur cette fonction est voulu.
- App : écran **Réglages** (roue dentée dans la barre du haut de la Pêche) : compte (type, e-mail, identifiant à copier pour le support), se déconnecter (avertissement sans compte), **supprimer mon compte** (confirmation, puis partie remise à zéro et skins achetés relus auprès d'Apple), vibrations (réglage respecté par `Haptics`), probabilités, restaurer les achats, aide, écrire au support (identifiant dans l'objet), confidentialité, conditions, mentions légales, version.
- Pages du site et guide juridique mis à jour (suppression dans l'app).

**À faire**
- **Connexion avec Apple** : à la suppression, révoquer aussi le jeton Apple (API REST d'Apple, clé côté serveur : fonction Supabase Edge), une fois le fournisseur Apple configuré.
- Tester la suppression de bout en bout avec un vrai compte de test (TestFlight).

**Fragile**
- Si une nouvelle table liée aux joueurs est ajoutée, elle doit référencer `profiles` (ou `auth.users`) avec `ON DELETE CASCADE`, sinon la suppression échouera ou laissera des données.

---

## 2026-10-13 (suite 7) · Jules · Claude Code · branche `jules/ios-app`

Juridique pour l'App Store : pages publiques, manifeste de confidentialité, guide des questionnaires d'Apple.

**Fait**
- Pages du site, FR et EN, au style de l'accueil (`site/legal.css`) : confidentialité (`/confidentialite/`, `/en/privacy/`), conditions d'utilisation (`/conditions/`, `/en/terms/`), aide et contact avec FAQ (`/support/`, `/en/support/`), mentions légales (`/mentions-legales/`, `/en/legal-notice/`). Liens en bas de l'accueil. Éditeur : entreprise individuelle (MJHstudio), contact laplateformemjh@gmail.com. Supabase vérifié : région eu-west-1 (Irlande).
- App iOS : manifeste `PrivacyInfo.xcprivacy` (e-mail et identifiant liés, pas de pistage, `UserDefaults` raison CA92.1), `ITSAppUsesNonExemptEncryption = NO`, liens conditions et confidentialité sur l'écran de connexion.
- `docs/app-store-juridique.md` : URL à saisir, étiquette « App Privacy », chiffrement, âge, statut de commerçant (DSA), règles Apple encore manquantes, points à faire valider.

**À faire**
- Remplir les champs jaunes « À compléter » (nom, adresse, téléphone, SIREN, TVA, médiateur), **puis seulement** mettre ces pages en ligne (fusion dans `main`).
- Adhérer à un médiateur de la consommation ; faire relire par un juriste (§6 du guide).
- Dans l'app : suppression du compte, écran Réglages, pub réelle ou retirée, sauvegarde en ligne ou phrase de connexion à changer.

**Fragile**
- Politique, manifeste et étiquette App Store doivent changer ensemble à chaque nouvelle donnée (sauvegarde en ligne, régie publicitaire, mesure d'audience).

---

## 2026-10-13 (suite 6) · Jules · Claude Code · branche `jules/ios-app`

Formulaires Tally : vérifiés, déjà à jour.

**Fait**
- Les deux formulaires (FR J9N7AJ, EN Me9oLY) promettent déjà le **skin d'huître exclusif**, dans l'éditeur comme dans la version publiée ; plus aucune « perle de bienvenue ». Aucun changement en attente de publication. Notification par e-mail à chaque inscription : activée sur les deux.
- `docs/tally-formulaire.md` aligné sur les textes réellement publiés (FR et EN).

**À faire**
- Inscription test FR et EN une fois, puis la supprimer dans Tally.

---

## 2026-10-13 (suite 5) · Jules · Claude Code · branche `jules/ios-app`

Icône de l'app partout (app iOS, site, fichier à télécharger) ; le prototype du site montre mieux qu'on ouvre l'iPhone.

**Fait**
- `scripts/make-app-icon.sh` (+ `scripts/app-icon.swift`) : l'icône du site (la perle dans le lagon) redessinée fidèlement et exportée en une fois : icône de l'app iOS 1024 px carrée et opaque (`ios/PearlInc/Assets.xcassets/AppIcon.appiconset`, réglage `ASSETCATALOG_COMPILER_APPICON_NAME`), `docs/icone/` (carrée, et arrondie sur fond transparent, pour les réseaux), `site/favicon.svg` (le SVG de la page), `favicon-32/64.png`, `favicon.ico`, `apple-touch-icon.png`, liens dans le `<head>`.
- Prototype (`site/index.html`) : tant que personne n'y a touché, l'iPhone s'entrouvre seul (26°) toutes les ~4 s puis se referme (rien n'est révélé ni compté dans l'essai) ; l'aide devient une pastille de verre placée sous l'iPhone, avec une flèche ← qui pousse dans le sens du geste. L'arc d'angle et le message d'état restent cachés pendant ces entrouvertures. « Réduire les animations » : ni entrouverture, ni flèche animée. Vérifié dans Safari (simulateur iPhone 17 Pro).

**À faire**
- Mettre le site en ligne (rien n'est publié tant que ce n'est pas déployé sur Vercel).

---

## 2026-10-13 (suite 4) · Jules · Claude Code · branche `jules/ios-app`

La doc suit la nouvelle promesse de la page : les inscrits recevront le **skin Première marée** (plus de « perle de bienvenue »).

**Fait**
- Branche mise à jour depuis `main` (texte du site modifié par Jules sur GitHub le 2026-10-12 : « un skin d'huître exclusif »).
- `docs/duo-gadget.md` : périmètre (§4), §6 réécrit (« Le skin des inscrits : Première marée », deux pistes pour le donner : par le compte Supabase avec la même adresse que sur Tally, ou par un lien dans l'e-mail de lancement), mesure de traction, calendrier, ordre des coupes, accord entre associés.
- Écran de connexion de l'app : « Utilise la même adresse pour récupérer ta coquille Première marée ».

**À faire**
- Les formulaires Tally publiés (FR et EN) promettent encore une « perle de bienvenue » : textes d'introduction, de remerciement et de confidentialité à changer, puis `docs/tally-formulaire.md` (un avertissement y est posé).
- Choisir la piste pour donner le skin (compte ou lien) et la date limite.

---

## 2026-10-13 (suite 3) · Jules · Claude Code · branche `jules/ios-app`

App iOS : les trouvailles en relief, comme dans la webapp.

**Fait**
- `Art/Canvas2D.swift` : un petit équivalent du Canvas 2D du navigateur au-dessus de `GraphicsContext` (chemins transformés à la construction, dégradés et traits dans le repère courant, `evenodd`, pointillés, découpe, texte). Les dégradés radiaux à deux centres (le reflet décentré qui donne le volume) sont reconstruits fidèlement par disques emboîtés.
- `Art/FindArt.swift` : les 25 objets de `src/art/finds.ts` portés presque ligne à ligne (mêmes noms, même ordre), avec leurs animations (téléphone qui clignote, boussole qui hésite, jeton qui décompte, diode, éclats). Comparé côte à côte avec le rendu de la webapp : identique, à la police près (SF au lieu de Figtree / Young Serif).
- Branchés dans l'huître ouverte (à la place de la perle, dans leur lumière qui vacille), sur la carte (animée) et dans la liste « Trouvailles » de la collection. `PearlLook(find:)` (la boule lumineuse provisoire) supprimé.

**Fragile**
- Pour un nouvel objet dans `src/art/finds.ts`, il faut le porter aussi dans `FindArt.swift` (pas d'export automatique du dessin).
- Le volume des objets passe par ≈ 40 disques par dégradé radial : à surveiller si plusieurs trouvailles s'affichent en même temps (collection).

---

## 2026-10-13 (suite 2) · Jules · Claude Code · branche `jules/ios-app`

App iOS : direction artistique du prototype de pearl-inc.app, ouverture corrigée, bénitier redessiné, pub récompensée, achats intégrés.

**Fait**
- **Ouverture corrigée** : le Core tire l'huître suivante dès la révélation, et l'écran dessinait déjà sa perle pendant le suspense (la perle « changeait au dernier moment »). `GameModel.current` garde l'huître ouverte jusqu'à la carte refermée. Le couvercle finit de s'ouvrir en douceur, la perle palpite et son halo envahit l'écran pendant le suspense, éclair blanc pour les ★ (comme la webapp). Réglages `revealLidSettleMs` / `revealFlashMs` dans `src/tuning.ts`.
- **Lagon du prototype** (`Art/LagoonArt.swift`, port de `src/art/lagoon.ts`) : eau, récif, sable et rides, galets, étoiles de mer, rayons, caustiques, algues, poissons, bulles, ombre de l'huître, vignette. Sert à la Pêche (l'horizon suit l'huître), à la connexion, à la collection, à la boutique et aux aperçus des coquilles.
- **Verre clair du prototype** (`Glass.swift`), **cartes** aux couleurs de chaque perle avec vitrine, stats, reflet holographique (`PearlCardView`, `Art/CardStyle.swift`), **collection** en cases comme le prototype (toucher = plus belle carte), probabilités affichées (collection et boutique).
- **Bénitier redessiné** (`Art/ClamArt.swift`) : vu de dessus comme l'huître, 5 ou 6 gros plis avec écailles, bord festonné, porcelaine et manteau bleu-vert irisé tacheté ; il s'ouvre exactement comme l'huître. `docs/skins.png` régénérée (`sh scripts/make-skin-sheet.sh`).
- **Économie** : la poussière d'or n'achète plus de perles (TS + Swift + tests). **Pub récompensée** : 3 huîtres, 3 fois par jour (`Economy.rewardedAdOysters/PerDay`, `PlayerState.claimAdReward`), pub simulée de 5 s (`Platform/RewardedAds.swift`, `Features/SimulatedAdView.swift`).
- **Achats intégrés StoreKit 2** (`Platform/Store.swift`) : packs d'huîtres et de poussière, skins (achat ou poussière), « Restaurer les achats », prix venant de StoreKit. `ios/PearlInc.storekit` (prix de test) et schéma Xcode partagé qui l'utilise au lancement depuis Xcode.

**À faire**
- Lancer depuis Xcode pour tester les achats (le simulateur lancé hors Xcode affiche « Indisponible »). Vérifier dans le schéma (Run → Options → StoreKit Configuration) que `PearlInc.storekit` est bien choisi.
- App Store Connect : créer les 7 produits (mêmes identifiants), accord « Paid Apps » et coordonnées bancaires.
- Choisir la régie publicitaire (AdMob proposé) et remplacer la pub simulée ; consentement RGPD.

**Fragile**
- Les caustiques sont dessinées à partir d'une planche de motifs : le décalage doit rester ramené à un motif (sinon, avec le temps compté depuis 2001, plus rien ne s'affiche sur iPhone).
- Fluidité à vérifier sur un vrai iPhone : lagon complet redessiné à chaque image, plus le verre.
- Achats consommables : livrés puis `finish()` ; un plantage entre les deux pourrait livrer deux fois (rare).

---

## 2026-10-13 (suite) · Jules · Claude Code · branche `jules/ios-app`

L'app iOS (MVP « gadget ») prend la direction de l'écran de connexion : lagon lumineux et verre (glassmorphism).

**Fait**
- `Features/Glass.swift` : le verre commun à tout le jeu. `glass(_:)` / `glassPanel()` (flou du lagon + liseré clair en dégradé, liseré or possible), `lagoonTitle()`, `PearlButtonStyle` (nacre) et `GlassButtonStyle` (verre), avec une taille `compact` et un état désactivé estompé. Les styles quittent `LoginView.swift` (inchangés à l'écran).
- `LagoonBackground(dim:)` : voile d'eau profonde pour les écrans pleins de texte.
- Pêche : le lagon animé (rayons de lumière) remplace le dégradé ; pastilles du haut et message sous l'huître en verre.
- Carte de révélation et « La marée remonte… » : panneaux de verre (liseré or pour la carte), boutons nacre / verre.
- Collection et Boutique : fond lagon assombri, comptoir, cases de l'encyclopédie, listes et coquilles en panneaux de verre (coquille équipée : liseré or).
- Missions : feuille en verre au-dessus du lagon.

**À faire**
- Essayer sur iPhone : lisibilité du blanc sur le haut clair du lagon, fluidité (rayons animés + flou derrière les panneaux).
- Sur iOS 26, envisager le vrai « Liquid Glass » (`glassEffect`) derrière `#available`, en gardant ce verre pour iOS 18.

---

## 2026-10-13 · Jules · Claude Code · branche `jules/ios-app`

Connexion des joueurs dans l'app iOS (Supabase), écrite par Jules ; le domaine pearl-inc.app est branché sur Vercel.

**Fait**
- Domaine **pearl-inc.app** relié au projet Vercel de la page d'inscription (fait par Jules).
- Écran de connexion (`Features/LoginView.swift`) sur fond de lagon animé (`Art/LagoonBackground.swift`) : **Sign in with Apple**, **code à 6 chiffres par e-mail**, ou **jouer sans compte** (joueur anonyme Supabase, à lier plus tard). Messages d'erreur en français.
- `Platform/AuthViewModel.swift` (session, nonce Apple, OTP e-mail, anonyme, déconnexion) et `Platform/SupabaseClient.swift` (URL du projet + clé « publishable », faite pour être embarquée : la sécurité repose sur les règles RLS).
- `PearlIncApp.swift` : écran de connexion tant qu'il n'y a pas de session, puis le jeu (onglets inchangés). L'écran provisoire « Connecté » de Jules n'est pas repris, le jeu existe déjà.
- Projet Xcode : paquet `supabase-swift` (2.x, versions figées dans `Package.resolved`), capacité Sign in with Apple (`ios/PearlInc.entitlements`).

**À faire**
- Dans Supabase : activer les fournisseurs Apple (Services ID + clé), e-mail en mode code (modèle d'e-mail avec `{{ .Token }}`) et connexion anonyme ; vérifier que le projet est hébergé dans l'UE.
- Dans le portail Apple Developer : cocher Sign in with Apple sur l'App ID `app.pearlinc.PearlInc`.
- Bouton « Se déconnecter » / « Lier mon compte » quelque part dans le jeu (rien pour l'instant).
- Synchroniser la progression (aujourd'hui toujours locale, malgré « Ta collection te suit ») et relier l'e-mail aux inscrits Tally (huître pionnière).

**Fragile**
- **Build non vérifié** dans cette passe (compilation interrompue) : à lancer dans Xcode. Points à surveiller avec Swift 6 : la fermeture passée à `Task` dans `AuthViewModel.run`.
- Premier lancement **sans réseau** : même « Jouer sans compte » demande Supabase, on reste bloqué sur l'écran de connexion.

---

## 2026-10-08 (suite 10) · Jules · Claude Code · branche `jules/ios-app`

Formulaires d'inscription Tally créés, publiés et branchés sur la page pearl-inc.app.

**Fait**
- Tally FR https://tally.so/r/J9N7AJ et EN https://tally.so/r/Me9oLY : e-mail (obligatoire), téléphone (iPhone Duo / autre iPhone / Android, facultatif), consentement (obligatoire), résumé de confidentialité (contact laplateformemjh@gmail.com), champs cachés `utm_source`, `utm_campaign`, `lang`, `bouton`, page de remerciement. Couleurs et police du site, icône du site en logo.
- `site/index.html` : `TALLY_URLS` renseigné ; chaque visiteur va vers le formulaire de sa langue (FR / EN).
- `docs/tally-formulaire.md` à jour (liens, 3 options de téléphone, contact).

**À faire**
- Dans Tally (Settings) : activer la notification par e-mail à chaque inscription.
- Vérifier que Tally héberge bien les données dans l'UE (texte de confidentialité).
- Envoyer une inscription test de chaque langue une fois le site en ligne, puis la supprimer.

---

## 2026-10-08 (suite 9) · Jules · Claude Code · branche `jules/ios-app`

Ouverture du bénitier en 3D ; forme stable de chaque huître pendant la révélation.

**Fait**
- Retour de Jules : le bénitier ouvert était bizarre (valve retournée en « ailes », puis valve écrasée à plat). La valve du haut est maintenant **modélisée en 3D** (`ClamArt.drawLidMesh`) : un dôme à gros plis, maillé (48 × 14 facettes), éclairé du haut à gauche, dessiné du plus loin au plus proche. Elle bascule en arrière en restant attachée le long du bord de la coquille, jusqu'à 72° : on voit son relief, puis le manteau et la perle. Fermée, c'est toujours le dessin 2D que Jules aime (fondu vers la 3D sur les premiers degrés).
- Variété du bénitier : largeur, nombre (2,5 ou 3,5) et profondeur des ondulations tirés des phases, comme les bosses et la dentelure de l'huître.
- Correction : la forme de l'huître changeait au moment de la révélation (la graine suivait le numéro de série, qui avance à l'ouverture). `GameModel.shapeSeed` ne change plus qu'à l'huître suivante.
- `docs/skins.png` : ajout de « Chaque huître est unique » (4 tirages de l'huître et du bénitier) et des étapes de l'ouverture du bénitier (0° à 180°).

**Fragile**
- Le maillage 3D du bénitier (≈ 670 facettes triées à chaque image) : à surveiller sur iPhone avec le reste du dessin.

---

## 2026-10-08 (suite 8) · Jules · Claude Code · branche `jules/ios-app`

Les huîtres de l'app iOS reprennent la direction artistique de la webapp ; bénitier refait d'après une photo.

**Fait**
- Retour de Jules : les huîtres iOS ne ressemblaient pas à celles du jeu web. Le dessin de la webapp est porté en Swift, à l'identique : `Art/ShellArt.swift` (contour, bandes de croissance en relief avec ombre portée, stries, taches, algues, balanes, reflet ; nacre irisée ; chair, depuis `src/art/shell.ts`), `Art/PearlArt.swift` (perle selon ses traits : forme, reflet, marques, fêlure ; halo, depuis `src/art/pearl.ts`), `Art/OysterArt.swift` (scène composée comme `oysterScreen.ts` : pénombre, halo, couvercle qui s'assombrit en se redressant, lumière qui filtre).
- Skins = variantes du même dessin (`ShellPalette`) : huître du lagon (couleurs exactes de la webapp), Première marée (sable, écume, liseré argent), huître d'or (bandes dorées, nacre champagne, éclats). **Bénitier** (`Art/ClamArt.swift`), d'après la photo de Jules : deux valves crème aux larges plis écailleux, jointure en zigzag aux lèvres blanches, manteau sombre irisé (bleu-vert, taches) entre les valves ; la valve du haut se soulève comme le couvercle de l'huître (le geste ne change pas), la perle se pose sur le manteau.
- Les couleurs des skins vivent avec le dessin (`Art/SkinLook.swift`) ; le catalogue (`appEconomy.ts`) ne garde que l'identifiant et la silhouette (`oyster` / `clam`).
- `docs/skins.png` régénérée.

**À faire**
- Porter aussi le lagon de la webapp (`art/lagoon.ts` : rayons, sable, caustiques, algues) : le fond iOS est encore un simple dégradé.
- Vérifier la fluidité sur iPhone : la webapp garde l'extérieur de la coquille en cache (image), l'app le redessine à chaque image.

---

## 2026-10-08 (suite 7) · Jules · Claude Code · branche `jules/ios-app`

Économie de l'app iOS codée : stock, poussière d'or, comptoir, missions du jour, skins.

**Fait**
- `src/core/appEconomy.ts` (nouveau catalogue, app iOS seulement) : barème de revente (◆ 1 … ★★ 40 ✦), prix des perles manquantes (◆ à ◆◆◆ seulement), huître à 20 ✦, missions du jour, 4 skins (huître du lagon, bénitier, première marée, huître d'or) avec leurs couleurs, produits de la boutique. Exporté vers `catalog.json`. `tests/app-economy.test.ts` vérifie l'équilibre (≈ 2,5 ✦ par huître, bénitier en 2 à 5 semaines, ★ non achetables, huître d'or en achat seulement).
- `ios/PearlCore` : `Stock` (miroir de `stock.ts`), `Missions` (3 par jour, graine = la date), `Economy`, et `Player` : stock consommé à l'ouverture, revente (jamais le dernier exemplaire ; « tout revendre » garde le plus bel exemplaire et les perles marquées), achats en poussière (huître, perle manquante, skin), skins possédés et équipé, missions et bonus, pièce d'or engloutie = 5 ✦. Les anciennes sauvegardes se chargent avec des valeurs de départ. **20 tests Swift.**
- App : barre du haut (huîtres + minuteur, poussière qui rebondit, missions avec pastille), écran « La marée remonte… » avec une huître à 20 ✦, fiche des missions, comptoir dans la collection (revente en lot ou à l'appui long, achat des perles manquantes), onglet **Boutique** (skins avec aperçu, équiper / acheter en poussière ; achats Apple désactivés), bouton Partager sur la carte (texte ; compte pour la mission).
- Dessin des skins (`Art/OysterArt.swift`, `Art/SkinLook.swift`) : silhouette et matière par skin, lumière de la perle intacte. Bénitier : grands plis en éventail, bord ondulé, manteau bleu-vert tacheté qui dépasse. Huître d'or : or martelé, reflet, éclats qui scintillent.
- `scripts/make-skin-sheet.sh` → `docs/skins.png` : planche des 4 skins, fermés et ouverts, dessinée sur le Mac avec le code de l'app.

**À faire**
- StoreKit 2 (skins, recharges, poussière), calendrier de connexion, tutoriel, image story, Core Haptics, Game Center, iCloud.
- Lancer l'app dans le simulateur (plateforme iOS à installer dans Xcode).

**Fragile**
- Le changement de jour des missions suit l'heure du téléphone (comme la webapp).
- La mission « Partager » compte le toucher du bouton, pas le partage effectif (iOS ne dit pas si le partage a abouti).

---

## 2026-10-08 (suite 6) · Jules · Claude Code · branche `jules/ios-app`

Équilibre de la poussière d'or et missions du jour (app iOS), sans code.

**Fait**
- `docs/duo-gadget.md` §6 quater : barème de revente de l'app (◆ 1, ◆◆ 2, ◆◆◆ 5, ★ 15, ★★ 40 ✦), missions du jour (3 par jour, 5 ✦ chacune, + 10 ✦ les trois), calcul par profil de joueur (≈ 65 à 200 ✦ par jour), bénitier à 2 000 ✦ ou 2,99 €, packs de poussière revus (400 / 1 200 / 3 000 ✦), prix en poussière (huître 20 ✦, pièces ◆ à ◆◆◆). Le bénitier n'est plus offert par le calendrier.
- AGENTS.md §6 : décision.

**À faire**
- Coder ce barème dans un catalogue (exporté vers l'app, pas dans les écrans), puis le stock, le comptoir, les missions et la boutique.

---

## 2026-10-08 (suite 5) · Jules · Claude Code · branche `jules/ios-app`

Création de l'app iOS, et périmètre de la 1.0 App Store.

**Fait**
- `ios/PearlCore` (Swift Package, logique pure) : générateur à graine, réglages, catalogue, tirage avec garantie et trouvailles, traits des perles, moteur d'ouverture et lustre, conversion pouce → angle, état du joueur, valeur des cartes. **8 tests Swift passent** et donnent exactement les mêmes résultats que le TypeScript (400 huîtres, ouvertures, fêlures, lustre, valeurs).
- `tests/ios-export.test.ts` + `npm run ios:export` : exporte `catalog.json` (catalogues et réglages) et `parity.json` (cas de référence) ; le test échoue si l'export est périmé. `SHAPE_WEIGHTS` et `OVERTONE_WEIGHTS` sont maintenant exportés par `core/pearlTraits.ts` (aucun changement de comportement).
- `ios/PearlInc.xcodeproj` + `ios/PearlInc` (SwiftUI, iOS 18+) : Pêche (lagon, huître dessinée par code, couvercle qui se soulève, lumière de la couleur de la perle, tremblement des rares, fêlure), geste du pouce avec résistance, « pop », ouverture automatique en fin de course, haptique, suspense selon la rareté, carte de révélation (perle, trouvaille ou huître vide), collection (encyclopédie en 2 colonnes, trouvailles, dernières perles), sauvegarde, action VoiceOver « Ouvrir l'huître ». Onglets du système (Duo). **La build passe** pour le simulateur.
- `docs/duo-gadget.md` : périmètre choisi par Jules (trouvailles, poussière d'or et revente, skins bénitier et huître d'or, boutique : recharges, poussière, skins), ajouts proposés (calendrier, Game Center, iCloud, notification, réglages), points d'attention de la boutique (probabilités avant achat, Belgique, pièces ★, consommables), architecture réelle.
- AGENTS.md : dossier `ios/`, commandes, deux décisions (§6).

**À faire**
- Installer la plateforme iOS dans Xcode (Settings → Components) pour lancer l'app dans le simulateur, et choisir l'identifiant définitif de l'app (`app.pearlinc.PearlInc` provisoire, il ne pourra plus changer une fois sur l'App Store).
- Prochaines passes : stock d'huîtres, poussière d'or et comptoir, skins, boutique StoreKit 2, tutoriel, partage, Core Haptics, décor plus riche, anglais, puis la charnière avec Xcode / iOS 27.1.

**Fragile**
- Le projet Xcode a été écrit à la main (format Xcode 16+ à dossiers synchronisés) : tout fichier ajouté dans `ios/PearlInc/` est pris automatiquement, sans toucher au projet.
- Après tout changement de catalogue ou de réglage dans `src/` : `npm run ios:export`, sinon `npm test` échoue.

---

## 2026-10-08 (suite 4) · Jules · Claude Code · branche `jules/duo-gadget`

Lecture des règles d'Apple pour l'iPhone Duo.

**Fait**
- `docs/duo-gadget.md` §5 : règles de « Designing for iPhone Duo » et « Preparing your app for iPhone Duo » (deux écrans, poses, zones réservées dont le pli, barres sur le côté, jeux qui remplissent l'écran dans chaque pose) et ce qu'elles changent pour Pearl Inc. (le pli = la charnière de l'huître, onglets du système, rien ne se perd entre les écrans).
- §7 : **l'API de la charnière existe** (`DeviceHinge` en SwiftUI, angle continu + état, `.onHingeChange`, iOS 27.1 bêta). Absente du SDK iOS 26.2 de Xcode 26.3, installé sur le Mac.

**À faire**
- Installer la version d'Xcode qui fournit iOS 27.1 ; mesurer la fréquence de l'angle et le passage d'un écran à l'autre (simulateur du Duo, Device Hub).

---

## 2026-10-08 (suite 3) · Jules · Claude Code · branche `jules/duo-gadget`

Image d'aperçu des liens et skins d'huître.

**Fait**
- `site/og.jpg` (1200×630) : lagon, huître ouverte, perle dorée qui brille, « Pearl Inc. », « iPhone Duo », « pearl-inc.app ». Pas de phrase traduite, pour servir aux posts FR et EN. Dessinée avec le code de la page, par `sh scripts/make-og.sh` (Chrome sans fenêtre, `scripts/og-image.js`).
- `site/index.html` : balises Open Graph et Twitter (titre, description, image), adresse canonique `https://pearl-inc.app/`.
- `docs/duo-gadget.md` : poussière d'or et **skins d'huître** dans le périmètre (§6 bis) : cosmétique pur, signal de lumière intact, visible sur l'écran extérieur du Duo et dans les partages ; 3 skins gagnables ou achetables, « Première marée » pour les inscrits, **huître d'or à 9,99 € en achat seulement**. Règles Apple des achats intégrés, indicateurs et calendrier mis à jour. **Proposition, à valider entre associés.**

**À faire**
- Après l'achat du domaine : vérifier l'aperçu avec les outils de LinkedIn (Post Inspector) et de X. Si le domaine change, changer les adresses absolues dans `site/index.html`.

**Fragile**
- `make-og.sh` lit le code de dessin dans le `<script>` qui suit three.js : si la page change de structure, adapter la commande `awk`.

---

## 2026-10-08 (suite 2) · Jules · Claude Code · branche `jules/duo-gadget`

Page d'inscription prête pour la mise en ligne.

**Fait**
- `site/index.html` : la page « Pearl Inc. pour iPhone Duo » (fournie par Jules) entre dans le dépôt. Branchement Tally : un lien par langue (`TALLY_URLS`), et la page transmet au formulaire `utm_source`, `utm_campaign`, `lang` et le bouton cliqué (`fin-essai`, `haut-de-page`, `bas-de-page`, `menu`). Vérifié dans le navigateur (provenance, changement de langue, aucune erreur).
- `docs/tally-formulaire.md` : contenu du formulaire FR / EN, champs cachés, texte de confidentialité (RGPD), réglages, relevés, liens de campagne.
- `.claude/launch.json` : serveur `site` (port 4280) pour prévisualiser la page.
- AGENTS.md : dossier `site/` et décision de mise en ligne (§6).

**À faire**
- Jules : créer les formulaires Tally, coller les liens ; acheter le domaine ; projet Vercel avec **Root Directory = `site`**.
- Image d'aperçu de lien (Open Graph, 1200×630) : la page n'en a pas, les posts LinkedIn et X seront sans visuel.
- Page de l'écrin pour la semaine 2.

**Fragile**
- Sans liens Tally, les boutons affichent « Les inscriptions ouvrent très bientôt ».

---

## 2026-10-08 (suite) · Jules · Claude Code · branche `jules/duo-gadget`

Périmètre du premier jeu App Store (« gadget » Duo), sans code.

**Fait**
- `docs/duo-gadget.md` : app SwiftUI native appelée **Pearl Inc.**, réduite au geste d'ouverture (huître, 8 perles, carte, collection, stock, partage, perle de bienvenue), qui grandira par mises à jour. Calée sur la page d'inscription et le plan de campagne X / LinkedIn (12 – 25 oct., décision huître / écrin le 25). Règles Apple à respecter, questions sur l'API de la charnière, architecture `ios/` (Core Swift pur, réglages partagés en JSON, tests de parité avec le TypeScript), indicateurs de traction, calendrier proposé (sortie vers mi-novembre plutôt que le 23 octobre).
- Lien vers ce document dans AGENTS.md §1.

**À faire**
- Valider le périmètre entre associés, puis inscrire les décisions en §6 (SwiftUI, une seule app, date de sortie, perle de bienvenue).
- Installer Xcode, ouvrir le compte Apple Developer, réserver le nom.

**Fragile**
- Tout repose sur l'API de la charnière, encore inconnue (§7 du document) : la vérifier avant de promettre une date.

---

## 2026-10-08 · Jules · Claude Code · branche `jules/pearl-inc`

La Maison redessinée en maison de poupée (choix de Jules), qui grandit jusqu'à Pearl Inc.

**Fait**
- `art/house.ts` réécrit : vue en coupe de trois quarts (projection oblique : un pas vers le fond décale à droite et vers le haut), sur pilotis au bout du ponton, la nuit. Pièces avec mur du fond, mur de gauche et sol (papier peint, lambris, parquet ou marbre), meubles en volume (faces avant, dessus, côté), coupes des murs et planchers, côté droit en bardage, toit à pignon avec l'enseigne, cheminée qui fume, lanterne qui vacille et se reflète dans l'eau.
- Lettres → pièces : la porte (mur de gauche de la boutique, clouée de planches avant), la lanterne, l'enseigne (« R SE » délavée → Maison Rose → Pearl Inc.), la fenêtre et le carnet (bureau de Rose, avec son portrait et une bougie), l'établi (atelier, panneau à outils), la vitrine (avec ta plus belle pièce sous verre), la boîte (grenier, elle pulse). Avant sa lettre, une pièce dort : pénombre, draps sur les meubles, toiles d'araignée.
- `houseStage(level)` (Core) = rang du joueur. Étapes : 0 cabane délavée, toit troué ; 1 l'étage ; 2 la boutique repeinte, jardinières, le chat ; 3 Pearl Inc. (façade claire et dorée, salon avec lustre et présentoirs, fanion, voiliers au mouillage) ; 4 l'aile du musée (socles, cloches de verre, tableaux, toit-terrasse) ; 5 la tour au dôme doré.
- Le décor fixe est dessiné une fois (cache par taille et par état) ; seuls les étoiles, l'eau, la fumée et les lumières s'animent.
- Écran : la scène occupe toute la largeur sous le titre.

**À faire ensuite**
- Toucher une pièce pour l'afficher en grand, avec son histoire (et plus tard ce qu'elle débloque).
- Décider du sort de la carte des marées (Codex) ; fonte des trouvailles en double ; fonctions à débloquer (Lagon, commandes, vitrine qui vend).

**Fragile / à surveiller**
- Les pièces des étapes 3 à 5 (salon, musée, tour) sont du décor : rien à y faire pour l'instant.
- Lisibilité des petits détails sur iPhone SE (la Maison est dessinée à environ 110 px par pièce).

**Vérification**
- `npm test` : 17 fichiers, 148 tests passés (`houseStage`). `npm run build` : OK.
- Les six étapes rendues à part dans le navigateur, et l'écran Maison au format 375 × 812 sur la partie de Jules (lecture seule : le calendrier du jour a été masqué le temps de la capture, puis la page rechargée, rien n'a été récupéré).

## 2026-10-06 (suite) · Jules · Claude Code · branche `jules/pearl-inc`

Perles uniques, bijoux variés, puis chasse aux bugs d'affichage et de mécanique (demande de Jules : « tout ce qui rend le jeu cheap »).

**Perles et bijoux**
- `core/pearlTraits.ts` : forme, reflet, marque rare (4 %), tirés avec la perle et sauvegardés ; facteurs de valeur. Anciennes cartes : traits par défaut (`traitsOf`). Perles marquées protégées de la fonte en lot. L'atelier teinte les perles de leur reflet.
- `core/jewels.ts` : types pendentif et broche (diadème dès le rubis), 22 modèles, métaux par rareté, 8 tailles de pierre (pendentif goutte = poire, cœur = cœur). Noms générés (« Bague trilogie aux émeraudes », « Gourmette en or jaune »…).
- Dessins : `art/pearl.ts` (formes, reflets, jumelle, étoile, lune, cœur, cerclée), `art/jewel.ts` (un dessin par modèle, griffes qui suivent la taille). `jewelYOffset()` centre chaque modèle (cartes, story, écrin).
- Collection : carnet des variantes quand on touche une case (formes / reflets / marques ; types / tailles). 6 succès.

**Bugs corrigés**
- Écrin : griffes et arêtes des pierres dessinées géantes (disque blanc sur tout le plateau) — épaisseurs minimales en pixels ajoutées par Codex, alors que l'écrin dessine dans un repère où 1 = la largeur du coffret.
- Transitions : glissement latéral sur toute la largeur au lieu du fondu (qui superposait deux écrans) ; atelier et expertise montent depuis le bas au lieu d'apparaître en fondu.
- Pêche : la coquille passait sous la consigne sur petit écran (le pied changeait de hauteur après le calcul) ; jauge de réglage masquée par défaut (`showGauge`) ; la « main fantôme » était un disque blanc qui ressemblait à une perle → un doigt dessiné.
- Haut de l'écran : l'aide d'installation et le cap du jour se recouvraient ; les bannières de succès les recouvraient aussi → un seul panneau à la fois, effacé pendant une bannière.
- Récompenses : la montée de niveau (plein écran) passait après la file de bannières et pouvait surgir en plein geste → elle passe en premier, au moment calme.
- Stock au-delà du maximum affiché « 16/10 » → « 16 » en or.
- Cartes de bijoux étroites : la ligne de stats débordait (n° coupé) → deux lignes.
- Collection : bloc « Carnet de la Crique » de Codex retiré (doublon de l'en-tête) ; barre vide sous « Mes pièces ».
- Maison : le titre recouvrait le toit, le toit sortait du cadre → la scène est dessinée sous le titre.
- Carte des marées : onglet Maison allumé, plus de perles non trouvées dévoilées, note de développeur retirée.
- Textes : « 0 jour d'affilée », comptoir de poussière d'or, bulle du premier écrin, écusson de l'écrin.

**iPhone : barre d'état, Dynamic Island, barre d'accueil** (demande de Jules, pour la version installée)
- Marges de sécurité centralisées dans `--safe-top/bottom/left/right` (sur `:root`, avec `--hud-h` et `--tab-h`, désormais visibles aussi des fenêtres ajoutées hors de `#app`).
- Ajoutées là où elles manquaient : carte agrandie de la collection, fiches (hauteur max sous la barre d'état), montée de niveau et calendrier, lettre de Rose, probabilités de l'écrin.
- Paysage sur téléphone : message « Pearl Inc. se joue en tenant le téléphone droit » (iOS ne bloque pas toujours la rotation d'une app installée).
- Vérifié avec une Dynamic Island simulée (393 × 852, 59 px / 34 px) : Pêche, fiche de progression, carte agrandie, montée de niveau, lettre, atelier.
- Au passage : la recette « Broche Baroque » était une bague et le « Pendentif Soleil » un collier (types ajoutés depuis) ; les créations suivent le type de leur recette (`craftedType`), la broche de l'atelier porte ses perles au cœur, et les icônes de l'atelier sont centrées.

**À faire ensuite**
- La Maison en maison de poupée 3/4 et le passage à Pearl Inc.
- Doublons de trouvailles (fonte) ; décider du sort de la carte des marées.
- Fonctions à débloquer (Lagon, commandes, vitrine qui vend, outils).

**Fragile / à surveiller**
- Le réglage `showHud` est abandonné au profit de `showGauge` (faux par défaut) : ceux qui voulaient la jauge doivent la rallumer.
- Vérifier le glissement entre onglets sur un vrai iPhone (fluidité des canvas animés pendant 320 ms).

**Vérification**
- `npm test` : 17 fichiers, 147 tests passés. `npm run build` : OK.
- Parcours complet dans le navigateur sur une partie neuve, en 375 × 667 (iPhone SE) puis 375 × 812 : tutoriel, premier écrin, collection, Maison, lettre, atelier, carte, quêtes, comptoir, réglages, expertise. Sauvegarde de Jules remise ensuite.

## 2026-10-06 · Jules · Claude Code · branche `jules/pearl-inc`

Revue des passes de Codex avec Jules, puis : le jeu s'appelle **Pearl Inc.**, et les **trouvailles** arrivent dans les huîtres. Branche partie de `jules/codex-retention-maison` (les changements de Codex y sont encore, à retravailler).

**Retours de Jules sur la passe Codex**
- « Trop plat partout » : ce sont surtout les **dessins** (relief, lumière, matière). La Maison ne lui plaît pas : à refaire en **maison de poupée en 3/4** (vue en coupe, pièces visibles, qui grandit jusqu'à Pearl Inc.).
- Veut plus de contenu : objets plus variés (perles, bijoux, objets), des easter eggs dans les huîtres, des fonctions à débloquer.
- iPhone Duo : conseillé de ne pas attendre la fin du jeu ; petit test natif de la charnière dès qu'un Duo est disponible.

**Fait**
- **Pearl Inc.** : nom de l'app (manifeste, titre, icône), textes d'installation, partage, image story, dorures de l'écrin. La Maison garde l'enseigne « Maison Rose » jusqu'au rang de Joaillier (niveau 20), puis devient « Pearl Inc. — Joailliers » (`houseBrand()` dans `core/house.ts`). Clés de sauvegarde inchangées.
- **Trouvailles** (`core/finds.ts`) : 25 objets, 3 albums, 5 % des huîtres à la place de la perle. Effets : pièce d'or → 15 ✦, clé d'épave → 1 écrin, bouteille → un message (8 messages, choisis par le n° de série). Réputation comme une perle de même rareté (+ découverte). 5 succès (première trouvaille, 3 albums avec titre + 1 écrin, 1 secret). Les succès peuvent maintenant donner des écrins (`album: true`).
- **Dessins en relief** (`art/finds.ts`) : les 25 objets dessinés en code avec la même lumière (dégradé de matière, liseré, reflet, ombre de contact) ; quelques détails animés (compte à rebours du jeton, diode de la clé USB, aiguille de la boussole, inscription de l'anneau, éclats du diamant).
- Pêche : l'objet est dessiné dans la coquille, la lumière prend sa couleur et vacille ; carte « Ce n'est pas une perle… », son dédié, bouton Partager. Collection : volet « Trouvailles » (apparaît après la première), rangé par album avec avancement.

**À faire ensuite** (choix de Jules)
1. Perles uniques (forme, reflet, marques) et bijoux plus variés (types, métaux, tailles de pierre).
2. Dessins plus riches partout (coquille, perles, bijoux, décors).
3. La Maison en maison de poupée 3/4, et le passage à Pearl Inc.
4. Fonctions à débloquer (Le Lagon niv. 8, commandes clients, vitrine qui vend, outils de pêche).
5. Décider du sort de la carte des marées et de l'atlas de Codex (ses 15 « rumeurs » font doublon avec les trouvailles).

**Fragile / à surveiller**
- Les doublons de trouvailles ne se fondent pas encore en poussière d'or, et la poussière n'achète pas de trouvaille manquante.
- Le volet « Trouvailles » fait 4 onglets dans la collection : vérifier la largeur sur iPhone SE.
- Probabilités des perles changées (vide 9 %, blanche 38 %) : écart au cahier, à valider avec Mathys.

**Vérification**
- `npm test` : 16 fichiers, 138 tests passés. `npm run build` : OK.
- Dans le navigateur (375 × 812), sur une copie de la sauvegarde : ouverture d'une huître à trouvaille (jeton), carte, montée de niveau, volet Trouvailles, carte de la bouteille avec son message. Sauvegarde de Jules remise ensuite.

## 2026-10-06 · Codex · branche `jules/codex-retention-maison`

Atlas des trouvailles filtrable et projection enrichie des destinations, dans la DA « lagon lumineux + luxe ».

**Fait**
- Remplacement du cabinet de curiosités par l’Atlas : filtres synchronisés avec les destinations sur la carte, cartes en grille et compteurs de découverte.
- La Crique reprend les perles du catalogue V1 et leur état réel dans la collection : les perles inconnues restent anonymes, les découvertes affichent leur nombre d’exemplaires.
- Ajout de 15 trouvailles illustrées en SVG (cinq pour le Jardin d’algues, l’Épave des échos et la Faille d’azur), entre perles, bijoux et objets insolites.
- Les destinations futures restent verrouillées et leurs objets sont signalés comme des rumeurs. Aucun tirage, taux, valeur, récompense ou règle n’a changé.

**À faire ensuite**
- Choisir séparément les rumeurs qui méritent de devenir du contenu jouable, puis décider de leur découverte, leur économie et leur progression.

**Fragile / à surveiller**
- Noms et objets futurs sont une proposition de contenu ; ils ne font pas partie du catalogue de jeu.
- Confirmer les illustrations et la lisibilité sur iPhone réel avant d’intégrer de nouvelles destinations au gameplay.

**Vérification**
- `npm test` : 15 fichiers, 127 tests passés.
- `npm run build` : TypeScript et build Vite réussis.
- `git diff --check` : aucun problème d’espacement.
- Vérification visuelle et interactive de la Crique et des trois destinations dans le navigateur, au format par défaut et à 375 × 812.

## 2026-10-06 · Codex · branche `jules/codex-retention-maison`

Refonte de la Maison et concept de progression du monde, dans la DA « lagon lumineux + luxe ».

**Fait**
- Maison : remplacement de la façade rectangulaire par une boutique maritime sur pilotis, à pignon et toit dissymétrique, avec fenêtres et porte cintrées, cheminée, jardinières, enseigne émaillée, lanterne et vitrine. Les restaurations du carnet continuent de piloter l'apparition des éléments.
- Carte des marées : nouvel écran accessible depuis la Maison, avec La Crique et trois destinations annoncées (Jardin d’algues, Épave des échos, Faille d’azur), une progression d'encyclopédie de la crique, et un aperçu d'objets insolites (coquillage-radio, jeton « Continue ? », bouton de scaphandre).
- Ces lieux et trouvailles sont des pistes visuelles uniquement : aucune zone n'est déblocable, aucun objet n'est tiré, aucun taux ni règle de jeu ne change.
- Événements `map_viewed` et `map_destination_previewed` pour mesurer l'intérêt pour cette projection du monde.

**À faire ensuite**
- Valider le style et le niveau de détail de la Maison et de la carte avec Jules ; décider séparément quelles destinations et quels objets entrent dans le jeu.

**Fragile / à surveiller**
- Vérifier la lisibilité des détails dessinés en Canvas sur petit écran et les performances sur iPhone réel.
- La carte a volontairement quatre destinations de démonstration, sans calendrier, conditions de déblocage ni nouveaux objets de catalogue.

**Vérification**
- `npm test` : 15 fichiers, 127 tests passés.
- `npm run build` : TypeScript et build Vite réussis.
- `git diff --check` : aucun problème d'espacement.
- Vérification visuelle dans le navigateur sur le format par défaut et à 375 × 812 : parcours Maison → carte → sélection de l’Épave, retour lisible vers la Maison.

## 2026-10-06 · Codex · branche `jules/codex-retention-maison`

Passe UX / rétention et rendu procédural des objets, en conservant la direction « lagon lumineux + luxe ».

**Fait**
- Pêche : aperçu de la prochaine quête du jour sous la barre de ressources, avec son avancement et un accès direct à la fiche des quêtes. L’aperçu se masque pendant le tutoriel, un geste ou une révélation.
- Collection : progression unique Perles / Bijoux / Créations, atlas séparé des cartes possédées, et raccourci vers l’action correspondante.
- Maison : prochaine lettre ou prochain niveau mis en avant, vitrine UI de la pièce maîtresse quand elle est restaurée ; façade enrichie en bois flotté, bardeaux irréguliers, reflets et détails plus doux.
- Objets : formes et irisations plus différenciées pour les perles ; saphir, émeraude et rubis ont maintenant des tailles distinctes, avec un serti plus détaillé.
- Nouveaux événements analytics pour mesurer l’usage des nouveaux raccourcis. Aucun changement aux règles, probabilités ou valeurs.

**Fragile / à reprendre**
- Rendu procédural à valider sur iPhone réel (notamment les performances du Canvas en continu et la lisibilité aux petites tailles).
- Le contenu de la table de tirage reste celui de la V1 ; toute extension de catalogue demandera son équilibrage et une décision distincte.

**Vérification**
- `npm test` : 15 fichiers, 127 tests passés.
- `npm run build` : TypeScript et build Vite réussis.

## 2026-10-05 (22) · Jules · Claude Code · branche `jules/refonte-visuelle`

Refonte visuelle, 1re passe : décors détaillés et design général. Direction choisie par Jules : tout en code animé, « lagon lumineux + luxe ».

**Fait**
- `art/lagoon.ts` (Pêche) : eau turquoise claire vers la surface, ondulation de la surface, 6 rayons de soleil qui ondulent, récif et coraux au loin dans la brume, sable avec rides en perspective, galets et étoiles de mer, caustiques (motif généré, sans couture, deux nappes qui glissent), algues qui ondulent, bulles, plancton, banc de poissons toutes les 22 s, ombre de l'huître, vignette. Le fixe est calculé une fois par taille d'écran (≈ 0,5 ms par image mesuré sur Mac).
- `art/shell.ts` : coquille en relief (lumière du dessus, ombres portées entre les bandes, liserés), stries rayonnantes, taches, algues, balanes ; dessinée une fois puis gardée en cache.
- **Écrin plat de joaillier en cuir, en 3D** (piste D choisie par Jules sur une planche de 4 pistes, après trois versions refusées : monogramme « É », coffret plat, coffret de velours) : `art/ecrin3d.ts` modélise un étui plat aux coins à peine arrondis, vu d'assez haut (46°), en vraie 3D dessinée au Canvas 2D (projection perspective, faces cachées). Cuir lisse éclairé face par face (diffus + reflet satiné) avec un léger grain ; dorures poussées au fer tracées en vraie perspective (double filet, fleurons d'angle, cartouche à la perle, « MAISON ROSE ») ; filet d'or sur les tranches ; fermoir à poussoir. Le couvercle s'ouvre comme un livre avec le geste (`LID_RATIO` : 180° de geste ≈ 115° de couvercle) et découvre un plateau de velours bleu nuit ; l'intérieur du couvercle est capitonné de velours (coutures en losanges, boutons) avec un écusson de satin « Maison Rose – Perles fines ». Le bijou est **couché à plat sur le plateau**, en perspective (dessiné dans le repère du plateau), et reste dans le coin ouvert entre le bord de la base et le dessous du couvercle ; lumière et étincelles restent à l'écran. Cuirs : bleu nuit, bordeaux, vert anglais, cognac (`art/ecrin.ts`).
  - Retours de Jules sur cette version : « on voit le couvercle à travers » et « les bijoux flottent ». Causes : les faces étaient cachées selon leur orientation « vue de très loin » ; en perspective, un couvercle presque de profil perdait ses deux faces (on voyait à travers). Visibilité maintenant calculée depuis la vraie position de l'œil (`facing`). Le cuir ivoire et ses filets d'or ressemblaient à l'intérieur clair : remplacé par du cognac, et l'intérieur du couvercle est devenu du velours capitonné.
- **Transition entre écrans en fondu enchaîné** (retour de Jules : « une bande de pixels qui bug à gauche ») : le glissement de 24 px découvrait une bande vide sur un bord, maintenant que les écrans couvrent tout l'écran. L'ancien écran reste dessous pendant le fondu (`main.ts`).
- `art/salon.ts` (Écrins) : mur de soie prune à motif losangé, lumières floues (bokeh), plinthe et filet doré, table de velours sombre, faisceau chaud, flaque de lumière, ombre de l'écrin, poussières dorées qui scintillent, vignette.
- `art/house.ts` : cratères de la lune, nuages, phare au loin dont le feu tourne, reflet de la lune et de la lanterne sur l'eau, lucioles.
- `style.css` (section « Refonte visuelle ») : fond « galerie » bleu nuit + motif d'écailles dorées ; barres en verre fumé à filet doré, onglet actif doré ; boutons principaux en or, secondaires en nacre ; cartes avec liseré intérieur et relief ; fenêtres en velours nuit ; vitrines de verre pour les listes.

**Prochaines passes possibles**
- Perles plus réalistes (irisation, reflets), effets de révélation (particules, rayons), cartes « foil », icônes, atelier et expertise, images story dans le nouveau style.

**Fragile**
- `ctx.filter` n'existe pas sur Safari : ne pas l'utiliser pour les flous (dégradés à la place).

---

## 2026-10-05 (21) · Jules · Claude Code · branche `jules/affichage`

Défauts d'affichage, passés en revue sur 375×812, 375×667 (iPhone SE) et 320×568.

**Fait**
- **Fond plein écran** : les écrans occupent tout l'écran, sous la barre du haut et sous les onglets (plus de bande vide). Barre du haut et onglets flottent par-dessus ; `--hud-h` et `--tab-h` (sur `#app`) décalent le contenu. La barre du haut a un voile dégradé pour rester lisible quand le contenu défile dessous.
- **Scènes huître et écrin** : centrées dans la bande libre entre la barre du haut et le pied (message + jauge) grâce à `features/nav/insets.ts` (`visibleBand`). Avant, l'huître touchait le message sur petit écran.
- **Cartes** : la carte révélée ou agrandie rapetisse selon la hauteur disponible (et plus encore avec la bulle du tutoriel ou la bannière « Écrin gagné ») ; l'illustration et le texte suivent la taille de la carte (requêtes de conteneur) ; si rien ne tient, la fenêtre défile au lieu d'écraser la carte. Jauge et message masqués sous la carte révélée.
- **Petites cartes** : taille et valeur (métal et estimation pour les bijoux) au lieu de deux mesures coupées.
- **Écrans étroits** (320 pt) : barre du haut resserrée (elle débordait), grilles de 2 cartes et 3 cases d'encyclopédie (au lieu d'une carte géante par ligne).
- Barres de défilement masquées (comme sur iPhone) ; « aucune création pour l'instant » au lieu de « 0 création ».

**Fragile**
- Les scènes mesurent la barre du haut et le pied au redimensionnement : si on change leur hauteur, vérifier que l'huître reste centrée.
- `:has()` et les requêtes de conteneur demandent iOS 16.4 ou plus récent.

---

## 2026-10-05 (20) · Jules · Claude Code · branche `jules/finitions`

Finitions : partage des créations, et parcours d'un nouveau joueur rejoué de bout en bout.

**Fait**
- Les créations de l'atelier se partagent comme les perles et les bijoux : image story (`renderCraftedStoryImage`), bouton Partager sur la carte agrandie et sur l'écran de résultat. `craftedJewel` est passé dans `art/atelier.ts` (utilisé par le dessin et par l'image).
- Parcours rejoué (4 huîtres du tutoriel → fin) : à la fin du tutoriel, le calendrier s'ouvrait avant les succès, le niveau 3 et les lettres, juste quand le joueur doit aller vers son premier écrin guidé (cahier §15). Le calendrier ne s'ouvre plus tout seul pendant la séance où l'on découvre le jeu (il reste dans la fiche des quêtes, et s'ouvrira à la prochaine visite).
- Ordre constaté ensuite : « Première perle » → « Geste parfait » → niveau 3 (rappel des 2 lettres de la Maison) → onglet Écrin avec la bulle du premier écrin. Pastille 2 sur la Maison.

---

## 2026-10-05 (19) · Jules · Claude Code · branche `jules/atelier`

L'Atelier (cahier §6), première version jouable.

**Fait**
- Core (tests : `tests/atelier.test.ts`) :
  - `setting.ts` : `SettingEngine` (fermeture 0…1 → durée, régularité mesurée sur une fenêtre de temps, verdict parfait / bien / brusque / hésitant) ; lâcher avant la fin recommence sans pénalité ;
  - `atelier.ts` : 8 recettes (niveaux 5 à 12), 4 montures, `pickPearls` (meilleures perles, garde un exemplaire), `craft`, `craftStars` ; `CraftedCard`, `PlayerState.craftedCards`, statistiques et 4 succès d'atelier.
- `input/pinch.ts` : pincement à deux doigts (ou un doigt vers le bas). Sur Duo, une source « charnière » donnera les mêmes `SettingSample`.
- `art/atelier.ts` : l'établi (bois, feutre, pliure) ; perles à gauche, monture à droite, qui se rejoignent ; le bijou serti qui brille. `art/jewel.ts` : perles en couleur (`Jewel.pearlColors`) et bagues à perle.
- `features/atelier/` : carnet de recettes (ingrédients, ce qui manque, avertissement « dernier exemplaire »), établi, résultat (étoiles, carte « Fait main »). Entrée dans la Maison ; volet « Créations » dans la collection ; la vitrine de la Maison peut montrer une création.
- Le déblocage « Atelier » du niveau 5 est marqué disponible ; les lettres 4 et 5 renvoient à l'atelier.

**À régler sur iPhone**
- Le confort du pincement (écart de 140 pt, durée idéale 350–1000 ms) ; un doigt qui glisse vers le bas marche aussi.

**À décider avec Mathys**
- Recettes, montures payées en poussière d'or (provisoire), étoiles et valeurs ; création libre, parures et autres mini-jeux plus tard.

---

## 2026-10-05 (18) · Jules · Claude Code · branche `jules/calendrier`

Rendez-vous quotidiens (cahier §15) : calendrier de connexion et série de jours.

**Fait**
- `src/core/daily.ts` (tests : `tests/daily.test.ts`) : `CALENDAR` (7 cases), `claimDaily`, `canClaimDaily`, série et joker (`streakIfClaimed`, `jokerAvailable`). `PlayerState.login`. Deux succès de fidélité (7 et 30 jours).
- `src/features/progress/dailyCalendar.ts` : le calendrier (7 cases, la case du jour en or, la série avec sa flamme, l'état du joker).
- Il s'ouvre tout seul une fois par jour, en premier dans la file des célébrations (`shell.showRewards()`, appelée aussi au lancement et au retour dans l'app) ; ligne « jours d'affilée » en haut de la fiche des quêtes ; la case à récupérer compte dans la pastille du bouton Quêtes.

**Fragile**
- Comme les quêtes : le jour suit l'heure du téléphone.

---

## 2026-10-05 (17) · Jules · Claude Code · branche `jules/maison`

La Maison, début du fil narratif, en 4e onglet (choix de Jules).

**Fait**
- `src/core/house.ts` (tests : `tests/house.test.ts`) : 7 lettres de grand-mère Rose (niveaux 1, 3, 4, 5, 6, 8, 10), chacune restaure un élément ; `readChapter` (récompense une seule fois), `unreadChapters`, `restoredFeatures`, `houseStageName` (la cabane du ponton → … selon le rang). `PlayerState.chaptersRead`.
- `src/art/house.ts` : la cabane au crépuscule (ciel, lune, mer animée, ponton) et ses éléments restaurés : porte décondamnée, lanterne allumée, enseigne « Maison Rose », fenêtre éclairée avec le carnet, établi, vitrine avec la plus belle pièce du joueur, boîte qui luit (mystère de la perle maudite). Éclat quand un élément apparaît.
- `src/features/house/houseScreen.ts` : la scène, le nom de la Maison, le carnet (lettres nouvelles, lues, scellées, « La suite… niveau 15 ») et la lecture sur papier ; ranger une lettre restaure l'élément sous les yeux du joueur.
- Onglet Maison (verrouillé pendant le tutoriel, pastille des lettres à lire) ; la célébration de niveau rappelle les lettres qui attendent.

**À décider avec Mathys**
- Le prénom de la grand-mère, le nom de la Maison, les textes, le rythme des lettres, la suite de l'histoire (chapitre 8 au niveau 15).

---

## 2026-10-05 (16) · Jules · Claude Code · branche `jules/succes-quetes`

Succès, titres et quêtes du jour.

**Fait**
- Core (tests : `tests/progression.test.ts`) :
  - `achievements.ts` : 24 succès (pêche, geste, écrins, expertise, poussière), paliers bronze / argent / or, 2 secrets, titres, `wearTitle` ;
  - `quests.ts` : quêtes du jour tirées par date (graine = AAAA-MM-JJ local), sans quête d'écrin tant que les écrins ne sont pas débloqués, série « sans fêlure » qui repart à zéro ;
  - `progression.ts` : `afterEvent` (statistiques + quêtes + succès), appelé par `recordOpening`, `recordEcrin`, `recordExpertise`, `meltCard` ; `claimQuest` (récompense, écrin bonus au 3e) ; `unlockAchievements`.
  - `PlayerState` : `stats`, `achievements`, `title`, `quests`.
- Interface :
  - bannières « Succès débloqué » / « Quête terminée » en haut, une à une, puis la montée de niveau (`ctx.showRewards()`, ex-`showLevelUps`) ; toucher une bannière ouvre les succès ou les quêtes ;
  - bouton Quêtes dans la barre du haut (badge et lueur dorée quand une récompense attend) et fiche des quêtes ;
  - « Ma progression » en deux volets : Progression (plus de statistiques) et Succès (avancement, secrets, titres à porter) ; lien « Réglages du prototype » (la roue dentée a quitté la barre du haut).
- Tests existants : récompenses de succès coupées dans `dust.test.ts` et `levels.test.ts` pour garder leurs comptes.

**À décider avec Mathys**
- Liste des succès, titres, barèmes ; quêtes hebdomadaires et série de jours (cahier §15) plus tard.

**Fragile**
- Les quêtes changent à minuit selon l'heure du téléphone : changer l'heure à la main permet de les renouveler (à verrouiller côté serveur plus tard).

---

## 2026-10-05 (15) · Jules · Claude Code · branche `jules/niveaux`

Niveaux, réputation et rangs (cahier §8-9), pour sentir l'évolution dans la bêta.

**Fait**
- `src/core/levels.ts` (pur, testé dans `tests/levels.test.ts`) : courbe de niveau, rangs et déblocages du cahier, récompenses, barème de réputation, `gainReputation`. `PlayerState.reputation` et `rewardedLevel`. `pearlTier` est passé dans `catalog.ts` (réexporté par `dust.ts`).
- La réputation est donnée dans le Core : `recordOpening`, `recordEcrin`, `recordExpertise`. Les vues n'ont rien à calculer.
- Barre du haut : anneau de niveau qui se remplit, « +N » doré à chaque gain ; huîtres au-delà du maximum en doré.
- `src/features/progress/` : célébration de montée de niveau (rayons, médaille, récompenses, prochain déblocage et rang suivant) et fiche « Ma progression ». La célébration attend un moment calme (`ctx.showLevelUps()` quand une carte se ferme, en fin d'expertise, en changeant d'onglet) et jamais pendant le tutoriel : à la fin du tutoriel, on arrive niveau 3 avec 6 huîtres, 30 ✦ et un écrin en plus.
- Réglages : 3 curseurs (réputation de base et croissance par niveau, écrin tous les N niveaux).
- Tests existants : ceux qui comptent huîtres et écrins coupent les montées de niveau (`levelBaseXp: 1e9`).

**À décider avec Mathys**
- Barème de réputation, courbe et récompenses.
- Rien ne se débloque vraiment aux rangs pour l'instant (atelier, commandes… sont « à venir ») : il faudra brancher les vrais déblocages au fur et à mesure.

**Corrigé en passant**
- Carte agrandie de la collection affichée en haut de la page (sous la barre) quand on avait défilé : l'animation d'entrée d'écran restait appliquée (`animation-fill-mode: both` sur un `transform`), ce qui faisait de l'écran le repère des éléments `position: fixed`. Passée en `backwards`.

**Fragile**
- Les joueurs existants repartent du niveau 1 (pas de rattrapage de la réputation passée).
- Ne pas laisser d'animation de `transform` appliquée sur un écran : les surcouches `position: fixed` à l'intérieur se décaleraient.

---

## 2026-10-05 (14) · Jules · Claude Code · branche `jules/navigation`

Retour de Jules : l'UI/UX des onglets ne montrait pas d'évolution dans le jeu.

**Fait**
- `src/features/nav/` : coquille de l'app (`shell.ts`) et icônes SVG (`icons.ts`). `main.ts` ne fait plus que monter les écrans.
- Onglets en bas (Pêche, Écrins, Collection) : icônes, pilule qui glisse vers l'onglet actif, pastilles (écrins à ouvrir, nouvelles cartes), transition d'écran dans le sens des onglets. Réglages : roue dentée en haut à droite.
- Écrins verrouillé (cadenas + message) jusqu'au premier écrin, puis l'icône pulse en doré jusqu'à la première visite (`isEcrinUnlocked` dans `core/tutorial.ts`).
- Barre de ressources : huîtres x/10 + minuteur (cachée pendant le tutoriel, rouge à 0), poussière d'or ; rebond quand la valeur monte. Le compteur sous la coquille a été retiré (doublon).
- Collection : cartes « Nouveau » (contour lumineux) et point sur le volet Perles / Bijoux qui en contient ; `Settings.seenSerial` (les cartes déjà là lors de la mise à jour ne sont pas comptées comme nouvelles) ; `newCardsSince` dans `core/collection.ts`.
- Tests : `tests/navigation.test.ts`.

**Fragile / à revoir**
- Sur iPhone : vérifier que la barre du bas ne gêne pas le geste d'ouverture (le pouce part juste au-dessus) et la marge de la barre de geste iOS.
- Les icônes sont provisoires (phase 2).

---

## 2026-10-05 (13) · Jules · Claude Code · branche `jules/poussiere-or`

Poussière d'or (cahier §7), qui achète aussi des écrins (demande de Jules).

**Fait**
- `src/core/dust.ts` (pur, testé dans `tests/dust.test.ts`) : fonte d'un doublon, fonte en lot des doublons ordinaires, pièces manquantes, achat d'une pièce, achat d'un écrin. `PlayerState.dust` (0 par défaut : les anciennes sauvegardes se chargent sans migration) ; `fromDust` sur les cartes achetées.
- `jewels.ts` : la fabrication d'un bijou d'une rareté donnée est sortie de `rollJewel` (`jewelOfRarity`), sans changer le tirage (mêmes nombres aléatoires, mêmes résultats).
- Réglages : barème par rareté (`dustTier0…5`), `dustBuyMultiplier`, `dustEcrinPrice` (curseurs pour les deux derniers) ; bouton debug « Ajouter 200 ✦ ».
- Collection : barre « poussière d'or » qui ouvre le comptoir (fondre en lot, acheter un écrin, pièces manquantes avec leur prix). Carte agrandie : bouton « Fondre » sur les doublons, à confirmer d'un second toucher. Une pièce achetée s'ouvre aussitôt en grand, marquée « Obtenue avec la poussière d'or ».
- Écrin vide : bouton « Acheter un écrin · 60 ✦ » (hors tutoriel).
- Analytics : `dust_shop_viewed`, `dust_melted`, `dust_piece_bought`, `dust_ecrin_bought`.
- Vérifié dans le navigateur (375×812) : fonte en lot (garde le meilleur exemplaire et le bijou parfait), fonte d'une carte, achat d'un bijou manquant, achat d'un écrin qui s'ouvre aussitôt.

**À décider avec Mathys**
- Le barème et les prix (§6) ; s'il faut aussi pouvoir racheter une pièce déjà obtenue (aujourd'hui : non, seulement les manquantes).

---

## 2026-10-05 (12) · Jules · Claude Code · branche `jules/correctifs-iphone`

Retours du premier test sur iPhone.

**Fait**
- **Coins carrés du reflet holographique** sur des cartes arrondies : Safari iOS ne découpe pas toujours les calques animés selon les coins de la carte. Les calques holo et « variante » héritent désormais des coins arrondis (`border-radius: inherit`) et les cartes isolent leur contenu (`isolation: isolate`).
- **Ouverture à une main** :
  - course du pouce raccourcie : pop à 70 pt, révélation à 267 pt (avant : 378 pt) ;
  - ouverture automatique : lâcher au-delà de 115° laisse le couvercle finir seul en 240 ms (`src/input/thumb.ts`, réglage « Ouverture automatique à partir de ») ; pour l'écrin, jamais avant la fin de la zone de l'angle d'éclat (121°) ;
  - vitesses rapportées à la nouvelle course (fêlure 380 °/s, « immobile » 45 °/s) ; angle d'éclat resserré à 55–115° ;
  - lustre mesuré dans la zone fragile seulement, pour que l'ouverture automatique ne le fausse pas ;
  - réglages sauvegardés sous `perle.tuning.v2` : les anciens réglages enregistrés sur le téléphone sont ignorés.
- Vérifié dans le navigateur : un seul geste de 235 pt ouvre l'huître jusqu'à la carte (lustre S) ; lâcher à 98° laisse la coquille entrouverte ; écrin lâché à 115° reste ouvert, repris et lâché après 121° finit seul.

**À revérifier sur iPhone**
- Les coins des cartes holo (le défaut n'apparaît pas dans le navigateur du Mac, la correction n'a donc pas pu y être constatée).
- Le confort d'une main, et si la fêlure est trop facile ou trop rare avec le nouveau seuil.

---

## 2026-10-05 (11) · Jules · Claude Code · branche `jules/expertise`

**Fait**
- Expertise à la loupe (cahier §7) :
  - Core `src/core/expertise.ts` : bijoux éligibles, inclusions déterministes par carte (3 / 4 ★ / 5 légende), détection sous le viseur, note (Excellent / Bon / Non concluant), `recordExpertise` qui revalorise la carte une seule fois.
  - Mini-jeu `src/features/expertise/` : intro, loupe cerclée de laiton au-dessus du doigt avec vue ×2,2, inclusions (point, plume, aiguille) visibles seulement dans la loupe, viseur qui se remplit, marques dorées sur les inclusions trouvées, barre de temps (alerte sonore les 5 dernières secondes), certificat à la fin.
  - Bouton « Expertiser à la loupe » sous la carte révélée de l'écrin et dans la carte agrandie (volet Bijoux) ; certificat affiché sur la carte et sur l'image story (plusieurs mentions possibles).
- Nouveaux réglages (durée, tolérance, temps sur une inclusion) et événements `expertise_started`, `expertise_finished`. 7 tests de plus (76 au total).
- Corrigé pendant les tests :
  - position du doigt calculée depuis l'écran plutôt que `offsetX`/`offsetY` (les marques tombaient à côté des inclusions visées) ;
  - un échec de `setPointerCapture` empêchait d'enregistrer le doigt ;
  - la barre du haut garde sa place pour que la pierre ne saute pas au début et à la fin ;
  - accords « 1 huître ouverte » / « 1 écrin ouvert » dans la collection ;
  - délai d'apparition inutile sur le bouton « Commencer ».
- Vérifié dans le navigateur : rubis (4 inclusions) → 3 trouvées puis fermeture = « Non concluant » sur une carte, puis sur une autre carte 4/4 = « Excellent », 4 000 € → 5 000 € ; certificat sur la carte et l'image story ; bouton présent dans l'écrin, fermeture avant de commencer sans consommer la tentative.

**Fragile / à surveiller**
- À tester au doigt sur iPhone : décalage de la loupe (96 px au-dessus du doigt), taille du viseur, durée de 20 s.
- Pendant les tests, une 1re expertise lancée avant la correction de la position du doigt s'est terminée en arrière-plan. Pas d'impact sur le code final, mais cela montre que l'expertise continue tant que la fenêtre est ouverte (normal).

---

## 2026-10-05 (10) · Jules · Claude Code · branche `jules/variante-rare`

**Fait**
- Variante rare de l'éclat parfait (cahier §7) : `JEWEL_VARIANTS` (Aurore, Nuit, Givre), `rollRareVariant`, `withVariant` dans `src/core/jewels.ts` ; tirée à l'ouverture de l'écrin (`variantIfPerfect`), appliquée seulement sur éclat parfait, valeur ×2 (`recordEcrin`). La carte garde le bijou de base + `variant`, l'affichage applique la variante.
- Écrin : au moment de l'éclat parfait, le bijou se transforme (couleurs de la variante, double gerbe d'étoiles, triple tintement, « Variante rare : Aurore ! »), suspense maximal à la révélation.
- Carte, image story, texte de partage et collection (« N variantes rares », plus belle pièce avec sa variante) ; liseré irisé animé sur les cartes de variante ; panneau « Probabilités » complété.
- Corrigé : pendant le suspense de révélation, le bijou disparaissait de l'écrin (il était lu dans l'écrin en cours, vidé à l'enregistrement de la carte).
- Corrigé : la mention dorée (« Éclat parfait », « Variante rare ») s'affichait en rouge, écrasée par une règle CSS plus loin.
- Nouvel événement : `ecrin_variant`. 5 tests de plus (69 au total).
- Vérifié dans le navigateur : écrin préparé (solitaire diamant, angle 90°, variante Aurore promise) → transformation à l'éclat parfait → carte « Solitaire diamant · Aurore » à 37 870 € → collection et image story.

**Fragile / à surveiller**
- La correction du bijou qui disparaissait pendant le suspense est vérifiée par lecture du code, pas par capture d'écran (le suspense est passé trop vite pour la capture).
- Les variantes et leurs 12 % sont une proposition à valider avec Mathys (AGENTS.md §6).

---

## 2026-10-05 (9) · Jules · Claude Code · branche `jules/partage-bijoux`

**Fait**
- Partage des cartes de bijoux : bouton « Partager » sous la carte révélée de l'écrin et sous la carte agrandie (volet Bijoux).
- `src/art/storyImage.ts` refait autour d'une mise en page unique (`StorySpec`) : perles sur fond « eau profonde » et nacre, bijoux sur fond « nuit chaude » et velours, avec scintillements, reflet holographique (◆◆◆ et plus, ou éclat parfait), mention « Éclat parfait » et « Estimation fictive ». Le titre rétrécit s'il est trop long.
- Cadres des bijoux, format des euros et des carats déplacés dans `src/art/cardStyle.ts` (partagés entre la carte à l'écran et l'image).
- `shareButton.ts` : `pearlShareButton` et `jewelShareButton` ; l'événement `card_shared` indique `kind` (pearl / jewel).
- Vérifié dans le navigateur : images générées pour une bague bonbon, un solitaire diamant (éclat parfait) et le diadème des Abysses ; image de perle inchangée ; bouton présent dans l'écrin et dans la collection.

**Fragile / à surveiller**
- La légende vaut des centaines de milliers d'euros fictifs (formule du prototype : estimation × carats, et elle fait 40 à 45 ct). Cohérent avec le prototype, à rééquilibrer peut-être.

---

## 2026-10-05 (8) · Jules · Claude Code

**Fait**
- **Écrin** (cahier §7), inspiré du prototype Duo :
  - Core : `src/core/jewels.ts` (10 raretés, tirage, garantie ★ après 20), `src/core/glint.ts` (ouverture sans fêlure + angle d'éclat ; `tick()` à chaque image car un pouce immobile n'envoie plus de mesures), écrins dans `player.ts` (gain, écrin en cours sauvegardé, cartes de bijoux).
  - Dessin : `src/art/jewel.ts` (bague, collier, bracelet, boucles, diadème, pierres taillées, scintillements), `src/art/ecrin.ts` (velours, satin capitonné, filets d'or, monogramme « É »).
  - Écran `src/features/ecrin/` : vue de dessus, couvercle qui se relève (extérieur velours puis satin « Maison · Écrin »), scintillement selon la proximité de l'angle, éclat parfait (étoiles, tintement), jauge d'éclat dorée, suspense selon la rareté, « pouet » pour le toc, panneau « Probabilités », écran « Pas d'écrin » avec la progression.
  - Premier écrin guidé : bulles d'aide et jauge d'éclat toujours visible.
  - Onglet « Écrin » avec pastille (écrins à ouvrir), annonce « Écrin gagné ! » sous la carte de perle.
  - Collection en deux volets Perles / Bijoux (encyclopédie des 10 raretés avec la plus belle pièce, tri, filtre, carte agrandie).
- Réglages : tolérance, temps à tenir, vitesse « immobile », huîtres par écrin. Icône ⚙︎ pour l'onglet Réglages (place pour 4 onglets).
- Nouveaux événements : `ecrin_earned`, `ecrin_shown`, `ecrin_perfect`, `ecrin_reveal`, `ecrin_odds_viewed`. 17 tests de plus (64 au total).
- Vérifié dans le navigateur : 1er écrin guidé (bracelet à l'émeraude, angle 90°) → arrêt sur l'angle → éclat parfait → carte à 6 071 € avec mention ; 2e écrin ouvert d'un trait → collier en argent sans bonus ; écran « Pas d'écrin » ; volet Bijoux ; annonce « Écrin gagné ! » à la 8e huître.

**À faire ensuite**
- Partage des cartes de bijoux (l'image story ne gère que les perles).
- Variante rare en cas d'éclat parfait (cahier §7), expertise à la loupe, poussière d'or.

**Fragile / à surveiller**
- À 90°, le couvercle est vu par la tranche (vue de dessus) : il disparaît un instant. Logique, mais à juger sur téléphone.
- L'éclat parfait demande de tenir le pouce immobile ; le tremblement naturel du doigt sur iPhone est à vérifier (curseurs « tolérance » et « vitesse immobile » dans Réglages).

---

## 2026-10-05 (7) · Jules · Claude Code

**Fait**
- Stock d'huîtres (`src/core/stock.ts`) : 10 maximum, 1 qui revient toutes les 20 minutes (choix bêta, voir AGENTS.md §6). Le minuteur ne tourne que quand le stock n'est pas plein ; une horloge reculée ne fait rien gagner.
- Les 4 huîtres du tutoriel sont offertes ; une huître déjà tirée (page rechargée) n'est jamais payée deux fois.
- Indicateur de stock sous l'huître (pastilles + « +1 dans mm:ss »), masqué pendant le tutoriel.
- Stock vide : écran « La marée remonte… » avec compte à rebours et bouton vers la collection ; l'huître revient automatiquement à zéro (avec un carillon).
- Réglages : curseurs « Stock maximum » et « Recharge » ; boutons « Remplir » / « Vider le stock » pour tester.
- Nouvel événement : `stock_empty`. 8 tests de plus (47 au total).
- Huître remontée un peu à l'écran pour laisser la place à l'indicateur.
- Vérifié dans le navigateur : stock 2 → 2 ouvertures → écran de marée (14:41) ; recharge réglée à 1 min → l'huître revient seule à 0:00.

**Fragile / à surveiller**
- Avancer l'heure du téléphone remplit le stock (pas de serveur pour vérifier l'heure). Acceptable pour la bêta.
- Pas encore de notification « tes huîtres sont revenues » : demandera la mise en ligne (HTTPS) et l'accord du joueur.

---

## 2026-10-05 (6) · Jules · Claude Code

**Fait**
- Icône provisoire générée par script (`scripts/make-icons.py`, `npm run icons`) avec la même formule de coquille que le jeu : SVG + PNG 512, 192, 180 (iPhone), 32 (favicon). Déclarée dans le manifeste et `index.html`.
- Mode hors ligne : service worker `public/sw.js` (actif seulement dans le build de production). Page en « réseau d'abord », fichiers de build en « cache d'abord », polices Google mises en cache. Les fichiers chargés avant l'activation sont envoyés au service worker pour être mis en cache dès la 1re visite.
- Aide à l'installation : bandeau sur iPhone (Safari, hors écran d'accueil), après le tutoriel, fermable définitivement ; instructions aussi dans Réglages.
- `npm start` : build + version de production (port 4173).
- Nouveaux événements : `install_hint_shown`, `install_hint_dismissed`.
- Vérifié : version de production chargée, serveur coupé, page rechargée → le jeu s'affiche entièrement depuis le cache (polices comprises). Aide à l'installation testée en simulant un iPhone.
- Corrigé pendant le test : le serveur répond `Vary: Origin`, ce qui empêchait le cache de servir le JS et le CSS hors ligne (page blanche). Le service worker ignore désormais cet en-tête (`CACHE_VERSION` passé à `perle-v2`).

**Fragile / à surveiller**
- Mode hors ligne et partage exigent HTTPS sur iPhone (voir AGENTS.md §7) : non testables via l'adresse Wi-Fi en http.
- Safari (iOS) peut effacer les données d'un site non installé après environ 7 jours sans visite : le cache **et la collection sauvegardée** (localStorage). Installée sur l'écran d'accueil, l'app n'est pas concernée. D'où l'intérêt de pousser l'installation, et plus tard une sauvegarde serveur (liée au portail de connexion bêta).

---

## 2026-10-05 (5) · Jules · Claude Code

**Fait**
- Premières minutes (cahier §15) : les 4 premières huîtres sont écrites à l'avance (`src/core/tutorial.ts`) : rosée garantie, blanche, vide, baroque. Ensuite, tirage normal.
- La 1re perle ne peut pas se fêler ; la zone fragile est expliquée avant la 2e huître, puis commentée sur la carte (fêlée ou intacte).
- Bulles d'accompagnement (`src/features/oyster/coach.ts`) et main fantôme qui montre le geste (1re huître, ou après 6 s sans geste).
- Partage : bouton « Partager » sous la carte révélée et sous la carte agrandie. Image story 1080×1920 (`src/art/storyImage.ts`), feuille de partage iOS, téléchargement sinon.
- Nouveaux événements : `tutorial_step`, `tutorial_completed`, `card_shared`.
- 3 tests de plus (39 au total).
- Corrigé : ordre d'affichage explicite (z-index) sur l'écran huître ; sans lui, la bulle et la main fantôme pouvaient passer sous la toile.
- Vérifié dans le navigateur : tutoriel complet joué (rosée intacte malgré une ouverture rapide, blanche fêlée avec l'explication, vide, baroque, puis tirage libre), images story générées pour une dorée et une noire fêlée.

**À faire ensuite**
- Tester le partage sur un vrai iPhone : la feuille de partage doit s'ouvrir directement (l'image est préparée à l'avance pour ça).
- Ajouter l'URL du jeu sur l'image story quand on aura une adresse publique.

**Fragile / à surveiller**
- Le partage iOS refuse de s'ouvrir si l'image n'est pas prête au moment du toucher. Elle est générée dès l’affichage de la carte, donc normalement prête avant le toucher (durée de génération non mesurée sur iPhone).

---

## 2026-10-05 (4) · Jules · Claude Code

**Fait**
- Collection : tri des cartes par **rareté** (par défaut : la plus rare d'abord, puis la plus précieuse), **récentes** ou **valeur**. Le choix est mémorisé.
- Toucher une perle de l'encyclopédie filtre les cartes sur cette perle (« Tout afficher » pour revenir) ; l'encyclopédie est rangée de la plus rare à la plus commune.
- Toucher une carte l'affiche en grand avec tous ses détails.
- Tri et filtre en fonctions pures (`src/core/collection.ts`) + 6 tests (36 au total).
- Nouveaux événements de mesure : `collection_sorted`, `collection_filtered`, `card_zoomed`.
- Corrigé : la navigation du haut réinitialisait les boutons de tri (sélecteur trop large dans `main.ts`).

---

## 2026-10-05 (3) · Jules · Claude Code

**Fait**
- Refonte visuelle d'après le prototype Duo de Jules (copié dans `docs/reference/prototype-duo.html`) : fond « eau profonde », typos Young Serif + Figtree, coquille dentelée, nacre irisée, chair et perle dessinées par code (`src/art/`).
- Vue de dessus : le couvercle se soulève vers le haut de l'écran, dans le sens du pouce ; la lumière filtre au bord du couvercle puis le halo de la perle éclaire l'intérieur.
- Messages du proto sous l'huître (« Ouvre doucement… », « Zone fragile », « Trop vite ! », « Crac. La perle est fêlée. », « Elle tremble… »).
- Jauge façon proto (angle, état, barre de vitesse), activable dans Réglages.
- Sons générés (`src/platform/audio.ts`) : craquements de résistance, pop, fêlure, carillon selon la rareté. Interrupteur dans Réglages.
- Cartes refaites façon proto : cadre selon la rareté, texte d'ambiance, reflet holographique pour ◆◆◆ et mieux (non fêlées).
- Catalogue : couleurs, halos, tailles, valeurs et textes repris du proto ; la perle dorée tremble aussi.
- Vérifié dans le navigateur (format iPhone) : huître fermée, ouverture à 76°, carte blanche, suspense et carte dorée, collection.

**À faire ensuite**
- Test sur un vrai iPhone : sensation du geste, sons, haptique.
- Les décisions en attente de l'entrée précédente (perle à 0,1 %, analytics, connexion, mise en ligne, icône).

**Fragile / à surveiller**
- Garantie : le proto Duo garantit la 25e huître, notre Core la 26e (« après 25 sans »). À trancher.
- Le rendu Canvas tourne en continu (reflets qui bougent) : surveiller la batterie et la fluidité sur les vieux iPhone.
- Les polices viennent de Google Fonts : sans réseau, retour aux polices système.

---

## 2026-10-05 (2) · Jules · Claude Code

**Fait**
- Bascule vers un prototype **webapp** (TypeScript + Vite), voir AGENTS.md §6.
- Core complet et testé (29 tests) : catalogue des 8 perles, tirage + garantie à 25, moteur d'ouverture (résistance, pop, zone fragile, révélation), lustre S/A/B/C, état du joueur avec numéros de série.
- Geste pouce vers le haut (`src/input/thumb.ts`) : résistance, puis saut au pop.
- Écrans jouables : Huître (avec mesures en direct), Collection (encyclopédie + cartes), Réglages (curseurs du geste, forcer une perle pour tester, effacer la collection).
- Révélation graduée selon la rareté (note de Mathys sur FUT / Clash Royale).
- Mesure d'usage : `track()` en place (stockage local pour l'instant).
- Cahier des charges mis à jour avec les notes de Mathys ; leur suivi est dans AGENTS.md §8.
- Vérifié dans le navigateur : ouverture lente → perle blanche, lustre S ; ouverture rapide d'une perle dorée forcée → fêlée, suspense ★, carte dorée.

**À faire ensuite**
- Tester sur un vrai iPhone (`npm run dev`, puis ouvrir l'adresse « Network » affichée, en Wi-Fi) et régler le geste.
- Mettre en ligne (Vercel ou équivalent) pour Mathys et la bêta X.
- Décider : perle à 0,1 %, outil d'analytics + consentement, connexion / bonus bêta, icône mascotte.

**Fragile / à surveiller**
- Haptique iOS : l'astuce du `<input switch>` n'est pas vérifiée sur appareil. Les vibrations différées (suspense, fêlure) risquent d'être ignorées par iOS hors geste.
- Le lustre récompense un geste régulier, même rapide : une perle fêlée peut avoir un lustre S. À rediscuter si ça paraît incohérent en jeu.
- Pas encore d'icône : l'écran d'accueil iPhone affichera une capture de la page.

---

## 2026-10-05 · Jules · Claude Code

**Fait**
- Cahier des charges converti en Markdown (`docs/cahier-des-charges.md`).
- Création de `AGENTS.md` (règles communes), `CLAUDE.md` (renvoie vers AGENTS.md) et de ce journal.
- Décisions V1 actées (voir AGENTS.md §6).
