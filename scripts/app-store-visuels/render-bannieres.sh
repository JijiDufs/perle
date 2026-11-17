#!/bin/sh
# Bannières paysage (PNG sans transparence) de la page produit App Store (docs/app-store/visuels/{fr,en}/bannieres) :
#   en-tête 3840 × 1646 (sans texte : la même dans les deux langues), résultats de recherche 3840 × 2560.
# 1. L'huître 3D de l'app, ouverte sur une perle dorée, détourée par deux captures de l'iPhone 17 simulé, l'une sur fond
#    noir et l'autre sur fond blanc (à faire avant, un seul simulateur allumé) :
#      python3 scripts/app-store-visuels/seed.py golden lagon
#      xcrun simctl spawn <iPhone 17> defaults write app.pearlinc.PearlInc OysterTestAngle -float 100
#      xcrun simctl spawn <iPhone 17> defaults write app.pearlinc.PearlInc LagoonStyle noir   (puis blanc)
#      xcrun simctl launch <iPhone 17> app.pearlinc.PearlInc -NoSound -StoreShot
#      xcrun simctl io <iPhone 17> screenshot build/captures-app-store/doree-noir-100.png   (puis doree-blanc-100.png)
#    et effacer ensuite OysterTestAngle et LagoonStyle (`defaults delete`).
# 2. Le lagon de l'app dessiné en paysage (vitrine, cible art), son foyer de lumière sur l'huître ; la vignette passe devant.
# 3. Lumière dorée, perles qui flottent et texte : banniere.html, photographiée par Google Chrome sans fenêtre.
# Usage : sh scripts/app-store-visuels/render-bannieres.sh
set -e
D=$(cd "$(dirname "$0")" && pwd); ROOT=$(cd "$D/../.." && pwd); CAPS="$ROOT/build/captures-app-store"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/a"
for f in doree-noir-100 doree-blanc-100; do [ -f "$CAPS/$f.png" ] || { echo "il manque $CAPS/$f.png (étape 1)"; exit 1; }; done

# 2. Le lagon, en points de scène : largeur × hauteur, foyer, échelle (= 3840 / largeur). L'huître tombe dans la zone sûre.
BIN=$(swift build -c release --package-path "$D/vitrine" --show-bin-path)
swift build -c release --package-path "$D/vitrine" --product art >/dev/null 2>&1
CAT="$ROOT/ios/PearlCore/Sources/PearlCore/Resources/catalog.json"
"$BIN/art" "$CAT" "$TMP" banniere entete 3151.1 1350.7 1567.9 626.3 1.2186 >/dev/null
"$BIN/art" "$CAT" "$TMP" banniere recherche 2022.2 1348.1 1361.5 624.9 1.899 >/dev/null
FOCUS=$("$BIN/art" "$CAT" "$TMP" foyer)

# 1 et 2. Détourage (alpha = 1 − écart blanc/noir) et assemblage lagon + huître + vignette.
python3 -P -E - "$CAPS" "$TMP" $FOCUS <<'EOF'
import sys
from PIL import Image, ImageChops, ImageMath
caps, tmp, fx, fy = sys.argv[1], sys.argv[2], float(sys.argv[3]), float(sys.argv[4])
B = Image.open(caps + '/doree-noir-100.png').convert('RGB')
W = Image.open(caps + '/doree-blanc-100.png').convert('RGB')
diff = [ImageChops.subtract(w, b) for w, b in zip(W.split(), B.split())]
alpha = ImageMath.lambda_eval(lambda e: e['convert'](255 - (e['r'] + e['g'] + e['b']) / 3, 'L'), r=diff[0], g=diff[1], b=diff[2])
alpha.paste(0, (0, 0, alpha.width, 200))  # barre d'état
chans = [ImageMath.lambda_eval(lambda e: e['convert'](e['min'](e['c'] * 255 / e['max'](e['a'], 1), 255), 'L'), c=c, a=alpha) for c in B.split()]
oyster = Image.merge('RGBA', (*chans, alpha))
# contrôle : l'huître détourée posée sur du blanc redonne la capture blanche
back = Image.new('RGBA', oyster.size, (255, 255, 255, 255)); back.alpha_composite(oyster)
gap = ImageChops.difference(back.convert('RGB').crop((0, 200, W.width, W.height)), W.crop((0, 200, W.width, W.height))).convert('L').getextrema()[1]
assert gap <= 8, f'détourage raté (écart {gap})'
for name, size, k, focus in [('entete', (3840, 1646), 1.2186, (1567.9, 626.3)), ('recherche', (3840, 2560), 1.899, (1361.5, 624.9))]:
    base = Image.open(f'{tmp}/{name}-lagon.png').convert('RGBA').resize(size, Image.LANCZOS)
    o = oyster.resize((round(oyster.width * k / 3), round(oyster.height * k / 3)), Image.LANCZOS)
    base.alpha_composite(o, (round((focus[0] - fx) * k), round((focus[1] - fy) * k)))
    base.alpha_composite(Image.open(f'{tmp}/{name}-vignette.png').convert('RGBA').resize(size, Image.LANCZOS))
    base.convert('RGB').save(f'{tmp}/a/{name}-fond.png')
EOF

# 3. Composition, à la taille exacte demandée par App Store Connect
for p in rose-ronde-rose black-ronde-vert-paon giant-ronde-arc-en-ciel white-ronde-creme golden-ronde-dore; do
  cp "$ROOT/ios/PearlInc/Art/PearlPhotos/pearl-$p.png" "$TMP/a/"
done
cp "$D/banniere.html" "$TMP/"
for L in fr en; do
  OUT="$ROOT/docs/app-store/visuels/$L/bannieres"; mkdir -p "$OUT"; rm -f "$OUT"/*.png
  for spec in "entete 3840 1646" "recherche 3840 2560"; do
    set -- $spec
    "$CHROME" --headless=new --user-data-dir="$TMP/profil" --hide-scrollbars --force-device-scale-factor=1 \
      --window-size=$2,$3 --virtual-time-budget=9000 --allow-file-access-from-files \
      --screenshot="$TMP/b.png" "file://$TMP/banniere.html?kind=$1&lang=$L" >/dev/null 2>&1
    python3 -P -E -c "import sys;from PIL import Image;Image.open(sys.argv[1]).convert('RGB').save(sys.argv[2])" "$TMP/b.png" "$OUT/$1-$2x$3.png"
  done
done
echo "docs/app-store/visuels/{fr,en}/bannieres"
