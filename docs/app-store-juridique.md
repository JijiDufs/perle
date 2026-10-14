# Juridique et App Store : ce qu'il faut pour soumettre Pearl Inc.

> Rédigé le 2026-10-13. Éditeur : **la micro-entreprise de Mathys** (entrepreneur individuel) tant que le studio MJHstudio n'est pas créé, contact `laplateformemjh@gmail.com`.
> Ce sont des **brouillons sérieux, pas un avis juridique** : faire relire par un avocat (ou un juriste en droit du numérique) avant la sortie, en particulier les points du §6.

## 1. Les pages publiques (site/)

| Page | FR | EN | À saisir dans App Store Connect |
|---|---|---|---|
| Politique de confidentialité | `/confidentialite/` | `/en/privacy/` | **Privacy Policy URL** (obligatoire) |
| Aide et contact | `/support/` | `/en/support/` | **Support URL** (obligatoire) |
| Conditions d'utilisation | `/conditions/` | `/en/terms/` | Lien dans la description ; la licence reste l'EULA standard d'Apple |
| Mentions légales | `/mentions-legales/` | `/en/legal-notice/` | — (obligation française, loi LCEN) |
| Site | `/` | `/?lang=en` | **Marketing URL** (facultatif) |

Les pages sont au même style que l'accueil (`site/legal.css`). **Aujourd'hui, seules les mentions légales et une confidentialité courte (prototype + inscription) sont sur le site** ; les versions de l'app (confidentialité complète, conditions, aide) attendent dans `docs/pages-app/` et reviennent dans `site/` à la soumission. **Ne rien mettre en ligne tant que les champs jaunes « À compléter » ne sont pas remplis** :

- prénom et nom de l'entrepreneur, adresse postale, numéro de téléphone (mentions légales), SIREN et registre (RNE ou RCS) ;
- TVA : numéro intracommunautaire, ou « TVA non applicable, art. 293 B du CGI » en franchise ;
- directeur de la publication (la même personne) ;
- **médiateur de la consommation** (voir §6).

L'app affiche les liens « conditions d'utilisation » et « politique de confidentialité » sur l'écran de connexion (Apple veut la politique accessible depuis l'app). Ils pointent vers la version française ; à doubler quand l'app sera traduite.

## 2. Ce que l'app collecte aujourd'hui (et l'étiquette « App Privacy »)

Dans App Store Connect → App Privacy, répondre **« Oui, nous collectons des données »** :

| Catégorie Apple | Type | Liée à l'utilisateur | Pistage | Finalité |
|---|---|---|---|---|
| Contact Info | Email Address | Oui | Non | App Functionality |
| Identifiers | User ID | Oui | Non | App Functionality |
| Location | Coarse Location | Non | Non | Third-Party Advertising, Analytics |
| Identifiers | Device ID | Non | Non | Third-Party Advertising, Analytics |
| Usage Data | Product Interaction | Non | Non | Third-Party Advertising, Analytics |
| Usage Data | Advertising Data | Non | Non | Third-Party Advertising, Analytics |
| Diagnostics | Crash Data, Performance Data, Other Diagnostic Data | Non | Non | Analytics |

Les cinq dernières lignes viennent du kit **Google AdMob** (pubs récompensées, branché le 2026-10-14), d'après la page de Google « Data disclosure » pour iOS ; la relire au moment de remplir. **Pistage : Non** : l'app ne demande que des pubs **non personnalisées** (`publisherPrivacyPersonalizationState = .disabled`) et ne demande pas l'ATT (pas d'IDFA). Si un jour on active la pub personnalisée, il faudra déclarer le pistage et ajouter la fenêtre ATT.

**Non collecté** (à ne pas cocher) : achats (Apple les gère, l'app ne nous les envoie pas), partie (reste sur l'iPhone).

Le manifeste de confidentialité de l'app (`ios/PearlInc/PrivacyInfo.xcprivacy`) dit la même chose, plus l'usage de `UserDefaults` (raison `CA92.1`, la sauvegarde de la partie). Les paquets Supabase et Google Mobile Ads fournissent leur propre manifeste.

**À mettre à jour en même temps (politique, manifeste, étiquette)** :
- **sauvegarde en ligne** de la partie : ajouter « Gameplay Content » ou « Other User Content » (liée, App Functionality) ;
- ~~régie publicitaire~~ : fait (AdMob, 2026-10-14) : politique FR/EN, tableau ci-dessus, formulaire RGPD de Google ; pubs non personnalisées, pas de pistage ;
- **mesure d'audience** (PostHog…) : Product Interaction, Usage Data.

## 3. Les autres questions d'App Store Connect

