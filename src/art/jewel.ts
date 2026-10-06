// Dessin procédural des bijoux (Canvas 2D), repris du prototype Duo.
// L'échelle `s` vaut 1 pour un bijou d'environ 440 px de large.
import type { GemCut, Jewel, JewelStyle } from '../core/jewels';
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

/** Contour d'une taille de pierre, dans un repère unité (rayon 1). */
function cutShape(cut: GemCut): Point[] {
  switch (cut) {
    case 'rond':
      return Array.from({ length: 16 }, (_, i): Point => {
        const a = (i / 16) * Math.PI * 2;
        return [Math.cos(a), Math.sin(a)];
      });
    case 'ovale':
      return Array.from({ length: 14 }, (_, i): Point => {
        const a = (i / 14) * Math.PI * 2 - Math.PI / 2;
        return [Math.cos(a) * 0.76, Math.sin(a)];
      });
    case 'poire': {
      // Pointe en haut, rondeur en bas.
      const half: Point[] = [[0, -1], [0.36, -0.56], [0.6, -0.08], [0.66, 0.32], [0.52, 0.7], [0.24, 0.92]];
      return [...half, [0, 0.97], ...half.slice(1).reverse().map(([px, py]): Point => [-px, py])];
    }
    case 'coussin':
      return Array.from({ length: 16 }, (_, i): Point => {
        const a = (i / 16) * Math.PI * 2 + Math.PI / 16;
        const k = 0.92 / Math.pow(Math.abs(Math.cos(a)) ** 4 + Math.abs(Math.sin(a)) ** 4, 0.25);
        return [Math.cos(a) * k, Math.sin(a) * k];
      });
    case 'emeraude':
      return [[-.55, -1], [.55, -1], [.84, -.7], [.84, .7], [.55, 1], [-.55, 1], [-.84, .7], [-.84, -.7]];
    case 'princesse':
      return [[-.78, -.84], [.78, -.84], [.84, -.78], [.84, .78], [.78, .84], [-.78, .84], [-.84, .78], [-.84, -.78]];
    case 'coeur':
      return Array.from({ length: 18 }, (_, i): Point => {
        const t = (i / 18) * Math.PI * 2;
        return [Math.sin(t) ** 3 * 0.98, -(13 * Math.cos(t) - 5 * Math.cos(2 * t) - 2 * Math.cos(3 * t) - Math.cos(4 * t)) / 16 + 0.08];
      });
    case 'marquise': {
      const right: Point[] = Array.from({ length: 7 }, (_, i): Point => {
        const t = i / 6;
        return [Math.sin(Math.PI * t) * 0.5, -1 + 2 * t];
      });
      return [...right, ...right.slice(1, -1).reverse().map(([px, py]): Point => [-px, py])];
    }
  }
}

function gemOutline(x: number, y: number, r: number, col: string, cut?: GemCut): Point[] {
  const scaled = (points: Point[]): Point[] => points.map(([px, py]) => [x + px * r, y + py * r]);
  if (cut) return scaled(cutShape(cut));
  // Bijoux d'avant les tailles : la taille se déduit de la couleur de la pierre.
  const color = col.toLowerCase();
  if (color === '#13a36b') return scaled(cutShape('emeraude'));
  if (color === '#1f4fd1' || color === '#7f8cff') return scaled(cutShape('ovale'));
  if (color === '#c8102e') return scaled(cutShape('poire'));
  return Array.from({ length: 8 }, (_, i) => {
    const angle = (i / 8) * Math.PI * 2 + Math.PI / 8;
    return [x + Math.cos(angle) * r, y + Math.sin(angle) * r];
  });
}

