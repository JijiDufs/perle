# Découpe une planche de bijoux générée (Kling) sur fond noir pur, en grille : alpha = luminosité
# (le noir devient transparent), recadrage sur le bijou, carré 512 px, pour ios/PearlInc/Art/JewelPhotos.
# usage : python3 -P -E scripts/decoupe-planche.py planche.png lignes colonnes dossier nom1,nom2@b,... (« - » saute une case)
import sys
from PIL import Image, ImageChops, ImageFilter
src, rows, cols, out, names = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4], sys.argv[5].split(',')
im = Image.open(src).convert('RGB')
ch, cw = im.height // rows, im.width // cols
for i, name in enumerate(names):
    if name == '-': continue
    # « nom@b » coupe le bas de la case (ce qui dépasse de la rangée suivante), « @l » / « @r » son bord gauche / droit.
    name, _, flags = name.partition('@')
    r, c = divmod(i, cols)
    left, right = (cw // 16 if f in flags else 0 for f in 'lr')
    cell = im.crop((c*cw + left, r*ch, (c+1)*cw - right, (r+1)*ch - (ch // 8 if 'b' in flags else 0)))
    red, green, blue = cell.split()
    alpha = ImageChops.lighter(ImageChops.lighter(red, green), blue).point(lambda v: max(0, min(255, (v - 14) * 255 // 30)))
    # Ouverture morphologique : enlève les points clairs isolés du fond, garde les chaînes fines.
    solid = alpha.point(lambda v: 255 if v > 40 else 0).filter(ImageFilter.MinFilter(3)).filter(ImageFilter.MaxFilter(7))
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
