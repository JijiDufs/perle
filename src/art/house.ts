// La Maison en maison de poupée, vue en coupe de trois quarts (Canvas 2D) : la façade est ouverte,
// on voit l'intérieur des pièces. Elle grandit avec le rang (cabane → Pearl Inc. → haute joaillerie)
// et chaque lettre de Rose restaure un élément (porte, lanterne, enseigne, fenêtre et carnet, établi,
// vitrine, boîte). Projection oblique : un pas vers le fond décale le dessin à droite et vers le haut.
// Le décor fixe est dessiné une fois (cache) ; lumières, eau, fumée et étoiles s'animent par-dessus.
import type { HouseBrand, HouseFeature } from '../core/house';
import { SANS, SERIF } from './cardStyle';
import { rgba, shade, tint } from './color';

type Ctx = CanvasRenderingContext2D;
type Pt = [number, number];

export interface HouseScene {
  restored: ReadonlySet<HouseFeature>;
  /** Enseigne peinte : Maison Rose, puis Pearl Inc. */
  brand: HouseBrand;
  /** Étape de la Maison (core/house.ts, houseStage) : 0 cabane … 5 haute joaillerie. */
  stage: number;
  /** Plus belle pièce, posée dans la vitrine (déjà dessinée). */
  showcase: HTMLCanvasElement | null;
  /** Élément tout juste restauré et avancement de son apparition (0…1), pour l'éclat. */
  appearing: { feature: HouseFeature; progress: number } | null;
}

/** Haut du ciel : l'écran le peint aussi au-dessus de la scène, derrière le titre. */
export const HOUSE_SKY_TOP = '#081422';

const TAU = Math.PI * 2;
/** Décalage à l'écran d'un pas vers le fond (en unités du monde : 1 ≈ la largeur d'une pièce). */
const KX = 0.5;
const KY = 0.34;
const DEPTH = 0.62;
const WALL = 0.05;
const GROUND_H = 0.74;
const FLOOR_H = 0.64;
const ROOF_H = 0.5;
/** Limite entre les deux pièces d'un étage (la boutique est un peu plus large que l'atelier). */
const SPLIT = 1.06;

type RoomKind = 'boutique' | 'atelier' | 'bureau' | 'grenier' | 'salon' | 'musee';

interface Room {
  kind: RoomKind;
  x: number;
  y: number;
  w: number;
  h: number;
}

interface Plan {
  rooms: Room[];
  /** Largeur du corps principal (sous le toit). */
  body: number;
  /** Largeur totale, aile comprise. */
  width: number;
  /** Haut du dernier étage, sous le toit. */
  top: number;
  wing: boolean;
  tower: boolean;
}

/** Les pièces de chaque étape : l'étage à Perlier, le salon à Pearl Inc., l'aile du musée, puis la tour. */
function plan(stage: number): Plan {
  const rooms: Room[] = [
    { kind: 'boutique', x: 0, y: 0, w: SPLIT, h: GROUND_H },
    { kind: 'atelier', x: SPLIT, y: 0, w: 2 - SPLIT, h: GROUND_H },
  ];
  let top = GROUND_H;
  if (stage >= 1) {
    rooms.push({ kind: 'bureau', x: 0, y: top, w: SPLIT, h: FLOOR_H }, { kind: 'grenier', x: SPLIT, y: top, w: 2 - SPLIT, h: FLOOR_H });
    top += FLOOR_H;
  }
  if (stage >= 3) {
    rooms.push({ kind: 'salon', x: 0, y: top, w: 2, h: FLOOR_H });
    top += FLOOR_H;
  }
  const wing = stage >= 4;
  if (wing) rooms.push({ kind: 'musee', x: 2, y: 0, w: 0.92, h: GROUND_H + FLOOR_H });
  return { rooms, body: 2, width: wing ? 2.92 : 2, top, wing, tower: stage >= 5 };
}

/** Matières de la façade, de la cabane délavée à la pierre claire de Pearl Inc. */
interface Facade {
  siding: string;
  roof: string;
  trim: string;
  cut: string;
  /** Usure : tuiles manquantes, bois terne (1 : cabane, 0 : restaurée). */
  worn: number;
}

const FACADES: readonly Facade[] = [
  { siding: '#6c675c', roof: '#4a3c34', trim: '#8f7d63', cut: '#3a3430', worn: 1 },
  { siding: '#5a746f', roof: '#3b4b55', trim: '#b39b6e', cut: '#343e3d', worn: 0.5 },
  { siding: '#2f6f73', roof: '#203f4f', trim: '#e3c58a', cut: '#22393c', worn: 0 },
  { siding: '#e6dfcf', roof: '#22324a', trim: '#d8b25a', cut: '#b3a891', worn: 0 },
];

const facadeFor = (stage: number) => FACADES[Math.min(stage, FACADES.length - 1)];

/** Papier peint, sol et lumière de chaque pièce. */
const ROOM_STYLE: Record<RoomKind, { wall: string; floor: string; light: string }> = {
  boutique: { wall: '#7a3b4a', floor: '#7a5a3e', light: '#ffd9a0' },
  atelier: { wall: '#4d5b4f', floor: '#6d5038', light: '#fff1c4' },
  bureau: { wall: '#2f4a6a', floor: '#6a4a33', light: '#ffcf8a' },
  grenier: { wall: '#5a4636', floor: '#5e4530', light: '#ff8fc8' },
  salon: { wall: '#1e2f4a', floor: '#d9d3c7', light: '#fff0c8' },
  musee: { wall: '#3a2c4a', floor: '#8a6a4a', light: '#ffe7b0' },
};

interface View {
  P: (x: number, y: number, z: number) => Pt;
  s: number;
  w: number;
  h: number;
  /** Ligne d'horizon et niveau de l'eau à l'écran. */
  horizon: number;
  waterY: number;
}

function makeView(w: number, h: number, p: Plan): View {
  const roofTop = p.top + ROOF_H + (p.tower ? 0.85 : 0.24);
  // Le ponton dépasse un peu à gauche ; à droite, juste le côté du plancher : la Maison prend toute la largeur.
  const xmin = -0.54;
  const xmax = p.width + DEPTH * KX + 0.16;
  const ymin = -0.42;
  const ymax = roofTop + DEPTH * KY;
  const s = Math.min((w * 0.94) / (xmax - xmin), (h * 0.92) / (ymax - ymin));
  const ox = (w - (xmax - xmin) * s) / 2 - xmin * s;
  const oy = h * 0.985 + ymin * s;
  const P = (x: number, y: number, z: number): Pt => [ox + (x + z * KX) * s, oy - (y + z * KY) * s];
  return { P, s, w, h, horizon: oy - DEPTH * 1.7 * KY * s, waterY: oy + 0.3 * s };
}

// ---------- Outils ----------

function poly(c: Ctx, pts: Pt[]): void {
  c.beginPath();
  pts.forEach(([x, y], i) => (i ? c.lineTo(x, y) : c.moveTo(x, y)));
  c.closePath();
}

function line(c: Ctx, a: Pt, b: Pt, color: string, width: number): void {
  c.beginPath();
  c.moveTo(a[0], a[1]);
  c.lineTo(b[0], b[1]);
  c.strokeStyle = color;
  c.lineWidth = width;
  c.stroke();
}

function roundedRect(c: Ctx, x: number, y: number, w: number, h: number, r: number): void {
  c.beginPath();
  c.moveTo(x + r, y);
  c.arcTo(x + w, y, x + w, y + h, r);
  c.arcTo(x + w, y + h, x, y + h, r);
  c.arcTo(x, y + h, x, y, r);
  c.arcTo(x, y, x + w, y, r);
  c.closePath();
}

function glow(c: Ctx, x: number, y: number, r: number, color: string, alpha: number): void {
  if (alpha <= 0.01) return;
  c.save();
  c.globalCompositeOperation = 'lighter';
  const g = c.createRadialGradient(x, y, 0, x, y, r);
  g.addColorStop(0, rgba(color, alpha));
  g.addColorStop(0.45, rgba(color, alpha * 0.35));
  g.addColorStop(1, rgba(color, 0));
  c.fillStyle = g;
  c.fillRect(x - r, y - r, r * 2, r * 2);
  c.restore();
}

