// L'écrin en 3D (Canvas 2D, sans bibliothèque) : un écrin plat de joaillier en cuir, vu de trois quarts
// (piste D choisie par Jules). Base et couvercle sont des prismes aux coins à peine arrondis ; le couvercle
// s'ouvre comme un livre, sur sa charnière arrière, avec le geste. Cuir lisse éclairé face par face
// (diffus + reflet satiné), dorures poussées au fer sur le dessus, filet d'or sur la tranche, fermoir à poussoir.
import { goldGradient } from './jewel';

type Ctx = CanvasRenderingContext2D;
type V3 = [number, number, number];
type P2 = [number, number];

/** Proportions de l'étui (unités du monde : largeur = 1). */
const W = 1;
const D = 0.78;
const H = 0.11; // hauteur de la base
const T = 0.085; // épaisseur du couvercle
const R = 0.045; // rayon des coins
const PITCH = (46 * Math.PI) / 180; // vu d'assez haut : on voit bien le dessus
const DIST = 3.4;
/** Le couvercle s'ouvre jusqu'à ~115° quand le geste va jusqu'à 180°. */
export const LID_RATIO = 0.64;

// Lumière du salon : d'en haut, un peu de face et de la gauche. Demi-vecteur pour le reflet du cuir.
const LIGHT: V3 = normalize([-0.4, 0.78, 0.48]);
const HALF: V3 = normalize([LIGHT[0], LIGHT[1], LIGHT[2] + 1]);

function normalize(v: V3): V3 {
  const l = Math.hypot(...v);
  return [v[0] / l, v[1] / l, v[2] / l];
}

const dot = (a: V3, b: V3) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2];

/** Contour de l'étui vu de dessus (plan xz), coins arrondis, sens direct. */
function outline(inset = 0): [number, number][] {
  const pts: [number, number][] = [];
  const w = W / 2 - inset;
  const d = D / 2 - inset;
  const r = Math.max(0.008, R - inset * 0.5);
  const corners: [number, number, number][] = [
    [w - r, d - r, 0],
    [-(w - r), d - r, Math.PI / 2],
    [-(w - r), -(d - r), Math.PI],
    [w - r, -(d - r), (3 * Math.PI) / 2],
  ];
  for (const [cx, cz, start] of corners) {
    for (let i = 0; i <= 5; i++) {
      const a = start + (i / 5) * (Math.PI / 2);
      pts.push([cx + Math.cos(a) * r, cz + Math.sin(a) * r]);
    }
  }
  return pts;
}

const OUTLINE = outline();
const TRAY = outline(0.05);

export interface EcrinView {
  /** Centre de l'écran où poser l'écrin, et sa largeur à l'écran. */
  cx: number;
  cy: number;
  width: number;
}

export interface EcrinStyle {
  /** Couleur du cuir. */
  leather: string;
  /** Angle du geste (0…180) : le couvercle suit, à LID_RATIO près. */
  angle: number;
  /** Assombrissement de l'intérieur tant que l'écrin est peu ouvert (0…1). */
  dim: number;
  /**
   * Dessin du bijou, couché à plat sur le plateau : appelé dans le repère du plateau (origine au centre,
   * 1 = largeur de l'écrin, y vers l'avant). Il suffit de dessiner le bijou vu de dessus, centré en (0, 0).
   */
  drawJewel?: () => void;
  /** Lumière et étincelles au-dessus du bijou, à l'écran : (x, y, px par unité). */
  drawEffects?: (x: number, y: number, unit: number) => void;
  /** Reflet qui passe sur le couvercle (pièces ★), position 0…1 ou null. */
  sweep: number | null;
}

export interface EcrinAnchors {
  /** Où se trouve le bijou à l'écran, et l'échelle (px par unité). */
  jewel: P2;
  scale: number;
  /** Bord avant du couvercle (d'où filtre la lumière). */
  lidEdge: P2;
}

