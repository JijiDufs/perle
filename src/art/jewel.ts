// Dessin procédural des bijoux (Canvas 2D), repris du prototype Duo.
// L'échelle `s` vaut 1 pour un bijou d'environ 440 px de large.
import type { Jewel } from '../core/jewels';
import { hexRgb, shade } from './color';

type Ctx = CanvasRenderingContext2D;
type Point = [number, number];

export function lighten(hex: string, k: number): string {
  return `rgb(${hexRgb(hex).map((v) => Math.round(v + (255 - v) * k)).join(',')})`;
}

export function goldGradient(c: Ctx, x0: number, y0: number, x1: number, y1: number): CanvasGradient {
  const g = c.createLinearGradient(x0, y0, x1, y1);
  ([['#8a6420', 0], ['#f5d77e', 0.3], ['#b8862b', 0.5], ['#ffe9a8', 0.72], ['#8a6420', 1]] as const).forEach(([col, at]) => g.addColorStop(at, col));
  return g;
}

function metalGradient(c: Ctx, x0: number, y0: number, x1: number, y1: number, col: string): CanvasGradient {
  const g = c.createLinearGradient(x0, y0, x1, y1);
  g.addColorStop(0, shade(col, 0.4));
  g.addColorStop(0.3, lighten(col, 0.6));
  g.addColorStop(0.55, col);
  g.addColorStop(0.8, shade(col, 0.3));
  g.addColorStop(1, lighten(col, 0.35));
  return g;
}

function polygon(c: Ctx, points: Point[]): void {
  c.beginPath();
  points.forEach(([x, y], i) => (i ? c.lineTo(x, y) : c.moveTo(x, y)));
  c.closePath();
}

/** Pierre taillée (8 facettes) ou « bonbon » pour le toc. */
export function drawGem(c: Ctx, x: number, y: number, r: number, col: string, candy = false): void {
  c.save();
  if (candy) {
    const g = c.createRadialGradient(x - r * 0.3, y - r * 0.35, r * 0.1, x, y, r);
    g.addColorStop(0, lighten(col, 0.65));
    g.addColorStop(0.5, col);
    g.addColorStop(1, shade(col, 0.35));
    c.fillStyle = g;
    c.beginPath();
    c.arc(x, y, r, 0, Math.PI * 2);
    c.fill();
    c.globalAlpha = 0.75;
    c.fillStyle = '#fff';
    c.beginPath();
    c.ellipse(x - r * 0.35, y - r * 0.42, r * 0.3, r * 0.15, -0.6, 0, Math.PI * 2);
    c.fill();
    c.restore();
    return;
  }
  const n = 8;
  const outer: Point[] = [];
  const table: Point[] = [];
  for (let i = 0; i < n; i++) {
    const a = (i / n) * Math.PI * 2 + Math.PI / 8;
    outer.push([x + Math.cos(a) * r, y + Math.sin(a) * r]);
    table.push([x + Math.cos(a) * r * 0.55, y + Math.sin(a) * r * 0.55]);
  }
  const g = c.createRadialGradient(x - r * 0.2, y - r * 0.2, r * 0.1, x, y, r * 1.05);
  g.addColorStop(0, lighten(col, 0.4));
  g.addColorStop(0.6, col);
  g.addColorStop(1, shade(col, 0.45));
  polygon(c, outer);
  c.fillStyle = g;
  c.fill();
  for (let i = 0; i < n; i++) {
    polygon(c, [outer[i], outer[(i + 1) % n], table[(i + 1) % n], table[i]]);
    c.fillStyle = i % 2 ? 'rgba(255,255,255,.18)' : 'rgba(0,0,0,.16)';
    c.fill();
  }
  polygon(c, table);
  c.globalAlpha = 0.7;
  c.fillStyle = lighten(col, 0.45);
  c.fill();
  c.globalAlpha = 1;
  const [rr, gg, bb] = hexRgb(col);
  if (rr + gg + bb > 620 && 'createConicGradient' in c) {
    // Feux irisés des pierres claires (diamant, strass).
    const k = c.createConicGradient(0.6, x, y);
    ['#ff9ad5', '#9af0ff', '#fff59a', '#b9a6ff', '#ff9ad5'].forEach((s, i, a) => k.addColorStop(i / (a.length - 1), s));
    polygon(c, outer);
    c.globalAlpha = 0.32;
    c.fillStyle = k;
    c.fill();
    c.globalAlpha = 1;
  }
  c.beginPath();
  c.moveTo(x - r * 0.45, y - r * 0.5);
  c.lineTo(x - r * 0.1, y - r * 0.62);
  c.lineTo(x - r * 0.3, y - r * 0.25);
  c.closePath();
  c.fillStyle = 'rgba(255,255,255,.85)';
  c.fill();
  c.restore();
}

