## Perle — Cahier des charges du jeu

> Les notes surlignées en vert dans le .docx (notes de Mathys) sont intégrées telles quelles ci-dessous ; leur traitement est suivi dans AGENTS.md §8.

Oct 5, 2026 · @Jules

### 1. Vision et positionnement

Perle est un jeu mobile gratuit où l'on part pêcheur de perles pour finir à la tête d'une Maison de haute joaillerie, et où chaque ouverture se joue avec un vrai geste. Sur iPhone Duo, ce geste est la charnière du téléphone ; sur un iPhone classique, c'est un geste tactile dédié.

Pitch en une phrase : ouvre des huîtres, révèle des perles, crée des bijoux, bâtis ta Maison.

Promesse au joueur :

- Un frisson à chaque ouverture : suspense, lumière qui filtre, révélation, carte à collectionner.

- Une collection qui grandit et se montre : perles, pierres, bijoux, cartes holographiques.

- Une création qui m'appartient : je transforme ce que je trouve en pièces uniques, que je peux offrir.

- Une Maison qui monte en prestige, jour après jour.

Positionnement. Le jeu croise trois familles qui marchent sur mobile : l'ouverture de packs façon jeu de cartes à collectionner, la collection cosy, et la gestion d'atelier et de boutique. Sa différence tient en trois points : le geste physique d'ouverture, un univers luxe mais accessible, et une bonne dose d'humour (bijoux en toc, fausse demande en mariage).

Ambition. Devenir l'application vitrine du pliage de l'iPhone Duo, tout en restant pleinement jouable sur n'importe quel iPhone, puis décliner le moteur d'ouverture sur d'autres objets et d'autres pliables.

### 2. Cible, piliers et ton

Le cœur de cible a 18 à 35 ans, joue en sessions courtes et adore l'effet de révélation : unboxing, ASMR, ouverture de boosters.

| Segment | Pourquoi il joue | Ce qu'on lui sert en priorité |
|---|---|---|
| Joueurs casual mobile | Petites sessions satisfaisantes | Ouvertures rapides, récompenses quotidiennes |
| Collectionneurs (cartes, figurines) | Compléter, comparer, exhiber | Raretés, cartes holo, albums, numéros de série |
| Amateurs de création et de déco | Faire des choses belles et uniques | Atelier, vitrine personnalisable |
| Couples et groupes d'amis | Offrir, faire rire, piéger | Cadeaux, fausse demande, jeux à deux |
| Acheteurs de l'iPhone Duo | Tester leur nouveau téléphone | Mécanique de charnière, exclusivités Duo |

Les quatre piliers de design. Chaque fonctionnalité doit servir au moins l'un d'eux, sinon elle sort du périmètre.

- Le geste. Chaque ouverture est un petit moment de suspense physique, jamais un simple bouton.

- La collection. Tout ce qu'on trouve se range, se compare et se montre.

- La création. On transforme ses trouvailles en pièces uniques.

- Le lien. On offre, on montre, on piège ses proches.

Ton. Élégant et décalé à la fois : la mise en scène d'une maison de luxe, avec des clins d'œil comme la bague qui verdit ou l'huître vide qui te nargue. Rendre chaque animation inoubliable et ultra addictive insipire toi des meilleur (fut , clash royale ect…)

Rythme de jeu visé. Trois à cinq sessions de 2 à 5 minutes par jour, plus une session longue de 15 à 20 minutes à l'atelier ou à la vitrine, plusieurs fois par semaine.

### 3. Plateformes : iPhone Duo et iPhone classique

Tout le contenu est jouable sur n'importe quel iPhone ; l'iPhone Duo offre la version « comme en vrai » du même jeu, jamais du contenu en plus. Aucune perle, aucun bijou, aucune progression n'est réservée au Duo : seuls quelques cosmétiques et effets le sont.

| Action | Sur iPhone Duo | Sur iPhone classique |
|---|---|---|
| Ouvrir une huître ou un écrin | Ouvrir réellement le téléphone : l'angle de charnière pilote l'ouverture | Écarter deux doigts, ou glisser le pouce vers le haut, sur la coquille |
| Résistance au début | Aimants physiques + vibration | Glissé freiné + vibration Taptic |
| Zone fragile (huître) | Vitesse d'ouverture de la charnière | Vitesse du glissé |
| Angle d'éclat (écrin) | Tenir la charnière immobile | Tenir le doigt immobile à la bonne hauteur |
| Sertir un bijou (atelier) | Refermer le téléphone | Pincer deux doigts jusqu'à les rejoindre |
| Écran extérieur | Huître fermée, annonce de rareté, télécommande du farceur | Dynamic Island, Live Activities et widgets |
| Jeux à deux face à face | Un écran par joueur | À tour de rôle, ou en ligne |

