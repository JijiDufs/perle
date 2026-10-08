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
| **Trouvailles (easter eggs)** | 5 % des huîtres cachent un objet à la place de la perle : 25 objets en 3 albums (bric-à-brac du port, clins d'œil à la pop culture sans nom d'œuvre ni de marque, trésors engloutis) | `core/finds.ts` |
| **Poussière d'or** | On **revend ses perles en double** contre de la poussière d'or (on garde toujours un exemplaire de chaque sorte) ; elle achète des skins, des huîtres et les pièces manquantes de la collection | `core/dust.ts` |
| **Skins d'huître** | Le **bénitier** (poussière d'or ou achat) et l'**huître d'or** pour le flex (achat seulement) : voir §6 bis | nouveau |
| **Boutique** | Recharger ses huîtres, acheter de la poussière d'or, acheter un skin : voir §6 ter | nouveau |
| **Missions du jour** | 3 petites missions par jour (mêmes pour tous, renouvelées à minuit), un peu de poussière d'or chacune : voir §6 quater | `core/quests.ts` |
| **Calendrier de connexion** | 7 jours (huîtres, un peu de poussière d'or) ; série avec un joker par semaine | `core/daily.ts` |
| **Classement Game Center** | « Huîtres ouvertes » et « Plus belle perle » : le classement demandé par Mathys, sans serveur ni compte à nous | nouveau |
| **Sauvegarde iCloud** | La collection suit le joueur sur un nouveau téléphone (les achats de skins se restaurent de toute façon) | nouveau |
| **Notifications** | Une seule, désactivable : « Tes huîtres sont revenues » quand le stock est plein | nouveau |
| **Réglages** | Son, haptique, notifications, restaurer les achats, probabilités, confidentialité, conditions | nouveau |
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

Écrins, expertise, atelier, Maison, niveaux, succès, quêtes du jour, pubs, abonnement, compte, bandeau « BÊTA ».

## 5. Règles Apple à respecter

| Règle | Ce qu'on fait |
|---|---|
| **4.2 Fonctionnalités minimales** (risque n° 1 pour un petit jeu) | Jeu complet : 8 raretés, collection, garantie, lustre, partage, rejouabilité quotidienne. Ne pas descendre en dessous. |
| **2.2 Pas de bêta sur l'App Store** | Pas de bandeau « BÊTA » ; les tests se font sur TestFlight. |
| **2.1 Complétude** | Aucun écran « à venir », aucun bouton mort, aucune mention des fonctions futures. |
| **3.1.1 Achats intégrés** | Les skins payants passent **obligatoirement** par les achats intégrés d'Apple (StoreKit 2) : achats « non consommables », bouton « Restaurer les achats », prix affichés par StoreKit (jamais écrits en dur), aucun lien vers un paiement extérieur. Le partage familial peut être activé. |
| **3.1.1 Probabilités** | On n'achète jamais de hasard : chaque skin est un achat direct, connu d'avance. Les probabilités des perles restent affichées : c'est une promesse de la campagne (« toujours »). |
| **5.1 Vie privée** | Pas de compte, pas de suivi publicitaire, donc pas de fenêtre ATT. Étiquette de confidentialité de l'App Store remplie ; manifeste de confidentialité (`PrivacyInfo.xcprivacy`). |
| **Classification par âge** | Questionnaire rempli honnêtement : récompenses aléatoires, sans argent réel. |
| **Marques Apple** | Pas de « iPhone » ni « Duo » dans le nom ou l'icône. La description et la page peuvent dire que le jeu est conçu pour l'iPhone Duo, avec la mention de non-affiliation déjà présente sur la page. |

**Interface (Human Interface Guidelines, iOS)**
- **Zones sûres partout** : Dynamic Island, barre d'accueil, et les zones réservées du Duo (ci-dessous).
- **Accessibilité** : Dynamic Type sur tous les textes ; VoiceOver avec une **action « Ouvrir l'huître »** (un jeu tout en geste doit offrir une autre façon de jouer) ; « Réduire les animations » respecté ; haptique coupée si l'utilisateur l'a désactivée.
- **Haptique** : Core Haptics quand l'appareil le permet, sinon les retours UIKit standard.
- Pas de texte ni de bouton dans les zones système, comme déjà dans la webapp.

**Spécifique à l'iPhone Duo** (lu le 2026-10-08 : [Designing for iPhone Duo](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo) et [Preparing your app for iPhone Duo](https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo))

*Ce qu'Apple dit de l'appareil*
- Deux écrans : l'**extérieur**, plus large et **moins haut** qu'un iPhone habituel (taille « compacte »), et l'**intérieur**, grand (taille « régulière »). Quand on ouvre ou ferme le téléphone, **l'app passe d'un écran à l'autre** et change de taille.
- **Poses** : à moitié plié comme un livre, posé à plat, debout sur la tranche. On ne dessine pas une mise en page par pose : l'app s'adapte à la taille disponible.
- **Zones réservées** : la caméra de l'écran extérieur (dans un coin, toujours là), la caméra de l'écran intérieur (seulement quand elle est active) et **le pli**, quand le téléphone est à moitié ouvert (il coupe l'écran intérieur en deux). On les lit avec `ReservedRegion` (SwiftUI).
- **Barres sur le côté** : sur l'écran extérieur, et sur l'écran intérieur en paysage, les onglets, la barre d'outils et même la barre d'état passent **à la verticale, sur le bord**. C'est automatique avec les composants système.
- **Jeux** : on peut verrouiller l'orientation, mais il faut **remplir l'écran dans chaque pose**. Changer de proportions plutôt que d'ajouter des bandes noires ; sinon, décorer les bandes. Garder la même taille de texte et de boutons quand l'écran change.
- Il faut compiler avec **le dernier Xcode** : avec Xcode 26 ou plus ancien, l'app ne s'étend pas sous la barre d'état et la caméra du Duo.

*Ce que ça change pour Pearl Inc.*
- **Le pli de l'écran = la charnière de l'huître.** À moitié ouvert, l'écran intérieur est coupé en deux par le pli : le couvercle de l'huître sur une moitié, le fond (et la perle) sur l'autre, la charnière de l'huître exactement sur le pli (lu avec `ReservedRegion`). C'est déjà ce que fait le prototype de la page d'inscription. Aucun texte ni bouton sur le pli.
- **Écran extérieur = l'huître fermée.** On l'y dessine en remplissant tout l'écran (lagon sous la barre latérale, avec l'extension de fond de SwiftUI), en évitant la caméra du coin. C'est là que se voit le skin (le flex, §6 bis).
- **Onglets du système** (`TabView`) pour Pêche et Collection, **pas une barre maison** comme dans la webapp : ils passeront tout seuls sur le côté. Les boutons de barre ont un symbole **et** un titre.
- **Rien ne se perd en passant d'un écran à l'autre** : l'huître en cours, l'angle, la carte affichée restent les mêmes. Pas de grand chamboulement de mise en page quand on plie : on déplace seulement ce qui est nécessaire.
- **La carte de révélation** n'est jamais coupée par le pli : centrée sur une moitié quand le téléphone est à moitié ouvert, au centre quand il est grand ouvert. L'encyclopédie de la collection prend un **nombre pair de colonnes**, pour se couper proprement au pli.
- **Tester toutes les poses** avec Device Hub dans Xcode (simulateur du Duo), puis sur un vrai Duo.

## 6. La perle de bienvenue

La page promet que « les premiers inscrits auront une perle de bienvenue ». Sans compte ni serveur, la piste la plus simple :

- l'e-mail de lancement envoyé aux inscrits contient un **lien** (`pearlinc://bienvenue?code=…`, ou un lien universel) ;
- l'app vérifie le code **sans serveur**, puis offre une perle cosmétique exclusive (« Perle de la première marée ») qui n'entre ni dans les probabilités ni dans la garantie.

**À décider** : quelle perle exactement, un code commun ou un code par inscrit, et la date limite. Les codes d'offre d'Apple ne servent qu'aux achats intégrés, ils ne conviennent pas ici.

## 6 bis. Les skins d'huître

**L'idée.** On change l'apparence de sa coquille, et l'huître la plus chère sert au **flex**. Sur le Duo, le flex est réel : téléphone fermé, l'écran extérieur montre la coquille, donc tout le monde autour voit ton huître d'or posée sur la table.

**Règles du jeu (non négociables)**
- **Purement cosmétique.** Un skin ne change ni les probabilités, ni la garantie, ni la zone fragile, ni le lustre, ni la valeur des perles.
- **Le signal reste lisible.** Le skin habille l'extérieur de la coquille et la nacre. La lumière qui filtre garde la couleur de la perle (noire si l'huître est vide), et les plus rares tremblent toujours.
- **Visible partout où l'on montre son jeu** : écran extérieur du Duo, image story partagée, mention « Coquille : … » sur la carte.
- Un skin s'applique à toutes les huîtres ; on en change quand on veut dans la collection.