function pearlDot(c: Ctx, x: number, y: number, r: number): void {
  const g = c.createRadialGradient(x - r * 0.35, y - r * 0.4, r * 0.05, x, y, r);
  g.addColorStop(0, '#ffffff');
  g.addColorStop(0.45, '#f2ece4');
  g.addColorStop(1, '#a99d90');
  c.fillStyle = g;
  c.beginPath();
  c.arc(x, y, r, 0, Math.PI * 2);
  c.fill();
}

function prongs(c: Ctx, x: number, y: number, r: number, col: string, s: number): void {
  c.fillStyle = metalGradient(c, x - r, y - r, x + r, y + r, col);
  [0.25, 0.75, 1.25, 1.75].forEach((k) => {
    const a = k * Math.PI;
    c.beginPath();
    c.arc(x + Math.cos(a) * r * 0.95, y + Math.sin(a) * r * 0.95, 4.5 * s, 0, Math.PI * 2);
    c.fill();
  });
}

const curve = (p0: Point, ctrl: Point, p2: Point) => (t: number): Point => [
  (1 - t) * (1 - t) * p0[0] + 2 * (1 - t) * t * ctrl[0] + t * t * p2[0],
  (1 - t) * (1 - t) * p0[1] + 2 * (1 - t) * t * ctrl[1] + t * t * p2[1],
];