- **Chiffrement à l'exportation** : l'app n'utilise que le chiffrement standard (HTTPS). Déclaré dans l'app (`ITSAppUsesNonExemptEncryption = NO`) : la question ne sera plus posée à chaque build.
- **Classification par âge** (questionnaire de 2025) : répondre honnêtement ; points concernés : **achats intégrés**, **objets obtenus au hasard achetables** (les huîtres), **publicité** (AdMob, pubs récompensées). Pas de jeu d'argent réel, pas de violence, pas de navigation web libre, pas de contenu créé par les joueurs. Le résultat (4+, 9+, 13+…) sort du questionnaire : à noter ici une fois rempli.
- **Statut de commerçant (DSA, Union européenne)** : avec des achats intégrés, on est **commerçant**. Apple **affiche publiquement** sur la fiche de l'app, dans l'UE : nom, **adresse**, **téléphone** et e-mail. Pour une entreprise individuelle, c'est l'adresse de l'entrepreneur : prévoir si besoin une **domiciliation** (adresse professionnelle) et un numéro dédié.
- **Compte Apple Developer** : au nom de l'entrepreneur (compte individuel, pas besoin de D-U-N-S) ; le nom affiché comme vendeur sur l'App Store sera son nom.
- **Accords** : Paid Apps Agreement, coordonnées bancaires, fiscalité (formulaires dans App Store Connect).
- **Notes pour la revue d'Apple** : expliquer que « Jouer sans compte » permet d'entrer sans identifiant ; que la publicité est récompensée et facultative ; où sont affichées les probabilités (Collection, Boutique).

## 4. Ce qu'Apple vérifie et qui manque encore dans l'app

| Règle | État | À faire |
|---|---|---|
| 5.1.1 (v) Suppression du compte **dans l'app** | ✅ Réglages → « Supprimer mon compte » (fonction Supabase `delete_account`, en cascade) | **Connexion avec Apple** : révoquer aussi le jeton Apple à la suppression (API REST d'Apple, demande la clé « Sign in with Apple » côté serveur : fonction Supabase Edge à écrire quand le fournisseur Apple sera configuré) |
| 5.1.1 (i) Politique accessible depuis l'app | ✅ écran de connexion et Réglages | — |
| 3.1.1 Probabilités affichées avant achat | ✅ Collection et Boutique | — |
| 3.1.1 Restaurer les achats | ✅ Boutique | — |
| 2.1 Pas de fonction factice | ❌ pub simulée | Brancher une régie ou retirer la pub de la 1.0 |
| 4.8 Connexion avec Apple proposée | ✅ | — |
| 5.1.2 Pas de pistage sans ATT | ✅ aucun pistage | Revoir avec la régie |
| Manifeste de confidentialité | ✅ | Tenir à jour (§2) |
| « Ta collection te suit sur tous tes iPhone » | ❌ promesse non tenue | Sauvegarde en ligne, ou changer la phrase |

## 5. Les promesses faites aux joueurs (à garder cohérentes)

- **Probabilités** « toujours affichées » (site et app), jamais modifiées par un achat ou un skin.
- **Garantie** : perle dorée ou mieux au plus tard à la 26ᵉ huître.
- **Skin des inscrits** (« Première marée ») promis sur la page et dans les formulaires Tally.
- **Données des inscrits** effacées 6 mois après la sortie (formulaires Tally) : programmer l'effacement.
- **Arrêt du jeu** : prévenir 30 jours avant, cesser de vendre huîtres et poussière dès l'annonce (conditions d'utilisation).

## 6. Points à faire valider (avocat ou juriste)

1. **Médiateur de la consommation (obligatoire en France)** : tout professionnel qui vend à des consommateurs doit adhérer à un médiateur et l'indiquer (Code de la consommation, art. L612-1 et L616-1). Choisir un médiateur agréé (liste sur economie.gouv.fr), adhérer (coût annuel modeste), puis compléter les conditions d'utilisation.
2. **Huîtres achetées = tirage au hasard payant** : en **Belgique**, la Commission des jeux de hasard assimile les « loot boxes » payantes à des jeux de hasard. Proposition : ne pas vendre de recharges d'huîtres dans la boutique belge (`Storefront.countryCode`), ou ne pas publier en Belgique au début. Vérifier aussi les Pays-Bas.
3. **Monnaie virtuelle (poussière d'or)** : principes européens de protection des consommateurs sur les monnaies de jeu (réseau CPC, 2025) : prix toujours affichés en euros, pas d'urgence artificielle, pas de ciblage des enfants, droit au remboursement préservé. Notre boutique affiche le prix en euros de chaque pack ; vérifier qu'un skin acheté en poussière peut aussi montrer son équivalent en euros.
4. **Droit de rétractation** : les conditions reprennent l'exception de l'art. L221-28 13° (contenu numérique fourni immédiatement). Apple étant le vendeur, vérifier que son parcours d'achat recueille bien l'accord exprès.
5. **Mineurs** : le jeu n'est pas destiné aux enfants en particulier, mais peut leur plaire. Inscription à la liste : accord d'un parent sous 15 ans (loi Informatique et Libertés, art. 45). Pour une future régie : publicité non personnalisée pour les mineurs.
6. **Transferts hors UE** (Vercel, Google Fonts, Cloudflare) : encadrés par le Data Privacy Framework ou les clauses types. Amélioration simple : **héberger la police Inter sur le site** au lieu de Google Fonts (la page n'enverrait plus l'adresse IP des visiteurs à Google).
7. **Marques** : « iPhone » et « iPhone Duo » n'apparaissent ni dans le nom ni dans l'icône de l'app ; la mention de non-affiliation est sur le site et dans les conditions.