**Catalogue de départ (proposition, prix à valider)**

| Skin | Comment l'obtenir | Ce qu'il change |
|---|---|---|
| Huître du lagon | Offerte (celle de départ) | — |
| **Bénitier** | 2 000 ✦ (environ 3 semaines de jeu régulier) ou 2,99 € | Le coquillage géant : valves ondulées à grosses côtes, bord en zigzag, manteau bleu-vert irisé à l'intérieur, plus grand à l'écran |
| **Première marée** | Exclusive aux inscrits (lien de l'e-mail de lancement, §6) | Coquille sable et écume, liseré argent ; ne sera plus jamais disponible |
| **Huître d'or** (*golden oyster*) | **9,99 €, achat seulement** | Coquille d'or martelé, nacre champagne, reflets qui suivent l'angle, son et vibration dédiés au « pop », badge « Or » sur les cartes |

D'autres skins (nacre de lune, corail, Tahiti…) arriveront par mises à jour : chaque nouveau skin est une raison de revenir.

Le calcul du prix est au §6 quater.

**Pourquoi l'huître d'or seulement en achat.** Le flex tient à sa rareté et à son prix. Et chaque achat est la preuve la plus forte de traction : des gens paient pour ce geste.

**Technique**
- Un skin = des paramètres de dessin (couleurs, matière, reflets) dans un catalogue du Core (`Skins`), dessinés par le code de la coquille. Pas d'images.
- Ce que le joueur possède est sauvegardé comme le reste. Les achats sont vérifiés par StoreKit 2 au lancement (transactions signées par Apple, sans serveur), et restaurés sur un nouveau téléphone.
- Le prix de la poussière d'or et la liste des skins vivent dans le Core (aucun nombre magique). Les prix en euros sont configurés dans App Store Connect.

**À ne pas faire dans la 1.0** : des skins à durée limitée qui forcent l'achat, ou des offres « dernière chance ».

## 6 ter. La boutique (achats intégrés)

Choix de Jules (2026-10-08) : on peut **recharger ses huîtres** et **acheter de la poussière d'or** avec de l'argent réel, en plus des skins. Tout passe par les achats intégrés d'Apple (StoreKit 2).

| Produit | Type Apple | Prix proposé | Ce qu'il donne |
|---|---|---|---|
| Marée haute | consommable | 0,99 € | Le stock d'huîtres rempli (10) |
| Grande marée | consommable | 2,99 € | 30 huîtres (au-delà du maximum) |
| Bourse de poussière d'or | consommable | 1,99 € | 400 ✦ |
| Coffret de poussière d'or | consommable | 4,99 € | 1 200 ✦ |
| Malle de poussière d'or | consommable | 9,99 € | 3 000 ✦ |
| Bénitier | non consommable | 2,99 € | Le skin (aussi 2 000 ✦) |
| Huître d'or | non consommable | 9,99 € | Le skin, seulement en achat |

**Revente des perles.** Le comptoir de la collection rachète les perles en double contre de la poussière d'or, au barème de l'app (§6 quater). On ne revend jamais le dernier exemplaire d'une sorte, ni une perle à marque rare en lot (décisions déjà prises, AGENTS.md §6). « Tout revendre » garde le plus bel exemplaire de chaque sorte.

**Points d'attention (à trancher entre associés)**
- **Acheter des huîtres, c'est payer pour du hasard** : Apple l'autorise si **les probabilités sont affichées avant l'achat** (règle 3.1.1). On les montre déjà ; il faut les rappeler sur l'écran d'achat.
- **Belgique (et peut-être Pays-Bas)** : les objets aléatoires payants y sont traités comme des jeux d'argent. Proposition : masquer les recharges d'huîtres pour la boutique de l'App Store belge (`Storefront.countryCode`), ou ne pas publier en Belgique au début. **À vérifier avec un juriste avant la sortie.**
- **Payer pour compléter sa collection** : sans garde-fou, une perle maudite manquante s'achèterait avec quelques euros de poussière. Ça enlève du prestige aux perles rares. Proposition : la poussière achète les pièces manquantes **jusqu'à ◆◆◆ seulement** ; les ★ et ★★ restent à pêcher (la garantie après 25 huîtres est là pour ça).
- **Monnaie virtuelle (règles européennes de protection des consommateurs)** : montrer clairement ce que coûte un objet et ce qu'il donne, pas d'urgence artificielle, pas de vente ciblée vers les enfants. À relire avant la sortie.
- **Les achats consommables ne se restaurent pas** chez Apple : la poussière et les huîtres achetées vivent dans la sauvegarde (d'où la sauvegarde iCloud). Les skins, eux, se restaurent.
- Les huîtres achetées et données au-delà du maximum ne bloquent pas la recharge gratuite : elle reprend quand on repasse sous 10.


## 6 quater. L'équilibre de la poussière d'or

**Le principe (choix de Jules, 2026-10-08)** : la poussière d'or se gagne **lentement**. On peut avoir le bénitier sans payer, mais il faut environ trois semaines de jeu régulier ; payer 2,99 € doit être la solution évidente pour qui le veut tout de suite. L'huître d'or reste à l'achat seulement.

**Barème de l'app** (plus bas que celui de la webapp, qui reste un prototype) :

| Source | Poussière d'or |
|---|---|
| Revendre un doublon — / ◆ / ◆◆ / ◆◆◆ / ★ / ★★ | 0 / 1 / 2 / 5 / 15 / 40 ✦ |
| Trouvaille « pièce d'or engloutie » | 5 ✦ |
| Chaque mission du jour | 5 ✦ |
| Les trois missions du jour terminées | + 10 ✦ |
| Calendrier de connexion | 10 à 25 ✦ certains jours (les autres : des huîtres) |

**Ce que ça donne par jour** (une fois les doublons arrivés : environ 2,5 ✦ par huître revendue en moyenne)

| Joueur | Huîtres par jour | Revente | Missions + calendrier | Total | Bénitier (2 000 ✦) |
|---|---|---|---|---|---|
| Occasionnel | 15 | ≈ 35 ✦ | ≈ 30 ✦ | ≈ 65 ✦ | ≈ 1 mois |
| Régulier | 30 | ≈ 70 ✦ | ≈ 35 ✦ | ≈ 105 ✦ | ≈ 3 semaines |
| Acharné (stock gratuit au maximum) | 72 | ≈ 165 ✦ | ≈ 35 ✦ | ≈ 200 ✦ | ≈ 10 jours |

Les premiers jours, il y a peu de doublons (on garde toujours le premier exemplaire), donc encore moins de poussière.

**Ce que la poussière achète**

| Article | Prix |
|---|---|
| Une huître (quand le stock est vide) | 20 ✦ |
| Une perle manquante ◆ / ◆◆ / ◆◆◆ | 5 / 10 / 25 ✦ (les ★ et ★★ restent à pêcher) |
| Bénitier | 2 000 ✦ |

**Cohérence avec la boutique** : 2 000 ✦ en poussière achetée coûtent plus de 4,99 €, alors que le bénitier coûte 2,99 € en direct. Celui qui paie achète donc le skin, pas la poussière. Et 10 huîtres valent 200 ✦ ou 0,99 € : les deux prix se tiennent.

**Missions du jour** (3 tirées chaque jour parmi la liste, mêmes pour tous, graine = la date, comme dans la webapp)

| Mission | Objectif |
|---|---|
| Ouvrir des huîtres | 5 ou 8 |
| Obtenir un lustre A ou S | 2 ou 3 |
| Obtenir un lustre S | 1 |
| Trouver une perle ◆◆ ou plus rare | 1 |
| Ouvrir des huîtres d'affilée sans fêlure | 3 ou 5 |
| Revendre des doublons au comptoir | 1 ou 3 |
| Partager une carte | 1 |

Elles se font en une ou deux sessions avec le stock gratuit : elles donnent une raison de revenir chaque jour, pas une corvée.

**Tous ces montants sont des points de départ.** On les ajustera avec les vrais chiffres de la bêta TestFlight (poussière gagnée par jour, part des joueurs qui achètent le bénitier). Ils vivront dans les réglages, en un seul endroit, et pas dans le code des écrans.

## 7. La charnière : ce qu'on sait, ce qu'il faut vérifier

La page d'inscription fixe le comportement voulu : fermé, l'écran extérieur montre la coquille ; on ouvre, la lumière filtre ; ouvert, la carte se révèle ; on referme, l'huître suivante attend.

**Ce que la documentation d'Apple confirme (2026-10-08)**
- **L'API existe** : [`DeviceHinge`](https://developer.apple.com/documentation/swiftui/devicehinge) en SwiftUI, **iOS 27.1+, encore en bêta**. Elle donne un **angle continu** (`angle`) et un **état** (`status`, calculé par le système d'après l'angle et l'orientation), reçus avec le modificateur `.onHingeChange`. Sur un téléphone sans charnière, il n'y a pas de charnière : on bascule sur le pouce.
- **Le Xcode installé (26.3, SDK iOS 26.2) ne la contient pas.** Il faut la version d'Xcode qui fournit le SDK iOS 27.1 (bêta pour l'instant). On construit tout le reste avec le pouce en attendant.

