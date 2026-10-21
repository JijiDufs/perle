# Audit de l'app iOS Pearl Inc. (branche `jules/app-1.0.1`, lots 1.1 à 1.3)

> 2026-10-21 · Claude Code (session « audit-app-ios »), à la demande de Jules. **Aucun code modifié.**
> Méthode : lecture de `AGENTS.md`, `docs/duo-gadget.md`, `docs/ios-feuille-de-route.md`, `docs/app-store-juridique.md`, du journal et du code (PearlCore + app) ; parcours au simulateur (iPhone 17 Pro avec une partie avancée niveau 13, iPhone 17e en partie neuve, Duo simulé `-SimulatedHinge -SimulatedFold`, français et anglais, texte au plus grand, `-AlwaysFishThief`, marée basse forcée, pub de test) ; **simulation de l'économie avec le vrai moteur Swift** (PearlCore, 4 profils × 200 parties × 30 jours, détails en annexe A). Captures : [`docs/audit-app-ios/`](audit-app-ios/).
> Limites : VoiceOver pas piloté au simulateur (audit par le code) ; curseur de charnière simulée insensible à l'outil d'automatisation (Duo jugé sur les captures, le code et le journal) ; « Se connecter avec Apple » pas testé (compte Apple requis) ; chiffres CPU mesurés au simulateur, indicatifs seulement.

## Résumé en 10 lignes

