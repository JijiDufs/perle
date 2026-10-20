#!/bin/sh
# Bannières paysage (PNG) de la page produit App Store (docs/app-store/visuels/{fr,en}/bannieres) :
#   en-tête 5244 × 2950 et 3840 × 1646, résultats de recherche 5244 × 2950, 3840 × 2560 et 1920 × 1280.
# 1. L'iPhone Duo en 3D de la page pearl-inc.app (site/index.html), à moitié ouvert sur une perle dorée,
#    photographié sur fond transparent (charnière à 118°, sans les pastilles de texte).
# 2. Perles haute définition : art.swift, avec le code de dessin de l'app.
# 3. Composition : banniere.html (textes FR / EN dedans), photographiée par Google Chrome sans fenêtre.
# Usage : sh scripts/app-store-visuels/render-bannieres.sh
set -e
D=$(cd "$(dirname "$0")" && pwd); ROOT=$(cd "$D/../.." && pwd)
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
shot() { # largeur hauteur échelle sortie url
  "$CHROME" --headless=new --user-data-dir="$TMP/profil" --hide-scrollbars --default-background-color=00000000 \
    --force-device-scale-factor=$3 --window-size=$1,$2 --virtual-time-budget=9000 --allow-file-access-from-files \
    --screenshot="$4" "$5" >/dev/null 2>&1
}
mkdir -p "$TMP/a"

# 1. Le Duo : copie du site, perle imposée, angle de vue et pastilles masquées par l'adresse.
python3 - "$ROOT/site/index.html" "$TMP/duo.html" <<'EOF'
import sys
s = open(sys.argv[1]).read()
def rep(a, b):
    global s
    assert s.count(a) == 1, a
    s = s.replace(a, b)
rep("function roll(){", "function roll(){const fp=new URLSearchParams(location.search).get('pearl');if(fp)return A.PEARLS.find(p=>p.id===fp);")
rep("let yaw=0,pitch=0.04", "const QQ=new URLSearchParams(location.search);let yaw=+(QQ.get('yaw')||0),pitch=+(QQ.get('pitch')||0.04)")
rep("if(q>0){hTarget=h=prevH=clamp(q,0,180);}", "if(q>0){touched=true;hTarget=h=prevH=clamp(q,0,180);}")
rep("function glassPill(c,cx,cy,text,warn){", "function glassPill(c,cx,cy,text,warn){if(location.search.includes('clean'))return;")
rep("</head>", """<style>html,body{background:transparent!important;overflow:hidden}
body>*:not(#demo){display:none!important}#demo{position:fixed!important;inset:0!important;margin:0!important;padding:0!important;height:100vh!important;background:transparent!important}
#demo>*:not(#scene){display:none!important}</style></head>""")
open(sys.argv[2], 'w').write(s)
EOF
shot 1800 1400 2 "$TMP/duo-full.png" "file://$TMP/duo.html?clean=1&pearl=golden&h=118&yaw=0.6&pitch=0.2"
sips --cropToHeightWidth 1800 2200 --cropOffset 560 640 "$TMP/duo-full.png" --out "$TMP/a/duo.png" >/dev/null

# 2. Les perles
ART="$ROOT/ios/PearlInc/Art"; cp "$D/art.swift" "$TMP/main.swift"
swiftc -O -target arm64-apple-macos14 -o "$TMP/art" $(ls "$ART"/*.swift | grep -v "PearlLook+Catalog\|CardStyle\|LagoonBackground") "$TMP/main.swift" 2>/dev/null
"$TMP/art" "$ROOT/ios/PearlCore/Sources/PearlCore/Resources/catalog.json" "$TMP/a" >/dev/null

# 3. Composition (taille CSS × échelle = taille exacte demandée par App Store Connect)
cp "$D/banniere.html" "$TMP/"
for L in fr en; do
  OUT="$ROOT/docs/app-store/visuels/$L/bannieres"; mkdir -p "$OUT"
  for spec in "entete 5244x2950 2622 1475 2" "entete 3840x1646 1920 823 2" \
              "recherche 5244x2950 2622 1475 2" "recherche 3840x2560 1920 1280 2" "recherche 1920x1280 1920 1280 1"; do
    set -- $spec
    shot $3 $4 $5 "$TMP/b.png" "file://$TMP/banniere.html?kind=$1&lang=$L"
    # PNG sans couche alpha (App Store Connect refuse la transparence)
    python3 -c "import sys;from PIL import Image;Image.open(sys.argv[1]).convert('RGB').save(sys.argv[2])" "$TMP/b.png" "$OUT/$1-$2.png"
  done
done
echo "docs/app-store/visuels/{fr,en}/bannieres"