**Encore à vérifier, dans le simulateur du Duo puis sur un vrai Duo**
1. **Fréquence des mises à jour de l'angle.** La zone fragile dépend de la vitesse : il faut au moins 30 mesures par seconde, sinon lisser ou adapter le seuil de vitesse (`tuning`).
2. **À quel angle l'app passe de l'écran extérieur à l'écran intérieur**, et si elle reçoit l'angle pendant ce passage. **C'est la grande question d'UX.** Si le début de l'ouverture n'est pas lisible, plan B : la résistance et le « pop » se jouent sur les premiers degrés lisibles, ou l'on finit au pouce.
3. **Plage d'angles réelle** (0–180° ?), sens de la mesure, et valeurs possibles de `status`.
4. Comportement quand l'utilisateur **pose le téléphone à moitié ouvert** : l'huître doit rester entrouverte (comme quand on relâche le pouce pendant `opening`).

Architecture : la charnière est **une source de geste de plus** (invariant n° 2). `HingeSource` transforme chaque `DeviceHinge.angle` en `OpeningSample { angle, time }` ; le moteur ne sait pas d'où vient le geste. Sans charnière, on bascule automatiquement sur le pouce (cahier §3).

## 8. Architecture (en place depuis le 2026-10-08, branche `jules/ios-app`)