/** Pierre facettée, dans sa taille (ou une taille qui évoque sa couleur), ou « bonbon » pour le toc. */
export function drawGem(c: Ctx, x: number, y: number, r: number, col: string, candy = false, cut?: GemCut): void {
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
  const outer = gemOutline(x, y, r, col, cut);
  const table = gemOutline(x, y, r * 0.53, col, cut);
  const n = outer.length;
  const g = c.createRadialGradient(x - r * 0.2, y - r * 0.2, r * 0.1, x, y, r * 1.05);
  g.addColorStop(0, lighten(col, 0.4));
  g.addColorStop(0.6, col);
  g.addColorStop(1, shade(col, 0.45));
  polygon(c, outer);
  c.fillStyle = g;
  c.fill();
  for (let i = 0; i < n; i++) {
    polygon(c, [outer[i], outer[(i + 1) % n], table[(i + 1) % n], table[i]]);
    c.fillStyle = i % 3 === 0 ? 'rgba(255,255,255,.28)' : i % 2 ? 'rgba(255,255,255,.1)' : 'rgba(0,0,0,.18)';
    c.fill();
  }
  // Lignes de taille au cœur : elles donnent un reflet net même sur les petites cartes.
  c.strokeStyle = 'rgba(255,255,255,.24)';
  // Épaisseurs proportionnelles à la pierre : le bijou est aussi dessiné dans le repère de l'écrin, où 1 = la largeur du coffret.
  c.lineWidth = r * 0.03;
  for (let i = 0; i < n; i += 2) {
    c.beginPath();
    c.moveTo(...outer[i]);
    c.lineTo(...table[i]);
    c.stroke();
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

function pearlDot(c: Ctx, x: number, y: number, r: number, color = '#f2ece4'): void {
  const g = c.createRadialGradient(x - r * 0.35, y - r * 0.4, r * 0.05, x, y, r);
  g.addColorStop(0, '#ffffff');
  g.addColorStop(0.45, color);
  g.addColorStop(1, shade(color, 0.35));
  c.fillStyle = g;
  c.beginPath();
  c.arc(x, y, r, 0, Math.PI * 2);
  c.fill();
}

function prongs(c: Ctx, x: number, y: number, r: number, col: string, s: number, cut?: GemCut): void {
  const finish = metalGradient(c, x - r, y - r, x + r, y + r, col);
  if (cut && cut !== 'rond') {
    // Le serti épouse la taille : liseré tout autour, une griffe à chaque extrémité.
    const outline = gemOutline(x, y, r * 1.1, '', cut);
    polygon(c, outline);
    c.strokeStyle = finish;
    c.lineWidth = Math.max(r * 0.05, 3 * s);
    c.stroke();
    const by = (k: 0 | 1, sign: number) => outline.reduce((best, p) => (p[k] * sign > best[k] * sign ? p : best));
    c.fillStyle = finish;
    for (const [px, py] of [by(1, -1), by(1, 1), by(0, -1), by(0, 1)]) {
      c.beginPath();
      c.arc(px, py, Math.max(r * 0.1, 4.5 * s), 0, Math.PI * 2);
      c.fill();
    }
    return;
  }
  c.strokeStyle = finish;
  c.lineWidth = Math.max(r * 0.05, 3 * s);
  c.beginPath();
  c.arc(x, y, r * 1.08, 0, Math.PI * 2);
  c.stroke();
  c.fillStyle = finish;
  [0.25, 0.75, 1.25, 1.75].forEach((k) => {
    const a = k * Math.PI;
    c.beginPath();
    c.arc(x + Math.cos(a) * r * 1.08, y + Math.sin(a) * r * 1.08, Math.max(r * 0.1, 4.5 * s), 0, Math.PI * 2);
    c.fill();
  });
}

const curve = (p0: Point, ctrl: Point, p2: Point) => (t: number): Point => [
  (1 - t) * (1 - t) * p0[0] + 2 * (1 - t) * t * ctrl[0] + t * t * p2[0],
  (1 - t) * (1 - t) * p0[1] + 2 * (1 - t) * t * ctrl[1] + t * t * p2[1],
];

const TAU = Math.PI * 2;

function roundedRect(c: Ctx, x: number, y: number, w: number, h: number, r: number): void {
  c.beginPath();
  c.moveTo(x + r, y);
  c.arcTo(x + w, y, x + w, y + h, r);
  c.arcTo(x + w, y + h, x, y + h, r);
  c.arcTo(x, y + h, x, y, r);
  c.arcTo(x, y, x + w, y, r);
  c.closePath();
}

/** Coquille Saint-Jacques : éventail côtelé, deux oreilles à la base (pendentif, gravure de chevalière). */
function scallop(c: Ctx, x: number, y: number, size: number, fill: string | CanvasGradient | null, line: string, lw: number): void {
  const base: Point = [x, y + size * 0.55];
  const ribs = 9;
  const edge = (k: number): Point => {
    const a = Math.PI * (1.12 + (k / ribs) * 0.76);
    return [base[0] + Math.cos(a) * size * 1.15, base[1] + Math.sin(a) * size * 1.15];
  };
  c.beginPath();
  c.moveTo(base[0] - size * 0.32, base[1] + size * 0.1);
  c.lineTo(base[0] - size * 0.3, base[1] - size * 0.12);
  c.lineTo(...edge(0));
  for (let k = 1; k <= ribs; k++) {
    const [qx, qy] = edge(k - 0.5);
    c.quadraticCurveTo(base[0] + (qx - base[0]) * 1.08, base[1] + (qy - base[1]) * 1.08, ...edge(k));
  }
  c.lineTo(base[0] + size * 0.3, base[1] - size * 0.12);
  c.lineTo(base[0] + size * 0.32, base[1] + size * 0.1);
  c.closePath();
  if (fill) {
    c.fillStyle = fill;
    c.fill();
  }
  c.strokeStyle = line;
  c.lineWidth = lw;
  c.stroke();
  for (let k = 0; k <= ribs; k++) {
    const [px, py] = edge(k);
    c.beginPath();
    c.moveTo(base[0], base[1] - size * 0.05);
    c.lineTo(base[0] + (px - base[0]) * 0.9, base[1] + (py - base[1]) * 0.9);
    c.stroke();
  }
}

/** Modèle d'un bijou ; ceux d'avant les modèles le déduisent de leur type et de ce qui les orne. */
export function jewelStyleOf(jewel: Jewel): JewelStyle {
  if (jewel.style) return jewel.style;
  switch (jewel.type) {
    case 'bague':
      return jewel.gem ? 'solitaire' : jewel.pearls ? 'perle' : 'jonc';
    case 'collier':
      return jewel.pearls ? 'rang' : jewel.gem && (jewel.rarityId === 'diamant' || jewel.rarityId === 'fantaisie') ? 'riviere' : jewel.gem ? 'solitaire' : 'chaine';
    case 'bracelet':
      return jewel.pearls ? 'rang' : jewel.gem ? 'tennis' : 'jonc';
    case 'boucles':
      return jewel.gem || jewel.pearls ? 'pendants' : 'creoles';
    case 'pendentif':
      return jewel.gem || jewel.pearls ? 'goutte' : 'medaille';
    case 'broche':
      return 'fleur';
    case 'diademe':
      return 'classique';
  }
}

/**
 * Où placer le bijou dans un carré, en fraction de la hauteur, pour qu'il y paraisse centré
 * (`drawJewel` part d'un point d'ancrage qui n'est pas le centre visuel de tous les modèles).
 */
export function jewelYOffset(jewel: Jewel): number {
  const style = jewelStyleOf(jewel);
  switch (jewel.type) {
    case 'collier':
      return 0.62;
    case 'pendentif':
      return 0.77;
    case 'diademe':
      return 0.52;
    case 'boucles':
      return style === 'puces' ? 0.68 : 0.56;
    case 'broche':
      return style === 'fleur' ? 0.44 : style === 'libellule' ? 0.47 : 0.5;
    default:
      return 0.5;
  }
}

export function drawJewel(c: Ctx, x: number, y: number, s: number, jewel: Jewel): void {
  c.save();
  c.lineCap = 'round';
  const style = jewelStyleOf(jewel);
  const toc = jewel.rarityId === 'toc';
  const metal = (x0: number, y0: number, x1: number, y1: number) => metalGradient(c, x0, y0, x1, y1, jewel.metal);
  const gemRadius = (base: number, max: number) => (base + Math.min(max, (jewel.carats || 1) * 6)) * s;
  // Perles de l'atelier : leurs vraies couleurs, en alternance.
  const pearlAt = (k: number) => (jewel.pearlColors?.length ? jewel.pearlColors[k % jewel.pearlColors.length] : undefined);
  /** La pierre principale, dans sa taille, sertie de griffes. */
  const mainGem = (gx: number, gy: number, r: number) => {
    if (!jewel.gem) return;
    if (!toc) prongs(c, gx, gy, r, jewel.metal, s, jewel.cut);
    drawGem(c, gx, gy, r, jewel.gem, jewel.candy, jewel.cut);
  };
  /** Petites pierres d'accompagnement (pavé), toujours rondes. */
  const accent = (gx: number, gy: number, r: number, color = jewel.gem ?? '#f2fbff') => drawGem(c, gx, gy, r, color, false, 'rond');
  /** Serti clos : un liseré de métal tout autour de la pierre (pendentifs). */
  const bezel = (gx: number, gy: number, r: number) => {
    if (!jewel.gem) return;
    polygon(c, gemOutline(gx, gy, r * 1.14, jewel.gem, jewel.cut));
    c.fillStyle = metal(gx - r, gy - r, gx + r, gy + r);
    c.fill();
    drawGem(c, gx, gy, r, jewel.gem, false, jewel.cut);
  };
  /** Petit dôme de métal, à la place d'une pierre. */
  const dome = (gx: number, gy: number, r: number) => {
    const g = c.createRadialGradient(gx - r * 0.35, gy - r * 0.4, r * 0.05, gx, gy, r);
    g.addColorStop(0, lighten(jewel.metal, 0.75));
    g.addColorStop(0.5, jewel.metal);
    g.addColorStop(1, shade(jewel.metal, 0.4));
    c.fillStyle = g;
    c.beginPath();
    c.arc(gx, gy, r, 0, TAU);
    c.fill();
  };

  if (jewel.type === 'bague') {
    const R = 64 * s;
    const cy = y + 12 * s;
    const lw = (toc ? 18 : style === 'jonc' ? 24 : style === 'chevaliere' ? 16 : jewel.gem ? 13 : 20) * s;
    c.fillStyle = 'rgba(0,0,0,.55)';
    c.beginPath();
    c.ellipse(x, cy + R * 0.92, R * 1.4, 10 * s, 0, 0, TAU);
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
    const top = cy - R;
    if (style === 'jonc') {
      // Filet gravé au milieu de l'anneau.
      c.lineWidth = 1.6 * s;
      c.strokeStyle = 'rgba(0,0,0,.28)';
      c.beginPath();
      c.arc(x, cy, R, Math.PI * 0.85, Math.PI * 2.15);
      c.stroke();
    } else if (style === 'chevaliere') {
      // Plateau ovale, gravé d'une coquille.
      const pw = 46 * s;
      const ph = 34 * s;
      const py = top - 4 * s;
      c.beginPath();
      c.ellipse(x, py + 6 * s, pw, ph, 0, 0, TAU);
      c.fillStyle = shade(jewel.metal, 0.45);
      c.fill();
      c.beginPath();
      c.ellipse(x, py, pw, ph, 0, 0, TAU);
      c.fillStyle = metal(x - pw, py - ph, x + pw, py + ph);
      c.fill();
      c.lineWidth = 2 * s;
      c.strokeStyle = 'rgba(255,255,255,.5)';
      c.beginPath();
      c.ellipse(x, py, pw * 0.84, ph * 0.8, 0, Math.PI * 1.05, Math.PI * 1.7);
      c.stroke();
      scallop(c, x, py - 4 * s, 20 * s, null, 'rgba(40,25,5,.4)', 1.6 * s);
    } else if (style === 'perle') {
      // Bague à perle (atelier) : une ou deux perles posées sur l'anneau.
      const colors = jewel.pearlColors?.length ? jewel.pearlColors : ['#f2ece4'];
      const r = 26 * s;
      if (colors.length > 1) {
        pearlDot(c, x - r * 0.75, top - r * 0.6, r * 0.85, colors[0]);
        pearlDot(c, x + r * 0.75, top - r * 0.6, r * 0.85, colors[1]);
      } else pearlDot(c, x, top - r * 0.6, r, colors[0]);
    } else if (style === 'trilogie') {
      // Trois pierres : la plus grande au milieu.
      const r0 = gemRadius(14, 18);
      const r1 = r0 * 0.66;
      const gy = top - r0 * 0.7;
      for (const side of [-1, 1]) mainGem(x + side * (r0 + r1 * 0.95), gy + r1 * 0.6, r1);
      mainGem(x, gy, r0);
    } else if (style === 'cocktail') {
      // Grosse pierre entourée d'un halo de petits diamants.
      const r0 = gemRadius(18, 22);
      const gy = top - r0 * 0.8;
      for (let k = 0; k < 16; k++) {
        const a = (k / 16) * TAU;
        accent(x + Math.cos(a) * r0 * 1.42, gy + Math.sin(a) * r0 * 1.42, 6.5 * s, '#f2fbff');
      }
      mainGem(x, gy, r0);
    } else if (jewel.gem) {
      const r = toc ? 42 * s : jewel.rarityId === 'fantaisie' ? 22 * s : gemRadius(18, 30);
      mainGem(x, top - r * 0.7, r);
    }
  } else if (jewel.type === 'collier') {
    const sautoir = style === 'sautoir';
    const q = curve([x - 210 * s, y - 190 * s], [x, y + 120 * s], [x + 210 * s, y - 190 * s]);
    if (jewel.pearls) {
      if (sautoir) {
        // Deuxième rang, plus long.
        const q2 = curve([x - 200 * s, y - 190 * s], [x, y + 210 * s], [x + 200 * s, y - 190 * s]);
        for (let k = 0; k <= 42; k++) pearlDot(c, ...q2(k / 42), 9 * s, pearlAt(k + 3));
      }
      for (let k = 0; k <= 34; k++) pearlDot(c, ...q(k / 34), (sautoir ? 9.5 : 11) * s, pearlAt(k));
    } else {
      c.strokeStyle = metal(x - 210 * s, y - 190 * s, x + 210 * s, y);
      c.lineWidth = (style === 'chaine' ? 4 : 3) * s;
      for (let k = 0; k <= 70; k++) {
        const [px, py] = q(k / 70);
        c.beginPath();
        c.ellipse(px, py, (style === 'chaine' ? 6 : 5) * s, (style === 'chaine' ? 3.6 : 3) * s, k % 2 ? 0.8 : -0.8, 0, TAU);
        c.stroke();
      }
      if (style === 'riviere' && jewel.gem) {
        // Rivière : des pierres tout le long, plus grosses vers le milieu.
        for (let k = 5; k <= 65; k += 3) {
          const t = k / 70;
          accent(...q(t), (5 + 5 * (1 - Math.abs(t - 0.5) * 2)) * s);
        }
      }
    }
    const [bx, by] = q(0.5);
    if (jewel.pearls) {
      if (!sautoir) pearlDot(c, bx, by + 24 * s, 18 * s, pearlAt(0));
    } else if (jewel.gem) {
      c.strokeStyle = metal(bx - 10, by, bx + 10, by + 20);
      c.lineWidth = 3 * s;
      c.beginPath();
      c.arc(bx, by + 8 * s, 7 * s, 0, TAU);
      c.stroke();
      const r = style === 'riviere' ? gemRadius(12, 16) : gemRadius(16, 26);
      mainGem(bx, by + 16 * s + r, r);
    } else {
      c.fillStyle = metal(bx - 24 * s, by, bx + 24 * s, by + 60 * s);
      c.beginPath();
      c.arc(bx, by + 34 * s, 24 * s, 0, TAU);
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
    if (style === 'jonc') {
      c.lineWidth = 20 * s;
      c.strokeStyle = metal(x - rx, y - ry, x + rx, y + ry);
      c.beginPath();
      c.ellipse(x, y, rx, ry, 0, 0, TAU);
      c.stroke();
      c.lineWidth = 4 * s;
      c.strokeStyle = 'rgba(255,255,255,.5)';
      c.beginPath();
      c.ellipse(x, y - 2 * s, rx, ry, 0, 3.5, 4.9);
      c.stroke();
      if (jewel.gem) {
        // Jonc serti : cinq pierres sur l'avant, la plus grosse au milieu.
        for (const k of [-2, -1, 1, 2]) {
          const a = Math.PI / 2 + k * 0.2;
          accent(x + Math.cos(a) * rx, y + Math.sin(a) * ry, 7 * s);
        }
        mainGem(x, y + ry, gemRadius(9, 8));
      }
    } else if (style === 'gourmette') {
      // Grosses mailles entrelacées, et la plaque à graver sur l'avant.
      c.strokeStyle = metal(x - rx, y - ry, x + rx, y + ry);
      c.lineWidth = 7 * s;
      for (let k = 0; k < 30; k++) {
        const a = (k / 30) * TAU;
        c.beginPath();
        c.ellipse(x + Math.cos(a) * rx, y + Math.sin(a) * ry, 11 * s, 6.5 * s, a + (k % 2 ? 0.55 : -0.55), 0, TAU);
        c.stroke();
      }
      const pw = 74 * s;
      const ph = 26 * s;
      roundedRect(c, x - pw / 2, y + ry - ph / 2, pw, ph, 8 * s);
      c.fillStyle = metal(x - pw / 2, y + ry - ph / 2, x + pw / 2, y + ry + ph / 2);
      c.fill();
      c.lineWidth = 2 * s;
      c.strokeStyle = 'rgba(255,255,255,.55)';
      c.beginPath();
      c.moveTo(x - pw / 2 + 8 * s, y + ry - ph / 2 + 4 * s);
      c.lineTo(x + pw / 2 - 8 * s, y + ry - ph / 2 + 4 * s);
      c.stroke();
    } else {
      // Tennis (pierres) ou rang de perles.
      const n = jewel.pearls ? 30 : 44;
      c.strokeStyle = metal(x - rx, y - ry, x + rx, y + ry);
      c.lineWidth = 3 * s;
      for (let k = 0; k < n; k++) {
        const a = (k / n) * TAU;
        const px = x + Math.cos(a) * rx;
        const py = y + Math.sin(a) * ry;
        if (jewel.pearls) pearlDot(c, px, py, 13 * s, pearlAt(k));
        else {
          c.beginPath();
          c.ellipse(px, py, 6 * s, 4 * s, a, 0, TAU);
          c.stroke();
          const dense = style === 'tennis' || jewel.rarityId === 'diamant';
          if (jewel.gem && k % (dense ? 2 : 4) === 0) accent(px, py, (dense ? 8 : 10) * s);
        }
      }
    }
  } else if (jewel.type === 'boucles') {
    for (const side of [-1, 1]) {
      const px = x + side * 95 * s;
      const top = y - 110 * s;
      if (style === 'puces') {
        // Puces : la pierre ou la perle seule, posée sur son poussoir.
        const cy = top + 40 * s;
        if (jewel.pearls) pearlDot(c, px, cy, 26 * s, pearlAt(side < 0 ? 0 : 1));
        else mainGem(px, cy, gemRadius(16, 14));
        continue;
      }
      if (style === 'creoles') {
        const hy = top + 72 * s;
        const hr = 50 * s;
        c.lineWidth = 8 * s;
        c.strokeStyle = metal(px - hr, hy - hr, px + hr, hy + hr);
        c.beginPath();
        c.arc(px, hy, hr, 0, TAU);
        c.stroke();
        c.lineWidth = 2 * s;
        c.strokeStyle = 'rgba(255,255,255,.5)';
        c.beginPath();
        c.arc(px, hy, hr + 2 * s, Math.PI * 1.1, Math.PI * 1.45);
        c.stroke();
        if (jewel.gem) {
          for (let k = 0; k < 7; k++) {
            const a = Math.PI * (0.15 + (k / 6) * 0.7);
            accent(px + Math.cos(a) * hr, hy + Math.sin(a) * hr, 6 * s);
          }
        }
        continue;
      }
      // Pendants : crochet et pendeloque.
      c.strokeStyle = metal(px - 20 * s, top - 20 * s, px + 20 * s, top + 30 * s);
      c.lineWidth = 4 * s;
      c.beginPath();
      c.arc(px, top, 16 * s, Math.PI, TAU);
      c.lineTo(px + 16 * s, top + 6 * s);
      c.stroke();
      c.beginPath();
      c.moveTo(px, top);
      c.lineTo(px, top + 34 * s);
      c.stroke();
      if (jewel.pearls) pearlDot(c, px, top + 62 * s, 24 * s, pearlAt(side < 0 ? 0 : 1));
      else if (jewel.gem) {
        const r = gemRadius(16, 14);
        mainGem(px, top + 40 * s + r, r);
      } else {
        c.lineWidth = 7 * s;
        c.strokeStyle = metal(px - 46 * s, top + 20 * s, px + 46 * s, top + 110 * s);
        c.beginPath();
        c.arc(px, top + 80 * s, 46 * s, 0, TAU);
        c.stroke();
      }
    }
  } else if (jewel.type === 'pendentif') {
    const q = curve([x - 170 * s, y - 215 * s], [x, y + 10 * s], [x + 170 * s, y - 215 * s]);
    // Chaîne fine.
    c.strokeStyle = metal(x - 170 * s, y - 215 * s, x + 170 * s, y);
    c.lineWidth = 2 * s;
    for (let k = 0; k <= 56; k++) {
      const [px, py] = q(k / 56);
      c.beginPath();
      c.ellipse(px, py, 3.6 * s, 2.2 * s, k % 2 ? 0.8 : -0.8, 0, TAU);
      c.stroke();
    }
    const [bx, by] = q(0.5);
    c.lineWidth = 3.5 * s;
    c.beginPath();
    c.ellipse(bx, by + 8 * s, 5 * s, 8 * s, 0, 0, TAU);
    c.stroke();
    const top = by + 16 * s;
    if (style === 'medaille') {
      // Médaille : disque à bord roulé, étoile du marin en relief.
      const r = 40 * s;
      const cy = top + r;
      c.beginPath();
      c.arc(bx + 2 * s, cy + 3 * s, r, 0, TAU);
      c.fillStyle = 'rgba(0,0,0,.35)';
      c.fill();
      c.beginPath();
      c.arc(bx, cy, r, 0, TAU);
      c.fillStyle = metal(bx - r, cy - r, bx + r, cy + r);
      c.fill();
      c.lineWidth = 2.5 * s;
      c.strokeStyle = 'rgba(255,255,255,.5)';
      c.beginPath();
      c.arc(bx, cy, r * 0.84, 0, TAU);
      c.stroke();
      const star: Point[] = Array.from({ length: 16 }, (_, i) => {
        const a = (i / 16) * TAU - Math.PI / 2;
        const k = i % 2 ? 0.18 : i % 4 === 0 ? 0.62 : 0.4;
        return [bx + Math.cos(a) * r * k, cy + Math.sin(a) * r * k];
      });
      polygon(c, star);
      c.fillStyle = 'rgba(255,255,255,.32)';
      c.fill();
      c.lineWidth = 1.2 * s;
      c.strokeStyle = 'rgba(0,0,0,.25)';
      c.stroke();
    } else if (style === 'coquillage') {
      scallop(c, bx, top + 40 * s, 44 * s, metal(bx - 50 * s, top, bx + 50 * s, top + 90 * s), shade(jewel.metal, 0.45), 1.6 * s);
    } else if (jewel.pearls) {
      // Perle en goutte sous une petite calotte.
      c.save();
      c.translate(bx, top + 32 * s);
      c.scale(1, 1.18);
      pearlDot(c, 0, 0, 24 * s, pearlAt(0));
      c.restore();
      c.beginPath();
      c.arc(bx, top + 6 * s, 8 * s, Math.PI, TAU);
      c.fillStyle = metal(bx - 8 * s, top, bx + 8 * s, top + 8 * s);
      c.fill();
    } else if (jewel.gem) {
      const r = gemRadius(20, 20);
      bezel(bx, top + r * 1.1, r);
    }
  } else if (jewel.type === 'broche') {
    if (style === 'fleur') {
      // Tige et feuille, puis cinq pétales et le cœur.
      c.strokeStyle = metal(x, y, x + 60 * s, y + 140 * s);
      c.lineWidth = 6 * s;
      c.beginPath();
      c.moveTo(x + 8 * s, y + 30 * s);
      c.quadraticCurveTo(x + 40 * s, y + 90 * s, x + 18 * s, y + 140 * s);
      c.stroke();
      c.beginPath();
      c.moveTo(x + 30 * s, y + 82 * s);
      c.quadraticCurveTo(x + 92 * s, y + 58 * s, x + 104 * s, y + 100 * s);
      c.quadraticCurveTo(x + 62 * s, y + 114 * s, x + 30 * s, y + 82 * s);
      c.fillStyle = metal(x + 30 * s, y + 60 * s, x + 104 * s, y + 114 * s);
      c.fill();
      for (let k = 0; k < 5; k++) {
        const a = (k / 5) * TAU - Math.PI / 2;
        c.save();
        c.translate(x + Math.cos(a) * 42 * s, y + Math.sin(a) * 42 * s);
        c.rotate(a + Math.PI / 2);
        c.beginPath();
        c.ellipse(0, 0, 28 * s, 44 * s, 0, 0, TAU);
        c.fillStyle = metal(-28 * s, -44 * s, 28 * s, 44 * s);
        c.fill();
        c.lineWidth = 1.5 * s;
        c.strokeStyle = shade(jewel.metal, 0.4);
        c.stroke();
        c.lineWidth = 2 * s;
        c.strokeStyle = 'rgba(255,255,255,.5)';
        c.beginPath();
        c.ellipse(0, 0, 20 * s, 34 * s, 0, Math.PI * 1.1, Math.PI * 1.6);
        c.stroke();
        if (jewel.gem) for (let j = 0; j < 3; j++) accent(0, -22 * s + j * 15 * s, 4.5 * s);
        c.restore();
      }
      if (jewel.pearls) {
        // Broche de l'atelier : ses perles au cœur de la fleur.
        const count = Math.min(2, jewel.pearlColors?.length ?? 1);
        if (count > 1) {
          pearlDot(c, x - 13 * s, y + 2 * s, 17 * s, pearlAt(0));
          pearlDot(c, x + 13 * s, y - 2 * s, 17 * s, pearlAt(1));
        } else pearlDot(c, x, y, 22 * s, pearlAt(0));
      } else if (jewel.gem) mainGem(x, y, gemRadius(13, 12));
      else dome(x, y, 18 * s);
    } else if (style === 'libellule') {
      // Deux paires d'ailes ajourées, puis le corps.
      for (const side of [-1, 1]) {
        for (const [dy, len, rot] of [[-38, 128, -0.22], [-6, 108, 0.22]] as const) {
          const wx = x + side * (len / 2 + 6) * s;
          const wy = y + dy * s;
          c.beginPath();
          c.ellipse(wx, wy, (len / 2) * s, 21 * s, side * rot, 0, TAU);
          c.fillStyle = jewel.gem ? `${jewel.gem}44` : 'rgba(220,240,255,.28)';
          c.fill();
          c.lineWidth = 4 * s;
          c.strokeStyle = metal(wx - (len / 2) * s, wy - 21 * s, wx + (len / 2) * s, wy + 21 * s);
          c.stroke();
          c.lineWidth = 1.2 * s;
          c.strokeStyle = 'rgba(255,255,255,.45)';
          c.beginPath();
          c.moveTo(x + side * 8 * s, wy);
          c.lineTo(x + side * (len + 2) * s, wy + side * Math.tan(rot) * len * s * 0.4);
          c.stroke();
        }
      }
      for (let k = 0; k < 8; k++) {
        const r = (9 - k * 0.65) * s;
        const by = y + (14 + k * 15) * s;
        if (jewel.gem) accent(x, by, r);
        else dome(x, by, r);
      }
      if (jewel.gem) mainGem(x, y - 24 * s, gemRadius(11, 8));
      else dome(x, y - 24 * s, 15 * s);
      dome(x, y - 54 * s, 11 * s);
    } else {
      // Étoile de mer : cinq bras arrondis, picots ou petites pierres.
      const points: Point[] = Array.from({ length: 10 }, (_, i) => {
        const a = (i / 10) * TAU - Math.PI / 2;
        const r = (i % 2 ? 44 : 104) * s;
        return [x + Math.cos(a) * r, y + Math.sin(a) * r];
      });
      polygon(c, points);
      c.lineJoin = 'round';
      c.lineWidth = 16 * s;
      c.strokeStyle = metal(x - 104 * s, y - 104 * s, x + 104 * s, y + 104 * s);
      c.stroke();
      c.fillStyle = metal(x - 104 * s, y - 104 * s, x + 104 * s, y + 104 * s);
      c.fill();
      for (let arm = 0; arm < 5; arm++) {
        const a = (arm / 5) * TAU - Math.PI / 2;
        for (let k = 1; k <= 4; k++) {
          const px = x + Math.cos(a) * (18 + k * 18) * s;
          const py = y + Math.sin(a) * (18 + k * 18) * s;
          if (jewel.gem) accent(px, py, (6 - k * 0.6) * s);
          else dome(px, py, (6 - k * 0.7) * s);
        }
      }
      if (jewel.gem) mainGem(x, y, gemRadius(12, 10));
      else dome(x, y, 16 * s);
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
      drawGem(c, bx, by - height, (i === 0 ? 32 : 12) * s, i === 0 && jewel.gem ? jewel.gem : '#f2fbff', false, i === 0 ? jewel.cut : 'rond');
    }
    for (let k = 1; k < 20; k++) drawGem(c, ...q(k / 20), 5 * s, '#f2fbff', false, 'rond');
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
  const yOffset = jewelYOffset(jewel);
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
