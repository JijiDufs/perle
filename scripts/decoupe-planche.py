# Découpe une planche de bijoux générée (Kling) sur fond noir pur, en grille : alpha = luminosité
# (le noir devient transparent), recadrage sur le bijou, carré 512 px, pour ios/PearlInc/Art/JewelPhotos.
# usage : python3 -P -E scripts/decoupe-planche.py planche.png lignes colonnes dossier nom1,nom2@b,... (« - » saute une case)
#    ou : python3 -P -E scripts/decoupe-planche.py planche.png cases.json - dossier noms   (cases [x0, y0, x1, y1] en pixels,
#         dans l'ordre de lecture, quand la planche n'est pas une grille régulière ou garde des cadres)
#    6e argument facultatif : taille du nettoyage des points isolés (3 par défaut ; 7 pour un fond de cadre granuleux,
#    mais il mange les chaînes très fines)
import json
import sys
from PIL import Image, ImageChops, ImageFilter
src, out, names = sys.argv[1], sys.argv[4], sys.argv[5].split(',')
speck = int(sys.argv[6]) if len(sys.argv) > 6 else 3
im = Image.open(src).convert('RGB')
if sys.argv[2].endswith('.json'):
    boxes = json.load(open(sys.argv[2]))
else:
    rows, cols = int(sys.argv[2]), int(sys.argv[3])
    ch, cw = im.height // rows, im.width // cols
    boxes = [[c * cw, r * ch, (c + 1) * cw, (r + 1) * ch] for r in range(rows) for c in range(cols)]
for i, name in enumerate(names):
    if name == '-': continue
    # « nom@b » coupe le bas de la case (ce qui dépasse de la rangée suivante), « @l » / « @r » son bord gauche / droit, « @c » ses coins.
    name, _, flags = name.partition('@')
    x0, y0, x1, y1 = boxes[i]
    left, right = ((x1 - x0) // 16 if f in flags else 0 for f in 'lr')
    cell = im.crop((x0 + left, y0, x1 - right, y1 - ((y1 - y0) // 8 if 'b' in flags else 0)))
    red, green, blue = cell.split()
    light = ImageChops.lighter(ImageChops.lighter(red, green), blue)
    # Niveau du fond : la médiane d'une bordure de la case (noir pur ≈ 2, fond d'un cadre resté ≈ 20) ; seuil juste au-dessus.
    w, h = light.size
    border = list(light.crop((0, 0, w, h // 25)).getdata()) + list(light.crop((0, h - h // 25, w, h)).getdata())
    floor = max(14, sorted(border)[len(border) // 2] + 12)
    alpha = light.point(lambda v: max(0, min(255, (v - floor) * 255 // 30)))
    # Ouverture morphologique : enlève les points clairs isolés du fond, garde les chaînes fines.
    solid = alpha.point(lambda v: 255 if v > 40 else 0).filter(ImageFilter.MinFilter(speck)).filter(ImageFilter.MaxFilter(speck + 4))
    if 'c' in flags:  # « @c » efface les quatre coins de la case (restes des coins arrondis d'un cadre)
        for cx, cy in ((0, 0), (w - w // 10, 0), (0, h - h // 10), (w - w // 10, h - h // 10)):
            solid.paste(0, (cx, cy, cx + w // 10, cy + h // 10))
    alpha = ImageChops.darker(alpha, solid)
    box = solid.getbbox()
    assert box, name
    piece = Image.merge('RGBA', (red, green, blue, alpha)).crop(box)
    s = 512 * 0.88 / max(piece.size)
    piece = piece.resize((max(1, round(piece.width * s)), max(1, round(piece.height * s))), Image.LANCZOS)
    canvas = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    canvas.paste(piece, ((512 - piece.width) // 2, (512 - piece.height) // 2))
    canvas.save(f'{out}/{name}.png', optimize=True)
    print('✓', name, box[2] - box[0], box[3] - box[1])