```
ios/
  PearlInc.xcodeproj    Projet Xcode (iOS 18+, iPhone). Ouvrir ce fichier dans Xcode.
  PearlCore/            Swift Package : logique PURE, miroir de src/core (aucun UIKit / SwiftUI)
    Sources/PearlCore/
      Resources/catalog.json   Perles, trouvailles, traits, réglages : EXPORTÉS depuis le TypeScript
      Random, Tuning, Catalog, Oyster (tirage, garantie, traits), Opening (moteur + lustre),
      ThumbMapping (pouce → angle), Player (cartes, valeurs, comptoir, achats en poussière, skins),
      Stock (huîtres et recharge), Missions (missions du jour), Economy (barèmes, skins, produits)
    Tests/PearlCoreTests/
      Resources/parity.json    Cas de référence produits par le TypeScript
      ParityTests              Le Swift doit donner exactement les mêmes résultats
  PearlInc/             L'app SwiftUI
    Game/GameModel      Relie moteur, geste, haptique, sauvegarde (aucune règle)
    Input/ThumbSource   Pouce vers le haut → OpeningSample (HingeSource viendra avec iOS 27.1)
    Art/                Lagon, coquille, nacre, perle, halo : dessinés par code
    Platform/           Haptique, sauvegarde
    Features/           Pêche (barre de ressources, marée basse), carte, missions, collection (comptoir), boutique (skins)
```

