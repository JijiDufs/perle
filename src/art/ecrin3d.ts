// L'écrin en 3D (Canvas 2D, sans bibliothèque) : un coffret de velours aux coins arrondis, vu de trois quarts.
// Base et couvercle sont des prismes ; le couvercle tourne vraiment sur sa charnière arrière avec le geste.
// Le velours est éclairé face par face (lumière du salon) avec l'éclat rasant propre au velours sur les arêtes.
import { goldGradient } from './jewel';

type Ctx = CanvasRenderingContext2D;
type V3 = [number, number, number];
type P2 = [number, number];

/** Proportions du coffret (unités du monde : largeur = 1). */
const W = 1;
const D = 0.74;
const H = 0.3; // hauteur de la base
const T = 0.17; // épaisseur du couvercle
const R = 0.13; // rayon des coins
const PITCH = (34 * Math.PI) / 180; // la caméra regarde un peu d'en haut
const DIST = 3.6;
/** Le couvercle s'ouvre jusqu'à ~130° quand le geste va jusqu'à 180°. */
export const LID_RATIO = 0.72;

// Lumière du salon : d'en haut, un peu de face et de la gauche.
const LIGHT: V3 = normalize([-0.35, 0.75, 0.62]);

function normalize(v: V3): V3 {
  const l = Math.hypot(...v);
  return [v[0] / l, v[1] / l, v[2] / l];
}

/** Contour du coffret vu de dessus (plan xz), coins arrondis, sens direct. */
function outline(inset = 0): [number, number][] {
  const pts: [number, number][] = [];
  const w = W / 2 - inset;
  const d = D / 2 - inset;
  const r = Math.max(0.01, R - inset);
  const corners: [number, number, number][] = [
    [w - r, d - r, 0],
    [-(w - r), d - r, Math.PI / 2],
    [-(w - r), -(d - r), Math.PI],
    [w - r, -(d - r), (3 * Math.PI) / 2],
  ];
  for (const [cx, cz, start] of corners) {
    for (let i = 0; i <= 6; i++) {
      const a = start + (i / 6) * (Math.PI / 2);
      pts.push([cx + Math.cos(a) * r, cz + Math.sin(a) * r]);
    }
  }
  return pts;
}

const OUTLINE = outline();
const CUSHION = outline(0.055);

export interface EcrinView {
  /** Centre de l'écran où poser le coffret, et sa largeur à l'écran. */
  cx: number;
  cy: number;
  width: number;
}

export interface EcrinStyle {
  velvet: string;
  /** Angle du geste (0…180) : le couvercle suit, à LID_RATIO près. */
  angle: number;
  /** Assombrissement de l'intérieur tant que l'écrin est peu ouvert (0…1). */
  dim: number;
  /** Dessin du bijou, posé dans la fente du coussin : (x, y, échelle). */
  drawJewel?: (x: number, y: number, scale: number) => void;
  /** Reflet qui passe sur le couvercle (pièces ★), position 0…1 ou null. */
  sweep: number | null;
}

export interface EcrinAnchors {
  /** Où se trouve le bijou à l'écran, et l'échelle du coffret (px par unité). */
  jewel: P2;
  scale: number;
  /** Bord avant du couvercle (d'où filtre la lumière), et pied du coffret (pour l'ombre). */
  lidEdge: P2;
  foot: P2;
}

let grainTile: HTMLCanvasElement | null = null;

/** Grain du velours : petit motif de bruit, posé en transparence sur chaque face. */
function grain(c: Ctx): CanvasPattern | null {
  if (!grainTile) {
    grainTile = document.createElement('canvas');
    grainTile.width = grainTile.height = 64;
    const g = grainTile.getContext('2d')!;
    const image = g.createImageData(64, 64);
    let seed = 7;
    for (let i = 0; i < 64 * 64; i++) {
      seed = (seed * 16807) % 2147483647;
      const v = seed / 2147483647;
      image.data[i * 4] = image.data[i * 4 + 1] = image.data[i * 4 + 2] = v > 0.5 ? 255 : 0;
      image.data[i * 4 + 3] = Math.round(Math.abs(v - 0.5) * 40);
    }
    g.putImageData(image, 0, 0);
  }
  return c.createPattern(grainTile, 'repeat');
}

