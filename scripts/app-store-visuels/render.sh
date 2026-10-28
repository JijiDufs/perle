#!/bin/sh
# Visuels de la fiche App Store (docs/app-store/visuels/{fr,en}, 1320 × 2868, iPhone 6,9 pouces).
# 1. Captures de l'app au simulateur (iPhone 17 Pro, barre d'état à 9:41) avec seed.py, copiées dans
#    $ASSETS sous les noms raw_*.png (raw_*_en.png pour l'anglais) attendus par index.html :
#    golden_open, cursed_card, ecrin_glint (écrin entrouvert sur l'éclat parfait), jewel_card, collection,
#    find_card, benitier_glow, or_glow, progress (« Ma progression »).
# 2. Art haute définition (perles, trouvailles, bijoux, scène du héros) : dessiné par vitrine/ (cible `art`)
#    avec le code de l'app.
# 3. Composition : index.html (textes FR / EN dedans), photographiée par Google Chrome sans fenêtre.
# Usage : sh scripts/app-store-visuels/render.sh <dossier des captures brutes>
set -e
D=$(cd "$(dirname "$0")" && pwd); ROOT=$(cd "$D/../.." && pwd)
ASSETS=${1:?dossier des captures brutes}
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/a" && cp "$ASSETS"/raw_*.png "$TMP/a/" && cp "$D/index.html" "$TMP/"
swift run -c release --package-path "$D/vitrine" art "$ROOT/ios/PearlCore/Sources/PearlCore/Resources/catalog.json" "$TMP/a" >/dev/null
names="01-ouvre 02-geste 03-perle-maudite 04-ecrins 05-bijoux 06-raretes 07-collection 08-trouvailles 09-coquilles 10-progression"
for L in fr en; do
  SFX=""; [ "$L" = en ] && SFX=_en
  mkdir -p "$ROOT/docs/app-store/visuels/$L"; rm -f "$ROOT/docs/app-store/visuels/$L"/*.jpg; p=1
  for n in $names; do
    "$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 --allow-file-access-from-files \
      --window-size=1320,2868 --virtual-time-budget=6000 --screenshot="$TMP/$n.png" \
      "file://$TMP/index.html?p=$p&lang=$L&sfx=$SFX" 2>/dev/null >/dev/null
    sips -s format jpeg -s formatOptions 92 "$TMP/$n.png" --out "$ROOT/docs/app-store/visuels/$L/$n.jpg" >/dev/null
    p=$((p+1))
  done
done
echo "docs/app-store/visuels/{fr,en}"
