#!/bin/sh
# Vidéo « Pearl Inc. fait peau neuve » (version 1.2) : docs/lancement/pearl-inc-peau-neuve.mp4, 1080 × 1350 (format 4:5 du
# fil LinkedIn), 60 i/s, 32 s, avec musique, et une image de couverture. Le post : docs/lancement/post-peau-neuve.md.
# 1. L'huître et l'écrin en 3D : les scènes RealityKit de l'app rendues sur le Mac (huitre3d, l'outil de
#    scripts/site/rendus-3d.sh), sur fond noir et sur fond blanc, puis détourées (detoure.py).
# 2. pearl-inc.app filmé image par image dans Chrome sans fenêtre (capture.mjs + site-clock.js : horloge virtuelle,
#    défilement et pouce écrits à l'avance), sur ordinateur puis sur téléphone.
# 3. Montage : index.html photographiée image par image (capture.mjs) ; musique : music.swift ; encodage : frames.swift
#    de scripts/video-lancement.
# Entrées hors du dépôt : les captures de l'app (build/captures-app-store : raw_golden_open.png, duo-int-perle-doree.png).
# Usage : sh scripts/video-peau-neuve/make.sh [dossier de travail]   (Mac : Xcode, Google Chrome, Node 22+, Python + Pillow)
set -e
D=$(cd "$(dirname "$0")" && pwd); ROOT=$(cd "$D/../.." && pwd)
W=${1:-$ROOT/build/video-peau-neuve}; V=$W/v; ART=$ROOT/ios/PearlInc/Art; CAPS=$ROOT/build/captures-app-store
# Le Swift des Command Line Tools ne vient pas à bout des scènes 3D (« unable to type-check ») : celui d'Xcode.
case $(xcode-select -p) in *CommandLineTools*) export DEVELOPER_DIR=${DEVELOPER_DIR:-$(ls -d /Applications/Xcode*.app | tail -1)/Contents/Developer};; esac
mkdir -p "$W/bin" "$V/pearls" "$V/trouvailles" "$V/bijoux"

# 1. L'huître (perle dorée) de 0,5° à 120° tous les 2°, l'écrin bleu nuit (diadème de légende) de 0,5° à 150° tous les 2,5°.
BIN=$(OUTIL_SEUL=1 sh "$ROOT/scripts/site/rendus-3d.sh")
RAW=$W/rendus-3d; rm -rf "$RAW"; mkdir -p "$RAW/huitre" "$RAW/ecrin"
"$BIN/huitre3d" huitre "$RAW/huitre" golden ronde dore 214 0 1000 1900 0.5 $(seq 2 2 120) >/dev/null
"$BIN/huitre3d" ecrin "$RAW/ecrin" "#1b2b5c" legende diademe classique 1500 1500 0.5 $(seq 2.5 2.5 150) >/dev/null
python3 -P -E "$D/detoure.py" "$RAW" "$V"

# 2. Le site, servi tel quel ; ?app=1 : ni bannière de cookies ni pixel. Un Chrome à la fois (mémoire du Mac).
python3 -m http.server 8765 --bind 127.0.0.1 --directory "$ROOT/site" >/dev/null 2>&1 & SRV=$!
trap 'kill $SRV 2>/dev/null' EXIT
sleep 1
rm -rf "$V/site-d" "$V/site-m"
node "$D/capture.mjs" "http://127.0.0.1:8765/?app=1&plan=desktop" "$V/site-d" 1280 800 1.5 "$D/site-clock.js"
# La ligne « pouce {…} » donne la place du doigt : THUMB dans index.html.
node "$D/capture.mjs" "http://127.0.0.1:8765/?app=1&plan=mobile" "$V/site-m" 390 844 2 "$D/site-clock.js" | grep pouce

# 3. Les images de l'app : la capture App Store de la 1.1 (« avant »), celles de la 1.2, perles, bijoux, trouvailles, icône.
cp "$ROOT/docs/app-store/captures/02-ouverture.jpg" "$V/old.jpg"
python3 -P -E -c "
from PIL import Image
Image.open('$CAPS/raw_golden_open.png').convert('RGB').save('$V/new.jpg', quality=93)
Image.open('$CAPS/duo-int-perle-doree.png').convert('RGB').resize((1680, 1182), Image.LANCZOS).save('$V/duo.jpg', quality=92)"
for p in golden-ronde-dore white-ronde rose-ronde-rose baroque-baroque-lavande black-ronde-vert-paon giant-ronde-arc-en-ciel \
         white-cerclee-rose black-ronde-aubergine golden-ronde-arc-en-ciel baroque-coeur-rose cursed-presque-ronde-sang; do
  cp "$ART/PearlPhotos/pearl-$p.png" "$V/pearls/"
done
cp "$ROOT"/site/img/trouvailles/*.webp "$V/trouvailles/"; cp "$ROOT"/site/img/bijoux/*.webp "$V/bijoux/"
cp "$ROOT/docs/icone/pearl-inc-icone-1024.png" "$V/icon.png"

# 4. Musique (AAC : LinkedIn et X refusent le PCM), montage, encodage.
swiftc -O "$D/music.swift" -o "$W/bin/music"; swiftc -O "$ROOT/scripts/video-lancement/frames.swift" -o "$W/bin/frames"
"$W/bin/music" "$W/music.wav" && afconvert -f m4af -d aac -b 256000 "$W/music.wav" "$W/music.m4a"
rm -rf "$W/img"
node "$D/capture.mjs" "file://$D/index.html?a=file://$V" "$W/img" 1080 1350
mkdir -p "$ROOT/docs/lancement"
"$W/bin/frames" encode "$W/img" "$ROOT/docs/lancement/pearl-inc-peau-neuve.mp4" 60 "$W/music.m4a"
cp "$W/img/01740.jpg" "$ROOT/docs/lancement/pearl-inc-peau-neuve-couverture.jpg"   # 29 s : « Mets à jour sur l'App Store »