1. **Le cœur est bon** : le geste, le suspense gradué, la lumière de la perle, la carte qu'on incline, le lagon. C'est un vrai jeu, pas une démo.
2. **L'« économie lente » n'existe pas dans les faits** : niveaux et succès donnent des huîtres qui rapportent de la réputation, qui donne des niveaux, qui donnent des huîtres… Mesuré : **un nouveau joueur peut ouvrir ≈ 205 huîtres d'affilée à sa première séance** (31 en stock dès la fin du tutoriel, 64 après 10 huîtres).
3. Conséquence : **les 7 perles sont toutes trouvées en 2 à 3 jours** (médiane), le bénitier « 3 semaines » s'obtient en **4 à 12 jours**, le niveau 20 en ≈ 2 semaines. Le contenu brûle, puis le joueur tombe d'un coup sur « 1 huître toutes les 20 min » : c'est la falaise de rétention classique vers J3.
4. **Équité** : le tirage payant est assumé et bien affiché, mais trois choses seraient reprochées : le **poisson qui fait perdre une perle** (même achetée), la **garantie invisible** (aucun compteur), et 9 % d'huîtres vides sans aucune consolation.
5. **Premiers instants** : écran de connexion obligatoire avant de jouer (le compte ne sert à rien aujourd'hui : ni sauvegarde en ligne, ni skin des inscrits), puis **le formulaire de consentement de Google coupe la toute première huître**.
6. **Promesse cassée visible** : « Première marée » est affichée « Réservée aux inscrits » et l'écran de connexion dit de l'obtenir avec son e-mail, mais **aucun code ne la donne**.
7. **Accessibilité bloquante** : au plus grand texte, la fenêtre « Les succès arrivent ! » met son bouton sous la barre d'onglets (impossible à fermer proprement), la barre du haut devient illisible, le calendrier se casse.
8. **UI** : les écrans principaux sont au niveau ; les feuilles système grises (missions, calendrier, réglages) et la carte en police système sans cadre de rareté font encore « template ».
9. **Technique** : pas de plantage vu ; le lagon est redessiné en continu (≈ 30–40 % d'un cœur au simulateur sur tous les écrans, même sous une fenêtre) : batterie et chauffe à surveiller. **Aucune mesure d'usage** : impossible de vérifier les seuils de `duo-gadget.md` §9.
10. **Recommandation** : ne pas envoyer la 1.1 telle quelle. Un lot court « 1.1 Confiance et équilibrage » (P0 ci-dessous, ≈ 1 semaine) avant, puis revoir l'ordre : la Maison et l'Atelier (puits à poussière et à doublons) avant l'Expertise.

---

## P0 : avant d'envoyer la 1.1

| # | Écran | Constat et preuve | Recommandation | Effort |
|---|---|---|---|---|
| **P0-1** | Toute l'économie | **Boule de neige des huîtres offertes.** Niveaux (5 huîtres, + 10 au rang) et succès (3 / 5 / 10 huîtres) se nourrissent l'un l'autre. Simulation PearlCore : 1re séance sans pause = **205 huîtres, niveau 15, 19 succès** ; stock 31 à la fin du tutoriel (vu au simulateur, [13](audit-app-ios/13-fin-tuto-31-huitres.jpg)), 64 après 10 huîtres, 90 après 40. Joueur léger (2 séances/jour) : **993 huîtres en 30 jours**, niveau 27 ; régulier : 1 615, niveau 33. | Les récompenses de niveau et de succès en **poussière d'or, titres, coquilles**, pas en huîtres (ou au plus 1 à 2 huîtres, et seulement à partir du niveau 10). Garder des huîtres pour le calendrier et les rangs. Viser, mesuré par la même simulation : première séance ≤ 40 huîtres, 7 perles en ≥ 3 semaines pour un régulier. Ajouter ce test d'économie à `swift test` (un « joueur type » sur 30 jours) pour qu'aucun lot ne recasse l'équilibre. | M |
| **P0-2** | Toute l'économie | **Les huîtres au-delà de 10 gèlent la recharge** (`refreshStock` : au-dessus du maximum, le minuteur repart de zéro). Un joueur qui a 90 huîtres en réserve ne recharge rien pendant des jours : les « + 5 huîtres » valent en partie moins que promis, sans que le joueur le sache. | Tranché avec P0-1 : si les récompenses restent en huîtres, les mettre dans une **réserve séparée** (« huîtres offertes ») qui ne bloque pas la marée, et l'afficher. | S |
| **P0-3** | Pêche, après la carte | **Le poisson voleur fait perdre une perle, y compris d'une huître payée** (pub ou argent). 2,8 s pour toucher ; avec VoiceOver ou un handicap moteur, c'est une punition (WCAG 2.2.1, temps imposé). Simulation : ≈ 28 perles perdues par mois chez un joueur léger. Capture [06](audit-app-ios/06-poisson.jpg), [07](audit-app-ios/07-poisson-perdu.jpg). « Ça arrive aux meilleurs pêcheurs » ne console pas d'une perte sèche. | Garder le moment (il est drôle), **supprimer la perte** : raté = la perle revient quand même, rattrapé = bonus (+ 2 ✦, mission, succès). Ou le poisson « garde » la perle et la rend à la séance suivante (raison de revenir). Délai doublé si VoiceOver ou « Réduire les animations ». | S |
| **P0-4** | Pêche | **La garantie est invisible** : la règle est écrite dans les probabilités, mais aucun compteur (`drawState.sinceGoldenOrBetter` n'est affiché nulle part). Le joueur qui paie ne sait pas où il en est. | Petite jauge « Perle dorée garantie dans N huîtres » (sous le compteur d'huîtres ou dans la fiche des probabilités). C'est aussi un moteur d'anticipation. | S |
| **P0-5** | Boutique, probabilités | Probabilités **repliées sous les boutons d'achat** ([03](audit-app-ios/03-boutique.jpg)) ; il manque les **chances des trouvailles par rareté** (25 objets, poids 40/18/12/5/2) et des **marques rares** (4 %, elles changent la valeur) ([05](audit-app-ios/05-probabilites.jpg)). Règle Apple 3.1.1 : chances de chaque type d'objet **avant** l'achat. | Tableau visible (déplié) au-dessus des recharges ; même fiche complète partout (trouvailles par rareté, marques, garantie, poisson). | S |
| **P0-6** | Premier lancement | **Mur de connexion** avant la première huître ([15](audit-app-ios/15-connexion.jpg)), alors que le compte n'apporte rien aujourd'hui (la partie reste dans `UserDefaults` ; se déconnecter puis « Jouer sans compte » garde la même partie). Friction au pire moment, et donnée personnelle (e-mail) collectée sans usage (minimisation RGPD). | Lancer **directement le tutoriel** ; proposer le compte plus tard, quand il sert (sauvegarde, skin des inscrits), dans Réglages et après la 1re perle rare. | S |
| **P0-7** | Tutoriel | **Le formulaire de consentement de Google s'ouvre pendant la toute première huître** ([12](audit-app-ios/12-consentement-pendant-tuto.jpg)) et mange le geste. Il demande aussi « publicités personnalisées… 210 partenaires » alors que l'app n'en sert que des non personnalisées. | Demander le consentement **à la première pub** (marée basse ou boutique), jamais pendant le tutoriel ; régler le message RGPD d'AdMob sur les finalités réellement utilisées. | S |
| **P0-8** | Boutique, connexion | **Première marée promise, impossible à obtenir** : aucun code ne la donne (`grant == "signup"` n'est qu'un libellé) ; l'écran de connexion dit pourtant « Inscrit avant la sortie ? Utilise la même adresse pour récupérer ta coquille » ([04](audit-app-ios/04-coquilles-barre-etat.jpg)). | Choisir la piste (`duo-gadget.md` §6 : lien à code, plus simple, sans serveur) et la livrer avant l'e-mail aux inscrits ; d'ici là, retirer la phrase de la connexion. | M |
| **P0-9** | Fenêtres, texte au plus grand | **Blocage** : « Les succès arrivent ! » au plus grand texte, titre tronqué, médaille sous l'heure, **bouton Continuer sous la barre d'onglets** ([10](audit-app-ios/10-xxxl-succes-bloque.jpg)) ; même risque pour la fête de niveau. | Contenu de ces fenêtres dans un `ScrollView` (ou `ViewThatFits`), bouton toujours visible. | S |
| **P0-10** | Mesure | **Aucune mesure d'usage** (pas de `Analytics`) : les seuils de `duo-gadget.md` §9 (huîtres/jour, ✦/jour, missions, part du Duo) sont invérifiables, et les montants « à ajuster avec la bêta » ne pourront pas l'être. | Brancher un outil (décision §6 ; TelemetryDeck ou PostHog EU, sans pistage) avec une dizaine d'événements : séance, huître, rareté, fêlure, poisson, pub, achat, marée basse, mission, niveau. | M |
| **P0-11** | Connexion | Le journal (2026-10-19) note le fournisseur Apple **désactivé dans Supabase** (« Se connecter avec Apple échoue »). Rien ne dit qu'il a été activé depuis. Un bouton qui échoue = rejet 2.1. | Vérifier dans Supabase → Authentication → Providers, et tester sur un iPhone réel. | S |

## P1 : dans les prochains lots

### Équité et économie

| # | Constat et preuve | Recommandation | Effort |
|---|---|---|---|
| P1-1 | **Bénitier trop rapide** : 2 000 ✦ atteints en médiane à **J12** (léger), **J7** (régulier), **J4** (gros), contre « ≈ 3 semaines à 1 mois » visés ; la revente fait 65 à 77 % de la poussière. Même après P0-1, la revente reste le gros robinet. | Refaire tourner la simulation après P0-1 ; puis soit baisser la revente des ◆ (1 → 0,5, arrondi par lot), soit ajouter des **puits** (coquilles en poussière, Atelier) plutôt que de monter le prix. | S |
| P1-2 | **Huîtres vides** : 9 % des tirages ne donnent rien (plus ≈ 3 % de perles perdues au poisson aujourd'hui) ; sur une huître payée, c'est le reproche n° 1 des « loot boxes ». | Une consolation visible : réputation affichée « + 10 », ou 1 ✦ « grain de nacre ». | S |
| P1-3 | **Prix incohérents** entre documents et App Store : au simulateur (bac à sable), Coffret **3,99 $** et Malle **8,99 $** ; `PearlInc.storekit` et `duo-gadget.md` disent 4,99 / 9,99. Le raisonnement « payer le skin direct est toujours moins cher » tient encore, mais les docs mentent. | Une seule table de prix (App Store Connect), recopiée dans `duo-gadget.md` §6 ter. | S |
| P1-4 | **Règles monnaie virtuelle (UE, principes CPC de 2025)** : le bénitier s'affiche en « 2 000 ✦ » sans équivalent en euros ; achat d'une huître en poussière en un toucher, sans confirmation. | Afficher « ≈ x € » à côté de tout prix en ✦ ; confirmation pour les achats ≥ 100 ✦. | S |
| P1-5 | **Les achats consommables vivent seulement sur le téléphone** (`UserDefaults`) : changer d'iPhone ou réinstaller = huîtres et poussière achetées perdues. C'est écrit dans la boutique, mais ce sera la 1re demande de remboursement. | Sauvegarde iCloud (CloudKit ou clé-valeur) ou Supabase : c'est ce qui donnera enfin un rôle au compte. | M |
| P1-6 | **Juridique hors Belgique** (à faire relire, pas un avis) : **Brésil** (loi 15.211/2025, « ECA Digital », qui interdit les loot boxes dans les jeux accessibles aux mineurs ; l'app y est 16+ chez Apple mais visée « tous publics ») ; Royaume-Uni (principes de l'industrie : contrôle parental des achats aléatoires) ; Pays-Bas et Espagne (projets de loi récurrents) ; futur Digital Fairness Act européen. | Le plus simple et le plus « irréprochable » : **ne plus vendre de hasard** (voir décision D1). Sinon, retirer les recharges dans les pays à risque (`Storefront.countryCode`). | S à M |

### Rétention et game design

| # | Constat et preuve | Recommandation | Effort |
|---|---|---|---|
| P1-7 | **La Pêche ne montre aucun objectif** : ni mission en cours, ni prochaine perle à trouver, ni garantie ([19](audit-app-ios/19-peche.jpg) : seulement l'huître et « Glisse vers le haut »). Les missions sont cachées derrière une icône. | Une ligne sous l'huître : la mission la plus proche (« 2 / 3 lustres A ») ou la garantie ; c'était la décision du 2026-10-06 pour la webapp. | S |
| P1-8 | **Collection trop courte** : 7 sortes seulement ; « 7 / 7 » dès J2 à J3 ([17](audit-app-ios/17-collection.jpg)) ; la perle maudite (0,3 %) tombe chez 97 % des joueurs légers en 30 jours. Ensuite, le seul chasse reste le carnet des variantes, peu mis en avant. | Faire du **carnet des variantes** la vraie chasse (compteur « 34 / 96 variantes », récompenses par sorte complète) ; avancer un lagon (nouvelles perles) dans la feuille de route. | M |
| P1-9 | **Deux « valeurs » sans lien** : la carte affiche « Valeur 29 » (sans unité) et la collection « Trésor : 2 704 », mais la revente donne 1 à 40 ✦ selon la rareté seulement. Le joueur ne comprend pas ce que vaut une perle. | Une seule notion : soit la valeur devient le prix de revente (en ✦), soit elle sert au classement « plus belle perle » et le dit. | S |
| P1-10 | **Missions faibles** : 5 ✦ chacune (≈ 2 huîtres revendues), peu visibles ; la mission « partager » se valide en touchant le bouton (même si on annule la feuille). | Récompense plus parlante (une huître offerte, de la réputation affichée) ; compter le partage seulement s'il est fait (`ShareLink` / completion). | S |
| P1-11 | **Tout arrive d'un coup après le tutoriel** : onglets, 3 compteurs, anneau, missions, fête de niveau, bulle du stock, bannières. La bulle dit « 10 au maximum » pendant que le compteur affiche 31 ([14](audit-app-ios/14-bulle-10-max.jpg)). Le tutoriel n'explique ni le lustre, ni la collection, ni la revente. | Étaler sur les 20 premières huîtres (Collection à la 1re perle en double, Boutique à la 1re marée basse) ; corriger la bulle (« Elles reviennent toutes seules, une toutes les 20 min »). Une bulle sur le lustre à la 1re carte S. | M |
| P1-12 | **Deux fenêtres l'une sur l'autre** : au lancement, le calendrier s'ouvre par-dessus la fête de niveau ([01](audit-app-ios/01-calendrier-sur-fete.jpg)). | File d'attente unique des fenêtres (consentement → calendrier → niveau → succès), une à la fois. | S |

### UX, UI, accessibilité, textes

| # | Écran | Constat et preuve | Recommandation | Effort |
|---|---|---|---|---|
| P1-13 | Texte au plus grand | Barre du haut illisible (nombres disparus, anneau coupé), consigne coupée des deux côtés ([11](audit-app-ios/11-xxxl-peche.jpg)) ; calendrier « Jou / r 1 » ([09](audit-app-ios/09-xxxl-calendrier.jpg)). **Boutons et bulles en taille fixe** (`Glass.swift:93`, `Coach.swift:54`, `StolenView`, `RevealCardView`) : ils ne grossissent pas. | Polices relatives (`.body`, `@ScaledMetric`) ; au-delà de `accessibility1`, barre du haut en icônes + nombres sur 2 lignes, calendrier en liste. | M |
| P1-14 | VoiceOver | L'huître garde l'étiquette « Huître fermée » à toutes les étapes (carte, vol) ; son indice dit « Glisse le doigt vers le haut », geste impossible sous VoiceOver ; aucune annonce quand le poisson arrive. | Étiquette selon l'étape ; indice « Action : Ouvrir l'huître » ; annonce « Un poisson ! Action : l'attraper » (et P0-3). | S |
| P1-15 | Missions, calendrier, réglages | **Feuilles système grises** ([18](audit-app-ios/18-missions.jpg), [01](audit-app-ios/01-calendrier-sur-fete.jpg)) : rupture nette avec le verre clair du lagon. La feuille des missions n'a pas de bouton OK (le calendrier si). Dans le calendrier, la coche recouvre le montant récupéré. | `presentationBackground` en verre sur lagon, bouton OK partout, case récupérée = montant estompé + petite coche dans le coin. | S |
| P1-16 | Carte de révélation | C'est l'objet le plus vu du jeu et il fait « fiche » : police système, fond pastel uni, bas vide, pas de **cadre par rareté** (la webapp en a : `CARD_FRAMES`). | Cadres par palier (nacre, argent, or, holo), une police d'affichage pour le nom (Young Serif, celle de la webapp), le lustre en médaille. C'est ce qu'on partage en story. | M |
| P1-17 | Boutique | La pub est le bouton le plus visible de la boutique ; elle propose des recharges à qui a 178 huîtres. Texte de la Malle qui passe sous l'heure pendant le défilement ([04](audit-app-ios/04-coquilles-barre-etat.jpg)). 4 coquilles seulement, dont une impossible à obtenir. | Boutique contextuelle (recharges mises en avant seulement à marée basse), coquilles en tête (c'est ce qu'on veut vendre) ; vérifier `statusBarFade`. | S |
| P1-18 | Duo, pli | La consigne « Ouvre le téléphone doucement » déborde du bord droit ([16](audit-app-ios/16-duo-pli.jpg)) ; la bulle du stock fait 7 lignes dans la demi-colonne. | Bulles limitées à la moitié d'écran avec marge ; textes courts dédiés au Duo. | S |
| P1-19 | Textes FR / EN | « Sans compte » + « Supprimer mon compte » côte à côte ; « Sans compte, tu ne pourras plus revenir sur ce compte » (EN : « Without an account, you won't be able to come back to this account ») ; « coquille » et « skin » mélangés ; « Lustre » (EN britannique) vs public américain « Luster » ; « by oyster number 26 at the latest » lourd ; perle « presque ronde, fêlée » dont le texte dit « Ronde, sage, impeccable ». | Propositions en annexe B. Relecture anglophone (déjà prévue en §6). | S |

### Technique visible

| # | Constat et preuve | Recommandation | Effort |
|---|---|---|---|
| P1-20 | **Rendu continu** : le lagon (Canvas) est redessiné à chaque image via `TimelineView(.animation)` sur la Pêche, la boutique (4 lagons de plus dans les cartes de coquilles), la collection ; mesuré ≈ 30–40 % d'un cœur au simulateur partout, **y compris sous une fenêtre**. Sur un iPhone ProMotion, c'est 120 images/s pour de l'eau calme. | Fond limité à 30 images/s (`minimumInterval`), en pause quand une fenêtre le couvre, en mode économie d'énergie et quand l'huître est immobile depuis 10 s ; cartes de coquilles figées (rendu animé seulement sur la coquille touchée). Mesurer avec Instruments sur un iPhone réel. | M |
| P1-21 | **Sauvegarde = tout le JSON dans `UserDefaults` à chaque action**, sur le fil principal. Un régulier fait ≈ 1 600 cartes par mois (moins avec la revente) : le fichier grossit sans fin. | Fichier dans Application Support, écriture différée (≤ 1 par seconde) hors fil principal ; préparer la synchro (P1-5). | M |

## P2 : plus tard

| # | Constat | Recommandation | Effort |
|---|---|---|---|
| P2-1 | Horloge du téléphone = jour des missions, du calendrier et des pubs : avancer la date donne tout (pas grave en solo, bloquant avant tout classement). | Heure serveur (Supabase) ou garde-fous monotones avant Game Center. | M |
| P2-2 | Fermer l'app pendant la fuite du poisson rend la perle **et** les 2 ✦ (`resolveTheft(caught: true)` au lancement). | Rendre la perle sans bonus (devient sans objet avec P0-3). | S |
| P2-3 | Un toucher arrivé juste après la fuite referme le panneau « Un poisson a filé… » avant qu'on l'ait lu. | Ignorer les touchers pendant 0,5 s après l'apparition. | S |
| P2-4 | Classement Game Center et sauvegarde iCloud promis dans `duo-gadget.md` §4, absents. | Lot technique (voir feuille de route revue). | M |
| P2-5 | Écran extérieur du Duo : le « flex » de la coquille est le meilleur argument de vente des skins ; seulement 3 coquilles à vendre. | Nouvelles coquilles régulières (une par lot), sans durée limitée. | M |

## Ce qui marche (à garder)

- Le geste et sa mise en scène : résistance, « pop », lumière de la couleur de la perle, suspense par rareté, perles qui tremblent. La carte qu'on incline est une très bonne idée.
- Les règles sont propres : tirage décidé avant le geste et sauvegardé (une perle restaurée revient identique), parité TS/Swift, aucun nombre magique, sauvegardes anciennes rattrapées sans rien perdre.
- Probabilités affichées en trois endroits, garantie écrite, coquilles « purement cosmétiques » dites clairement, pubs non personnalisées sans ATT, notification demandée seulement quand elle sert, « Réduire les animations » respecté partout.
- Marée basse ([08](audit-app-ios/08-maree-basse.jpg)) : quatre issues claires (attendre, pub, poussière, notification), ton juste.

---

## Feuille de route : proposition revue (à valider, `ios-feuille-de-route.md` non modifié)

Constat qui change l'ordre : avec la boule de neige actuelle, **un joueur de J7 est déjà niveau 18 à 25**. Tout ce qui « se débloque par niveau » (principe 4) dans les lots 1.4 à 1.7 arrivera **d'un coup** chez les joueurs existants. Et le contenu (7 perles) est épuisé en quelques jours : il faut du **but long** (Maison, carnet) et des **puits** (Atelier) plus tôt que du raffinement (Expertise).

| Version | Lot | Pourquoi |
|---|---|---|
| 1.0.1 | Lancement (inchangé) + P0-7 (consentement), P0-11 (Apple), P0-10 (mesure) | Corrections sans risque, et les premiers chiffres réels. |
| **1.1** | **Niveaux + Collection + Succès (déjà faits) + « Confiance et équilibrage »** : P0-1 à P0-6, P0-8, P0-9, P1-7, P1-12 | Les trois lots sont prêts sur la même branche ; les envoyer ensemble évite deux revues Apple et un équilibrage fait trois fois. Le « une fonction à la fois » se fait dans l'app (déblocage par niveau), pas par version. |
| 1.2 | Sauvegarde en ligne + compte utile + Game Center + Première marée | Donne enfin un rôle au compte, protège les achats (P1-5), et le classement demandé par Mathys. |
| 1.3 | Écrins et bijoux (ex-1.4), sources recalées sur l'économie corrigée | Le gros lot, sur une base saine. Prévoir dès le départ l'alternative VoiceOver à l'angle d'éclat. |
| 1.4 | **La Maison de Rose** (ex-1.6) | Le meilleur moteur J7–J30 (une lettre par niveau, un fil narratif), sans risque pour l'économie. |
| 1.5 | **L'Atelier** (ex-1.7) | Donne un usage aux doublons et à la poussière : c'est le puits qui manque (P1-1). |
| 1.6 | Lagon 2 (Jardin d'algues) | De nouvelles perles à chasser quand la Crique est complète. |
| 1.7 | Expertise à la loupe (ex-1.5), éventuellement fondue dans un lot Écrins 2 | Mini-jeu réservé aux pierres précieuses : utile, mais après les boucles longues. |
| 1.8+ | Lagons 3 et 4, nouvelles coquilles | Contenu régulier. |

**Ce qui est en trop ou à retirer** : le mur de connexion (P0-6) ; la perte au poisson (P0-3) ; les recharges vendues contre de l'argent si D1 est tranchée dans ce sens.
**Ce qui manque** : un objectif visible à la Pêche, une garantie affichée, un puits à poussière, la mesure d'usage, une raison sociale (classement, partage d'une carte « flex »).

## Décisions que Jules doit prendre

| # | Question | Options | Recommandation |
|---|---|---|---|
| **D1** | Continuer à **vendre des huîtres** (tirages payants) ? | (a) garder, avec P0-4/P0-5 et retrait par pays ; (b) **ne vendre que des coquilles et de la poussière qui n'achète pas d'huîtres**, la pub restant le seul moyen de pêcher plus | (b) : l'app devient irréprochable partout (Belgique comprise, Brésil, futurs textes UE), et le flex des coquilles est déjà le bon produit. À trancher avec les chiffres de P0-10 si possible. |
| **D2** | Récompenses de niveau et de succès : huîtres ou poussière / cosmétiques ? | (a) poussière + titres ; (b) huîtres dans une réserve séparée et plafonnée | (a), puis simulation pour viser ≤ 40 huîtres à la 1re séance. |
| **D3** | Le poisson voleur peut-il faire perdre une perle ? | (a) non, bonus seulement ; (b) la perle revient à la séance suivante ; (c) tel quel | (a) ou (b). |
| **D4** | Connexion au premier lancement ? | (a) supprimée, proposée plus tard ; (b) gardée | (a). |
| **D5** | Envoyer 1.1 + 1.2 + 1.3 en **une seule version** ? | (a) une version « 1.1 » ; (b) trois versions | (a), avec le lot d'équilibrage. |
| **D6** | Outil de mesure d'usage | TelemetryDeck (UE, sans données personnelles) ; PostHog EU | TelemetryDeck : simple, sans bannière. Nouvelle dépendance → §6. |
| D7 | Première marée : lien à code ou compte ? | voir `duo-gadget.md` §6 | Lien à code, livrable sans serveur. |

---

## Annexe A : la simulation de l'économie

Programme jetable (hors dépôt), **vrai moteur PearlCore** (`PlayerState.reveal`, `sellAllDuplicates`, `claimMission`, `claimDaily`, `claimAdReward`, niveaux et succès compris, tirage du poisson à part), 200 parties par profil, 30 jours à partir du 1er novembre. Hypothèses : chaque séance ouvre tout le stock, récupère calendrier et missions, revend les doublons ; lustre S/A/B/C = 10/30/35/25 % (léger) à 30/35/25/10 % (gros), fêlure 15 % à 5 % ; poisson rattrapé 50 % à 80 % ; le joueur épargne sa poussière.

| Profil | Séances / jour | Pubs | Huîtres / jour (moy.) | Niveau J7 / J30 | Succès J30 | ✦ gagnée en 30 j | Bénitier (médiane) | 7 perles (médiane) |
|---|---|---|---|---|---|---|---|---|
| Léger | 2 (9 h, 21 h) | 0 | 33 | 17,9 / 26,9 | 27,6 / 32 | 3 981 | **J12** | **J3** |
| Régulier | 3 | 3 / jour | 54 | 21,4 / 32,6 | 29,3 | 6 042 | **J7** | **J2** |
| Gros | 9 | 3 / jour | 84 | 24,6 / 39,0 | 30,1 | 8 664 | **J4** | **J1** |
| Payeur (régulier + Grande marée tous les 3 jours) | 3 | 3 / jour | 60 | 22,0 / 34,0 | 29,5 | 6 589 | J6 | J2 |

- **Jour 1** (léger) : 193 huîtres, niveau 14, 19 succès, 766 ✦. Séance unique sans pause : **205 huîtres (≈ 23 min)**, dont 90 données par les niveaux.
- Poussière : revente 65 % (léger) à 77 % (gros), missions 12 %, niveaux et succès 13 %, calendrier 7 %, poisson 1,5 %, pièces d'or < 1 % (joueur léger).
- Perles ◆◆◆ et plus : 15,4 % des huîtres (8 % de noires + 6 % de dorées ou mieux, plus la garantie). Huîtres vides : 9 %. Perles perdues au poisson : ≈ 28 par mois.
- **Effet des achats** : 30 huîtres tous les 3 jours (≈ 30 € par mois) n'avancent le bénitier que d'un jour et rien d'autre de visible : l'achat d'huîtres a peu de valeur perçue tant que P0-1 inonde le joueur d'huîtres gratuites.

## Annexe B : textes proposés (FR / EN)

| Où | Aujourd'hui | Proposé FR | Proposé EN |
|---|---|---|---|
| Bulle après le tutoriel | Tes huîtres sont en haut : 10 au maximum, une revient toutes les 20 min. | Tes huîtres sont en haut. Elles reviennent seules, une toutes les 20 min. | Your oysters are up top. They come back on their own, one every 20 min. |
| Réglages, compte anonyme | Sans compte · Supprimer mon compte | Partie sur cet iPhone · Effacer ma partie et mon identifiant | Game on this iPhone · Erase my game and ID |
| Déconnexion anonyme | Sans compte, tu ne pourras plus revenir sur ce compte. | Tu joues sans compte : en te déconnectant, tu ne pourras pas retrouver cet identifiant. Ta partie reste sur cet iPhone. | You're playing without an account: if you sign out, this ID can't be recovered. Your game stays on this iPhone. |
| Garantie | Guarantee: a golden pearl or rarer by oyster number 26 at the latest. | Garantie : une perle dorée ou plus rare en 26 huîtres au plus. Encore N. | Guaranteed: a golden pearl or rarer within 26 oysters. N to go. |
| Poisson raté (avec P0-3) | Un poisson a filé avec ta perle rosée ! | Le poisson a lâché ta perle rosée en filant. La prochaine fois, attrape-le : il paie l'amende ! | The fish dropped your rose pearl as it fled. Catch it next time: it pays a fine! |
| VoiceOver, huître | Glisse le doigt vers le haut pour l'ouvrir doucement. | Action disponible : ouvrir l'huître. | Action available: open the oyster. |
| Carte | Valeur 29 | Valeur 29 ✦ (si D-valeur = revente) | Value 29 ✦ |
| Termes | coquille / skin | « coquille » partout | « shell » everywhere |
| Lustre (EN) | Lustre | — | Luster (si l'on vise les États-Unis) |

## Annexe C : captures

`docs/audit-app-ios/` : 01 calendrier par-dessus la fête · 02 carte · 03 boutique · 04 coquilles et barre d'état · 05 probabilités · 06–07 poisson voleur · 08 marée basse · 09–11 texte au plus grand · 12 consentement pendant le tutoriel · 13 fin du tutoriel (31 huîtres) · 14 bulle « 10 au maximum » · 15 connexion · 16 Duo, pli · 17 collection 7/7 · 18 missions · 19 Pêche sans objectif visible.

Sauvegardes des simulateurs : copiées avant l'audit et remises à la fin (iPhone 17 Pro, iPhone 17e) ; simulateurs éteints. Sur le 17e, une déconnexion puis « Jouer sans compte » a créé un nouvel utilisateur anonyme dans Supabase.