function rgb(hex: string): V3 {
  const n = parseInt(hex.slice(1), 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}

/** Couleur d'une face de velours : lumière diffuse + éclat rasant (le velours brille de biais). */
function velvetShade(base: V3, normalCam: V3, boost = 0): string {
  const diffuse = Math.max(0, normalCam[0] * LIGHT[0] + normalCam[1] * LIGHT[1] + normalCam[2] * LIGHT[2]);
  const facing = Math.max(0, normalCam[2]);
  const sheen = Math.pow(1 - facing, 2.5) * 0.55;
  const k = 0.42 + 0.62 * diffuse + boost;
  const c = base.map((v) => Math.min(255, v * k + (255 - v * k) * sheen * 0.45));
  return `rgb(${c.map(Math.round).join(',')})`;
}

export function drawEcrin3D(c: Ctx, view: EcrinView, style: EcrinStyle): EcrinAnchors {
  const cosP = Math.cos(PITCH);
  const sinP = Math.sin(PITCH);
  const scale = view.width * (DIST - D / 2) * 0.98;
  const alpha = Math.min(180, Math.max(0, style.angle)) * LID_RATIO * (Math.PI / 180);
  const cosA = Math.cos(alpha);
  const sinA = Math.sin(alpha);

  const toCam = (p: V3): V3 => [p[0], p[1] * cosP - p[2] * sinP, p[1] * sinP + p[2] * cosP];
  // Le point (0, H/2, 0) au centre de la vue.
  const centre = toCam([0, H * 0.5, 0]);
  const project = (p: V3): P2 => {
    const q = toCam(p);
    const depth = DIST - q[2];
    return [view.cx + (scale * q[0]) / depth, view.cy - (scale * (q[1] - centre[1])) / depth];
  };
  const normalCam = (n: V3): V3 => toCam(n);
  // Couvercle : rotation autour de la charnière (y = H, z = -D/2).
  const lid = (p: V3): V3 => {
    const dy = p[1] - H;
    const dz = p[2] + D / 2;
    return [p[0], H + dy * cosA + dz * sinA, -D / 2 - dy * sinA + dz * cosA];
  };
  const lidN = (n: V3): V3 => [n[0], n[1] * cosA + n[2] * sinA, -n[1] * sinA + n[2] * cosA];

  const velvet = rgb(style.velvet);
  const texture = grain(c);
  const poly = (points: P2[]) => {
    c.beginPath();
    points.forEach(([x, y], i) => (i ? c.lineTo(x, y) : c.moveTo(x, y)));
    c.closePath();
  };

  /** Faces latérales d'un prisme (contour × hauteur), seulement celles tournées vers nous. */
  const drawSides = (y0: number, y1: number, transform: (p: V3) => V3, rotateN: (n: V3) => V3, trim: 'top' | 'bottom' | null) => {
    for (let i = 0; i < OUTLINE.length; i++) {
      const [x0, z0] = OUTLINE[i];
      const [x1, z1] = OUTLINE[(i + 1) % OUTLINE.length];
      const nx = z1 - z0;
      const nz = -(x1 - x0);
      const len = Math.hypot(nx, nz);
      const n = normalCam(rotateN([nx / len, 0, nz / len]));
      if (n[2] <= 0.01) continue;
      const quad = [transform([x0, y0, z0]), transform([x1, y0, z1]), transform([x1, y1, z1]), transform([x0, y1, z0])].map(project);
      poly(quad);
      c.fillStyle = velvetShade(velvet, n);
      c.fill();
      c.strokeStyle = c.fillStyle;
      c.lineWidth = 0.6;
      c.stroke();
      if (texture) {
        c.fillStyle = texture;
        c.fill();
      }
      if (trim) {
        // Filet d'or : en haut de la base (la jointure), en bas du couvercle.
        const ya = trim === 'top' ? y1 - 0.022 : y0;
        const yb = trim === 'top' ? y1 : y0 + 0.018;
        const band = [transform([x0, ya, z0]), transform([x1, ya, z1]), transform([x1, yb, z1]), transform([x0, yb, z0])].map(project);
        poly(band);
        const g = 0.55 + 0.45 * Math.max(0, n[0] * LIGHT[0] + n[1] * LIGHT[1] + n[2] * LIGHT[2]);
        c.fillStyle = `rgb(${Math.round(230 * g)},${Math.round(185 * g)},${Math.round(90 * g)})`;
        c.fill();
      }
    }
  };

  /** Dessine dans le plan d'une face (repère affine : origine, axe x, axe z du monde). */
  const inPlane = (origin: V3, ax: V3, az: V3, draw: () => void) => {
    const o = project(origin);
    const x = project([origin[0] + ax[0], origin[1] + ax[1], origin[2] + ax[2]]);
    const z = project([origin[0] + az[0], origin[1] + az[1], origin[2] + az[2]]);
    c.save();
    c.transform(x[0] - o[0], x[1] - o[1], z[0] - o[0], z[1] - o[1], o[0], o[1]);
    draw();
    c.restore();
  };

  // ---------- La base ----------
  const drawBase = () => {
    drawSides(0, H, (p) => p, (n) => n, 'top');
    // Fermoir doré sous la jointure, au milieu de la face avant.
    inPlane([0, H - 0.024, D / 2 + 0.002], [1, 0, 0], [0, -1, 0], () => {
      c.fillStyle = 'rgba(0,0,0,.35)';
      c.fillRect(-0.052, 0.006, 0.108, 0.082);
      c.fillStyle = goldGradient(c, -0.05, 0, 0.05, 0.08);
      c.beginPath();
      c.moveTo(-0.05, 0);
      c.lineTo(0.05, 0);
      c.lineTo(0.05, 0.06);
      c.quadraticCurveTo(0.05, 0.078, 0.032, 0.078);
      c.lineTo(-0.032, 0.078);
      c.quadraticCurveTo(-0.05, 0.078, -0.05, 0.06);
      c.closePath();
      c.fill();
      c.fillStyle = 'rgba(70, 45, 10, .7)';
      c.beginPath();
      c.arc(0, 0.035, 0.011, 0, Math.PI * 2);
      c.fill();
      c.fillRect(-0.004, 0.035, 0.008, 0.022);
    });
    // Le dessus de la base : rebord, puis coussin de velours (visible quand le couvercle se lève).
    const top = OUTLINE.map(([x, z]) => project([x, H, z]));
    poly(top);
    c.fillStyle = velvetShade(velvet, normalCam([0, 1, 0]), -0.15);
    c.fill();
    const cushion = CUSHION.map(([x, z]) => project([x, H - 0.012, z]));
    poly(cushion);
    const [ccx, ccy] = project([0, H, 0.02]);
    const g = c.createRadialGradient(ccx, ccy - scale * 0.05, 0, ccx, ccy, scale * 0.42);
    g.addColorStop(0, velvetShade(velvet, normalCam([0, 1, 0]), 0.25));
    g.addColorStop(1, velvetShade(velvet, normalCam([0, 1, 0]), -0.25));
    c.fillStyle = g;
    c.fill();
    // La fente du coussin, où le bijou est piqué.
    inPlane([0, H - 0.01, 0.04], [1, 0, 0], [0, 0, 1], () => {
      c.strokeStyle = 'rgba(0,0,0,.55)';
      c.lineWidth = 0.012;
      c.beginPath();
      c.moveTo(-0.16, 0);
      c.quadraticCurveTo(0, 0.025, 0.16, 0);
      c.stroke();
      c.strokeStyle = 'rgba(255,255,255,.12)';
      c.lineWidth = 0.006;
      c.beginPath();
      c.moveTo(-0.15, 0.012);
      c.quadraticCurveTo(0, 0.035, 0.15, 0.012);
      c.stroke();
    });
  };

  const jewelAt = project([0, H + 0.02, 0.04]);
  const jewelDepth = DIST - toCam([0, H, 0.04])[2];
  const pxPerUnit = scale / jewelDepth;

  const drawInterior = () => {
    // Le bijou ne sort pas de la boîte : il reste dans le coin ouvert entre le rebord de la base et le dessous
    // du couvercle (fermé, rien ne dépasse ; à mi-ouverture, rien ne passe au-dessus du couvercle).
    const hull = convexHull([...OUTLINE.map(([x, z]) => project([x, H, z])), ...OUTLINE.map(([x, z]) => project(lid([x, H, z])))]);
    c.save();
    poly(hull);
    c.clip();
    style.drawJewel?.(jewelAt[0], jewelAt[1], pxPerUnit);
    c.restore();
    if (style.dim > 0.001) {
      poly(OUTLINE.map(([x, z]) => project([x, H, z])));
      c.fillStyle = `rgba(0,0,0,${style.dim * 0.92})`;
      c.fill();
    }
  };

  // ---------- Le couvercle ----------
  const drawLid = () => {
    drawSides(H, H + T, lid, lidN, 'bottom');
    const topN = normalCam(lidN([0, 1, 0]));
    if (topN[2] > 0.01) {
      const top = OUTLINE.map(([x, z]) => project(lid([x, H + T, z])));
      poly(top);
      c.fillStyle = velvetShade(velvet, topN);
      c.fill();
      if (texture) {
        c.fillStyle = texture;
        c.fill();
      }
      // Arête arrondie du couvercle qui accroche la lumière.
      c.strokeStyle = 'rgba(255,255,255,.22)';
      c.lineWidth = Math.max(1, scale * 0.004);
      c.stroke();
      // Le dessus bombe : reflet doux vers la lumière, bords qui s'assombrissent.
      const [tx, ty] = project(lid([-0.08, H + T, -0.06]));
      const g = c.createRadialGradient(tx, ty, 0, tx, ty, scale * 0.42);
      g.addColorStop(0, 'rgba(255,255,255,.2)');
      g.addColorStop(1, 'rgba(255,255,255,0)');
      c.fillStyle = g;
      poly(top);
      c.fill();
      if (style.sweep !== null) {
        const [ax, ay] = top[0];
        const [bx, by] = top[Math.floor(top.length / 2)];
        const sweep = c.createLinearGradient(bx, by, ax, ay);
        const at = (v: number) => Math.min(1, Math.max(0, v));
        sweep.addColorStop(at(style.sweep - 0.1), 'rgba(255,240,180,0)');
        sweep.addColorStop(at(style.sweep), 'rgba(255,240,180,.5)');
        sweep.addColorStop(at(style.sweep + 0.1), 'rgba(255,240,180,0)');
        c.fillStyle = sweep;
        poly(top);
        c.fill();
      }
      // Monogramme : une perle sertie dans un anneau d'or, au centre du couvercle.
      inPlane(lid([0, H + T + 0.002, 0]), lidN([1, 0, 0]), lidN([0, 0, 1]), () => {
        c.fillStyle = 'rgba(0,0,0,.28)';
        c.beginPath();
        c.ellipse(0.006, 0.01, 0.105, 0.105, 0, 0, Math.PI * 2);
        c.fill();
        c.lineWidth = 0.022;
        c.strokeStyle = goldGradient(c, -0.1, -0.1, 0.1, 0.1);
        c.beginPath();
        c.arc(0, 0, 0.088, 0, Math.PI * 2);
        c.stroke();
        const pearl = c.createRadialGradient(-0.02, -0.022, 0.004, 0, 0, 0.055);
        pearl.addColorStop(0, '#ffffff');
        pearl.addColorStop(0.45, '#f1e9dd');
        pearl.addColorStop(1, '#a69a8a');
        c.fillStyle = pearl;
        c.beginPath();
        c.arc(0, 0, 0.055, 0, Math.PI * 2);
        c.fill();
      });
    }
    // L'intérieur du couvercle (satin crème), quand il est assez relevé pour qu'on le voie.
    const innerN = normalCam(lidN([0, -1, 0]));
    if (innerN[2] > 0.01) {
      const inner = OUTLINE.map(([x, z]) => project(lid([x, H, z])));
      poly(inner);
      const k = 0.55 + 0.45 * Math.max(0, innerN[0] * LIGHT[0] + innerN[1] * LIGHT[1] + innerN[2] * LIGHT[2]);
      c.fillStyle = `rgb(${Math.round(246 * k)},${Math.round(236 * k)},${Math.round(218 * k)})`;
      c.fill();
      const pad = CUSHION.map(([x, z]) => project(lid([x, H - 0.001, z])));
      poly(pad);
      c.strokeStyle = 'rgba(184, 138, 42, .8)';
      c.lineWidth = Math.max(1, scale * 0.004);
      c.stroke();
      inPlane(lid([0, H - 0.002, 0.02]), lidN([1, 0, 0]), lidN([0, 0, -1]), () => {
        // Texte en millièmes d'unité : les polices de moins d'un pixel ne s'affichent pas partout.
        c.scale(0.001, 0.001);
        c.fillStyle = goldGradient(c, -200, 0, 200, 0);
        c.textAlign = 'center';
        c.textBaseline = 'middle';
        c.font = '600 38px "Figtree", system-ui, sans-serif';
        c.fillText('MAISON ROSE', 0, -50);
        c.font = '75px "Young Serif", Georgia, serif';
        c.fillText('Perles fines', 0, 30);
      });
    }
  };

  // Ordre de dessin :
  // - tant qu'on voit le dessus du couvercle (il n'a pas dépassé l'angle de la caméra), il recouvre le bijou ;
  // - dès qu'on voit son satin, le bijou est devant lui ;
  // - au-delà de la verticale, le couvercle passe derrière la base.
  if (alpha < PITCH) {
    drawBase();
    drawInterior();
    drawLid();
  } else if (alpha < Math.PI / 2) {
    drawBase();
    drawLid();
    drawInterior();
  } else {
    drawLid();
    drawBase();
    drawInterior();
  }

  return {
    jewel: jewelAt,
    scale: pxPerUnit,
    lidEdge: project(lid([0, H, D / 2])),
    foot: project([0, 0, 0]),
  };
}

/** Ombre du coffret sur la table, sous son empreinte (à dessiner avant le coffret). */
export function drawEcrinShadow(c: Ctx, view: EcrinView): void {
  const cosP = Math.cos(PITCH);
  const sinP = Math.sin(PITCH);
  const scale = view.width * (DIST - D / 2) * 0.98;
  const toCam = (p: V3): V3 => [p[0], p[1] * cosP - p[2] * sinP, p[1] * sinP + p[2] * cosP];
  const centre = toCam([0, H * 0.5, 0]);
  const project = (p: V3): P2 => {
    const q = toCam(p);
    const depth = DIST - q[2];
    return [view.cx + (scale * q[0]) / depth, view.cy - (scale * (q[1] - centre[1])) / depth];
  };
  const pts = OUTLINE.map(([x, z]) => project([x * 1.08, 0, z * 1.08 + 0.03]));
  const xs = pts.map((p) => p[0]);
  const ys = pts.map((p) => p[1]);
  const cx = (Math.min(...xs) + Math.max(...xs)) / 2;
  const cy = (Math.min(...ys) + Math.max(...ys)) / 2;
  const rx = (Math.max(...xs) - Math.min(...xs)) / 2;
  const ry = (Math.max(...ys) - Math.min(...ys)) / 2;
  const g = c.createRadialGradient(0, 0, 0, 0, 0, 1);
  g.addColorStop(0, 'rgba(8, 0, 4, 0.75)');
  g.addColorStop(0.65, 'rgba(8, 0, 4, 0.45)');
  g.addColorStop(1, 'rgba(8, 0, 4, 0)');
  c.save();
  c.translate(cx, cy);
  c.scale(rx * 1.15, ry * 1.25);
  c.fillStyle = g;
  c.beginPath();
  c.arc(0, 0, 1, 0, Math.PI * 2);
  c.fill();
  c.restore();
}

/** Enveloppe convexe de points (chaîne monotone). */
function convexHull(points: P2[]): P2[] {
  const pts = [...points].sort((a, b) => a[0] - b[0] || a[1] - b[1]);
  const cross = (o: P2, a: P2, b: P2) => (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0]);
  const lower: P2[] = [];
  for (const p of pts) {
    while (lower.length >= 2 && cross(lower[lower.length - 2], lower[lower.length - 1], p) <= 0) lower.pop();
    lower.push(p);
  }
  const upper: P2[] = [];
  for (const p of pts.reverse()) {
    while (upper.length >= 2 && cross(upper[upper.length - 2], upper[upper.length - 1], p) <= 0) upper.pop();
    upper.push(p);
  }
  return [...lower.slice(0, -1), ...upper.slice(0, -1)];
}
