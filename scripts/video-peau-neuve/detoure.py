# Détoure les rendus 3D de huitre3d (chaque angle sur fond noir et sur fond blanc : l'écart des deux donne la transparence,
# comme scripts/site/rendus-3d.sh), même cadre pour toutes les images d'un objet, en WebP.
# usage : python3 -P -E detoure.py <rendus> <sortie> [huitre|ecrin…]
import glob, os, shutil, sys
from PIL import Image, ImageChops, ImageMath
raw, out = sys.argv[1], sys.argv[2]
SIZE = {}
def load(f, name):
    # Le moteur rend parfois une partie des angles à l'échelle 1 au lieu de 2 : tout ramener à la plus petite taille.
    im = Image.open(f).convert('RGB')
    return im if im.size == SIZE[name] else im.resize(SIZE[name], Image.LANCZOS)
def pairs(name):
    return [(b, b.replace('-noir', '-blanc')) for b in sorted(glob.glob(f'{raw}/{name}/*-noir.png'))]
def frame_box(name, pad=40):
    SIZE[name] = min((Image.open(b).size for b, _ in pairs(name)), key=lambda wh: wh[0])
    box = None
    for b, _ in pairs(name):
        bb = load(b, name).convert('L').point(lambda v: 255 if v > 6 else 0).getbbox()
        box = bb if box is None else (min(box[0], bb[0]), min(box[1], bb[1]), max(box[2], bb[2]), max(box[3], bb[3]))
    return (max(0, box[0] - pad), max(0, box[1] - pad), box[2] + pad, box[3] + pad)
def export(name, box, width, quality=88):
    shutil.rmtree(f'{out}/{name}', ignore_errors=True); os.makedirs(f'{out}/{name}')
    for i, (b, w) in enumerate(pairs(name)):
        B = load(b, name).crop(box); W = load(w, name).crop(box)
        d = [ImageChops.subtract(x, y) for x, y in zip(W.split(), B.split())]
        alpha = ImageMath.lambda_eval(lambda e: e['convert'](255 - (e['r'] + e['g'] + e['b']) / 3, 'L'), r=d[0], g=d[1], b=d[2])
        chans = [ImageMath.lambda_eval(lambda e: e['convert'](e['min'](e['c'] * 255 / e['max'](e['a'], 1), 255), 'L'), c=c, a=alpha) for c in B.split()]
        img = Image.merge('RGBA', (*chans, alpha))
        img = img.resize((width, round(img.height * width / img.width)), Image.LANCZOS)
        img.save(f'{out}/{name}/{i:02d}.webp', 'WEBP', quality=quality, method=4)
    print(name, len(pairs(name)), 'images', img.size, 'cadre', box)
for name, width in [('huitre', 900), ('ecrin', 800)]:
    if len(sys.argv) < 4 or name in sys.argv[3:]: export(name, frame_box(name), width)
