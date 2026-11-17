#!/bin/sh
# Captures de l'emplacement « iPhone Duo » de la fiche App Store (docs/app-store/visuels/{fr,en}/duo, 2853 × 2007, JPEG).
# 1. Captures du Duo simulé (iOS 27.3, démarré par le panneau de simulateur de Claude), partie vitrine :
#      python3 scripts/app-store-visuels/seed.py golden lagon 10 1240 3 rubis:aurore
#      xcrun simctl launch <Duo> app.pearlinc.PearlInc -NoSound -NoLogin [-StartTab ecrins|collection]
#    puis on plie le téléphone dans le panneau pendant une rafale de `xcrun simctl io <Duo> screenshot --display=3`
#    (écran intérieur ; --display=1 pour l'extérieur). En anglais : `-AppleLanguages "(en)"` au lancement, fichiers en -en.
#    Dans build/captures-app-store/ : duo-int-lumiere (perle dorée révélée), duo-int-carte-doree-s (sa carte),
#    duo-ext-ecrin-ferme (écran extérieur, écrin fermé), duo-int-ecrin-aurore (écrin ouvert qui scintille),
#    duo-int-ecrin-carte (carte du bijou), duo-int-collection.
# 2. Composition : duo.html (textes FR / EN dedans), photographiée par Google Chrome sans fenêtre.
# Usage : sh scripts/app-store-visuels/render-duo.sh
set -e
D=$(cd "$(dirname "$0")" && pwd); ROOT=$(cd "$D/../.." && pwd); CAPS="$ROOT/build/captures-app-store"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/a" && cp "$CAPS"/duo-*.png "$TMP/a/" && cp "$D/duo.html" "$TMP/"
for p in rose-ronde-rose black-ronde-vert-paon giant-ronde-arc-en-ciel white-ronde-creme golden-ronde-dore; do
  cp "$ROOT/ios/PearlInc/Art/PearlPhotos/pearl-$p.png" "$TMP/a/"
done
for j in rubis-bague-cocktail diamant-collier-riviere emeraude-bague-solitaire-poire; do
  cp "$ROOT/ios/PearlInc/Art/JewelPhotos/jewel-$j.png" "$TMP/a/"
done
names="01-huitre 02-suivante 03-ecrin 04-bijou 05-collection"
for L in fr en; do
  SFX=""; [ "$L" = en ] && SFX=-en
  # Sans captures anglaises, les visuels anglais reprennent les françaises (signalé).
  [ -n "$SFX" ] && [ ! -f "$CAPS/duo-int-lumiere-en.png" ] && { echo "pas de captures -en : visuels anglais sur les captures françaises"; SFX=""; }
  OUT="$ROOT/docs/app-store/visuels/$L/duo"; mkdir -p "$OUT"; rm -f "$OUT"/*.jpg; n=1
  for name in $names; do
    for try in 1 2 3; do
      "$CHROME" --headless=new --user-data-dir="$TMP/profil" --hide-scrollbars --force-device-scale-factor=1 \
        --window-size=2853,2007 --virtual-time-budget=9000 --allow-file-access-from-files \
        --screenshot="$TMP/s.png" "file://$TMP/duo.html?n=$n&lang=$L&sfx=$SFX" >/dev/null 2>&1 && break
      [ $try = 3 ] && exit 1; sleep 3
    done
    sips -s format jpeg -s formatOptions 92 "$TMP/s.png" --out "$OUT/$name.jpg" >/dev/null
    n=$((n+1))
  done
done
echo "docs/app-store/visuels/{fr,en}/duo"
