# Fiche App Store de Pearl Inc. (1.0, français)

> Rédigée le 2026-10-19, d'après ce que contient **vraiment** l'app 1.0 (vérifié dans le code). À coller dans App Store Connect.
> Le nombre entre parenthèses est le nombre de caractères ; la limite d'Apple est indiquée à côté.
> L'app n'est qu'en français : pas de fiche anglaise tant qu'elle n'est pas traduite (la fiche promettrait une langue que le jeu n'a pas).

## 1. Informations de l'app (une fois pour toutes)

| Champ | Texte | Longueur |
|---|---|---|
| **Nom** | `Pearl Inc.` | 10 / 30 |
| Nom de secours (si « Pearl Inc. » est pris) | `Pearl Inc. – Perles rares` | 25 / 30 |
| **Sous-titre** | `Huîtres, perles et trouvailles` | 30 / 30 |
| Sous-titre (autre choix) | `Trouve la perle rare` | 20 / 30 |
| Catégorie principale | Jeux → **Occasionnels** | |
| Catégorie secondaire | Jeux → Réflexion (facultatif) | |
| Copyright | `2026 Mathys Hosin` | |
| URL de confidentialité | `https://pearl-inc.app/confidentialite/` (version complète à mettre en ligne avant, voir le journal) | |

## 2. Version 1.0

**Texte promotionnel** (131 / 170, modifiable à tout moment sans nouvelle version)

```
La perle maudite ne sort que 3 fois sur 1 000. Glisse le pouce, sens la coquille résister… et découvre ce qui brille à l’intérieur.
```

**Mots-clés** (93 / 100 ; virgules sans espace ; pas de mot déjà dans le nom ou le sous-titre, ni « iPhone »)

```
nacre,collection,coquillage,coquille,trésor,lagon,mer,océan,bijou,rare,relaxant,collectionner
```

**URL d'assistance** : `https://pearl-inc.app/support/` · **URL marketing** : `https://pearl-inc.app`

**Description** (2 027 / 4 000)

```
Glisse le pouce vers le haut. La coquille résiste… puis cède d’un coup. Une lueur filtre entre les valves : rose, noire, dorée ? Dans Pearl Inc., ouvrir une huître, c’est tout le jeu.

UN GESTE, PAS UN BOUTON
Chaque huître s’ouvre à la main. Au début, elle résiste. Ensuite, attention à la zone fragile : ouvre trop vite et la perle se fêle, sa valeur est divisée par deux. Un geste régulier te vaut un lustre S, A, B ou C.

DES PERLES PLUS OU MOINS RARES
Blanche, rosée, baroque, noire, dorée, géante… et la perle maudite, qui ne sort que 3 fois sur 1 000. Parfois, l’huître est vide. Toutes les probabilités sont affichées dans le jeu, et une perle dorée ou mieux est garantie au plus tard à la 26e huître.

CHAQUE PERLE EST UNIQUE
Taille, forme, reflet, lustre, numéro de série : deux perles ne se ressemblent jamais. Certaines portent même une marque rare.

DES TROUVAILLES
Une huître sur vingt cache autre chose qu’une perle : 25 objets insolites à dénicher, du bric-à-brac du port aux trésors engloutis.

TA COLLECTION
Range tes perles, découvre celles qui te manquent et revends tes doublons au comptoir contre de la poussière d’or. On garde toujours au moins un exemplaire de chaque sorte.

DES COQUILLES À TON GOÛT
Change l’apparence de tes huîtres : le bénitier géant, ou l’huître d’or pour briller. Purement cosmétique : un skin ne change jamais tes chances.

CHAQUE JOUR
Trois missions du jour, et des huîtres qui reviennent avec la marée : 10 au maximum, une nouvelle toutes les 20 minutes. Tu peux aussi regarder une courte publicité pour gagner 3 huîtres, jusqu’à 3 fois par jour : c’est toujours toi qui choisis.

PARTAGE TES PLUS BELLES PRISES
Une perle maudite, ça se montre : partage ta prise en un geste.

Joue sans compte, ou connecte-toi avec Apple ou ton e-mail. Le jeu est gratuit ; certains contenus (huîtres, poussière d’or, coquilles) sont proposés en achats intégrés facultatifs.

Conditions d’utilisation : https://pearl-inc.app/conditions/
Confidentialité : https://pearl-inc.app/confidentialite/
```

## 3. Achats intégrés

Nom affiché : 35 caractères au plus ; description : 55 au plus.

| Identifiant | Nom affiché | Description |
|---|---|---|
| `app.pearlinc.oysters.10` | Marée haute | 10 huîtres à ouvrir tout de suite. |
| `app.pearlinc.oysters.30` | Grande marée | 30 huîtres, au-delà du maximum de ton stock. |
| `app.pearlinc.dust.400` | Bourse de poussière d’or | 400 de poussière d’or pour la boutique. |
| `app.pearlinc.dust.1200` | Coffret de poussière d’or | 1 200 de poussière d’or pour la boutique. |
| `app.pearlinc.dust.3000` | Malle de poussière d’or | 3 000 de poussière d’or pour la boutique. |
| `app.pearlinc.skin.benitier` | Bénitier | Coquille géante. Purement cosmétique. |
| `app.pearlinc.skin.or` | Huître d’or | Coquille d’or. Cosmétique : ne change pas tes chances. |

Pour chaque achat, Apple demande aussi une capture pour la revue : la Boutique, prise depuis TestFlight (les prix n'apparaissent pas hors de Xcode).

## 4. Notes pour la revue d'Apple (en anglais)

```
Pearl Inc. is a casual game: swipe up to open an oyster and reveal a pearl. The app is in French.

Sign-in: no credentials needed. On the first screen, tap "Jouer sans compte" (Play without an account). Sign in with Apple and email codes are also available.

Odds: the probability of every pearl is shown before any purchase, in the Shop ("Chaque huître est un tirage : voir les probabilités") and in Settings > "Probabilités des perles". A gold pearl or better is guaranteed within 26 oysters.

Ads: rewarded ads only (Google AdMob, non-personalised), always optional: "Regarder une pub" gives 3 oysters, up to 3 times a day. Google's consent form appears where required (EU).

In-app purchases: oysters and gold dust (consumables), two cosmetic shells (non-consumables, restorable in the Shop and in Settings). Shells never change the odds.

Account deletion: Settings (gear icon on the fishing screen) > "Supprimer mon compte".
```

## 5. Ce que la fiche ne doit pas dire (pas dans la 1.0)

- **iPhone Duo / charnière** : pas encore dans l'app, et « iPhone » est interdit dans le nom et les mots-clés.
- Classement Game Center, sauvegarde iCloud (« ta collection te suit »), notifications, calendrier de connexion, tutoriel guidé, vibrations « riches » (Core Haptics).
- Écrins, bijoux, atelier, Maison, niveaux : c'est la webapp, pas l'app.
- Le skin **Première marée** (inscrits) : pas encore distribuable (voir `docs/duo-gadget.md` §6).

À chaque fonction ajoutée, compléter la description et le texte promotionnel ici avant de les mettre dans App Store Connect.

## 6. Captures

`docs/app-store/captures/` : 5 captures 6,9 pouces (1320 × 2868), dans l'ordre : pêche, ouverture, révélation, collection, missions.