/** Meuble en boîte : faces avant, dessus et côté droit, éclairées différemment. */
function box(c: Ctx, v: View, x: number, y: number, z: number, w: number, h: number, d: number, color: string, outline = 'rgba(0,0,0,.28)'): void {
  const { P } = v;
  poly(c, [P(x + w, y, z), P(x + w, y, z + d), P(x + w, y + h, z + d), P(x + w, y + h, z)]);
  c.fillStyle = shade(color, 0.32);
  c.fill();
  poly(c, [P(x, y + h, z), P(x + w, y + h, z), P(x + w, y + h, z + d), P(x, y + h, z + d)]);
  c.fillStyle = tint(color, 0.16);
  c.fill();
  poly(c, [P(x, y, z), P(x + w, y, z), P(x + w, y + h, z), P(x, y + h, z)]);
  const g = c.createLinearGradient(...P(x, y + h, z), ...P(x, y, z));
  g.addColorStop(0, color);
  g.addColorStop(1, shade(color, 0.15));
  c.fillStyle = g;
  c.fill();
  c.lineWidth = Math.max(0.5, v.s * 0.003);
  c.strokeStyle = outline;
  c.stroke();
}

/** Drap gris jeté sur un meuble pas encore restauré. */
function sheet(c: Ctx, v: View, x: number, y: number, z: number, w: number, h: number, d: number): void {
  const { P } = v;
  const a = P(x - 0.02, y, z);
  const b = P(x + w + 0.02, y, z);
  const tl = P(x + 0.04, y + h, z + d * 0.4);
  const tr = P(x + w - 0.02, y + h * 1.04, z + d * 0.5);
  c.beginPath();
  c.moveTo(...a);
  c.quadraticCurveTo(a[0] - v.s * 0.02, (a[1] + tl[1]) / 2, ...tl);
  c.quadraticCurveTo((tl[0] + tr[0]) / 2, tl[1] - v.s * 0.04, ...tr);
  c.quadraticCurveTo(b[0] + v.s * 0.03, (b[1] + tr[1]) / 2, ...b);
  c.closePath();
  const g = c.createLinearGradient(tl[0], tl[1], b[0], b[1]);
  g.addColorStop(0, '#8d897f');
  g.addColorStop(1, '#4f4c46');
  c.fillStyle = g;
  c.fill();
  c.strokeStyle = 'rgba(40,36,30,.35)';
  c.lineWidth = Math.max(0.5, v.s * 0.003);
  for (let k = 1; k < 4; k++) {
    const u = k / 4;
    c.beginPath();
    c.moveTo(a[0] + (b[0] - a[0]) * u, a[1]);
    c.quadraticCurveTo(a[0] + (b[0] - a[0]) * u + v.s * 0.01, (a[1] + tl[1]) / 2, tl[0] + (tr[0] - tl[0]) * u, tl[1] + (tr[1] - tl[1]) * u);
    c.stroke();
  }
}

/** Toile d'araignée dans un coin. */
function cobweb(c: Ctx, at: Pt, r: number): void {
  c.save();
  c.strokeStyle = 'rgba(220,220,210,.28)';
  c.lineWidth = 0.7;
  for (let k = 0; k <= 4; k++) {
    const a = (k / 4) * (Math.PI / 2);
    c.beginPath();
    c.moveTo(...at);
    c.lineTo(at[0] + Math.cos(a) * r, at[1] + Math.sin(a) * r);
    c.stroke();
  }
  for (const f of [0.35, 0.65, 0.95]) {
    c.beginPath();
    c.arc(at[0], at[1], r * f, 0.05, Math.PI / 2 - 0.05);
    c.stroke();
  }
  c.restore();
}

// ---------- Le décor ----------

function drawSkyAndSea(c: Ctx, v: View, stage: number): void {
  const { w, h, horizon } = v;
  const sky = c.createLinearGradient(0, 0, 0, horizon);
  sky.addColorStop(0, HOUSE_SKY_TOP);
  sky.addColorStop(0.65, '#173041');
  sky.addColorStop(1, '#35505a');
  c.fillStyle = sky;
  c.fillRect(0, 0, w, horizon + 1);
  // Lune et ses cratères.
  const mx = w * 0.16;
  const my = h * 0.14;
  const mr = Math.min(w, h) * 0.045;
  glow(c, mx, my, mr * 5, '#cfe6ff', 0.16);
  c.fillStyle = '#e9f1f4';
  c.beginPath();
  c.arc(mx, my, mr, 0, TAU);
  c.fill();
  c.fillStyle = 'rgba(160,180,195,.35)';
  for (const [dx, dy, r] of [[-0.3, -0.2, 0.22], [0.25, 0.15, 0.16], [-0.05, 0.4, 0.12]] as const) {
    c.beginPath();
    c.arc(mx + dx * mr, my + dy * mr, r * mr, 0, TAU);
    c.fill();
  }
  // Phare au loin, sur l'horizon.
  const lx = w * 0.92;
  c.fillStyle = '#1d2c36';
  c.fillRect(lx - 3, horizon - 26, 6, 26);
  c.fillStyle = '#c94a3d';
  c.fillRect(lx - 3, horizon - 18, 6, 4);
  // L'eau.
  const sea = c.createLinearGradient(0, horizon, 0, h);
  sea.addColorStop(0, '#24434d');
  sea.addColorStop(0.4, '#10262f');
  sea.addColorStop(1, '#061117');
  c.fillStyle = sea;
  c.fillRect(0, horizon, w, h - horizon);
  // Reflet de la lune.
  c.save();
  c.globalAlpha = 0.25;
  c.fillStyle = '#cfe6ff';
  for (let k = 0; k < 9; k++) {
    const y = horizon + 6 + k * 7;
    const half = (14 - k) * 1.6;
    c.fillRect(mx - half, y, half * 2, 1.5);
  }
  c.restore();
  // Pearl Inc. et au-delà : des voiliers au mouillage, la Maison attire du monde.
  if (stage >= 3) {
    for (const [fx, size] of [[0.62, 1], [0.76, 0.7]] as const) {
      const bx = w * fx;
      const by = horizon + 4;
      c.fillStyle = '#0d1d26';
      c.beginPath();
      c.moveTo(bx - 14 * size, by);
      c.lineTo(bx + 14 * size, by);
      c.lineTo(bx + 10 * size, by + 4 * size);
      c.lineTo(bx - 10 * size, by + 4 * size);
      c.closePath();
      c.fill();
      c.fillStyle = 'rgba(230,230,220,.55)';
      c.beginPath();
      c.moveTo(bx, by - 18 * size);
      c.lineTo(bx, by - 1);
      c.lineTo(bx + 10 * size, by - 1);
      c.closePath();
      c.fill();
    }
  }
}

/** Le ponton et les pilotis : la Maison est posée au-dessus de l'eau. */
function drawDeck(c: Ctx, v: View, p: Plan, f: Facade): void {
  const { P } = v;
  const x0 = -0.5;
  const x1 = p.width + 0.12;
  const z0 = -0.08;
  const z1 = DEPTH + 0.06;
  const wood = f.worn > 0.5 ? '#5b4a3c' : '#6d5340';
  // Pilotis du fond, puis de devant.
  for (const z of [z1 - 0.03, z0 + 0.03]) {
    for (let x = x0 + 0.08; x <= x1; x += 0.42) {
      const top = P(x, -0.06, z);
      const bottom = P(x, -0.36, z);
      const r = v.s * 0.028;
      const g = c.createLinearGradient(top[0] - r, 0, top[0] + r, 0);
      g.addColorStop(0, shade(wood, 0.45));
      g.addColorStop(0.4, wood);
      g.addColorStop(1, shade(wood, 0.6));
      c.fillStyle = g;
      c.fillRect(top[0] - r, top[1], r * 2, bottom[1] - top[1]);
      // Reflet tremblé sous le pilotis.
      c.fillStyle = rgba(wood, 0.25);
      c.fillRect(top[0] - r, bottom[1], r * 2, v.s * 0.12);
    }
  }
  // Plancher du ponton : dessus, chant avant, côté droit.
  poly(c, [P(x0, 0, z0), P(x1, 0, z0), P(x1, 0, z1), P(x0, 0, z1)]);
  c.fillStyle = tint(wood, 0.12);
  c.fill();
  c.strokeStyle = rgba('#000000', 0.18);
  c.lineWidth = Math.max(0.5, v.s * 0.003);
  for (let x = x0 + 0.12; x < x1; x += 0.12) {
    c.beginPath();
    c.moveTo(...P(x, 0, z0));
    c.lineTo(...P(x, 0, z1));
    c.stroke();
  }
  poly(c, [P(x0, -0.07, z0), P(x1, -0.07, z0), P(x1, 0, z0), P(x0, 0, z0)]);
  c.fillStyle = shade(wood, 0.25);
  c.fill();
  poly(c, [P(x1, -0.07, z0), P(x1, -0.07, z1), P(x1, 0, z1), P(x1, 0, z0)]);
  c.fillStyle = shade(wood, 0.45);
  c.fill();
  // Bitte d'amarrage et cordage au bout du ponton.
  box(c, v, x0 + 0.06, 0, z0 + 0.04, 0.07, 0.14, 0.07, '#4a3a2e');
  const rope = P(x0 + 0.095, 0.12, z0 + 0.07);
  c.strokeStyle = '#b9a27a';
  c.lineWidth = Math.max(1, v.s * 0.008);
  c.beginPath();
  c.ellipse(rope[0], rope[1], v.s * 0.05, v.s * 0.018, 0, 0, TAU);
  c.stroke();
}