- **Une seule source de vérité** : catalogues et réglages restent dans `src/` (TypeScript) ; l'économie de l'app est dans `src/core/appEconomy.ts`. `npm run ios:export` régénère `catalog.json` et `parity.json`. Le test `tests/ios-export.test.ts` échoue si on oublie, et `swift test` (dans `ios/PearlCore`) vérifie que le Swift suit.
- **Mêmes invariants que la webapp** : Core pur, une seule interface de geste, aucun nombre magique, hasard et temps injectés, perle tirée à la création de l'huître et sauvegardée.
- Pas de dépendance externe.
- **Planche des skins** : `sh scripts/make-skin-sheet.sh` dessine `docs/skins.png` avec le code de dessin de l'app, sur le Mac (pas besoin du simulateur).

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
| Joueurs qui achètent au moins un skin | App Store Connect | ≥ 2 % |
| Part des huîtres d'or parmi les achats | App Store Connect | à observer (le flex marche-t-il ?) |
| Skins obtenus avec la poussière d'or | mesure d'usage | à observer (la boucle des doublons tourne-t-elle ?) |
| Poussière gagnée par jour et par joueur | mesure d'usage | ≈ 60 à 110 ✦ (sinon, réajuster le barème) |
| Missions du jour terminées (les trois) | mesure d'usage | ≥ 40 % des joueurs du jour |
| Fêlures et lustre S (équilibrage) | mesure d'usage | à observer |

