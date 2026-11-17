#!/bin/sh
# Visuels de la fiche App Store (docs/app-store/visuels/{fr,en}, 1320 × 2868, iPhone 6,9 pouces).
# 1. Captures de l'app au simulateur (iPhone 18 Pro, barre d'état à 9:41) avec seed.py, copiées dans
#    $ASSETS sous les noms raw_*.png (raw_*_en.png pour l'anglais) attendus par index.html :
#    golden_open, cursed_card, ecrin_glint (écrin entrouvert sur l'éclat parfait), jewel_card, collection,
#    find_valve (l'huître ouverte sur un canard, `-StoreShot`), benitier_glow, or_glow, progress (« Ma progression »).
#    Les ranger dans build/captures-app-store/ (hors du dépôt, mais pas dans un dossier temporaire).
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
# Les photos des perles, bijoux, trouvailles et du poisson (nouvelle DA, 1.2) : à côté de l'exécutable, où Bundle.main les cherche.
swift build -c release --package-path "$D/vitrine" --product art >/dev/null
cp "$ROOT"/ios/PearlInc/Art/PearlPhotos/*.png "$ROOT"/ios/PearlInc/Art/JewelPhotos/*.png "$ROOT"/ios/PearlInc/Art/FindPhotos/*.png "$(swift build -c release --package-path "$D/vitrine" --show-bin-path)/"
swift run -c release --package-path "$D/vitrine" art "$ROOT/ios/PearlCore/Sources/PearlCore/Resources/catalog.json" "$TMP/a" >/dev/null
# Héros capturé au simulateur (huître 3D, 1.2) : il remplace celui que dessine `art`.
[ -f "$ASSETS/hero-golden-34.png" ] && cp "$ASSETS/hero-golden-34.png" "$TMP/a/"
names="01-ouvre 02-perle-rare 03-collection 04-geste 05-perle-maudite 06-ecrins 07-bijoux 08-trouvailles 09-coquilles 10-progression"
for L in fr en; do
  SFX=""; [ "$L" = en ] && SFX=_en
  mkdir -p "$ROOT/docs/app-store/visuels/$L"; rm -f "$ROOT/docs/app-store/visuels/$L"/*.jpg; p=1
  for n in $names; do
    # Profil à part (le Chrome ouvert de Jules bloque le sien) et 3 essais : Chrome sans fenêtre échoue parfois sous la charge.
    for try in 1 2 3; do
      "$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 --allow-file-access-from-files \
        --user-data-dir="$TMP/chrome" --window-size=1320,2868 --virtual-time-budget=6000 --screenshot="$TMP/$n.png" \
        "file://$TMP/index.html?p=$p&lang=$L&sfx=$SFX" 2>/dev/null >/dev/null && break
      [ $try = 3 ] && exit 1; sleep 3
    done
    sips -s format jpeg -s formatOptions 92 "$TMP/$n.png" --out "$ROOT/docs/app-store/visuels/$L/$n.jpg" >/dev/null
    p=$((p+1))
  done
done
echo "docs/app-store/visuels/{fr,en}"