// ---------- Les pièces ----------

/** Fond, mur de gauche et sol d'une pièce. */
function drawShell(c: Ctx, v: View, room: Room): void {
  const { P } = v;
  const { x, y, w, h } = room;
  const st = ROOM_STYLE[room.kind];
  const x1 = x + w;
  const y1 = y + h;
  const D = DEPTH;
  const thin = Math.max(0.6, v.s * 0.004);
  // Mur du fond : papier peint à rayures, lambris en bas.
  poly(c, [P(x, y, D), P(x1, y, D), P(x1, y1, D), P(x, y1, D)]);
  const back = c.createLinearGradient(...P(x, y1, D), ...P(x, y, D));
  back.addColorStop(0, shade(st.wall, 0.25));
  back.addColorStop(0.5, st.wall);
  back.addColorStop(1, shade(st.wall, 0.1));
  c.fillStyle = back;
  c.fill();
  c.save();
  c.clip();
  const stripe = room.kind === 'salon' ? 'rgba(232,190,90,.18)' : 'rgba(255,255,255,.07)';
  for (let k = x + 0.08; k < x1; k += 0.08) line(c, P(k, y, D), P(k, y1, D), stripe, thin);
  poly(c, [P(x, y, D), P(x1, y, D), P(x1, y + h * 0.28, D), P(x, y + h * 0.28, D)]);
  c.fillStyle = 'rgba(30,18,10,.35)';
  c.fill();
  line(c, P(x, y + h * 0.28, D), P(x1, y + h * 0.28, D), 'rgba(255,230,180,.22)', Math.max(0.8, v.s * 0.006));
  c.restore();
  // Mur de gauche, vu de l'intérieur : plus sombre.
  poly(c, [P(x, y, 0), P(x, y, D), P(x, y1, D), P(x, y1, 0)]);
  const left = c.createLinearGradient(...P(x, y, 0), ...P(x, y, D));
  left.addColorStop(0, shade(st.wall, 0.45));
  left.addColorStop(1, shade(st.wall, 0.3));
  c.fillStyle = left;
  c.fill();
  // Sol : lattes (ou marbre en damier pour le salon), ombre au pied des murs.
  poly(c, [P(x, y, 0), P(x1, y, 0), P(x1, y, D), P(x, y, D)]);
  c.fillStyle = st.floor;
  c.fill();
  c.save();
  c.clip();
  if (room.kind === 'salon') {
    const n = 10;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < 4; j++) {
        if ((i + j) % 2) continue;
        const ax = x + (i / n) * w;
        const bx = x + ((i + 1) / n) * w;
        poly(c, [P(ax, y, (j / 4) * D), P(bx, y, (j / 4) * D), P(bx, y, ((j + 1) / 4) * D), P(ax, y, ((j + 1) / 4) * D)]);
        c.fillStyle = 'rgba(40,50,70,.35)';
        c.fill();
      }
    }
  } else {
    for (let k = x + 0.09; k < x1; k += 0.09) line(c, P(k, y, 0), P(k, y, D), 'rgba(0,0,0,.18)', thin);
  }
  const occl = c.createLinearGradient(...P(x, y, D), ...P(x, y, D * 0.55));
  occl.addColorStop(0, 'rgba(0,0,0,.35)');
  occl.addColorStop(1, 'rgba(0,0,0,0)');
  c.fillStyle = occl;
  c.fillRect(0, 0, v.w, v.h);
  c.restore();
}

/** Fenêtre au mur du fond : nuit et lune, ou planches clouées. */
function backWindow(c: Ctx, v: View, cx: number, y: number, w: number, h: number, open: boolean, round = false): void {
  const { P } = v;
  const a = P(cx - w / 2, y, DEPTH);
  const b = P(cx + w / 2, y + h, DEPTH);
  const left = a[0];
  const right = b[0];
  const bottom = a[1];
  const topY = b[1];
  const r = (right - left) / 2;
  c.beginPath();
  if (round) c.arc((left + right) / 2, (bottom + topY) / 2, Math.min(r, (bottom - topY) / 2), 0, TAU);
  else {
    c.moveTo(left, bottom);
    c.lineTo(left, topY + r);
    c.arc(left + r, topY + r, r, Math.PI, 0);
    c.lineTo(right, bottom);
    c.closePath();
  }
  c.save();
  c.clip();
  const night = c.createLinearGradient(0, topY, 0, bottom);
  night.addColorStop(0, '#0b1a2b');
  night.addColorStop(1, '#2a4a5c');
  c.fillStyle = night;
  c.fillRect(left, topY, right - left, bottom - topY);
  if (open) {
    c.fillStyle = '#e9f1f4';
    c.beginPath();
    c.arc(left + (right - left) * 0.68, topY + (bottom - topY) * 0.32, r * 0.22, 0, TAU);
    c.fill();
    c.fillStyle = 'rgba(255,255,255,.7)';
    for (const [fx, fy] of [[0.2, 0.2], [0.35, 0.5], [0.8, 0.7]] as const) c.fillRect(left + (right - left) * fx, topY + (bottom - topY) * fy, 1.2, 1.2);
  } else {
    // Planches clouées en travers.
    c.fillStyle = '#5b4636';
    for (const [k, angle] of [[0.3, -0.25], [0.65, 0.2]] as const) {
      c.save();
      c.translate((left + right) / 2, topY + (bottom - topY) * k);
      c.rotate(angle);
      c.fillRect(-r * 1.4, -r * 0.16, r * 2.8, r * 0.32);
      c.restore();
    }
  }
  c.restore();
  c.lineWidth = Math.max(1.2, v.s * 0.012);
  c.strokeStyle = open ? '#e3c58a' : '#4a3a2e';
  c.stroke();
  if (open && !round) {
    line(c, [(left + right) / 2, topY + 2], [(left + right) / 2, bottom], 'rgba(227,197,138,.8)', Math.max(0.8, v.s * 0.006));
    // Rideaux.
    c.fillStyle = 'rgba(160,50,70,.75)';
    c.fillRect(left - r * 0.25, topY + r * 0.2, r * 0.32, bottom - topY - r * 0.2);
    c.fillRect(right - r * 0.07, topY + r * 0.2, r * 0.32, bottom - topY - r * 0.2);
  }
}

/** Étagère au mur du fond, avec des bocaux de perles. */
function shelf(c: Ctx, v: View, x: number, y: number, w: number, jars: boolean): void {
  const z = DEPTH - 0.06;
  box(c, v, x, y, z, w, 0.018, 0.06, '#5a4030');
  if (!jars) return;
  for (let k = 0; k < 4; k++) {
    const [px, py] = v.P(x + 0.04 + (k * (w - 0.08)) / 3, y + 0.018, z + 0.03);
    const r = v.s * 0.022;
    c.fillStyle = 'rgba(200,230,235,.35)';
    c.fillRect(px - r, py - r * 2.2, r * 2, r * 2.2);
    c.fillStyle = ['#f3f0ea', '#f2c4cc', '#33374a', '#e2b04a'][k];
    c.beginPath();
    c.arc(px, py - r * 0.7, r * 0.55, 0, TAU);
    c.fill();
  }
}

