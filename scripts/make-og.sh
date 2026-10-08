#!/bin/sh
# Génère site/og.jpg (aperçu des liens, 1200×630) avec le code de dessin de site/index.html
# et Google Chrome sans fenêtre. Usage : sh scripts/make-og.sh
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Le code de dessin de la page (window.PerleArt) est le <script> qui suit three.js.
awk '/three\.min\.js/{grab=1;next} grab&&/<script>/{on=1;next} on&&/<\/script>/{exit} on' \
  "$ROOT/site/index.html" > "$TMP/art.js"

cat > "$TMP/og.html" <<EOF
<!doctype html><html><head><meta charset="utf-8">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@500;600;700&display=swap" rel="stylesheet">
<style>html,body{margin:0;background:#000}canvas{display:block}</style></head>
<body><canvas id="og" width="1200" height="630"></canvas>
<script>$(cat "$TMP/art.js")</script>
<script>$(cat "$ROOT/scripts/og-image.js")</script>
</body></html>
EOF

"$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
  --window-size=1200,630 --virtual-time-budget=8000 \
  --screenshot="$TMP/og.png" "file://$TMP/og.html" 2>/dev/null
# JPEG : 5 fois plus léger, les réseaux sociaux le chargent plus vite.
sips -s format jpeg -s formatOptions 88 "$TMP/og.png" --out "$ROOT/site/og.jpg" >/dev/null
echo "site/og.jpg"
