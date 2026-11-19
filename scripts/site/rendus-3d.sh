#!/bin/sh
# Les objets 3D de pearl-inc.app : les scènes 3D de l'app (Oyster3DScene, Ecrin3DScene) rendues sur le Mac, sans simulateur.
#   site/img/ouverture/00…20.webp  l'huître, perle dorée, de 0,5° à 120° (le site la fait s'ouvrir au défilement et au pouce)
#   site/img/felee/03…20.webp      la même, perle fêlée, de 18° à 120° (quand le visiteur ouvre trop vite)
#   site/img/ecrin/00…20.webp      l'écrin bleu nuit et le diadème de légende, geste de 0,5° à 150°
# Chaque angle est rendu sur fond noir et sur fond blanc ; l'écart des deux donne la transparence (comme
# render-bannieres.sh). Les images d'un même objet sont recadrées pareil. Images brutes dans build/rendus-3d/ (hors du dépôt).
# Usage : sh scripts/site/rendus-3d.sh
set -e
ROOT=${ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}
PKG="$ROOT/scripts/app-store-visuels/vitrine"
ART="$ROOT/ios/PearlInc/Art"
RAW="$ROOT/build/rendus-3d"
OUT="$ROOT/site/img"

# 1. Les scènes de l'app sans leur vue UIKit (ce sont des UIViewRepresentable, qui n'existent pas sur Mac).
python3 -I - "$ART" "$PKG/Sources/huitre3d" <<'EOF'
import sys
art, dst = sys.argv[1], sys.argv[2]
for name, cut_to in [('Oyster3D', '\n}\n\n/// La scène'), ('Ecrin3D', "\n}\n\n/// Les points de l'écrin 3D")]:
    s = open(f'{art}/{name}/{name}View.swift').read()
    start = s.index('    func makeCoordinator()')
    s = s[:start] + s[s.index(cut_to):]
    old = f'struct {name}View: UIViewRepresentable {{'
    assert old in s, old
    s = s.replace(old, f'struct {name}View {{')
    open(f'{dst}/{name}.generated.swift', 'w').write(
        f'// Généré par scripts/site/rendus-3d.sh depuis ios/PearlInc/Art/{name}/{name}View.swift : ne pas éditer.\n' + s)
EOF

# 2. L'outil, et à côté de lui ce que l'app charge par Bundle.main (textures de la coquille, photos de la perle et du bijou).
swift build -c release --package-path "$PKG" --product huitre3d >/dev/null
BIN=$(swift build -c release --package-path "$PKG" --show-bin-path)
cp "$ART"/Oyster3D/*.jpg "$ART"/PearlPhotos/pearl-golden-*.png "$ART"/JewelPhotos/jewel-legende-diademe-classique.png "$BIN/"
# OUTIL_SEUL=1 : s'arrêter là et donner le dossier de l'outil (vidéo « peau neuve », scripts/video-peau-neuve/make.sh).
[ -z "$OUTIL_SEUL" ] || { echo "$BIN"; exit 0; }

# 3. Les rendus.
rm -rf "$RAW" && mkdir -p "$RAW/ouverture" "$RAW/felee" "$RAW/ecrin"
"$BIN/huitre3d" huitre "$RAW/ouverture" golden ronde dore 214 0 1000 1900 0.5 $(seq 6 6 120) >/dev/null
"$BIN/huitre3d" huitre "$RAW/felee" golden ronde dore 214 1 1000 1900 $(seq 18 6 120) >/dev/null
"$BIN/huitre3d" ecrin "$RAW/ecrin" "#1b2b5c" legende diademe classique 1500 1500 0.5 $(seq 7.5 7.5 150) >/dev/null

# 4. Transparence, cadre commun, WebP.
python3 -P -E - "$RAW" "$OUT" <<'EOF'
import glob, os, shutil, sys
from PIL import Image, ImageChops, ImageMath
raw, out = sys.argv[1], sys.argv[2]

def pairs(name):
    return [(b, b.replace('-noir', '-blanc')) for b in sorted(glob.glob(f'{raw}/{name}/*-noir.png'))]

def frame_box(name, pad=40):
    """Cadre commun : tout ce qui n'est pas noir, sur toutes les images, plus une marge."""
    box = None
    for b, _ in pairs(name):
        bb = Image.open(b).convert('L').point(lambda v: 255 if v > 6 else 0).getbbox()
        box = bb if box is None else (min(box[0], bb[0]), min(box[1], bb[1]), max(box[2], bb[2]), max(box[3], bb[3]))
    return (max(0, box[0] - pad), max(0, box[1] - pad), box[2] + pad, box[3] + pad)

def export(name, box, width, first=0, quality=84):
    shutil.rmtree(f'{out}/{name}', ignore_errors=True)
    os.makedirs(f'{out}/{name}')
    for i, (b, w) in enumerate(pairs(name), start=first):
        B = Image.open(b).convert('RGB').crop(box)
        W = Image.open(w).convert('RGB').crop(box)
        # alpha = 1 - écart blanc/noir ; couleur = noir / alpha (comme render-bannieres.sh)
        d = [ImageChops.subtract(x, y) for x, y in zip(W.split(), B.split())]
        alpha = ImageMath.lambda_eval(lambda e: e['convert'](255 - (e['r'] + e['g'] + e['b']) / 3, 'L'), r=d[0], g=d[1], b=d[2])
        chans = [ImageMath.lambda_eval(lambda e: e['convert'](e['min'](e['c'] * 255 / e['max'](e['a'], 1), 255), 'L'), c=c, a=alpha) for c in B.split()]
        img = Image.merge('RGBA', (*chans, alpha))
        img = img.resize((width, round(img.height * width / img.width)), Image.LANCZOS)
        img.save(f'{out}/{name}/{i:02d}.webp', 'WEBP', quality=quality, method=6)
    print(name, len(pairs(name)), 'images', img.size, 'cadre', box)

oyster = frame_box('ouverture')
export('ouverture', oyster, 720)
export('felee', oyster, 720, first=3)  # même cadre que l'huître intacte : 18° est l'image 03
export('ecrin', frame_box('ecrin'), 820)
EOF
du -sh "$OUT/ouverture" "$OUT/felee" "$OUT/ecrin"