function drawBoutique(c: Ctx, v: View, room: Room, scene: HouseScene): void {
  const { P } = v;
  const { x, y } = room;
  const has = (f: HouseFeature) => scene.restored.has(f);
  // Étagères et comptoir au fond, caisse enregistreuse.
  shelf(c, v, x + 0.12, y + 0.42, 0.42, has('door'));
  shelf(c, v, x + 0.12, y + 0.56, 0.42, has('door'));
  box(c, v, x + 0.56, y, DEPTH - 0.2, 0.42, 0.27, 0.14, '#6b4a33');
  box(c, v, x + 0.55, y + 0.27, DEPTH - 0.21, 0.44, 0.02, 0.16, '#e8e2d6');
  if (has('door')) box(c, v, x + 0.78, y + 0.29, DEPTH - 0.16, 0.1, 0.06, 0.07, '#b38a3e');
  // La porte, dans le mur de gauche : elle donne sur le ponton.
  const z0 = 0.16;
  const z1 = 0.4;
  const door = [P(x, y, z0), P(x, y, z1), P(x, y + 0.52, z1), P(x, y + 0.52, z0)];
  poly(c, door);
  c.fillStyle = has('door') ? '#7d3b30' : '#2b2420';
  c.fill();
  if (has('door')) {
    const g = c.createLinearGradient(...door[0], ...door[1]);
    g.addColorStop(0, 'rgba(255,255,255,.12)');
    g.addColorStop(1, 'rgba(0,0,0,.25)');
    c.fillStyle = g;
    c.fill();
    poly(c, [P(x, y + 0.3, z0 + 0.04), P(x, y + 0.3, z1 - 0.04), P(x, y + 0.46, z1 - 0.04), P(x, y + 0.46, z0 + 0.04)]);
    c.fillStyle = 'rgba(255,214,150,.75)';
    c.fill();
    const [kx, ky] = P(x, y + 0.24, z1 - 0.04);
    c.fillStyle = '#e3c58a';
    c.beginPath();
    c.arc(kx, ky, v.s * 0.01, 0, TAU);
    c.fill();
  } else {
    // Planches clouées en travers de la porte.
    c.save();
    poly(c, door);
    c.clip();
    line(c, P(x, y + 0.08, z0), P(x, y + 0.44, z1), '#6a5240', v.s * 0.03);
    line(c, P(x, y + 0.44, z0), P(x, y + 0.1, z1), '#5a4434', v.s * 0.03);
    c.restore();
  }
  c.lineWidth = Math.max(1, v.s * 0.008);
  c.strokeStyle = '#3a2a20';
  poly(c, door);
  c.stroke();
  // Tapis.
  poly(c, [P(x + 0.2, y + 0.002, 0.06), P(x + 0.78, y + 0.002, 0.06), P(x + 0.78, y + 0.002, 0.38), P(x + 0.2, y + 0.002, 0.38)]);
  c.fillStyle = has('door') ? 'rgba(150,40,60,.7)' : 'rgba(90,60,50,.5)';
  c.fill();
  // La vitrine, au milieu : la plus belle pièce sous verre.
  const vx = x + 0.3;
  const vz = 0.12;
  if (!has('vitrine')) {
    sheet(c, v, vx, y, vz, 0.4, 0.38, 0.2);
    return;
  }
  box(c, v, vx, y, vz, 0.4, 0.16, 0.2, '#4a2e22');
  box(c, v, vx, y + 0.16, vz, 0.4, 0.012, 0.2, '#d8b25a');
  const a = P(vx + 0.02, y + 0.18, vz);
  const b = P(vx + 0.38, y + 0.38, vz);
  if (scene.showcase) {
    const size = Math.min(b[0] - a[0], a[1] - b[1]) * 1.15;
    c.drawImage(scene.showcase, (a[0] + b[0]) / 2 - size / 2, (a[1] + b[1]) / 2 - size / 2, size, size);
  }
  // Le verre : reflets et arêtes dorées.
  const gold = Math.max(0.8, v.s * 0.006);
  poly(c, [P(vx, y + 0.172, vz), P(vx + 0.4, y + 0.172, vz), P(vx + 0.4, y + 0.4, vz), P(vx, y + 0.4, vz)]);
  c.fillStyle = 'rgba(200,235,240,.12)';
  c.fill();
  c.strokeStyle = '#e3c58a';
  c.lineWidth = gold;
  c.stroke();
  poly(c, [P(vx, y + 0.4, vz), P(vx + 0.4, y + 0.4, vz), P(vx + 0.4, y + 0.4, vz + 0.2), P(vx, y + 0.4, vz + 0.2)]);
  c.fillStyle = 'rgba(200,235,240,.18)';
  c.fill();
  poly(c, [P(vx + 0.4, y + 0.172, vz), P(vx + 0.4, y + 0.172, vz + 0.2), P(vx + 0.4, y + 0.4, vz + 0.2), P(vx + 0.4, y + 0.4, vz)]);
  c.fillStyle = 'rgba(200,235,240,.1)';
  c.fill();
  line(c, P(vx + 0.4, y + 0.4, vz), P(vx + 0.4, y + 0.4, vz + 0.2), '#e3c58a', gold);
  line(c, P(vx, y + 0.4, vz), P(vx, y + 0.4, vz + 0.2), '#e3c58a', gold);
  line(c, P(vx + 0.06, y + 0.38, vz), P(vx + 0.16, y + 0.2, vz), 'rgba(255,255,255,.35)', gold);
}

function drawAtelier(c: Ctx, v: View, room: Room, scene: HouseScene): void {
  const { P } = v;
  const { x, y } = room;
  const ok = scene.restored.has('workbench');
  // Panneau à outils au mur du fond.
  const pa = P(x + 0.16, y + 0.36, DEPTH);
  const pb = P(x + 0.78, y + 0.62, DEPTH);
  c.fillStyle = ok ? '#8a6a48' : '#4a3a2e';
  c.fillRect(pa[0], pb[1], pb[0] - pa[0], pa[1] - pb[1]);
  if (ok) {
    c.strokeStyle = '#2b2b30';
    c.fillStyle = '#2b2b30';
    c.lineWidth = Math.max(1, v.s * 0.008);
    for (const [k, kind] of [[0.12, 'pince'], [0.3, 'marteau'], [0.5, 'lime'], [0.7, 'loupe'], [0.88, 'scie']] as const) {
      const tx = pa[0] + (pb[0] - pa[0]) * k;
      const ty = pb[1] + (pa[1] - pb[1]) * 0.25;
      const len = (pa[1] - pb[1]) * 0.55;
      c.beginPath();
      c.moveTo(tx, ty);
      c.lineTo(tx, ty + len);
      c.stroke();
      if (kind === 'marteau') c.fillRect(tx - len * 0.22, ty - 2, len * 0.44, len * 0.16);
      if (kind === 'loupe') {
        c.beginPath();
        c.arc(tx, ty, len * 0.18, 0, TAU);
        c.stroke();
      }
    }
  }
  // L'établi : étau, lampe, perles en attente.
  const bx = x + 0.12;
  const bz = DEPTH - 0.24;
  if (ok) {
    box(c, v, bx, y, bz, 0.66, 0.3, 0.2, '#7a5236');
    box(c, v, bx - 0.01, y + 0.3, bz - 0.01, 0.68, 0.025, 0.22, '#a07650');
    box(c, v, bx + 0.08, y + 0.325, bz + 0.05, 0.08, 0.06, 0.08, '#55606a');
    const lamp = P(bx + 0.52, y + 0.33, bz + 0.1);
    line(c, lamp, [lamp[0] + v.s * 0.03, lamp[1] - v.s * 0.14], '#2f3b33', Math.max(1, v.s * 0.01));
    c.fillStyle = '#2f6b4a';
    c.beginPath();
    c.moveTo(lamp[0], lamp[1] - v.s * 0.12);
    c.lineTo(lamp[0] + v.s * 0.08, lamp[1] - v.s * 0.16);
    c.lineTo(lamp[0] + v.s * 0.09, lamp[1] - v.s * 0.1);
    c.closePath();
    c.fill();
    for (let k = 0; k < 5; k++) {
      const [px, py] = P(bx + 0.24 + k * 0.035, y + 0.33, bz + 0.06);
      c.fillStyle = '#f3f0ea';
      c.beginPath();
      c.arc(px, py, v.s * 0.011, 0, TAU);
      c.fill();
    }
  } else {
    sheet(c, v, bx, y, bz, 0.66, 0.32, 0.2);
  }
  box(c, v, x + 0.42, y, 0.16, 0.12, 0.2, 0.1, '#5a4030');
}

