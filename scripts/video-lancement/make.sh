#!/bin/sh
# Vidéo de lancement (docs/lancement/pearl-inc-lancement[-carre]-{fr,en}.mp4 : 1080 × 1920 et 1080 × 1080, 60 i/s, 35 s).
# 1. Les ouvertures (huîtres, écrins ; iPhone et iPhone Duo) sont dessinées image par image par le code de l'app
#    (vitrine/, cible `scenes`, avec OpeningEngine et GlintEngine) : les prises du simulateur saccadent sur ce Mac.
# 2. L'interface de l'app (barre du haut, messages, onglets) est détourée des prises du simulateur (`frames ui` :
#    les pixels immobiles), et les cartes viennent des prises elles-mêmes.
#    Prises attendues dans <prises> (iPhone 17 Pro, partie scripts/app-store-visuels/seed.py, `simctl io recordVideo`) :
#    golden, black, find, giant (bénitier), cursed, ecrin, orskin (coquille d'or), bijoux (.mp4).
#    Les fenêtres ci-dessous (secondes dans chaque prise) sont relevées à la main : à refaire si on refilme.
# 3. Montage : index.html photographiée image par image par Chrome (render.mjs) ; musique et sons : music.swift.
# Usage : sh scripts/video-lancement/make.sh <prises> [dossier de travail]
set -e
D=$(cd "$(dirname "$0")" && pwd); ROOT=$(cd "$D/../.." && pwd)
TAKES=${1:?dossier des prises}; W=${2:-$(mktemp -d)}
mkdir -p "$W/bin" "$W/v/s" "$W/v/ui" "$W/v/c" "$W/tmp"
swiftc -O "$D/frames.swift" -o "$W/bin/frames"
swiftc -O "$D/music.swift" -o "$W/bin/music"
F="$W/bin/frames"

for s in golden black find giant cursed rose-or ecrin duo-golden duo-ecrin; do
  swift run -c release --package-path "$ROOT/scripts/app-store-visuels/vitrine" scenes "$W/v/s" $s 60
done

# Interface : images d'une phase de la prise (30 i/s), de <a> à <b> par pas de <p>.
ui() { out=$1; take=$2; bands=$3; a=$4; b=$5; p=$6
  [ -d "$W/tmp/$take" ] || "$F" extract "$TAKES/$take.mp4" "$W/tmp/$take" 30
  "$F" ui "$W/v/ui/$out.png" "$bands" $(for i in $(seq $a $p $b); do printf "$W/tmp/$take/%05d.jpg " $i; done); }
ui oyster-closed golden 0-125,688-874 0 36 3
# Résistance : la même interface sans message ni missions (bande 688–782 pt vidée).
python3 -c "from PIL import Image; im=Image.open('$W/v/ui/oyster-closed.png').convert('RGBA'); im.paste((0,0,0,0),(0,688*3,im.width,782*3)); im.save('$W/v/ui/oyster-resist.png')"
ui oyster-fragile golden 0-125,688-874 60 72 1
ui oyster-open golden 0-125,688-874 121 143 1
ui ecrin-closed ecrin 0-125,700-874 6 69 3
ui ecrin-resist ecrin 0-125,700-874 77 81 1
ui ecrin-search ecrin 0-125,700-874 92 103 1
ui ecrin-near ecrin 0-125,700-874 112 137 1
ui ecrin-variant ecrin 0-125,700-874 142 197 2
ui ecrin-suspense ecrin 0-125,700-874 208 278 3

# Cartes : un extrait de chaque prise, à 60 i/s, à partir de l'arrivée de la carte.
for spec in golden:5.25:7.6 black:12.12:13.6 find:4.65:6.1 giant:15.12:16.6 cursed:14.95:16.8 ecrin:9.45:11.3 orskin:4.3:5.8 bijoux:1.9:5.5; do
  n=${spec%%:*}; r=${spec#*:}; "$F" extract "$TAKES/$n.mp4" "$W/v/c/$n" 60 ${r%%:*} ${r#*:}
done
cp "$ROOT/docs/icone/pearl-inc-icone-1024.png" "$W/v/icon.png"
"$W/bin/music" "$W/music.wav" && afconvert -f m4af -d aac -b 256000 "$W/music.wav" "$W/music.m4a"  # AAC : X et LinkedIn refusent le PCM
mkdir -p "$ROOT/docs/lancement"
# Vertical (1080 × 1920) et carré (1080 × 1080, « -carre »), en français et en anglais.
for FMT in vertical carre; do
  SFX=""; [ $FMT = carre ] && SFX="-carre"
  for L in fr en; do
    rm -rf "$W/$L"
    node "$D/render.mjs" "$W/v" "$W/$L" $L 0 "" 1 $FMT
    "$F" encode "$W/$L" "$ROOT/docs/lancement/pearl-inc-lancement$SFX-$L.mp4" 60 "$W/music.m4a"
    rm -rf "$W/$L"
  done
done
