#!/usr/bin/env python3
"""Génère l'icône provisoire de Pearl Inc. (en attendant la mascotte, voir AGENTS.md §8).

Reprend la formule de coquille du jeu (src/art/shell.ts) pour rester cohérent avec l'écran.
Produit public/icons/icon.svg, puis les PNG via les outils intégrés à macOS (qlmanage, sips).

Usage : python3 scripts/make-icons.py
"""
import math
import os
import shutil
import subprocess
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'public', 'icons')
PHASES = (1.3, 4.1, 2.2)
BANDS = ['#3a322b', '#57493c', '#2e2722', '#6a5a49', '#433931', '#7a6a57', '#3b332c']


def outline(ax, ay, angle, L, ph, frill, squash=1.0):
    """Même formule que shellOutline() dans src/art/shell.ts ; squash écrase la valve (perspective)."""
    pts = []
    ca, sa = math.cos(angle), math.sin(angle)
    for i in range(111):
        f = -1.42 + 2.84 * i / 110
        r = L * math.cos(f) ** 0.55 * (1 + 0.06 * math.sin(f * 3 + ph[0]) + 0.04 * math.sin(f * 7 + ph[1]))
        if frill:
            r *= 1 + frill * math.sin(f * 38 + ph[2]) * math.cos(f) ** 0.3
        x, y = math.cos(f) * r * squash, math.sin(f) * r * 1.05
        pts.append((ax + x * ca - y * sa, ay + x * sa + y * ca))
    return 'M' + ' L'.join(f'{x:.1f} {y:.1f}' for x, y in pts) + ' Z'


def valve(ax, ay, angle, L, squash, nacre_id):
    parts = []
    for k, color in enumerate(BANDS):
        ph = (PHASES[0] + k * 0.2, PHASES[1], PHASES[2] + k)
        parts.append(f'<path d="{outline(ax, ay, angle, L * (1 - k * 0.085), ph, 0.045 - k * 0.004, squash)}" fill="{color}"/>')
    parts.append(f'<path d="{outline(ax, ay, angle, L * 0.8, PHASES, 0, squash)}" fill="url(#{nacre_id})"/>')
    return '\n  '.join(parts)


def svg():
    hinge_y = 214
    L = 262
    down, up = math.pi / 2, -math.pi / 2
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <!-- Icône provisoire de Pearl Inc., générée par scripts/make-icons.py. Ne pas modifier à la main. -->
  <defs>
    <radialGradient id="sea" cx="50%" cy="40%" r="75%">
      <stop offset="0" stop-color="#1d5e6b"/><stop offset="0.55" stop-color="#0c3b45"/><stop offset="1" stop-color="#03161c"/>
    </radialGradient>
    <radialGradient id="nacre" cx="50%" cy="35%" r="70%">
      <stop offset="0" stop-color="#fdfaff"/><stop offset="0.5" stop-color="#e7ddf2"/><stop offset="1" stop-color="#a99fbd"/>
    </radialGradient>
    <radialGradient id="nacreTop" cx="50%" cy="70%" r="70%">
      <stop offset="0" stop-color="#fdfaff"/><stop offset="0.5" stop-color="#e2d6ef"/><stop offset="1" stop-color="#9a8fb0"/>
    </radialGradient>
    <radialGradient id="halo" cx="50%" cy="50%" r="50%">
      <stop offset="0" stop-color="#fff4dc"/><stop offset="0.3" stop-color="#ffe2ae" stop-opacity="0.55"/><stop offset="1" stop-color="#ffe2ae" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="pearl" cx="36%" cy="32%" r="72%">
      <stop offset="0" stop-color="#ffffff"/><stop offset="0.3" stop-color="#f3f0ea"/><stop offset="1" stop-color="#8f877d"/>
    </radialGradient>
  </defs>
  <rect width="512" height="512" fill="url(#sea)"/>
  <circle cx="256" cy="{hinge_y + 50}" r="230" fill="url(#halo)" opacity="0.55"/>
  {valve(256, hinge_y, up, L * 0.6, 0.55, 'nacreTop')}
  {valve(256, hinge_y, down, L, 0.72, 'nacre')}
  <circle cx="256" cy="{hinge_y + 86}" r="125" fill="url(#halo)"/>
  <ellipse cx="262" cy="{hinge_y + 128}" rx="50" ry="12" fill="#3c2c22" opacity="0.25"/>
  <circle cx="256" cy="{hinge_y + 84}" r="54" fill="url(#pearl)"/>
  <ellipse cx="237" cy="{hinge_y + 63}" rx="16" ry="9.5" fill="#ffffff" opacity="0.9" transform="rotate(-35 237 {hinge_y + 63})"/>
</svg>
'''


def main():
    os.makedirs(OUT, exist_ok=True)
    svg_path = os.path.join(OUT, 'icon.svg')
    with open(svg_path, 'w') as f:
        f.write(svg())
    tmp = tempfile.mkdtemp()
    subprocess.run(['qlmanage', '-t', '-s', '1024', '-o', tmp, svg_path], check=True, capture_output=True)
    big = os.path.join(tmp, 'icon.svg.png')
    for name, size in [('icon-512.png', 512), ('icon-192.png', 192), ('apple-touch-icon.png', 180), ('favicon-32.png', 32)]:
        target = os.path.join(OUT, name)
        shutil.copy(big, target)
        subprocess.run(['sips', '-z', str(size), str(size), target], check=True, capture_output=True)
    shutil.rmtree(tmp)
    print('Icônes générées dans', OUT)


if __name__ == '__main__':
    main()