function drawBureau(c: Ctx, v: View, room: Room, scene: HouseScene): void {
  const { P } = v;
  const { x, y } = room;
  const ok = scene.restored.has('notebook');
  backWindow(c, v, x + 0.5, y + 0.3, 0.3, 0.3, ok);
  // Portrait de Rose au mur de gauche.
  poly(c, [P(x, y + 0.3, 0.18), P(x, y + 0.3, 0.34), P(x, y + 0.52, 0.34), P(x, y + 0.52, 0.18)]);
  c.fillStyle = '#c9a25a';
  c.fill();
  poly(c, [P(x, y + 0.32, 0.2), P(x, y + 0.32, 0.32), P(x, y + 0.5, 0.32), P(x, y + 0.5, 0.2)]);
  c.fillStyle = ok ? '#e8d9c0' : '#5d5448';
  c.fill();
  if (ok) {
    const [hx, hy] = P(x, y + 0.42, 0.26);
    c.fillStyle = '#7a5a48';
    c.beginPath();
    c.arc(hx, hy, v.s * 0.022, 0, TAU);
    c.fill();
    c.fillStyle = '#c7c2bd';
    c.beginPath();
    c.arc(hx, hy - v.s * 0.012, v.s * 0.022, Math.PI, 0);
    c.fill();
  }
  // Bibliothèque à droite.
  box(c, v, x + 0.86, y, DEPTH - 0.2, 0.16, 0.5, 0.16, '#4a3226');
  for (let k = 0; k < 3; k++) {
    for (let b = 0; b < 4; b++) {
      const [px, py] = P(x + 0.875 + b * 0.034, y + 0.08 + k * 0.15, DEPTH - 0.2);
      c.fillStyle = ['#8a2f3a', '#2f5a7a', '#c9a25a', '#3a6a4a'][(b + k) % 4];
      c.fillRect(px, py - v.s * 0.1, v.s * 0.026, v.s * 0.1);
    }
  }
  // Le bureau et le carnet ouvert, la bougie.
  const dx = x + 0.28;
  const dz = DEPTH - 0.26;
  box(c, v, dx, y, dz, 0.46, 0.25, 0.16, '#5a3a28');
  if (ok) {
    poly(c, [P(dx + 0.12, y + 0.252, dz + 0.04), P(dx + 0.3, y + 0.252, dz + 0.04), P(dx + 0.3, y + 0.252, dz + 0.12), P(dx + 0.12, y + 0.252, dz + 0.12)]);
    c.fillStyle = '#f2e6cf';
    c.fill();
    line(c, P(dx + 0.21, y + 0.252, dz + 0.04), P(dx + 0.21, y + 0.252, dz + 0.12), 'rgba(90,60,30,.5)', 1);
    box(c, v, dx + 0.36, y + 0.25, dz + 0.06, 0.025, 0.06, 0.025, '#f4efe0');
  } else {
    poly(c, [P(dx + 0.12, y + 0.252, dz + 0.04), P(dx + 0.26, y + 0.252, dz + 0.04), P(dx + 0.26, y + 0.252, dz + 0.1), P(dx + 0.12, y + 0.252, dz + 0.1)]);
    c.fillStyle = '#4a3a2e';
    c.fill();
  }
  box(c, v, dx + 0.14, y, dz - 0.14, 0.14, 0.15, 0.12, '#4a3020');
  // Le chat de la Maison, revenu quand la boutique a repris des couleurs.
  if (ok && scene.stage >= 2) {
    const [cx, cy] = P(x + 0.18, y, 0.14);
    c.fillStyle = '#2a2a30';
    c.beginPath();
    c.ellipse(cx, cy - v.s * 0.03, v.s * 0.07, v.s * 0.035, 0, 0, TAU);
    c.fill();
    c.beginPath();
    c.arc(cx + v.s * 0.06, cy - v.s * 0.05, v.s * 0.026, 0, TAU);
    c.fill();
    c.beginPath();
    c.moveTo(cx + v.s * 0.045, cy - v.s * 0.07);
    c.lineTo(cx + v.s * 0.055, cy - v.s * 0.095);
    c.lineTo(cx + v.s * 0.07, cy - v.s * 0.072);
    c.fill();
  }
}

function drawGrenier(c: Ctx, v: View, room: Room, scene: HouseScene): void {
  const { x, y } = room;
  backWindow(c, v, x + 0.62, y + 0.32, 0.18, 0.18, scene.restored.has('box'), true);
  // Filets de pêche au mur, malles et caisses.
  const [nx, ny] = v.P(x + 0.18, y + 0.56, DEPTH);
  c.strokeStyle = 'rgba(200,180,140,.45)';
  c.lineWidth = 0.8;
  for (let k = 0; k < 5; k++) {
    c.beginPath();
    c.moveTo(nx + k * v.s * 0.05, ny);
    c.quadraticCurveTo(nx + k * v.s * 0.05 + v.s * 0.04, ny + v.s * 0.16, nx + k * v.s * 0.05 + v.s * 0.02, ny + v.s * 0.26);
    c.stroke();
  }
  box(c, v, x + 0.08, y, DEPTH - 0.24, 0.26, 0.18, 0.18, '#6a4a32');
  box(c, v, x + 0.12, y + 0.18, DEPTH - 0.2, 0.16, 0.1, 0.12, '#7a5a3a');
  box(c, v, x + 0.66, y, DEPTH - 0.2, 0.2, 0.14, 0.16, '#5a3e2a');
  // La boîte : elle n'aurait pas dû briller.
  if (scene.restored.has('box')) {
    box(c, v, x + 0.42, y, 0.16, 0.16, 0.1, 0.12, '#3a0f2a', 'rgba(255,47,114,.6)');
    box(c, v, x + 0.415, y + 0.1, 0.155, 0.17, 0.02, 0.13, '#5a1840', 'rgba(255,47,114,.6)');
  } else {
    sheet(c, v, x + 0.42, y, 0.16, 0.16, 0.12, 0.12);
  }
}

function drawSalon(c: Ctx, v: View, room: Room): void {
  const { P } = v;
  const { x, y, w } = room;
  // Grandes fenêtres, monogramme doré au fond (le nom est déjà sur l'enseigne), présentoirs, lustre.
  backWindow(c, v, x + 0.32, y + 0.14, 0.3, 0.38, true);
  backWindow(c, v, x + w - 0.32, y + 0.14, 0.3, 0.38, true);
  const [lx, ly] = P(x + w / 2, y + 0.36, DEPTH);
  c.strokeStyle = '#d8b25a';
  c.lineWidth = Math.max(1, v.s * 0.008);
  c.beginPath();
  c.arc(lx, ly, v.s * 0.075, 0, TAU);
  c.stroke();
  c.fillStyle = '#d8b25a';
  c.textAlign = 'center';
  c.textBaseline = 'middle';
  c.font = `400 ${Math.round(v.s * 0.08)}px ${SERIF}`;
  c.fillText('P', lx, ly + v.s * 0.004);
  [0.3, 0.85, 1.4].forEach((px, i) => {
    box(c, v, x + px, y, 0.2, 0.2, 0.22, 0.16, '#efe8da');
    const [gx, gy] = P(x + px + 0.1, y + 0.27, 0.28);
    c.fillStyle = ['#5d86ff', '#ff4060', '#4dffb0'][i];
    c.beginPath();
    c.moveTo(gx, gy - v.s * 0.025);
    c.lineTo(gx + v.s * 0.02, gy);
    c.lineTo(gx, gy + v.s * 0.025);
    c.lineTo(gx - v.s * 0.02, gy);
    c.closePath();
    c.fill();
  });
  const [cx, cy] = P(x + w / 2, y + 0.56, DEPTH / 2);
  line(c, [cx, cy - v.s * 0.08], [cx, cy], '#d8b25a', 1);
  c.strokeStyle = '#d8b25a';
  c.lineWidth = Math.max(1, v.s * 0.006);
  c.beginPath();
  c.ellipse(cx, cy, v.s * 0.09, v.s * 0.025, 0, 0, Math.PI);
  c.stroke();
}

function drawMusee(c: Ctx, v: View, room: Room): void {
  const { P } = v;
  const { x, y, w } = room;
  // Tableaux au fond, socles et cloches de verre, cordon rouge.
  for (const [fx, fy] of [[0.25, 0.75], [0.62, 0.95]] as const) {
    const a = P(x + w * fx - 0.12, y + fy, DEPTH);
    const b = P(x + w * fx + 0.12, y + fy + 0.24, DEPTH);
    c.fillStyle = '#c9a25a';
    c.fillRect(a[0], b[1], b[0] - a[0], a[1] - b[1]);
    c.fillStyle = '#1d3a4a';
    c.fillRect(a[0] + 3, b[1] + 3, b[0] - a[0] - 6, a[1] - b[1] - 6);
  }
  for (const [px, pearl] of [[0.12, '#f3f0ea'], [0.42, '#e2b04a'], [0.7, '#33374a']] as const) {
    box(c, v, x + px, y, 0.18, 0.14, 0.32, 0.12, '#e9e2d3');
    const [gx, gy] = P(x + px + 0.07, y + 0.36, 0.24);
    c.fillStyle = pearl;
    c.beginPath();
    c.arc(gx, gy, v.s * 0.022, 0, TAU);
    c.fill();
    c.strokeStyle = 'rgba(220,240,245,.5)';
    c.lineWidth = 1;
    c.beginPath();
    c.arc(gx, gy - v.s * 0.01, v.s * 0.045, Math.PI, 0);
    c.lineTo(gx + v.s * 0.045, gy + v.s * 0.02);
    c.moveTo(gx - v.s * 0.045, gy - v.s * 0.01);
    c.lineTo(gx - v.s * 0.045, gy + v.s * 0.02);
    c.stroke();
  }
  line(c, P(x + 0.04, y + 0.16, 0.06), P(x + w - 0.04, y + 0.16, 0.06), '#a0283a', Math.max(1.2, v.s * 0.008));
}