export function drawJewel(c: Ctx, x: number, y: number, s: number, jewel: Jewel): void {
  c.save();
  c.lineCap = 'round';
  const toc = jewel.rarityId === 'toc';
  const metal = (x0: number, y0: number, x1: number, y1: number) => metalGradient(c, x0, y0, x1, y1, jewel.metal);
  const gemRadius = (base: number, max: number) => (base + Math.min(max, (jewel.carats || 1) * 6)) * s;

  if (jewel.type === 'bague') {
    const R = 64 * s;
    const cy = y + 12 * s;
    const lw = (toc ? 18 : jewel.gem ? 13 : 20) * s;
    c.fillStyle = 'rgba(0,0,0,.55)';
    c.beginPath();
    c.ellipse(x, cy + R * 0.92, R * 1.4, 10 * s, 0, 0, Math.PI * 2);
    c.fill();
    c.lineWidth = lw;
    c.strokeStyle = metal(x - R, cy - R, x + R, cy + R);
    c.beginPath();
    c.arc(x, cy, R, Math.PI * 0.8, Math.PI * 2.2);
    c.stroke();
    c.lineWidth = lw * 0.25;
    c.strokeStyle = 'rgba(255,255,255,.55)';
    c.beginPath();
    c.arc(x, cy, R + lw * 0.12, Math.PI * 1.15, Math.PI * 1.45);
    c.stroke();
    if (jewel.gem) {
      const r = toc ? 42 * s : jewel.rarityId === 'fantaisie' ? 22 * s : gemRadius(18, 30);
      const gy = cy - R - r * 0.7;
      if (!toc) prongs(c, x, gy, r, jewel.metal, s);
      drawGem(c, x, gy, r, jewel.gem, jewel.candy);
    }
  } else if (jewel.type === 'collier') {
    const q = curve([x - 210 * s, y - 190 * s], [x, y + 120 * s], [x + 210 * s, y - 190 * s]);
    if (jewel.pearls) {
      for (let k = 0; k <= 34; k++) pearlDot(c, ...q(k / 34), 11 * s);
    } else {
      c.strokeStyle = metal(x - 210 * s, y - 190 * s, x + 210 * s, y);
      c.lineWidth = 3 * s;
      for (let k = 0; k <= 70; k++) {
        const [px, py] = q(k / 70);
        c.beginPath();
        c.ellipse(px, py, 5 * s, 3 * s, k % 2 ? 0.8 : -0.8, 0, Math.PI * 2);
        c.stroke();
      }
      if (jewel.gem && (jewel.rarityId === 'diamant' || jewel.rarityId === 'fantaisie')) {
        for (let k = 4; k <= 66; k += jewel.rarityId === 'diamant' ? 3 : 7) drawGem(c, ...q(k / 70), 7 * s, jewel.gem);
      }
    }
    const [bx, by] = q(0.5);
    if (jewel.pearls) pearlDot(c, bx, by + 24 * s, 18 * s);
    else if (jewel.gem) {
      c.strokeStyle = metal(bx - 10, by, bx + 10, by + 20);
      c.lineWidth = 3 * s;
      c.beginPath();
      c.arc(bx, by + 8 * s, 7 * s, 0, Math.PI * 2);
      c.stroke();
      const r = gemRadius(16, 26);
      prongs(c, bx, by + 16 * s + r, r, jewel.metal, s);
      drawGem(c, bx, by + 16 * s + r, r, jewel.gem, jewel.candy);
    } else {
      c.fillStyle = metal(bx - 24 * s, by, bx + 24 * s, by + 60 * s);
      c.beginPath();
      c.arc(bx, by + 34 * s, 24 * s, 0, Math.PI * 2);
      c.fill();
      c.strokeStyle = 'rgba(255,255,255,.4)';
      c.lineWidth = 2 * s;
      c.beginPath();
      c.arc(bx, by + 34 * s, 17 * s, 3.6, 5.2);
      c.stroke();
    }
  } else if (jewel.type === 'bracelet') {
    const rx = 150 * s;
    const ry = 58 * s;
    if (!jewel.gem && !jewel.pearls) {
      c.lineWidth = 20 * s;
      c.strokeStyle = metal(x - rx, y - ry, x + rx, y + ry);
      c.beginPath();
      c.ellipse(x, y, rx, ry, 0, 0, Math.PI * 2);
      c.stroke();
      c.lineWidth = 4 * s;
      c.strokeStyle = 'rgba(255,255,255,.5)';
      c.beginPath();
      c.ellipse(x, y - 2 * s, rx, ry, 0, 3.5, 4.9);
      c.stroke();
    } else {
      const n = jewel.pearls ? 30 : 44;
      c.strokeStyle = metal(x - rx, y - ry, x + rx, y + ry);
      c.lineWidth = 3 * s;
      for (let k = 0; k < n; k++) {
        const a = (k / n) * Math.PI * 2;
        const px = x + Math.cos(a) * rx;
        const py = y + Math.sin(a) * ry;
        if (jewel.pearls) pearlDot(c, px, py, 13 * s);
        else {
          c.beginPath();
          c.ellipse(px, py, 6 * s, 4 * s, a, 0, Math.PI * 2);
          c.stroke();
          const diamond = jewel.rarityId === 'diamant';
          if (k % (diamond ? 2 : 4) === 0) drawGem(c, px, py, (diamond ? 8 : 10) * s, jewel.gem!);
        }
      }
    }
  } else if (jewel.type === 'boucles') {
    for (const side of [-1, 1]) {
      const px = x + side * 95 * s;
      const top = y - 110 * s;
      c.strokeStyle = metal(px - 20 * s, top - 20 * s, px + 20 * s, top + 30 * s);
      c.lineWidth = 4 * s;
      c.beginPath();
      c.arc(px, top, 16 * s, Math.PI, Math.PI * 2);
      c.lineTo(px + 16 * s, top + 6 * s);
      c.stroke();
      c.beginPath();
      c.moveTo(px, top);
      c.lineTo(px, top + 34 * s);
      c.stroke();
      if (jewel.pearls) pearlDot(c, px, top + 62 * s, 24 * s);
      else if (jewel.gem) {
        const r = gemRadius(16, 14);
        prongs(c, px, top + 40 * s + r, r, jewel.metal, s);
        drawGem(c, px, top + 40 * s + r, r, jewel.gem, jewel.candy);
      } else {
        c.lineWidth = 7 * s;
        c.strokeStyle = metal(px - 46 * s, top + 20 * s, px + 46 * s, top + 110 * s);
        c.beginPath();
        c.arc(px, top + 80 * s, 46 * s, 0, Math.PI * 2);
        c.stroke();
      }
    }
  } else {
    // Diadème.
    const p0: Point = [x - 220 * s, y + 70 * s];
    const p2: Point = [x + 220 * s, y + 70 * s];
    const q = curve(p0, [x, y - 20 * s], p2);
    c.lineWidth = 12 * s;
    c.strokeStyle = metal(x - 220 * s, y, x + 220 * s, y + 70 * s);
    c.beginPath();
    c.moveTo(...p0);
    c.quadraticCurveTo(x, y - 20 * s, ...p2);
    c.stroke();
    for (let i = -3; i <= 3; i++) {
      const [bx, by] = q(((i + 3) / 6) * 0.8 + 0.1);
      const height = (95 - Math.abs(i) * 20) * s;
      c.lineWidth = 5 * s;
      c.beginPath();
      c.moveTo(bx - 18 * s, by);
      c.lineTo(bx, by - height);
      c.lineTo(bx + 18 * s, by);
      c.stroke();
      drawGem(c, bx, by - height, (i === 0 ? 32 : 12) * s, i === 0 && jewel.gem ? jewel.gem : '#f2fbff');
    }
    for (let k = 1; k < 20; k++) drawGem(c, ...q(k / 20), 5 * s, '#f2fbff');
  }
  c.restore();
}