La mesure d'usage reste centralisée dans un seul fichier (`Platform/Analytics`), comme `track()` dans la webapp. **Outil à choisir** : c'est une nouvelle dépendance, donc une décision en §6.

## 10. Calendrier proposé

| Dates | Étape |
|---|---|
| **12 – 22 oct.** (pendant la campagne) | Xcode, compte Apple Developer, nom réservé sur App Store Connect ; projet créé ; PearlCore porté avec les tests de parité ; ouverture au pouce jouable sans décor ; lecture de la documentation de la charnière |
| 23 – 25 oct. | Essais sur un vrai Duo (§7) ; **décision du 25** ; périmètre ajusté |
| 26 oct. – 6 nov. | Décor, révélation, haptique, sons, carte, collection, premières minutes, stock, partage, perle de bienvenue, poussière d'or et skins (achats testés dans le bac à sable d'Apple), anglais, accessibilité |
| 6 – 12 nov. | TestFlight (quelques inscrits volontaires) ; corrections ; fiche App Store (captures, vidéo du geste, textes FR/EN) ; dossier pour l'équipe éditoriale de l'App Store |
| ≈ 13 nov. | **Soumission** ; examen d'Apple (souvent 1 à 2 jours, sans garantie) |
| ≈ 17 – 20 nov. | **Sortie** ; e-mail aux inscrits avec la perle de bienvenue |

**Si on prend du retard**, on coupe dans cet ordre : classement Game Center, calendrier de connexion, perles uniques, anglais (en mise à jour), bénitier en poussière d'or (on garde l'achat). On ne coupe ni le geste, ni l'haptique, ni la carte, ni le partage, ni la perle de bienvenue (c'est une promesse faite aux inscrits).

## 11. Ce qu'il faut avant de commencer

- [x] **Xcode** installé (26.3). Il faudra la version qui fournit iOS 27.1 (bêta) pour la charnière et le plein écran sur le Duo.
- [ ] **Compte Apple Developer** (99 $/an) : au nom de qui ? Une personne, ou la société MJHstudio (il faut alors un numéro D-U-N-S, compter plusieurs jours). Cela décide du nom du vendeur affiché sur l'App Store.
- [ ] **Contrat « Apps payantes »** dans App Store Connect, avec les informations bancaires et fiscales : obligatoire pour vendre des skins, et la validation prend du temps. À faire dès que le compte existe.
- [ ] **Réserver le nom « Pearl Inc. »** sur App Store Connect dès que le compte existe, et vérifier qu'il ne pose pas de problème de marque.
- [ ] Un iPhone récent pour tester l'haptique ; un Duo dès sa sortie.
- [ ] **Accord entre associés** sur : SwiftUI, une seule app qui grandit, sortie en novembre plutôt que le 23 octobre, perle de bienvenue, skins et prix (la boutique payante est encore marquée « hors V1 » dans AGENTS.md §2), seuils de traction. Ensuite, inscription en §6 de AGENTS.md.