/** Une pièce est éclairée quand sa lettre l'a fait revivre (ou, au-delà, quand la Maison a grandi). */
function isLit(kind: RoomKind, scene: HouseScene): boolean {
  switch (kind) {
    case 'boutique':
      return scene.restored.has('door');
    case 'atelier':
      return scene.restored.has('workbench');
    case 'bureau':
      return scene.restored.has('notebook');
    case 'grenier':
      return scene.restored.has('box');
    default:
      return true;
  }
}

function drawRoom(c: Ctx, v: View, room: Room, scene: HouseScene): void {
  const { P } = v;
  const { x, y, w, h } = room;
  drawShell(c, v, room);
  if (room.kind === 'boutique') drawBoutique(c, v, room, scene);
  else if (room.kind === 'atelier') drawAtelier(c, v, room, scene);
  else if (room.kind === 'bureau') drawBureau(c, v, room, scene);
  else if (room.kind === 'grenier') drawGrenier(c, v, room, scene);
  else if (room.kind === 'salon') drawSalon(c, v, room);
  else drawMusee(c, v, room);
  const inside = [P(x, y, 0), P(x + w, y, 0), P(x + w, y, DEPTH), P(x + w, y + h, DEPTH), P(x, y + h, DEPTH), P(x, y + h, 0)];
  if (!isLit(room.kind, scene)) {
    // Pénombre et toiles d'araignée tant que la pièce dort.
    poly(c, inside);
    c.fillStyle = 'rgba(4,10,16,.5)';
    c.fill();
    cobweb(c, P(x, y + h, DEPTH), v.s * 0.14);
    return;
  }
  // Lumière chaude de la pièce, venue du plafond.
  const [lx, ly] = P(x + w / 2, y + h * 0.85, DEPTH * 0.5);
  c.save();
  poly(c, inside);
  c.clip();
  const g = c.createRadialGradient(lx, ly, 0, lx, ly, v.s * w * 0.75);
  g.addColorStop(0, rgba(ROOM_STYLE[room.kind].light, 0.22));
  g.addColorStop(1, rgba(ROOM_STYLE[room.kind].light, 0));
  c.globalCompositeOperation = 'lighter';
  c.fillStyle = g;
  c.fillRect(0, 0, v.w, v.h);
  c.restore();
}

// ---------- La coque : coupes, côté droit, toit ----------

const near = (a: number, b: number) => Math.abs(a - b) < 1e-6;

function drawCuts(c: Ctx, v: View, p: Plan, f: Facade): void {
  const { P } = v;
  const fill = (pts: Pt[], color: string) => {
    poly(c, pts);
    c.fillStyle = color;
    c.fill();
  };
  // Le côté droit, vu de l'extérieur : bardage.
  const sideTop = p.wing ? GROUND_H + FLOOR_H : p.top;
  const siding = (x: number, y0: number, y1: number) => {
    fill([P(x, y0, 0), P(x, y0, DEPTH), P(x, y1, DEPTH), P(x, y1, 0)], shade(f.siding, 0.28));
    c.strokeStyle = rgba('#000000', 0.16);
    c.lineWidth = Math.max(0.5, v.s * 0.003);
    for (let yy = y0 + 0.08; yy < y1; yy += 0.08) {
      c.beginPath();
      c.moveTo(...P(x, yy, 0));
      c.lineTo(...P(x, yy, DEPTH));
      c.stroke();
    }
  };
  siding(p.width, 0, sideTop);
  if (p.wing) {
    siding(p.body, sideTop, p.top);
    // Toit-terrasse de l'aile, avec balustrade.
    fill([P(p.body, sideTop, 0), P(p.width, sideTop, 0), P(p.width, sideTop, DEPTH), P(p.body, sideTop, DEPTH)], shade(f.siding, 0.1));
    for (let k = p.body + 0.06; k < p.width; k += 0.09) line(c, P(k, sideTop, 0.02), P(k, sideTop + 0.08, 0.02), f.trim, Math.max(1, v.s * 0.006));
    line(c, P(p.body, sideTop + 0.08, 0.02), P(p.width, sideTop + 0.08, 0.02), f.trim, Math.max(1.2, v.s * 0.01));
  }
  // Coupes des planchers et des murs : là où la façade a été ôtée.
  const t = WALL;
  for (const yy of [...new Set(p.rooms.flatMap((r) => [r.y, r.y + r.h]))]) {
    const touching = p.rooms.filter((r) => near(r.y, yy) || near(r.y + r.h, yy));
    const x0 = Math.min(...touching.map((r) => r.x));
    const x1 = Math.max(...touching.map((r) => r.x + r.w));
    fill([P(x0 - t / 2, yy - t / 2, 0), P(x1 + t / 2, yy - t / 2, 0), P(x1 + t / 2, yy + t / 2, 0), P(x0 - t / 2, yy + t / 2, 0)], f.cut);
    fill([P(x0 - t / 2, yy + t / 2, 0), P(x1 + t / 2, yy + t / 2, 0), P(x1 + t / 2, yy + t / 2, t), P(x0 - t / 2, yy + t / 2, t)], tint(f.cut, 0.15));
  }
  c.strokeStyle = rgba(f.trim, 0.85);
  c.lineWidth = Math.max(1, v.s * 0.008);
  for (const xx of [...new Set(p.rooms.flatMap((r) => [r.x, r.x + r.w]))]) {
    const top = Math.max(...p.rooms.filter((r) => near(r.x, xx) || near(r.x + r.w, xx)).map((r) => r.y + r.h));
    fill([P(xx - t / 2, 0, 0), P(xx + t / 2, 0, 0), P(xx + t / 2, top, 0), P(xx - t / 2, top, 0)], f.cut);
    // Liseré de la façade (bois clair, puis or).
    c.beginPath();
    c.moveTo(...P(xx + t / 2, 0, 0));
    c.lineTo(...P(xx + t / 2, top, 0));
    c.stroke();
  }
}

function drawRoof(c: Ctx, v: View, p: Plan, f: Facade, scene: HouseScene): void {
  const { P } = v;
  const y0 = p.top;
  const eave = 0.12;
  const ridge = y0 + ROOF_H;
  const mid = p.body / 2;
  const back = DEPTH + 0.04;
  const slope = (pts: Pt[], color: string, rows: number) => {
    poly(c, pts);
    c.fillStyle = color;
    c.fill();
    c.save();
    c.clip();
    c.strokeStyle = rgba('#000000', 0.18);
    c.lineWidth = Math.max(0.6, v.s * 0.004);
    const [a, b, cc, d] = pts;
    for (let k = 1; k < rows; k++) {
      const u = k / rows;
      c.beginPath();
      c.moveTo(a[0] + (b[0] - a[0]) * u, a[1] + (b[1] - a[1]) * u);
      c.lineTo(d[0] + (cc[0] - d[0]) * u, d[1] + (cc[1] - d[1]) * u);
      c.stroke();
    }
    c.restore();
  };
  // Pente gauche (à peine visible), pente droite, puis le pignon en façade.
  slope([P(mid, ridge, -0.04), P(-eave, y0 - 0.04, -0.04), P(-eave, y0 - 0.04, back), P(mid, ridge, back)], shade(f.roof, 0.25), 6);
  slope([P(mid, ridge, -0.04), P(p.body + eave, y0 - 0.04, -0.04), P(p.body + eave, y0 - 0.04, back), P(mid, ridge, back)], f.roof, 6);
  // Tuiles manquantes sur la cabane.
  if (f.worn > 0) {
    c.fillStyle = 'rgba(10,8,8,.65)';
    for (const [u, size] of [[0.3, 0.6], [0.65, 0.35]] as const) {
      if (u > f.worn + 0.2) continue;
      const [hx, hy] = P(mid + (p.body + eave - mid) * u, ridge - ROOF_H * u, 0.24);
      c.beginPath();
      c.ellipse(hx, hy, v.s * 0.12 * size, v.s * 0.025, -0.3, 0, TAU);
      c.fill();
    }
  }
  // Cheminée (la fumée s'anime à part).
  box(c, v, p.body * 0.74, y0 + ROOF_H * 0.42, DEPTH * 0.55, 0.12, 0.34, 0.12, f.worn > 0.5 ? '#7a5a48' : '#8a5a48');
  // Le pignon, en bardage.
  const gable = [P(-eave * 0.6, y0, 0), P(p.body + eave * 0.6, y0, 0), P(mid, ridge - 0.02, 0)];
  poly(c, gable);
  const g = c.createLinearGradient(...gable[2], ...gable[0]);
  g.addColorStop(0, tint(f.siding, 0.08));
  g.addColorStop(1, shade(f.siding, 0.12));
  c.fillStyle = g;
  c.fill();
  c.save();
  c.clip();
  for (let yy = y0 + 0.07; yy < ridge; yy += 0.07) line(c, P(-1, yy, 0), P(p.body + 1, yy, 0), rgba('#000000', 0.14), Math.max(0.5, v.s * 0.003));
  c.restore();
  // Planche de rive.
  c.strokeStyle = f.trim;
  c.lineWidth = Math.max(1.5, v.s * 0.016);
  c.beginPath();
  c.moveTo(...P(-eave, y0 - 0.04, -0.04));
  c.lineTo(...P(mid, ridge, -0.04));
  c.lineTo(...P(p.body + eave, y0 - 0.04, -0.04));
  c.stroke();
  drawSign(c, v, p, scene);
}