/** Étoile de scintillement à quatre branches. */
export function drawStar(c: Ctx, x: number, y: number, r: number, alpha: number, col: string): void {
  if (alpha <= 0.02) return;
  c.save();
  c.globalCompositeOperation = 'lighter';
  c.globalAlpha = Math.min(1, alpha);
  c.fillStyle = col;
  c.beginPath();
  c.moveTo(x, y - r);
  c.lineTo(x + r * 0.13, y - r * 0.13);
  c.lineTo(x + r, y);
  c.lineTo(x + r * 0.13, y + r * 0.13);
  c.lineTo(x, y + r);
  c.lineTo(x - r * 0.13, y + r * 0.13);
  c.lineTo(x - r, y);
  c.lineTo(x - r * 0.13, y - r * 0.13);
  c.closePath();
  c.fill();
  c.fillStyle = '#fff';
  c.beginPath();
  c.arc(x, y, r * 0.12, 0, Math.PI * 2);
  c.fill();
  c.restore();
}

/** Scintillements autour du bijou ; `tier` en ajoute, `alpha` règle l'intensité, `scale` la taille. */
export function drawSparkles(c: Ctx, x: number, y: number, tier: number, glow: string, t: number, alpha: number, scale = 1): void {
  const n = 4 + tier * 3;
  for (let i = 0; i < n; i++) {
    const angle = i * 2.399;
    const radius = (50 + ((i * 73) % 170)) * scale;
    const twinkle = 0.5 + 0.5 * Math.sin(t * (3 + (i % 3)) + i * 1.7);
    drawStar(c, x + Math.cos(angle) * radius, y + Math.sin(angle) * radius * 0.75, ((12 + tier * 4) * twinkle + 6) * scale, alpha * twinkle, i % 2 ? '#ffffff' : glow);
  }
}

/** Petite toile contenant un bijou (cartes, collection). `size` en pixels CSS. */
export function jewelCanvas(jewel: Jewel, glow: string | null, size: number): HTMLCanvasElement {
  const dpr = Math.min(window.devicePixelRatio || 1, 3);
  const canvas = document.createElement('canvas');
  canvas.width = canvas.height = Math.round(size * dpr);
  canvas.style.width = canvas.style.height = `${size}px`;
  const c = canvas.getContext('2d')!;
  c.scale(dpr, dpr);
  const s = size / 440;
  const yOffset = jewel.type === 'collier' ? 0.62 : jewel.type === 'diademe' ? 0.52 : jewel.type === 'boucles' ? 0.56 : 0.5;
  if (glow) {
    const g = c.createRadialGradient(size / 2, size / 2, 0, size / 2, size / 2, size * 0.5);
    g.addColorStop(0, glow + '88');
    g.addColorStop(1, glow + '00');
    c.fillStyle = g;
    c.fillRect(0, 0, size, size);
  }
  drawJewel(c, size / 2, size * yOffset, s, jewel);
  return canvas;
}
