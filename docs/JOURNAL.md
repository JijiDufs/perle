# Journal des passes

Entrée la plus récente en haut. Format : date · qui · avec quel outil.

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