function rgb(hex: string): V3 {
  const n = parseInt(hex.slice(1), 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}

/** Cuir lisse : lumière diffuse + reflet satiné (un peu de brillance, sans être verni). */
function leatherShade(base: V3, n: V3, boost = 0): string {
  const diffuse = Math.max(0, dot(n, LIGHT));
  const spec = Math.pow(Math.max(0, dot(n, HALF)), 22) * 0.4;
  const k = 0.3 + 0.5 * diffuse + boost;
  const c = base.map((v) => Math.min(255, v * k + 255 * spec));
  return `rgb(${c.map(Math.round).join(',')})`;
}

let grainTile: HTMLCanvasElement | null = null;

/** Grain du cuir : petits pores, posés en transparence sur chaque face. */
function grain(c: Ctx): CanvasPattern | null {
  if (!grainTile) {
    grainTile = document.createElement('canvas');
    grainTile.width = grainTile.height = 96;
    const g = grainTile.getContext('2d')!;
    let seed = 11;
    const rand = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
    for (let i = 0; i < 900; i++) {
      const dark = rand() > 0.35;
      g.fillStyle = dark ? `rgba(0,0,0,${0.03 + rand() * 0.04})` : `rgba(255,255,255,${0.015 + rand() * 0.02})`;
      g.beginPath();
      g.arc(rand() * 96, rand() * 96, 0.4 + rand() * 0.9, 0, Math.PI * 2);
      g.fill();
    }
  }
  return c.createPattern(grainTile, 'repeat');
}

export function drawEcrin3D(c: Ctx, view: EcrinView, style: EcrinStyle): EcrinAnchors {
  const cosP = Math.cos(PITCH);
  const sinP = Math.sin(PITCH);
  const scale = view.width * (DIST - D / 2) * 0.98;
  const alpha = Math.min(180, Math.max(0, style.angle)) * LID_RATIO * (Math.PI / 180);
  const cosA = Math.cos(alpha);
  const sinA = Math.sin(alpha);

  const toCam = (p: V3): V3 => [p[0], p[1] * cosP - p[2] * sinP, p[1] * sinP + p[2] * cosP];
  const centre = toCam([0, H * 0.5, 0]);
  const project = (p: V3): P2 => {
    const q = toCam(p);
    const depth = DIST - q[2];
    return [view.cx + (scale * q[0]) / depth, view.cy - (scale * (q[1] - centre[1])) / depth];
  };
  const normalCam = (n: V3): V3 => toCam(n);
  /**
   * Une face est visible si elle regarde vers l'œil (placé en (0, centre, DIST) dans le repère caméra).
   * Test fait depuis la vraie position de l'œil, pas « de très loin » : sinon, en perspective, un couvercle
   * vu presque par la tranche perdait ses deux faces et l'on voyait à travers.
   */
  const facing = (nCam: V3, pointWorld: V3): boolean => {
    const q = toCam(pointWorld);
    return -q[0] * nCam[0] + (centre[1] - q[1]) * nCam[1] + (DIST - q[2]) * nCam[2] > 0;
  };
  // Couvercle : rotation autour de la charnière (y = H, z = -D/2).
  const lid = (p: V3): V3 => {
    const dy = p[1] - H;
    const dz = p[2] + D / 2;
    return [p[0], H + dy * cosA + dz * sinA, -D / 2 - dy * sinA + dz * cosA];
  };
  const lidN = (n: V3): V3 => [n[0], n[1] * cosA + n[2] * sinA, -n[1] * sinA + n[2] * cosA];

  const leather = rgb(style.leather);
  const texture = grain(c);
  const poly = (points: P2[]) => {
    c.beginPath();
    points.forEach(([x, y], i) => (i ? c.lineTo(x, y) : c.moveTo(x, y)));
    c.closePath();
  };
  const withGrain = () => {
    if (!texture) return;
    c.fillStyle = texture;
    c.fill();
  };

  /** Dessine dans le plan d'une face (repère affine : origine, axe x, axe z de la face). */
  const inPlane = (origin: V3, ax: V3, az: V3, draw: () => void) => {
    // Repère affine tangent au point d'origine (différences centrées) : juste autour de l'origine,
    // même en perspective forte.
    const e = 0.1;
    const along = (v: V3, k: number): V3 => [origin[0] + v[0] * k, origin[1] + v[1] * k, origin[2] + v[2] * k];
    const o = project(origin);
    const [x1, x0] = [project(along(ax, e)), project(along(ax, -e))];
    const [z1, z0] = [project(along(az, e)), project(along(az, -e))];
    c.save();
    c.transform((x1[0] - x0[0]) / (2 * e), (x1[1] - x0[1]) / (2 * e), (z1[0] - z0[0]) / (2 * e), (z1[1] - z0[1]) / (2 * e), o[0], o[1]);
    draw();
    c.restore();
  };

  /** Tranches d'un prisme (contour × hauteur), seulement celles tournées vers nous, avec un filet d'or. */
  const drawSides = (y0: number, y1: number, transform: (p: V3) => V3, rotateN: (n: V3) => V3, filet: number) => {
    for (let i = 0; i < OUTLINE.length; i++) {
      const [x0, z0] = OUTLINE[i];
      const [x1, z1] = OUTLINE[(i + 1) % OUTLINE.length];
      const nx = z1 - z0;
      const nz = -(x1 - x0);
      const len = Math.hypot(nx, nz);
      const n = normalCam(rotateN([nx / len, 0, nz / len]));
      if (!facing(n, transform([(x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2]))) continue;
      poly([transform([x0, y0, z0]), transform([x1, y0, z1]), transform([x1, y1, z1]), transform([x0, y1, z0])].map(project));
      c.fillStyle = leatherShade(leather, n, -0.12);
      c.fill();
      c.strokeStyle = c.fillStyle;
      c.lineWidth = 0.6;
      c.stroke();
      withGrain();
      // Filet d'or poussé sur la tranche.
      const ya = filet - 0.005;
      const yb = filet + 0.005;
      poly([transform([x0, ya, z0]), transform([x1, ya, z1]), transform([x1, yb, z1]), transform([x0, yb, z0])].map(project));
      const g = 0.5 + 0.5 * Math.max(0, dot(n, LIGHT));
      c.fillStyle = `rgb(${Math.round(236 * g)},${Math.round(192 * g)},${Math.round(98 * g)})`;
      c.fill();
    }
  };

  // ---------- La base ----------
  const drawBase = () => {
    drawSides(0, H, (p) => p, (n) => n, H * 0.45);
    // Fermoir à poussoir, au milieu de la tranche avant.
    inPlane([0, H * 0.82, D / 2 + 0.002], [1, 0, 0], [0, -1, 0], () => {
      c.fillStyle = 'rgba(0,0,0,.35)';
      c.fillRect(-0.045, 0.004, 0.092, 0.07);
      c.fillStyle = goldGradient(c, -0.045, 0, 0.045, 0.06);
      c.beginPath();
      c.moveTo(-0.045, 0);
      c.lineTo(0.045, 0);
      c.lineTo(0.045, 0.05);
      c.quadraticCurveTo(0.045, 0.064, 0.03, 0.064);
      c.lineTo(-0.03, 0.064);
      c.quadraticCurveTo(-0.045, 0.064, -0.045, 0.05);
      c.closePath();
      c.fill();
      c.fillStyle = 'rgba(255, 248, 220, .55)';
      c.fillRect(-0.038, 0.006, 0.076, 0.008);
    });
    // Le dessus de la base : bord de cuir, puis plateau de velours sombre, légèrement en creux.
    poly(OUTLINE.map(([x, z]) => project([x, H, z])));
    c.fillStyle = leatherShade(leather, normalCam([0, 1, 0]), -0.2);
    c.fill();
    poly(TRAY.map(([x, z]) => project([x, H - 0.006, z])));
    const [tx, ty] = project([0, H, 0]);
    const pad = c.createRadialGradient(tx, ty - scale * 0.05, 0, tx, ty, scale * 0.4);
    pad.addColorStop(0, '#2b2f45');
    pad.addColorStop(1, '#0d0f1a');
    c.fillStyle = pad;
    c.fill();
    c.strokeStyle = 'rgba(0,0,0,.55)';
    c.lineWidth = Math.max(1, scale * 0.004);
    c.stroke();
  };

  // Le bijou est couché au milieu du plateau, un peu vers l'avant.
  const jewelOrigin: V3 = [0, H - 0.004, 0.03];
  const jewelAt = project(jewelOrigin);
  const pxPerUnit = scale / (DIST - toCam(jewelOrigin)[2]);

  const drawInterior = () => {
    // Le bijou reste dans le coin ouvert entre le bord de la base et le dessous du couvercle.
    const hull = convexHull([...OUTLINE.map(([x, z]) => project([x, H, z])), ...OUTLINE.map(([x, z]) => project(lid([x, H, z])))]);
    c.save();
    poly(hull);
    c.clip();
    if (style.drawJewel) inPlane(jewelOrigin, [1, 0, 0], [0, 0, 1], style.drawJewel);
    style.drawEffects?.(jewelAt[0], jewelAt[1], pxPerUnit);
    if (style.dim > 0.001) {
      poly(OUTLINE.map(([x, z]) => project([x, H, z])));
      c.fillStyle = `rgba(0,0,0,${style.dim * 0.92})`;
      c.fill();
    }
    c.restore();
  };

  // ---------- Le couvercle ----------
  const drawLid = () => {
    drawSides(H, H + T, lid, lidN, H + T * 0.5);
    const topN = normalCam(lidN([0, 1, 0]));
    if (facing(topN, lid([0, H + T, 0]))) {
      const top = OUTLINE.map(([x, z]) => project(lid([x, H + T, z])));
      poly(top);
      c.fillStyle = leatherShade(leather, topN);
      c.fill();
      withGrain();
      // Le dessus est à peine rembourré : reflet doux, un peu décalé vers la lumière.
      const [hx, hy] = project(lid([-0.1, H + T, -0.08]));
      const sheen = c.createRadialGradient(hx, hy, 0, hx, hy, scale * 0.38);
      sheen.addColorStop(0, 'rgba(255,255,255,.16)');
      sheen.addColorStop(1, 'rgba(255,255,255,0)');
      c.fillStyle = sheen;
      poly(top);
      c.fill();
      if (style.sweep !== null) {
        const [ax, ay] = top[0];
        const [bx, by] = top[Math.floor(top.length / 2)];
        const sweep = c.createLinearGradient(bx, by, ax, ay);
        const at = (v: number) => Math.min(1, Math.max(0, v));
        sweep.addColorStop(at(style.sweep - 0.1), 'rgba(255,240,180,0)');
        sweep.addColorStop(at(style.sweep), 'rgba(255,240,180,.45)');
        sweep.addColorStop(at(style.sweep + 0.1), 'rgba(255,240,180,0)');
        c.fillStyle = sweep;
        poly(top);
        c.fill();
      }
      // Arête du couvercle qui accroche la lumière.
      poly(top);
      c.strokeStyle = 'rgba(255,255,255,.2)';
      c.lineWidth = Math.max(1, scale * 0.003);
      c.stroke();

      // Dorures poussées au fer : double filet, fleurons d'angle, cartouche à la perle, « Pearl Inc. ».
      // Tracées point par point en vraie perspective (une transformation affine les ferait déborder du cuir).
      const origin = lid([0, H + T + 0.001, 0]);
      const ax = lidN([1, 0, 0]);
      const az = lidN([0, 0, 1]);
      const at = (u: number, v: number): P2 => project([origin[0] + ax[0] * u + az[0] * v, origin[1] + ax[1] * u + az[1] * v, origin[2] + ax[2] * u + az[2] * v]);
      const unit = Math.hypot(at(1, 0)[0] - at(0, 0)[0], at(1, 0)[1] - at(0, 0)[1]);
      const [gx0, gy0] = at(-W / 2, -D / 2);
      const [gx1, gy1] = at(W / 2, D / 2);
      const gold = goldGradient(c, gx0, gy0, gx1, gy1);
      c.strokeStyle = gold;
      c.fillStyle = gold;
      c.lineJoin = 'round';
      c.lineCap = 'round';
      const trace = (points: [number, number][], closed: boolean, width: number) => {
        c.beginPath();
        points.forEach(([u, v], i) => (i ? c.lineTo(...at(u, v)) : c.moveTo(...at(u, v))));
        if (closed) c.closePath();
        c.lineWidth = Math.max(0.6, width * unit);
        c.stroke();
      };
      const rect = (inset: number): [number, number][] => [
        [-W / 2 + inset, -D / 2 + inset],
        [W / 2 - inset, -D / 2 + inset],
        [W / 2 - inset, D / 2 - inset],
        [-W / 2 + inset, D / 2 - inset],
      ];
      trace(rect(0.045), true, 0.008);
      trace(rect(0.065), true, 0.004);
      // Fleurons d'angle : deux volutes et une perle d'or.
      const quad = (p0: [number, number], p1: [number, number], p2: [number, number]): [number, number][] =>
        Array.from({ length: 9 }, (_, i) => {
          const t = i / 8;
          return [(1 - t) * (1 - t) * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0], (1 - t) * (1 - t) * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]];
        });
      for (const [sx, sy] of [[1, 1], [-1, 1], [1, -1], [-1, -1]] as const) {
        const ox = sx * (-W / 2 + 0.08);
        const oy = sy * (-D / 2 + 0.08);
        const k = 0.07;
        const p = (u: number, v: number): [number, number] => [ox + sx * u * k, oy + sy * v * k];
        trace(quad(p(0, 1), p(0, 0), p(1, 0)), false, 0.006);
        trace(quad(p(0.18, 0.75), p(0.35, 0.35), p(0.75, 0.18)), false, 0.005);
        const [dx, dy] = at(...p(0.3, 0.3));
        c.beginPath();
        c.arc(dx, dy, Math.max(1, 0.007 * unit), 0, Math.PI * 2);
        c.fill();
      }
      // Cartouche ovale (deux anneaux) et perle sertie.
      const ellipse = (rx: number, ry: number): [number, number][] =>
        Array.from({ length: 40 }, (_, i) => [Math.cos((i / 40) * Math.PI * 2) * rx, -0.03 + Math.sin((i / 40) * Math.PI * 2) * ry]);
      trace(ellipse(0.085, 0.07), true, 0.012);
      trace(ellipse(0.1, 0.085), true, 0.004);
      inPlane(lid([0, H + T + 0.002, -0.03]), ax, az, () => {
        const pearl = c.createRadialGradient(-0.016, -0.02, 0.003, 0, 0, 0.042);
        pearl.addColorStop(0, '#ffffff');
        pearl.addColorStop(0.45, '#f1e9dd');
        pearl.addColorStop(1, '#a69a8a');
        c.fillStyle = pearl;
        c.beginPath();
        c.arc(0, 0, 0.042, 0, Math.PI * 2);
        c.fill();
      });
      // Lettres d'or (repère local à l'endroit du texte, en millièmes d'unité :
      // les polices de moins d'un pixel ne s'affichent pas partout).
      inPlane(lid([0, H + T + 0.002, 0.115]), ax, az, () => {
        c.scale(0.001, 0.001);
        c.fillStyle = goldGradient(c, -150, 0, 150, 0);
        c.textAlign = 'center';
        c.textBaseline = 'middle';
        c.font = '600 36px "Figtree", system-ui, sans-serif';
        c.fillText('M A I S O N   R O S E', 0, 0);
      });
    }
    // L'intérieur du couvercle : capitonnage de velours (comme le plateau), avec le nom de la Maison en or.
    // Volontairement différent du dessus (cuir et filets d'or) : on ne doit jamais croire voir à travers.
    const innerN = normalCam(lidN([0, -1, 0]));
    if (facing(innerN, lid([0, H, 0]))) {
      const inner = OUTLINE.map(([x, z]) => project(lid([x, H, z])));
      poly(inner);
      c.fillStyle = leatherShade(leather, innerN, -0.15);
      c.fill();
      const lining = TRAY.map(([x, z]) => project(lid([x, H - 0.004, z])));
      poly(lining);
      const k = 0.55 + 0.45 * Math.max(0, dot(innerN, LIGHT));
      const [lx, ly] = project(lid([0, H, 0]));
      const velvet = c.createRadialGradient(lx, ly, 0, lx, ly, scale * 0.42);
      velvet.addColorStop(0, `rgb(${Math.round(52 * k)},${Math.round(58 * k)},${Math.round(86 * k)})`);
      velvet.addColorStop(1, `rgb(${Math.round(16 * k)},${Math.round(18 * k)},${Math.round(30 * k)})`);
      c.fillStyle = velvet;
      c.fill();
      // Capitons : coutures en losanges et petits boutons.
      const io = lid([0, H - 0.005, 0]);
      const ix = lidN([1, 0, 0]);
      const iz = lidN([0, 0, -1]);
      const iat = (u: number, v: number): P2 => project([io[0] + ix[0] * u + iz[0] * v, io[1] + ix[1] * u + iz[1] * v, io[2] + ix[2] * u + iz[2] * v]);
      c.save();
      poly(lining);
      c.clip();
      c.strokeStyle = 'rgba(0, 0, 0, 0.45)';
      c.lineWidth = Math.max(0.8, scale * 0.0025);
      const step = 0.14;
      for (let d = -1.2; d <= 1.2; d += step) {
        c.beginPath();
        c.moveTo(...iat(d - 0.4, -0.4));
        c.lineTo(...iat(d + 0.4, 0.4));
        c.moveTo(...iat(d + 0.4, -0.4));
        c.lineTo(...iat(d - 0.4, 0.4));
        c.stroke();
      }
      c.fillStyle = 'rgba(255, 255, 255, 0.18)';
      for (let u = -0.42; u <= 0.42; u += step) {
        for (let v = -0.35; v <= 0.35; v += step) {
          const [bx, by] = iat(u, v);
          c.beginPath();
          c.arc(bx, by, Math.max(0.8, scale * 0.003), 0, Math.PI * 2);
          c.fill();
        }
      }
      c.restore();
      // Le nom de la Maison, sur un petit écusson de satin.
      inPlane(lid([0, H - 0.006, 0.02]), ix, iz, () => {
        c.fillStyle = 'rgba(245, 236, 218, 0.95)';
        c.beginPath();
        c.ellipse(0, 0, 0.17, 0.075, 0, 0, Math.PI * 2);
        c.fill();
        c.strokeStyle = goldGradient(c, -0.17, 0, 0.17, 0);
        c.lineWidth = 0.006;
        c.stroke();
        c.scale(0.001, 0.001);
        c.fillStyle = goldGradient(c, -150, 0, 150, 0);
        c.textAlign = 'center';
        c.textBaseline = 'middle';
        c.font = '600 22px "Figtree", system-ui, sans-serif';
        c.fillText('P E A R L   I N C .', 0, -18);
        c.font = '40px "Young Serif", Georgia, serif';
        c.fillText('Perles fines', 0, 22);
      });
    }
  };

  // Ordre de dessin :
  // - tant qu'on voit le dessus du couvercle (il n'a pas dépassé l'angle de la caméra), il recouvre le bijou ;
  // - dès qu'on voit son satin, le bijou est devant lui ;
  // - au-delà de la verticale, le couvercle passe derrière la base.
  if (facing(normalCam(lidN([0, 1, 0])), lid([0, H + T, 0]))) {
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

  return { jewel: jewelAt, scale: pxPerUnit, lidEdge: project(lid([0, H, D / 2])) };
}

/** Ombre de l'étui sur la table, sous son empreinte (à dessiner avant l'étui). */
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
  const pts = OUTLINE.map(([x, z]) => project([x * 1.06, 0, z * 1.06 + 0.04]));
  const xs = pts.map((p) => p[0]);
  const ys = pts.map((p) => p[1]);
  const cx = (Math.min(...xs) + Math.max(...xs)) / 2;
  const cy = (Math.min(...ys) + Math.max(...ys)) / 2;
  const rx = (Math.max(...xs) - Math.min(...xs)) / 2;
  const ry = (Math.max(...ys) - Math.min(...ys)) / 2;
  const g = c.createRadialGradient(0, 0, 0, 0, 0, 1);
  g.addColorStop(0, 'rgba(8, 0, 4, 0.7)');
  g.addColorStop(0.7, 'rgba(8, 0, 4, 0.4)');
  g.addColorStop(1, 'rgba(8, 0, 4, 0)');
  c.save();
  c.translate(cx, cy);
  c.scale(rx * 1.12, ry * 1.2);
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
