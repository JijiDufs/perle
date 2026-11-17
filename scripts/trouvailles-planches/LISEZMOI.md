# Trouvailles en photo (nouvelle DA) : planches Kling

Les 25 trouvailles viennent de 3 planches générées par Kling sur fond noir, comme les bijoux et les perles.

- `planche-1.webp`, `planche-2.webp`, `planche-3.webp` : les planches de Kling (1507 × 2000, telles que Jules les a envoyées).
- `cases-1.json`, `cases-2.json`, `cases-3.json` : la case de chaque objet, en pixels de la planche, dans l'ordre de lecture.
- `decoupe.sh` : retouches, découpe et écriture de `ios/PearlInc/Art/FindPhotos/find-<id>.png` (512 px, fond transparent).
- `apercu.png` : les 25 photos dessinées par `FindArt`, à la taille de la carte.
- `ref-1.png`, `ref-2.png`, `ref-3.png` : les dessins d'avant, donnés à Kling comme modèle.

## 1. Générer (pour refaire une planche)

Kling 3.0 Omni, image → image, 4K, avec la planche `ref-N.png` jointe ; 4 crédits la planche. Le début et la fin de la consigne sont communs.

**Début (commun)**

> 图片1 is a reference sheet: 9 illustrated objects in a 3x3 grid on a pure black background. Recreate this exact sheet as an ultra-realistic studio product photograph (high-end catalogue packshot, macro lens, softbox lighting): the same 9 objects, each in the same cell, same position, same size, same orientation, same colours and same inscriptions, but every object must look like a real physical object photographed for real, with true materials and fine surface detail. No illustration, no outlines, no cartoon shading.

**Planche 1 — le bric-à-brac du port**

> Row 1: a single blue rubber flip-flop with a pink strap; an orange paper fairground ticket printed "MANÈGE", "1 TOUR", "N° 0042"; a heart-shaped brass love padlock with a steel shackle, engraved "J + M".
> Row 2: a classic yellow rubber bath duck with an orange beak; pink heart-shaped plastic sunglasses with only one lens left (the other frame is empty); an old silver flip phone, open, its screen lit and showing "12:07".
> Row 3: a set of dentures (pink gums, white teeth); a black USB stick with a white label handwritten in red "NE PAS OUVRIR"; a ceramic garden gnome with a red pointed hat, a white beard and a blue tunic.

**Planche 2 — clins d'œil** (aucun nom d'œuvre ni de marque dans la consigne, comme dans le jeu)

> Row 1: a small orange tropical fish with white bands edged in black, side view; a stainless-steel dinner fork; a colourful 3x3 puzzle cube with scrambled stickers (white, yellow, red, orange, blue, green).
> Row 2: a gold arcade token embossed "CONTINUE", "?" and a small "9"; a toy toadstool mushroom, red cap with white spots, cream stem with two small black eyes; a white leather volleyball with a smiling face painted in red inside a red hand print.
> Row 3: a straw hat with a red ribbon; a grey rubber shark-fin costume accessory on a dark strap, with a small paper price tag "2,99 €"; a grey retro video-game cartridge whose label shows a pixel-art purple sunset over a city skyline with a yellow pixel sun, titled "AVENTURE 8 BITS", gold contacts at the bottom.

**Planche 3 — fin des clins d'œil, trésors engloutis** (cases 8 et 9 : une deuxième chance pour le dentier et le nain)

> Row 1: an antique brass pocket compass, cream dial marked N, E, S, O, red and dark needle; a plain polished gold ring lying flat, a fine glowing script engraved around the band; a large heart-shaped deep-blue diamond pendant surrounded by small white diamonds, on a fine silver chain.
> Row 2: an ancient gold coin with a few verdigris spots, struck with the left-facing profile of a crowned king and the legend "REX MARIS ANNO"; a dark green glass bottle lying at an angle, corked, a rolled paper message tied with a red ribbon visible inside; a rough grey stone with an opening that reveals a raw purple gem inside.
> Row 3: an old corroded bronze key with a ring-shaped bow, patches of verdigris and a tiny barnacle; a set of dentures (pink gums, white teeth); a ceramic garden gnome with a red pointed hat, a white beard and a blue tunic.

**Fin (commune)**

> Background: perfectly uniform pure black (#000000) everywhere, no floor, no table, no cast shadows, no reflections under the objects, no glow, no frames, no borders, no captions, no added text. Every object fully visible, well separated from the others, brightly and evenly lit so that its edges stay clearly visible against the black: no part of an object fades into the background.

## 2. Découper

```sh
sh scripts/trouvailles-planches/decoupe.sh
```

Kling n'a gardé ni le format carré ni la grille : les cases sont repérées à la main. Pour refaire un objet, remplacer la
planche (ou en ajouter une), corriger sa case dans `cases-N.json`, relancer le script.

Options de `scripts/decoupe-planche.py` utilisées : `@p` objet plein (ses parties sombres restent opaques), `@t` plein sauf
ses vrais trous (anneau, anse, clé), `@e` taille équilibrée (un objet compact est réduit pour ne pas paraître plus gros
qu'un objet allongé).

Retouches faites par le script : accent du ticket (« MANÉGE » → « MANÈGE »), bouton noir effacé sous le champignon, sangle
de l'aileron éclaircie, bout du manche de la fourchette arrondi, verre teinté posé dans les lunettes (Kling les a faites
sans verre, la carte dit « un seul verre »), rubans de la bouteille raccourcis. Une seule tong gardée sur les deux ; dentier
de la planche 3 et nain de la planche 1 ; la tête de requin en trop de la planche 2 est ignorée.

## 3. Dans l'app

`FindArt.draw` prend `find-<id>.png` s'il est dans le bundle, sinon le dessin par code (`-FindDrawn` force le dessin).
Le dossier `FindPhotos` entre tout seul dans le projet Xcode ; l'outil des visuels App Store le copie aussi (`render.sh`).