/** L'enseigne, sur le pignon : Maison Rose délavée, restaurée, puis Pearl Inc. */
function drawSign(c: Ctx, v: View, p: Plan, scene: HouseScene): void {
  const restored = scene.restored.has('sign');
  const pearlInc = restored && scene.brand === 'pearl-inc';
  const mid = p.body / 2;
  const w = pearlInc ? 1.0 : 0.82;
  const a = v.P(mid - w / 2, p.top + 0.06, 0);
  const b = v.P(mid + w / 2, p.top + 0.21, 0);
  const x0 = a[0];
  const y0 = b[1];
  const sw = b[0] - a[0];
  const sh = a[1] - b[1];
  roundedRect(c, x0, y0, sw, sh, sh * 0.22);
  const paint = c.createLinearGradient(0, y0, 0, y0 + sh);
  paint.addColorStop(0, pearlInc ? '#22324a' : restored ? '#fff0c9' : '#8f8676');
  paint.addColorStop(1, pearlInc ? '#101a2a' : restored ? '#d7b87c' : '#5f6461');
  c.fillStyle = paint;
  c.fill();
  c.lineWidth = Math.max(1, v.s * 0.008);
  c.strokeStyle = pearlInc ? '#d8b25a' : restored ? '#c9a25a' : '#485056';
  c.stroke();
  c.textAlign = 'center';
  c.textBaseline = 'middle';
  const cx = x0 + sw / 2;
  if (pearlInc) {
    c.font = `400 ${Math.round(sh * 0.5)}px ${SERIF}`;
    c.fillStyle = '#e8c46a';
    c.fillText('PEARL INC.', cx, y0 + sh * 0.42, sw * 0.9);
    c.font = `600 ${Math.max(5, Math.round(sh * 0.18))}px ${SANS}`;
    c.fillText('J O A I L L I E R S', cx, y0 + sh * 0.8, sw * 0.9);
    return;
  }
  c.font = `700 ${Math.round(sh * (restored ? 0.42 : 0.38))}px ${SERIF}`;
  c.fillStyle = restored ? '#65483a' : 'rgba(27,37,40,.75)';
  c.fillText(restored ? 'MAISON ROSE' : 'R  SE', cx, y0 + sh * 0.42, sw * 0.9);
  c.font = `600 ${Math.max(5, Math.round(sh * 0.17))}px ${SANS}`;
  c.fillStyle = restored ? '#80684d' : 'rgba(30,35,36,.5)';
  c.fillText('PERLES FINES', cx, y0 + sh * 0.79, sw * 0.9);
}

/** La tour de la Maison de haute joaillerie : dôme doré et flèche. */
function drawTower(c: Ctx, v: View, p: Plan, f: Facade): void {
  const { P } = v;
  const mid = p.body / 2;
  const base = p.top + ROOF_H - 0.12;
  const z = DEPTH / 2;
  box(c, v, mid - 0.16, base, z - 0.1, 0.32, 0.4, 0.2, f.siding);
  for (const fx of [-0.1, 0.04]) {
    const a = P(mid + fx, base + 0.12, z - 0.1);
    const b = P(mid + fx + 0.06, base + 0.3, z - 0.1);
    c.fillStyle = '#ffe0a0';
    c.fillRect(a[0], b[1], b[0] - a[0], a[1] - b[1]);
  }
  const [dx, dy] = P(mid, base + 0.4, z);
  const r = v.s * 0.17;
  const g = c.createRadialGradient(dx - r * 0.3, dy - r * 0.5, r * 0.1, dx, dy - r * 0.2, r * 1.1);
  g.addColorStop(0, '#fff1b8');
  g.addColorStop(0.5, '#d8b25a');
  g.addColorStop(1, '#8a6420');
  c.fillStyle = g;
  c.beginPath();
  c.ellipse(dx + v.s * 0.06, dy, r, r * 0.9, 0, Math.PI, 0);
  c.fill();
  line(c, [dx + v.s * 0.06, dy - r * 0.9], [dx + v.s * 0.06, dy - r * 1.6], '#d8b25a', Math.max(1, v.s * 0.008));
}

/** La lanterne, accrochée à l'angle de la boutique, côté ponton. */
function lanternPos(v: View): Pt {
  return v.P(-0.13, 0.5, 0.02);
}

function drawLantern(c: Ctx, v: View, lit: boolean): void {
  const [lx, ly] = lanternPos(v);
  const [wx, wy] = v.P(-WALL, 0.58, 0.02);
  line(c, [wx, wy], [lx, wy], '#2f2a26', Math.max(1, v.s * 0.008));
  line(c, [lx, wy], [lx, ly - v.s * 0.04], '#2f2a26', Math.max(0.8, v.s * 0.005));
  const r = v.s * 0.035;
  c.fillStyle = '#2f2a26';
  c.beginPath();
  c.moveTo(lx - r * 0.9, ly - r * 0.9);
  c.lineTo(lx + r * 0.9, ly - r * 0.9);
  c.lineTo(lx, ly - r * 1.6);
  c.closePath();
  c.fill();
  c.fillStyle = lit ? '#ffd27a' : 'rgba(80,90,90,.6)';
  c.fillRect(lx - r * 0.7, ly - r * 0.9, r * 1.4, r * 1.6);
  c.strokeStyle = '#2f2a26';
  c.lineWidth = Math.max(0.8, v.s * 0.005);
  c.strokeRect(lx - r * 0.7, ly - r * 0.9, r * 1.4, r * 1.6);
  if (!lit) line(c, [lx - r * 0.5, ly - r * 0.6], [lx + r * 0.3, ly + r * 0.4], 'rgba(220,230,230,.5)', 0.8);
}

/** Jardinières (boutique repeinte), puis fanion Pearl Inc. au faîte. */
function drawDressing(c: Ctx, v: View, p: Plan, f: Facade, stage: number): void {
  const { P } = v;
  if (stage >= 2) {
    for (const x of [0.12, SPLIT + 0.12]) {
      box(c, v, x, GROUND_H + WALL / 2, -0.06, 0.3, 0.06, 0.06, '#5a3a28');
      for (let k = 0; k < 6; k++) {
        const [fx, fy] = P(x + 0.03 + k * 0.05, GROUND_H + WALL / 2 + 0.07, -0.03);
        c.fillStyle = ['#ff8fb0', '#ffd27a', '#ffffff'][k % 3];
        c.beginPath();
        c.arc(fx, fy, v.s * 0.014, 0, TAU);
        c.fill();
      }
    }
  }
  if (stage >= 3 && !p.tower) {
    const [px, py] = P(p.body / 2, p.top + ROOF_H, -0.04);
    line(c, [px, py], [px, py - v.s * 0.2], f.trim, Math.max(1, v.s * 0.008));
    c.fillStyle = '#22324a';
    c.beginPath();
    c.moveTo(px, py - v.s * 0.2);
    c.lineTo(px + v.s * 0.12, py - v.s * 0.17);
    c.lineTo(px, py - v.s * 0.14);
    c.closePath();
    c.fill();
  }
}

