#!/bin/sh
# Images de pearl-inc.app (site/img/, WebP), tirées des photos de l'app et des captures de la fiche App Store.
# Les captures brutes viennent de build/captures-app-store/ (hors du dépôt, voir docs/JOURNAL.md) ;
# l'huître et l'écrin en 3D ont leur propre script (scripts/site/rendus-3d.sh).
# Usage : sh scripts/site/images.sh
set -e
ROOT=${ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}
python3 -P -E - "$ROOT" <<'EOF'
import os, sys
from PIL import Image
root = sys.argv[1]
art, caps, out = f'{root}/ios/PearlInc/Art', f'{root}/build/captures-app-store', f'{root}/site/img'

def save(src, dst, width, crop=None, quality=82):
    img = Image.open(src)
    img = img.convert('RGBA' if img.mode in ('RGBA', 'LA', 'P') else 'RGB')
    if crop: img = img.crop(crop)
    if img.width > width: img = img.resize((width, round(img.height * width / img.width)), Image.LANCZOS)
    os.makedirs(os.path.dirname(f'{out}/{dst}'), exist_ok=True)
    img.save(f'{out}/{dst}.webp', 'WEBP', quality=quality, method=6)

# Les sept perles des tirages (l'huître vide n'a pas de photo).
for pearl in ['white-ronde-creme', 'rose-ronde-rose', 'baroque-baroque-rose', 'black-ronde-vert-paon', 'golden-ronde-dore',
              'giant-ronde-arc-en-ciel', 'cursed-presque-ronde-sang']:
    save(f'{art}/PearlPhotos/pearl-{pearl}.png', f'perles/{pearl}', 360)
# Variantes (formes, reflets, marques), pour les deux frises « Jamais deux fois la même ».
for pearl in ['white-coeur-rose', 'rose-goutte-arc-en-ciel', 'black-bouton-bleute', 'golden-presque-ronde-arc-en-ciel',
              'baroque-coeur-lavande', 'giant-goutte-bleute', 'cursed-cerclee-aubergine', 'white-cerclee-bleute',
              'rose-cerclee-lavande', 'black-goutte-cuivre', 'golden-bouton-cuivre', 'baroque-baroque-arc-en-ciel',
              'white-bouton-creme', 'black-coeur-vert-paon', 'giant-coeur-argente', 'rose-coeur-creme', 'cursed-coeur-sang',
              'golden-goutte-dore', 'black-cerclee-aubergine', 'white-goutte-argente', 'rose-bouton-lavande',
              'golden-coeur-arc-en-ciel']:
    save(f'{art}/PearlPhotos/pearl-{pearl}.png', f'variantes/{pearl}', 260)
# Trouvailles.
for find in ['canard', 'cube', 'champignon', 'ballon', 'tong', 'boussole', 'bouteille', 'cle-epave', 'piece-or', 'dentier',
             'lunettes', 'coeur-ocean', 'chapeau', 'fourchette']:
    save(f'{art}/FindPhotos/find-{find}.png', f'trouvailles/{find}', 260)
save(f'{art}/thief-fish.png', 'poisson-voleur', 640)
# Bijoux.
for jewel in ['diamant-collier-riviere', 'rubis-bague-cocktail', 'emeraude-bague-solitaire-poire',
              'saphir-bague-solitaire-marquise', 'perles-collier-rang', 'or-broche-libellule']:
    save(f'{art}/JewelPhotos/jewel-{jewel}.png', f'bijoux/{jewel}', 440)
# Écrans de l'app, en français et en anglais.
for shot in ['raw_collection', 'raw_progress', 'raw_jewel_card']:
    for sfx in ['', '_en']:
        save(f'{caps}/{shot}{sfx}.png', f'ecrans/{shot.removeprefix("raw_")}{sfx.replace("_", "-")}', 620, quality=80)
# iPhone Duo, écran intérieur.
for sfx in ['', '-en']:
    save(f'{caps}/duo-int-lumiere{sfx}.png', f'duo/interieur{sfx}', 1500, quality=80)
print('ok')
EOF
du -sh "$ROOT/site/img"