Exclusivités Duo, purement cosmétiques : badge « Pêché sur Duo » sur les cartes, effets d'ouverture dédiés, mode StandBy qui transforme le Duo posé en vitrine de tes plus belles pièces.

Socle technique recommandé. Une app native SwiftUI avec un moteur 3D léger (SceneKit ou RealityKit). Les API de charnière arrivent avec iOS 27.1, donc le jeu les détecte et bascule automatiquement sur les gestes tactiles ailleurs. La fréquence des mises à jour d'angle dépend du système : la mécanique de vitesse devra être calibrée sur un vrai Duo.

Plus tard : iPad, puis Android avec les pliables Samsung et Google, qui exposent aussi l'angle de charnière.

### 4. Boucles de jeu

Le jeu tourne sur trois boucles emboîtées : l'ouverture (30 secondes), la session (5 minutes) et la Maison (des semaines).

boucle de jeu · 6 étapes

Une huître ouverte rapporte des matériaux, l'atelier les transforme, les ventes font monter la Maison, et chaque rang débloque de meilleures zones et de meilleurs outils de pêche. Les écrins et la collection se branchent sur chaque étape.

| Boucle | Durée | Ce que fait le joueur | Ce qu'il en retire |
|---|---|---|---|
| Ouverture | 10 à 30 s | Ouvrir une huître ou un écrin | Une perle ou un bijou, une carte, un frisson |
| Session | 2 à 5 min | 5 à 10 huîtres, 1 écrin, 1 commande, quêtes du jour | Coquillages, réputation, progrès de collection |
| Maison | Semaines | Rangs, chapitres d'histoire, saisons, albums | Nouvelles zones, recettes, prestige, cosmétiques |

### 5. Acte 1 : la Pêche

La pêche est la boucle gratuite du quotidien : on ouvre des huîtres pour récolter perles, nacre et trouvailles, qui alimentent tout le reste du jeu.

#### Le geste d'ouverture

- Résistance : les premiers degrés résistent (aimants sur Duo, glissé freiné ailleurs), puis la coquille cède avec un petit « pop ».

- Signal de rareté : la lumière qui filtre par l'entrebâillement prend la couleur de la perle. Une huître vide reste noire. Les très rares tremblent avant même d'être touchées.

- Zone fragile : entre 20° et 110°, ouvrir trop vite fêle la perle et divise sa valeur par deux.

- Lustre : la régularité de l'ouverture donne une note de lustre (S, A, B, C) qui améliore la qualité des bijoux fabriqués ensuite.

- Révélation : carte à collectionner avec nom, taille, valeur, numéro de série unique.

#### Raretés des perles

| Perle | Rareté | Probabilité | Usage principal |
|---|---|---|---|
| Huître vide | — | 12 % | Donne des coquillages en consolation |
| Perle blanche | ◆ | 40 % | Colliers et bracelets de base |
| Perle rosée | ◆ | 22 % | Boucles d'oreilles, recettes douces |
| Perle baroque | ◆◆ | 12 % | Pièces uniques, prime d'originalité |
| Perle noire | ◆◆◆ | 8 % | Bijoux de prestige |
| Perle dorée | ★ | 4,5 % | Commandes de luxe |
| Perle géante | ★★ | 1,2 % | Pièces maîtresses, musée |
| Perle maudite | ★★ | 0,3 % | Quête cachée et parure secrète |

Une perle dorée ou mieux est garantie après 25 huîtres sans en trouver. Chaque zone ajoute ses propres perles (par exemple la perle lunaire, uniquement les nuits de pleine lune).

Pourquoi pas faire une perle encore plus rare avec 0,1% de chance

#### Zones de pêche

Les zones se débloquent avec le niveau et changent les tables de rareté, les trouvailles et l'ambiance sonore.

| Zone | Déblocage | Spécialité |
|---|---|---|
| La Crique | Début | Perles blanches et rosées, tutoriel |
| Le Lagon | Niveau 8 | Perles baroques, coquillages en abondance |
| Le Récif | Niveau 15 | Perles noires, pierres brutes |
| Les Abysses | Niveau 25 | Perles dorées et géantes, épaves |
| La Fosse polaire | Niveau 40 | Perles de glace exclusives, rareté accrue |
| Zone d'événement | Saison en cours | Perles limitées à la saison |

#### Chaque décor doit être ultra beau

#### Trouvailles