// ---------- Ce qui bouge ----------

function drawStars(c: Ctx, v: View, t: number): void {
  for (let i = 0; i < 40; i++) {
    const sx = ((i * 0.6180339) % 1) * v.w;
    const sy = ((i * 0.649) % 1) * v.horizon * 0.85;
    const a = 0.25 + 0.5 * (0.5 + 0.5 * Math.sin(t * 1.3 + i * 2.1));
    c.fillStyle = `rgba(255,255,255,${a})`;
    c.fillRect(sx, sy, 1.3, 1.3);
  }
}

function drawLife(c: Ctx, v: View, p: Plan, scene: HouseScene, t: number): void {
  const { P } = v;
  const has = (f: HouseFeature) => scene.restored.has(f);
  const hasRoom = (kind: RoomKind) => p.rooms.some((r) => r.kind === kind);
  // Fumée de la cheminée.
  const [cx, cy] = P(p.body * 0.74 + 0.06, p.top + ROOF_H * 0.42 + 0.36, DEPTH * 0.55 + 0.06);
  for (let k = 0; k < 4; k++) {
    const u = (t * 0.25 + k / 4) % 1;
    c.fillStyle = `rgba(200,210,215,${0.22 * (1 - u)})`;
    c.beginPath();
    c.arc(cx + Math.sin(t + k) * v.s * 0.03 + u * v.s * 0.08, cy - u * v.s * 0.4, v.s * (0.03 + u * 0.05), 0, TAU);
    c.fill();
  }
  // Lanterne qui vacille, et son reflet dans l'eau.
  if (has('lantern')) {
    const [lx, ly] = lanternPos(v);
    const flicker = 0.8 + 0.2 * Math.sin(t * 9) * Math.sin(t * 3.7);
    glow(c, lx, ly, v.s * 0.32, '#ffbf63', 0.45 * flicker);
    c.save();
    c.globalAlpha = 0.35 * flicker;
    c.fillStyle = '#ffbf63';
    for (let k = 0; k < 6; k++) {
      const y = v.waterY + v.s * 0.03 + k * v.s * 0.035;
      const half = v.s * (0.05 - k * 0.006) * (1 + 0.3 * Math.sin(t * 2 + k));
      c.fillRect(lx - half, y, half * 2, 1.4);
    }
    c.restore();
  }
  // Les pièces éclairées respirent doucement.
  for (const room of p.rooms) {
    if (!isLit(room.kind, scene)) continue;
    const [rx, ry] = P(room.x + room.w / 2, room.y + room.h * 0.6, DEPTH * 0.5);
    glow(c, rx, ry, v.s * room.w * 0.5, ROOM_STYLE[room.kind].light, 0.08 + 0.02 * Math.sin(t * 0.8 + room.x));
  }
  // La bougie du bureau.
  if (has('notebook') && hasRoom('bureau')) {
    const [bx, by] = P(0.28 + 0.372, GROUND_H + 0.33, DEPTH - 0.26 + 0.072);
    c.fillStyle = '#ffcf6b';
    c.beginPath();
    c.ellipse(bx, by - Math.sin(t * 11) * 0.6, v.s * 0.008, v.s * 0.016, 0, 0, TAU);
    c.fill();
    glow(c, bx, by, v.s * 0.12, '#ffb347', 0.35 + 0.08 * Math.sin(t * 7));
  }
  // La boîte du grenier pulse.
  if (has('box') && hasRoom('grenier')) {
    const [gx, gy] = P(SPLIT + 0.5, GROUND_H + 0.1, 0.22);
    glow(c, gx, gy, v.s * 0.22, '#ff2f72', 0.28 + 0.18 * Math.sin(t * 2.2));
  }
  // La lampe de l'établi.
  if (has('workbench')) {
    const [ax, ay] = P(SPLIT + 0.12 + 0.58, 0.46, DEPTH - 0.14);
    glow(c, ax, ay, v.s * 0.2, '#fff1c4', 0.3);
  }
  // Le lustre du salon Pearl Inc. scintille.
  if (hasRoom('salon')) {
    const [sx, sy] = P(1, p.top - FLOOR_H + 0.56, DEPTH / 2);
    glow(c, sx, sy, v.s * 0.3, '#fff0c8', 0.3 + 0.1 * Math.sin(t * 1.5));
  }
  // Rides de l'eau.
  c.save();
  c.strokeStyle = 'rgba(180,220,230,.12)';
  c.lineWidth = 1;
  for (let k = 0; k < 7; k++) {
    const y = v.waterY + (k * 0.06 + 0.02) * v.s;
    const off = Math.sin(t * 0.7 + k) * v.s * 0.1;
    c.beginPath();
    c.moveTo(v.w * 0.05 + off, y);
    c.lineTo(v.w * 0.35 + off, y);
    c.moveTo(v.w * 0.55 - off, y + 3);
    c.lineTo(v.w * 0.9 - off, y + 3);
    c.stroke();
  }
  c.restore();
}

/** Centre d'un élément, pour placer l'éclat de restauration. */
function anchor(v: View, p: Plan, feature: HouseFeature): Pt {
  const { P } = v;
  switch (feature) {
    case 'door':
      return P(0, 0.28, 0.28);
    case 'lantern':
      return lanternPos(v);
    case 'sign':
      return P(p.body / 2, p.top + 0.13, 0);
    case 'notebook':
      return P(0.5, GROUND_H + 0.3, DEPTH - 0.2);
    case 'workbench':
      return P(SPLIT + 0.45, 0.3, DEPTH - 0.14);
    case 'vitrine':
      return P(0.5, 0.28, 0.2);
    case 'box':
      return P(SPLIT + 0.5, GROUND_H + 0.06, 0.22);
  }
}

// ---------- Assemblage ----------

const showcaseIds = new WeakMap<HTMLCanvasElement, number>();
let nextShowcaseId = 1;
let cache: { key: string; canvas: HTMLCanvasElement } | null = null;

/** Tout ce qui ne bouge pas, dessiné une fois par taille et par état de la Maison. */
function staticLayer(w: number, h: number, ratio: number, scene: HouseScene, p: Plan, v: View): HTMLCanvasElement {
  let showcaseId = 0;
  if (scene.showcase) {
    if (!showcaseIds.has(scene.showcase)) showcaseIds.set(scene.showcase, nextShowcaseId++);
    showcaseId = showcaseIds.get(scene.showcase)!;
  }
  const key = [w, h, ratio, scene.stage, scene.brand, [...scene.restored].sort().join(','), showcaseId].join('|');
  if (cache?.key === key) return cache.canvas;
  const canvas = document.createElement('canvas');
  canvas.width = Math.max(1, Math.round(w * ratio));
  canvas.height = Math.max(1, Math.round(h * ratio));
  const c = canvas.getContext('2d')!;
  c.scale(ratio, ratio);
  const f = facadeFor(scene.stage);
  drawSkyAndSea(c, v, scene.stage);
  drawDeck(c, v, p, f);
  for (const room of p.rooms) drawRoom(c, v, room, scene);
  drawCuts(c, v, p, f);
  drawRoof(c, v, p, f, scene);
  if (p.tower) drawTower(c, v, p, f);
  drawDressing(c, v, p, f, scene.stage);
  drawLantern(c, v, scene.restored.has('lantern'));
  cache = { key, canvas };
  return canvas;
}

export function drawHouse(c: Ctx, w: number, h: number, scene: HouseScene, t: number): void {
  const p = plan(scene.stage);
  const v = makeView(w, h, p);
  const ratio = c.getTransform().a || 1;
  c.drawImage(staticLayer(w, h, ratio, scene, p, v), 0, 0, w, h);
  drawStars(c, v, t);
  drawLife(c, v, p, scene, t);
  if (!scene.appearing) return;
  // L'éclat de la restauration : un halo et une couronne d'étincelles.
  const [ax, ay] = anchor(v, p, scene.appearing.feature);
  const u = scene.appearing.progress;
  const burst = Math.sin(u * Math.PI);
  glow(c, ax, ay, v.s * (0.2 + u * 0.5), '#fff1c4', 0.8 * burst);
  for (let k = 0; k < 10; k++) {
    const a = (k / 10) * TAU + u * 2;
    const r = v.s * (0.08 + u * 0.35);
    c.fillStyle = `rgba(255,240,200,${burst})`;
    c.beginPath();
    c.arc(ax + Math.cos(a) * r, ay + Math.sin(a) * r * 0.7, v.s * 0.012 * (1 - u * 0.5), 0, TAU);
    c.fill();
  }
}
