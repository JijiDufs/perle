#!/bin/sh
# Découpe les 3 planches Kling des trouvailles (planche-N.webp, 1507 × 2000) en ios/PearlInc/Art/FindPhotos/find-<id>.png.
# Kling n'a pas gardé la grille : les cases (cases-N.json, pixels de la planche, dans l'ordre de lecture) sont repérées à la main.
# Usage : sh scripts/trouvailles-planches/decoupe.sh
set -e
D=$(cd "$(dirname "$0")" && pwd); ROOT=$(cd "$D/../.." && pwd)
OUT="$ROOT/ios/PearlInc/Art/FindPhotos"; TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
mkdir -p "$OUT"

# Retouches des planches avant la découpe.
python3 -P -E - "$D" "$TMP" <<'PY'
import sys
from PIL import Image, ImageDraw, ImageEnhance
src, tmp = sys.argv[1], sys.argv[2]
p1, p2, p3 = (Image.open(f'{src}/planche-{n}.webp').convert('RGB') for n in (1, 2, 3))
box = (789, 277, 807, 288)      # ticket : Kling a écrit « MANÉGE » ; l'accent retourné devient grave
p1.paste(p1.crop(box).transpose(Image.FLIP_LEFT_RIGHT), box)
p2.paste((0, 0, 0), (742, 1013, 808, 1050))      # champignon : un bouton noir sous le pied, effacé
band = Image.new('L', p2.size, 0)   # aileron : la sangle bleu nuit se perdait dans le fond noir, éclaircie (elle seule, pas son ombre)
ImageDraw.Draw(band).polygon([(478, 1652), (660, 1626), (660, 1688), (478, 1716)], fill=255)
p2.paste(ImageEnhance.Brightness(p2).enhance(2.4), mask=band)
for n, p in ((1, p1), (2, p2), (3, p3)): p.save(f'{tmp}/planche-{n}.png')
PY

# @p plein, @t plein sauf les vrais trous, @e taille équilibrée, @f liseré sombre rogné (voir decoupe-planche.py) ; « - » saute une case.
# Sautés : le dentier de la planche 1 et le nain de la planche 3 (on garde l'autre version) ; la tête de requin en trop
# de la planche 2 n'a pas de case. Les lunettes sont roses et claires : la luminosité seule suffit.
cut() { python3 -P -E "$ROOT/scripts/decoupe-planche.py" "$TMP/planche-$1.png" "$D/cases-$1.json" - "$OUT" "$2" 2>/dev/null; }
cut 1 find-tong@tef,find-ticket@pef,find-cadenas@tef,find-canard@pef,find-lunettes@ef,find-clapet@pef,-,find-usb@pef,find-nain@pef
cut 2 find-poisson-clown@pef,find-fourchette@pef,find-cube@pef,find-jeton@pef,find-champignon@pef,find-ballon@pef,find-chapeau@pef,find-aileron@pef,find-cartouche@pef
cut 3 find-boussole@tef,find-anneau@tef,find-coeur-ocean@tef,find-piece-or@pef,find-bouteille@tef,find-pierre-brute@pef,find-cle-epave@tef,find-dentier@pef,-

# Retouches des découpes.
python3 -P -E - "$OUT" <<'PY'
import sys
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageOps
out = sys.argv[1]

# Fourchette : Kling a coupé le manche net ; on arrondit son bout.
im = Image.open(f'{out}/find-fourchette.png')
a = im.getchannel('A')
bottom = a.point(lambda v: 255 if v > 128 else 0).getbbox()[3]
xa, _, xb, _ = a.crop((0, bottom - 3, im.width, bottom - 2)).point(lambda v: 255 if v > 128 else 0).getbbox()
r, cx = (xb - xa) / 2, (xa + xb) / 2
keep = Image.new('L', im.size, 255)
d = ImageDraw.Draw(keep)
d.rectangle((0, bottom - r, im.width, im.height), fill=0)
d.ellipse((cx - r, bottom - 2 * r, cx + r, bottom), fill=255)
im.putalpha(ImageChops.darker(a, keep.filter(ImageFilter.GaussianBlur(0.7))))
im.save(f'{out}/find-fourchette.png', optimize=True)

# Lunettes : Kling les a faites sans verre ; la carte dit « un seul verre ». On pose un verre teinté dans le cœur de gauche.
im = Image.open(f'{out}/find-lunettes.png')
w, h = im.size
frame = im.getchannel('A').point(lambda v: 255 if v > 60 else 0)
outside = ImageOps.expand(frame, 1, 0)
ImageDraw.floodfill(outside, (0, 0), 128)
lens = outside.crop((1, 1, w + 1, h + 1)).point(lambda v: 255 if v == 0 else 0)   # ni la monture ni le dehors
lens.paste(0, (w // 2, 0, w, h))
lens = lens.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.GaussianBlur(0.8))
shade = Image.linear_gradient('L').resize((w, h))
glass = Image.merge('RGB', (shade.point(lambda v: 176 - v * 60 // 255), shade.point(lambda v: 48 - v * 20 // 255),
                            shade.point(lambda v: 104 - v * 34 // 255))).convert('RGBA')
streak = Image.new('L', (w, h), 0)
box = lens.getbbox()
ImageDraw.Draw(streak).line([(box[0] + (box[2] - box[0]) * 0.2, box[1] + (box[3] - box[1]) * 0.62),
                             (box[0] + (box[2] - box[0]) * 0.62, box[1] + (box[3] - box[1]) * 0.16)], fill=150, width=max(3, w // 36))
glass.paste((255, 255, 255, 255), mask=streak.filter(ImageFilter.GaussianBlur(w / 110)))
glass.putalpha(lens.point(lambda v: v * 215 // 255))
Image.alpha_composite(glass, im).save(f'{out}/find-lunettes.png', optimize=True)
PY
ls "$OUT" | wc -l