Certaines huîtres contiennent autre chose qu'une perle : pièce d'or engloutie (fondue en métal à l'atelier), pierre brute (à tailler), bouteille avec un message (lance une quête), clé d'épave (ouvre un coffre d'épave rare).

#### Énergie et outils

- Stock d'huîtres : 10 huîtres maximum, 1 qui se recharge toutes les 30 minutes. Une pub récompensée en donne 3 (5 fois par jour maximum).

- Couteau à huîtres améliorable : réduit la résistance et élargit la marge de la zone fragile.

- Gants : protègent d'une fêlure par jour.

- Lampe de plongée : affiche la rareté probable sur l'écran extérieur avant ouverture, pour décider quelle huître garder pour un moment spécial.

- Bourriche : garder jusqu'à 3 huîtres fermées pour plus tard, par exemple pour les ouvrir en vidéo.

### 6. Acte 2 : l'Atelier

L'atelier, débloqué au niveau 5, transforme les trouvailles en bijoux, et le pliage y devient l'outil de fabrication : on pose les pièces de part et d'autre de la pliure, puis on referme le téléphone pour sertir.

#### L'établi

- Moitié gauche : la perle ou la pierre. Moitié droite : la monture (bague, collier, bracelet, boucles d'oreilles, broche, puis diadème).

- Sertissage : refermer le Duo, ou pincer deux doigts sur un iPhone classique. Une fermeture ni trop brusque ni trop hésitante donne un sertissage parfait.

- Qualité finale : qualité des matériaux (lustre, taille, pureté) × réussite du geste, notée de 1 à 5 étoiles.

#### Les matériaux

| Matériau | D'où il vient | À quoi il sert |
|---|---|---|
| Perles | Pêche | Pièce centrale ou rangs de perles |
| Pierres brutes | Pêche (Récif et plus), écrins | À tailler en saphir, rubis, émeraude, diamant |
| Métaux (argent, or, or rose, platine) | Pièces d'or fondues, écrins, commandes | Montures et chaînes |
| Nacre | Toutes les huîtres | Incrustations, améliorations de montures |
| Fermoirs et apprêts | Boutique de l'atelier (coquillages) | Indispensables aux colliers et bracelets |
| Montures de maître | Écrins rares, commandes de prestige | Bonus de qualité et de valeur |

#### Les mini-jeux artisanaux

Chaque étape a son geste court, toujours facultatif à partir du niveau de maîtrise suffisant (on peut alors l'automatiser) :

- Taille de pierre : faire pivoter la pierre et frapper en rythme pour créer les facettes. Plus de facettes réussies, plus d'éclat.

- Fonte : verser le métal en inclinant le téléphone, sans déborder.

- Sertissage : le geste de fermeture décrit plus haut.

- Polissage : frotter l'écran en cercles jusqu'à faire briller la pièce.

- Gravure : écrire au doigt (ou à l'Apple Pencil sur Duo) un prénom ou une date, idéal pour les cadeaux.

#### Recettes et création libre

- Grimoire de recettes : modèles débloqués par le niveau, les commandes, les bouteilles à la mer et les écrins. Une recette garantit un résultat précis (par exemple 7 perles blanches + fermoir en or = collier « Rivage »).

- Création libre : toute combinaison valide donne un bijou, nommé et évalué par le jeu. Découvrir une combinaison secrète ajoute la recette au grimoire.

- Parures : trois pièces assorties (même pierre, même métal) forment une parure, avec un bonus de valeur et une place dédiée dans la collection.

#### Temps et production

Les pièces simples sont instantanées. Les pièces maîtresses demandent de 1 à 8 heures, accélérables par une pub, des éclats ou l'abonnement. Un deuxième établi se débloque au niveau 20 (ou avec l'abonnement). Fondre un bijou rend une partie de ses matériaux, ce qui évite les impasses.

### 7. Acte 3 : les Écrins

Les écrins, débloqués au niveau 3, sont la récompense « coup de cœur » du jeu : ils contiennent des bijoux finis ou des composants rares, et se gagnent surtout en jouant.

#### Le geste : l'angle d'éclat

Chaque écrin cache un angle d'éclat aléatoire. Plus on s'en approche, plus le bijou scintille. Tenir la position une seconde donne un éclat parfait : valeur ×1,5, carte holographique, et une chance de variante rare. L'huître récompense la patience, l'écrin récompense la précision.

#### Les types d'écrins

| Écrin | Comment l'obtenir | Particularité |
|---|---|---|
| Velours | Niveaux, commandes, coffre quotidien, pub (1 par jour) | Table de rareté standard |
| Vintage | Quêtes, bouteilles à la mer | Bijoux anciens et montures de maître |
| Saison | Pass de saison, événements | Pièces limitées à la saison en cours |
| Couronne | Récompenses rares, éclats, abonnement (1 par semaine) | Garantit une pièce ◆◆◆ ou mieux |
| Atelier | Commandes d'artisans | Contient des composants plutôt que des bijoux |
| Marque | Partenariat avec une vraie maison de bijoux | Pièce inspirée de la marque + avantage réel |

#### Les raretés des bijoux

Dix raretés, du toc à la légende : toc, fantaisie, argent, or, perles, saphir, émeraude, rubis, diamant, légende. Chaque tirage combine une rareté, un type de bijou, un métal, un poids en carats et une estimation. Une pièce ★ ou mieux est garantie après 20 écrins sans en trouver. Les probabilités de chaque écrin sont affichées avant toute ouverture.

#### Expertise et doublons

- Expertise à la loupe : un mini-jeu facultatif pour repérer les inclusions d'une pierre. Une expertise réussie délivre un certificat qui augmente la valeur.

- Poussière d'or : un doublon peut être converti en poussière d'or, qui permet d'acheter précisément la pièce manquante de son choix. Personne ne reste bloqué sur une collection à cause du hasard.

- Admirer : on peut fermer la carte pour contempler le bijou dans son écrin, puis la rouvrir d'un geste.

### 8. Acte 4 : la Maison

La Maison est la méta-progression du jeu : le joueur reconstruit la Maison de joaillerie héritée de sa grand-mère perlière, de la cabane de pêcheur jusqu'à la boutique de luxe.

#### Le fil narratif

Une histoire en chapitres sert de colonne vertébrale : la grand-mère a laissé un carnet de recettes incomplet et une boutique à l'abandon. Chaque chapitre débloque une pièce de la Maison et révèle un secret, jusqu'à l'origine de la perle maudite.

#### Les rangs de prestige

| Rang | Niveau | Ce qui s'ouvre |
|---|---|---|
| Pêcheur | 1 | La Crique, l'ouverture d'huîtres |
| Perlier | 5 | L'atelier, les premières recettes |
| Artisan | 10 | La vitrine, les commandes clients |
| Joaillier | 20 | Deuxième établi, taille de pierres avancée, Salon hebdomadaire |
| Maître joaillier | 35 | Personnel, pièces maîtresses, musée ouvert aux amis |
| Maison de haute joaillerie | 50 | Collections signées, défilés, partenariats de marque |

#### Les commandes clients

Des personnages récurrents passent commande, chacun avec son histoire : le fiancé indécis, la comtesse exigeante, la star de cinéma pressée, le rappeur fan de diamants. Une commande précise un type de bijou, une pierre ou un métal, un budget et un délai. La réussir rapporte coquillages, réputation et parfois une recette ou un écrin. Les commandes urgentes paient double mais expirent vite.

#### La vitrine et la boutique

- La vitrine se décore (présentoirs, éclairages, sols, enseigne) et expose les plus belles pièces.

- Des visiteurs achètent les bijoux mis en vente, ce qui crée un revenu passif, plafonné pour inciter à revenir.

- Le musée accueille les pièces qu'on refuse de vendre ; les amis peuvent le visiter et laisser une appréciation.

#### Le personnel

| Employé | Effet |
|---|---|
| Plongeur | Ramène quelques huîtres par jour automatiquement |
| Apprenti | Accélère la fabrication à l'atelier |
| Vendeur | Améliore le prix de vente en vitrine |
| Expert | Réussit automatiquement les expertises simples |

#### Le Salon de la joaillerie

Chaque semaine, les joueurs présentent une parure sur un thème imposé. Un jury mêlant notes automatiques et votes de joueurs établit un classement, récompensé en écrins et en titres.

### 9. Progression, monnaies et économie

L'économie repose sur deux monnaies et deux ressources, avec une règle simple : tout ce qui touche au gameplay peut s'obtenir gratuitement, l'argent réel achète du temps, du confort et du style.

| Monnaie ou ressource | Comment on la gagne | À quoi elle sert |
|---|---|---|
| Coquillages (monnaie courante) | Huîtres vides, ventes en vitrine, commandes, quêtes | Outils, fermoirs, décor, améliorations |
| Éclats (monnaie premium) | Achat, pass de saison, succès, rares récompenses | Accélérations, écrins Couronne, cosmétiques |
| Poussière d'or | Conversion des doublons | Acheter la pièce ou la recette manquante de son choix |
| Réputation (expérience) | Toute action, surtout les commandes | Monter de niveau et de rang |
| Huîtres (énergie) | Recharge dans le temps, pub, abonnement, plongeur | Pêcher |

#### Niveaux et déblocages

Le niveau joueur va de 1 à 100. Chaque niveau donne une récompense, et les déblocages sont étalés pour qu'il y ait toujours une nouveauté proche :

| Niveau | Déblocage |
|---|---|
| 1 | Pêche, La Crique |
| 3 | Écrins |
| 5 | Atelier, rang Perlier |
| 8 | Commandes clients, Le Lagon |
| 10 | Vitrine, amis et cadeaux |
| 15 | Le Récif, taille de pierres |
| 20 | Deuxième établi, Salon hebdomadaire |
| 25 | Les Abysses, épaves |
| 35 | Personnel, musée ouvert |
| 40 | La Fosse polaire |
| 50 | Maison de haute joaillerie, collections signées |

#### Principes d'équilibrage

- Sources et dépenses équilibrées : chaque monnaie a au moins deux usages qui donnent envie, pour éviter l'accumulation sans but.

- Le temps comme limite : un joueur gratuit régulier atteint le niveau 50 en environ 4 à 6 mois ; un abonné, 30 à 40 % plus vite. Ces durées sont des objectifs à valider en tests.

- Aucune impasse : poussière d'or et fonte de bijoux garantissent qu'on progresse même avec une mauvaise série.

- Pas de vente directe de la rareté en compétition : le classement du Salon ne s'achète pas.

### 10. Collection, cartes et succès

Tout objet trouvé ou créé devient une carte numérotée qui se range, se compare et se partage : c'est le moteur de rétention à long terme.

- Encyclopédie des perles : une page par zone, avec les perles découvertes et des silhouettes pour celles qui manquent.

- Collection de bijoux : une grille rareté × type de bijou (10 raretés × 6 types), chaque case affichant la plus belle pièce obtenue et son nombre d'exemplaires.

- Cartes à collectionner : nom, rareté, statistiques, texte d'ambiance, numéro de série. Variantes rares : holographique (éclat parfait), « Première pêche du jour », « Pleine lune », « Pêché sur Duo », et les numéros #0001 à #0100 de chaque saison.

- Albums thématiques : par exemple « Les sept mers », « Parure royale », « Bijoux de pacotille ». Compléter un album donne un écrin, un titre et un décor de vitrine.

- Succès et titres : environ 150 succès (première perle noire, 100 huîtres sans fêlure, toutes les perles du Lagon…), dont certains secrets. Les titres s'affichent sur le profil.

- Partage : chaque carte s'exporte au format story vertical, avec le nom du joueur et un lien de téléchargement.

### 11. Social et jeux à deux

Le social sert d'abord l'acquisition : chaque cadeau envoyé est une ouverture d'écrin chez quelqu'un qui n'a pas encore le jeu.

#### Offrir

- On emballe un bijou de sa collection (ou une perle) dans un écrin, avec un mot et une gravure éventuelle.

- Le cadeau part par iMessage ou par lien. Le destinataire l'ouvre sans installer le jeu, grâce à un App Clip (mini-version instantanée d'une app iOS), puis il est invité à télécharger Perle pour le garder.

- Sur Duo, le destinataire ouvre l'écrin en pliant son téléphone ; sur un iPhone classique, au geste.

#### Amis et communauté

- Amis via Game Center ou code ami ; visite de la vitrine et du musée des amis.

- Échanges de perles et de doublons, limités par jour pour éviter les abus.

- Ateliers (guildes de 20 à 30 joueurs) : commandes collectives chaque semaine, discussion, classement entre ateliers.

- Classements : trésor, Salon hebdomadaire, collection, par pays et entre amis. Nombre d'huître ouvertes

#### Jeux à deux sur un seul téléphone

Sur Duo, chaque joueur a son écran (intérieur et extérieur) ; sur iPhone classique, on se passe le téléphone.

| Mode | Principe |
|---|---|
| Enchère à l'aveugle | Chacun voit une huître différente et mise des coquillages sur celle de l'autre |
| Devine la perle | L'un voit la perle, l'autre pose des questions fermées pour la deviner |
| Duel d'atelier | Même lot de matériaux, 90 secondes, le plus beau bijou gagne |
| Ouverture croisée | Chacun ouvre l'huître de l'autre ; la plus belle perle gagne les deux |

#### Partage vidéo

Un bouton enregistre l'ouverture en vidéo verticale de 10 secondes, avec en option la réaction filmée par la caméra frontale en incrustation, prête pour TikTok et Instagram. Voir si apple est ok avec ça

### 12. Fausse demande : l'application compagnon

La fausse demande vit à part, dans une petite application gratuite qui sert de porte d'entrée virale vers Perle, tout en restant accessible depuis le jeu.

#### Pourquoi une application séparée

- Elle se comprend en une seconde, sans tutoriel ni progression : idéal pour un téléchargement impulsif après une vidéo.

- Elle occupe un autre mot-clé dans l'App Store (« fausse demande », « prank »).

- Chaque utilisation se termine par une invitation à ouvrir de vraies huîtres dans Perle.

#### Le déroulé

- L'iPhone est tenu en paysage comme un écrin à bague ; fermé, l'écran extérieur ressemble à un couvercle en velours, sans aucun texte.

- On soulève le couvercle à moitié : le message (« Veux-tu m'épouser ? » par défaut, personnalisable) apparaît sur le satin, la bague scintille sur le coussin.

- Après un délai réglable, la chute s'affiche : « …avec une bague bonbon. Tu y as cru ? », avec un son.

- Pendant ce temps, le farceur voit sa télécommande (compte à rebours, déclenchement) : sur l'écran extérieur du Duo, ou sur l'Apple Watch avec un iPhone classique.

#### Fonctionnalités

| Fonction | Gratuit | Pack premium ou abonnement Perle |
|---|---|---|
| Bagues en toc (bonbon, fête foraine, qui verdit) | 3 bagues | Catalogue complet + bagues de sa collection Perle |
| Message personnalisé | Oui | Polices et couleurs supplémentaires |
| Chutes | 1 chute | Sons, animations (confettis, « Pas encore prêt(e) »), chute personnalisée |
| Vraie demande (solitaire, sans chute, musique) | Oui | Écrins et musiques premium |
| Enregistrement de la réaction | Oui, avec filigrane | Sans filigrane |

Prix indicatif du pack : 2,99 € en achat unique, inclus dans l'abonnement Perle. Pic d'activité visé : la Saint-Valentin.

### 13. Live ops : saisons et événements

Le jeu vit par saisons de 6 semaines, chacune avec un thème, une zone de pêche, une collection limitée et un pass ; le calendrier réel fournit les temps forts.

#### Une saison type

- Thème : par exemple Riviera, Art déco, Polaire, Orient, Carnaval.

- Zone de pêche temporaire avec ses perles exclusives.

- Collection limitée de 12 à 20 pièces, qui ne revient jamais sous la même forme.

- Pass de saison à deux voies : une voie gratuite, une voie premium (cosmétiques, écrins Saison, éclats, effet d'ouverture exclusif).

- Commandes et chapitre d'histoire liés au thème.

#### Temps forts du calendrier

| Période | Événement | Mécanique phare |
|---|---|---|
| Février | Saint-Valentin | Cadeaux en écrin, fausse demande, parures de couple |
| Mai | Fête des mères | Bijoux à offrir avec gravure |
| Été | Grandes marées | Double rareté certains week-ends |
| Octobre | Halloween | Perles maudites plus fréquentes, écrins hantés |
| Novembre | Black Friday | Offres de packs et d'abonnement annuel |
| Décembre | Calendrier de l'Avent | Un écrin par jour du 1er au 24 |
| Chaque mois | Pleine lune | Perles lunaires pendant 24 heures |

#### Événements communautaires

Des objectifs collectifs mondiaux (par exemple « 10 millions d'huîtres ouvertes en une semaine ») débloquent une récompense pour tous les participants, ce qui crée un sentiment d'événement partagé.

### 14. Business model

Perle est gratuit, sans pub imposée, et se finance par cinq sources : l'abonnement Club Perle, les pubs récompensées choisies par le joueur, les achats intégrés, le pass de saison et les partenariats de marques.

#### Les principes

- Jamais de pub forcée (pas d'interstitiel) : l'univers est haut de gamme, les pubs sont toujours un choix récompensé.

- Tout le gameplay est gagnable gratuitement ; l'argent achète du temps, du confort, du style et des exclusivités cosmétiques.

- Pas de pay-to-win dans le Salon et les classements.

- Probabilités affichées pour tout contenu aléatoire.

#### 1. L'abonnement Club Perle

Prix indicatifs : 4,99 € par mois ou 39,99 € par an, avec 7 jours d'essai gratuit.

| Avantage | Joueur gratuit | Club Perle |
|---|---|---|
| Stock d'huîtres | 10, recharge 30 min | 20, recharge 15 min |
| Récompenses des pubs | Après la pub | Automatiques, sans pub |
| Écrin Couronne | Rare | 1 par semaine |
| Établis | 1 (2 au niveau 20) | 2 dès le départ |
| Bourriche (huîtres gardées) | 3 | 10 |
| Fausse demande premium | Achat à part | Incluse |
| Cosmétique du mois | Créer une boutique payante ? | Inclus |
| Statistiques de collection avancées | — | Incluses |
| Badge et cadre de profil | — | Inclus |

#### 2. Les pubs récompensées

| Récompense | Limite par jour |
|---|---|
| +3 huîtres | 5 |
| 1 écrin Velours supplémentaire | 1 |
| Doubler la récompense d'une commande | 3 |
| Accélérer une fabrication de 30 minutes | 5 |
| Relancer une commande client | 3 |
| Deuxième chance après une perle fêlée (la recoller) | 1 |

#### 3. Les achats intégrés

| Offre | Prix indicatif | Contenu |
|---|---|---|
| Pack de bienvenue (une fois) | 2,99 € | Éclats, 1 écrin Couronne, couteau amélioré |
| Packs d'éclats | 0,99 € à 49,99 € | Monnaie premium |
| Cosmétiques | 1,99 € à 9,99 € | Décors de vitrine, peaux d'écrins, effets d'ouverture, outils |
| Pack Fausse demande | 2,99 € | Catalogue et chutes complets |
| Offres de progression | 4,99 € à 19,99 € | Lots ciblés au moment d'un déblocage |

#### 4. Le pass de saison

Prix indicatif : 7,99 € par saison de 6 semaines, pour la voie premium (cosmétiques exclusifs, écrins Saison, éclats). La voie gratuite reste généreuse.

#### 5. Les partenariats de marques

- Écrins de marque : une vraie maison de bijoux sponsorise un écrin avec une pièce inspirée de sa collection et un avantage réel (code promo, livraison offerte).

- Collections capsules co-signées pendant une saison.

- Lien « voir le vrai bijou » vers la boutique de la marque, rémunéré à la commission.

- Plus tard : produits physiques (cartes imprimées, coffrets « huître à perle » à ouvrir chez soi).

#### Objectifs chiffrés, à valider en test

Ces valeurs sont des ordres de grandeur de jeux mobiles casual, à confirmer pendant le lancement en douceur :

| Indicateur | Objectif |
|---|---|
| Rétention J1 / J7 / J30 | 40 % / 15 % / 6 % |
| Part de joueurs payeurs | 3 à 5 % |
| Part d'abonnés parmi les joueurs mensuels | 1 à 2 % |
| Pubs récompensées vues par joueur actif et par jour | 2 à 4 |

### 15. Onboarding et rétention

Le joueur doit vivre sa première révélation en moins de 60 secondes, et avoir chaque jour une raison claire de revenir.

#### Les dix premières minutes

- 0 à 1 min : une huître fermée à l'écran, une seule consigne. Sur Duo, « Ouvre ton iPhone » ; ailleurs, le geste est montré. Première perle garantie : une perle rosée.

- 1 à 3 min : trois huîtres de plus, dont une huître vide pour faire comprendre le hasard, puis la zone fragile expliquée par l'exemple.

- 3 à 5 min : premier écrin offert, angle d'éclat guidé, premier bijou dans la collection.

- 5 à 10 min : aperçu de l'atelier verrouillé (« niveau 5 ») et de la boutique abandonnée de la grand-mère, pour donner un horizon.

#### Les rendez-vous quotidiens

- Huîtres rechargées et coffre quotidien.

- Calendrier de connexion sur 7 jours, avec un écrin le 7e jour.

- Trois quêtes du jour et cinq quêtes de la semaine.

- Commandes clients qui expirent, ventes en vitrine à récupérer.

- Série de jours consécutifs, avec un « joker » par semaine pour ne pas punir un jour d'absence.

#### Notifications et surfaces iOS

- Au plus deux notifications par jour, toutes désactivables : huîtres pleines, commande prête, cadeau reçu, événement qui commence.

- Widgets de l'écran d'accueil : huîtres disponibles, perle du jour.

- Live Activities : fabrication en cours à l'atelier.

- StandBy sur Duo : le téléphone posé à moitié plié affiche la vitrine et sa plus belle pièce.

#### Indicateurs suivis

Rétention J1, J7, J30 ; durée et nombre de sessions par jour ; entonnoir du tutoriel ; taux d'éclat parfait et de fêlures (équilibrage) ; conversion vers l'abonnement ; pubs vues par joueur ; cadeaux envoyés et taux d'installation après un cadeau.

### 16. Acquisition et lancement

L'acquisition repose sur le contenu vidéo organique et les cadeaux entre joueurs, avec de la publicité payante seulement une fois la rétention prouvée.

- Fenêtre de lancement Duo : l'iPhone Duo sort le 23 octobre 2026. Être parmi les premières apps qui exploitent sa charnière maximise les chances d'être mis en avant par l'App Store. Prévoir un dossier pour l'équipe éditoriale d'Apple : vidéo, captures, explication du geste.

- TikTok et Reels : l'ouverture est un format de 10 secondes tout fait. Séries récurrentes (« j'ouvre 10 huîtres », « la perle la plus rare de la semaine »), créateurs ASMR, unboxing et couples, concours de la plus belle perle.

- Fausse demande : contenus de farces, temps fort à la Saint-Valentin, application compagnon gratuite comme porte d'entrée.

- Viralité intégrée : cadeaux via App Clip, cartes partageables, vidéos d'ouverture exportables, parrainage où les deux joueurs reçoivent un écrin.

- Publicité payante, après validation : Apple Search Ads (« jeu iPhone Duo », « perle », « bijoux »), puis Meta et TikTok avec des créations issues du gameplay.

- Communauté : Discord et compte Instagram pour les révélations de saison et les classements du Salon.

- Relations presse : sites tech et Apple au lancement du Duo ; presse lifestyle et mode pour les partenariats de marques.

- Une grosse partie de cette commu peut venir de X à ne pas négliger tous les gens qui kiffe la tech

### 17. Contraintes légales et App Store

Le jeu doit être conçu dès le départ pour respecter les règles sur les tirages aléatoires, les mineurs et les données ; chaque point ci-dessous est à faire valider par un juriste avant le lancement.

| Sujet | Règle à respecter | Réponse dans le jeu |
|---|---|---|
| Tirages aléatoires payants | L'App Store impose d'afficher les probabilités avant achat | Probabilités visibles sur chaque huître, écrin et pass |
| Belgique | Les tirages aléatoires payants y sont interdits | Version belge : écrins uniquement gagnés en jouant, achats directs d'objets précis |
| Mineurs | Protection renforcée, pas de publicité ciblée | Âge demandé au démarrage, plafond de dépenses, pubs non personnalisées |
| Données personnelles (RGPD) | Consentement, minimisation, droit à l'effacement | Consentement au suivi publicitaire, données hébergées dans l'UE, suppression du compte en un geste |
| Abonnement | Règles Apple des abonnements reconduits automatiquement | Prix et durée clairs, résiliation depuis les réglages iOS |
| Contenu sponsorisé | Mention obligatoire | Étiquette « partenaire » sur les écrins de marque |
| Valeurs des bijoux | Éviter toute confusion avec de l'argent réel | Estimations dans une monnaie fictive, ou en euros avec la mention « valeur fictive » |
| Propriété intellectuelle | Pas de marques ni de designs existants sans contrat | Bijoux, personnages et noms originaux |

Pour la fausse demande, un court message rappelle d'utiliser la farce avec bienveillance.

### 18. Roadmap

Un MVP centré sur l'huître et l'écrin sort avant la fin 2026 ; chaque étape suivante n'est lancée que si les chiffres de la précédente sont au rendez-vous.

roadmap · 4 phases, 3 seuils de passage

Les dates sont des cibles à ajuster selon la taille de l'équipe ; ce qui compte, ce sont l'ordre et les seuils de passage.

Dans le MVP : huître et écrin avec le geste Duo et le geste tactile, une zone de pêche, toutes les raretés, collection et cartes partageables, écrins Velours, stock d'huîtres et pubs récompensées, pack de bienvenue.

Hors MVP : atelier, Maison, social, saisons, abonnement. Ils arrivent quand la boucle d'ouverture a prouvé qu'elle fait revenir les joueurs.

### 19. Perspectives et risques

À terme, Perle peut devenir une plateforme de jeux d'ouverture pour pliables, au-delà d'un seul jeu.

#### Perspectives d'évolution

- Autres appareils : iPad, pliables Android, Apple Watch en compagnon (récolte du plongeur, notifications), Apple Vision pour visiter sa vitrine en réalité augmentée.

- Moteur d'ouverture réutilisable : coffres de pirates, œufs de dragon, capsules temporelles. Chaque nouvel objet peut devenir un jeu ou une saison.

- Marques et licences : collections avec de vraies maisons de bijoux, voire une Maison de joaillerie réelle née du jeu.

- Physique : cartes imprimées des plus belles pièces, coffrets d'huîtres à perle, bijoux réels fabriqués d'après les créations des joueurs.

- iPhone Duo de deuxième génération prévu en 2027 : nouvelles mécaniques si Apple ajoute des capteurs.

#### Risques principaux

| Risque | Parade |
|---|---|
| Le parc d'iPhone Duo reste petit | Parité totale sur iPhone classique ; le Duo sert de vitrine marketing |
| Mises à jour de l'angle de charnière trop lentes ou imprécises | Calibrage sur appareil réel, seuils de vitesse tolérants |
| Effet gadget qui s'essouffle | Méta-progression profonde (atelier, Maison, saisons) dès la V1 |
| Durcissement des règles sur les tirages aléatoires | Alternatives sans hasard payant déjà prévues (poussière d'or, achats directs) |
| Coût de production artistique et 3D | Style graphique stylisé et réutilisable, outils de génération de variantes |
| Dépendance à quelques temps forts | Saisons régulières de 6 semaines entre les grands événements |

Franchement grave cool :) Hésite pas à lancer des test en web app dès cette semaine et demander à hugo de push à fond sur X et tout :) Et envois moi ta web app dès que c’est good je ferrais un tweet avec mon compte certifié. Ajoute un truc pour tracker le comportement des gens demande à un claude de le faire.

Pour ton icone d’app utilise avec chat gpt , explique lui et faut absolument une mascotte un pêcheur ou ce que tu veux mais une mascotte pour l’icone.

Mais go faire une V1 ou juste tu ouvres , tu stockes et tu regardes comment les gens se comportent comme wikimaster. Et dis que c’est une béta mais que les gens qui utilise ta beta auront des bonu à l’ouverture de la vrai app donc mais un portail de connexion 🙂

