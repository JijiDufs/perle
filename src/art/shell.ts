// Dessin procédural de la coquille (Canvas 2D), repris du prototype Duo.
// Chaque valve part de la charnière (ax, ay) dans la direction `angle`, sur une longueur L.
// `phases` rend chaque huître unique (bosses, dentelure).

export type Phases = readonly [number, number, number];
type Point = [number, number];

export function randomPhases(random: () => number): Phases {
  return [random() * 6.3, random() * 6.3, random() * 6.3];
}

export function shellOutline(ax: number, ay: number, angle: number, L: number, ph: Phases, frill: number): Point[] {
  const points: Point[] = [];
  const steps = 110;
  const ca = Math.cos(angle);
  const sa = Math.sin(angle);
  for (let i = 0; i <= steps; i++) {
    const f = -1.42 + (2.84 * i) / steps;
    let r = L * Math.pow(Math.cos(f), 0.55) * (1 + 0.06 * Math.sin(f * 3 + ph[0]) + 0.04 * Math.sin(f * 7 + ph[1]));
    if (frill) r *= 1 + frill * Math.sin(f * 38 + ph[2]) * Math.pow(Math.cos(f), 0.3);
    const x = Math.cos(f) * r;
    const y = Math.sin(f) * r * 1.05;
    points.push([ax + x * ca - y * sa, ay + x * sa + y * ca]);
  }
  return points;
}

export function tracePath(c: CanvasRenderingContext2D, points: Point[]): void {
  c.beginPath();
  c.moveTo(points[0][0], points[0][1]);
  for (let i = 1; i < points.length; i++) c.lineTo(points[i][0], points[i][1]);
  c.closePath();
}

/** Couleurs des bandes de croissance [éclairée, dans l'ombre], de l'extérieur vers la charnière. */
const EXTERIOR_BANDS: readonly [string, string][] = [
  ['#5a4a3c', '#2a211b'],
  ['#7b6853', '#3e3229'],
  ['#4a3f36', '#221b17'],
  ['#988267', '#4f4236'],
  ['#6a5a4b', '#30271f'],
  ['#ad9878', '#5d4e3e'],
  ['#5d5246', '#2d261f'],
];

interface CachedShell {
  canvas: HTMLCanvasElement;
  /** Position de la charnière dans l'image. */
  ox: number;
  oy: number;
  scale: number;
}

const exteriorCache = new Map<string, CachedShell>();

/** Petit hasard déterministe tiré des phases : chaque huître garde ses taches et ses balanes. */
function shellRandom(ph: Phases): () => number {
  let seed = Math.floor((ph[0] * 1000 + ph[1] * 100 + ph[2] * 10) % 2147483646) + 1;
  return () => (seed = (seed * 16807) % 2147483647) / 2147483647;
}

/** Dessine l'extérieur une fois, charnière en (0, 0), avec relief, stries, taches et balanes. */
function paintExterior(c: CanvasRenderingContext2D, angle: number, L: number, ph: Phases): void {
  const rand = shellRandom(ph);
  const ca = Math.cos(angle);
  const sa = Math.sin(angle);
  // Point le plus éclairé : vers la surface (en haut), un peu à gauche.
  const lx = -L * 0.25;
  const ly = L * 0.15;

  EXTERIOR_BANDS.forEach(([light, dark], k) => {
    const outline = shellOutline(0, 0, angle, L * (1 - k * 0.085), [ph[0] + k * 0.2, ph[1], ph[2] + k], 0.045 - k * 0.004);
    // Ombre portée de la bande sur la précédente.
    c.save();
    c.translate(L * 0.006, L * 0.014);
    tracePath(c, outline);
    c.fillStyle = 'rgba(10, 6, 4, 0.35)';
    c.fill();
    c.restore();
    tracePath(c, outline);
    const g = c.createRadialGradient(lx, ly, L * 0.05, lx, ly, L * 1.25);
    g.addColorStop(0, light);
    g.addColorStop(1, dark);
    c.fillStyle = g;
    c.fill();
    // Liseré éclairé sur le bord dentelé.
    c.lineWidth = Math.max(1, L * 0.006);
    c.strokeStyle = `rgba(255, 238, 210, ${0.16 + k * 0.015})`;
    c.stroke();
  });

  // Stries qui rayonnent depuis la charnière, et texture : taches, algues, balanes.
  c.save();
  tracePath(c, shellOutline(0, 0, angle, L, ph, 0.045));
  c.clip();
  for (let i = 0; i < 22; i++) {
    const f = -1.3 + (2.6 * i) / 21 + (rand() - 0.5) * 0.05;
    const dx = Math.cos(f) * L * 1.1;
    const dy = Math.sin(f) * L * 1.1;
    const ex = dx * ca - dy * sa;
    const ey = dx * sa + dy * ca;
    c.strokeStyle = 'rgba(20, 12, 8, 0.16)';
    c.lineWidth = L * 0.008;
    c.beginPath();
    c.moveTo(0, 0);
    c.lineTo(ex, ey);
    c.stroke();
    c.strokeStyle = 'rgba(255, 240, 220, 0.07)';
    c.lineWidth = L * 0.005;
    c.beginPath();
    c.moveTo(L * 0.008, 0);
    c.lineTo(ex + L * 0.01, ey);
    c.stroke();
  }
  // Traces d'algues vertes près du bord.
  for (let i = 0; i < 3; i++) {
    const f = -1 + rand() * 2;
    const r = L * (0.6 + rand() * 0.3);
    const x = Math.cos(f) * r * ca - Math.sin(f) * r * sa;
    const y = Math.cos(f) * r * sa + Math.sin(f) * r * ca;
    const g = c.createRadialGradient(x, y, 0, x, y, L * 0.22);
    g.addColorStop(0, 'rgba(90, 140, 90, 0.32)');
    g.addColorStop(1, 'rgba(90, 140, 90, 0)');
    c.fillStyle = g;
    c.fillRect(x - L * 0.25, y - L * 0.25, L * 0.5, L * 0.5);
  }
  // Petites taches claires et sombres.
  for (let i = 0; i < 70; i++) {
    const f = -1.35 + rand() * 2.7;
    const r = L * Math.sqrt(rand()) * 0.98;
    const x = Math.cos(f) * r * ca - Math.sin(f) * r * sa;
    const y = Math.cos(f) * r * sa + Math.sin(f) * r * ca;
    c.fillStyle = rand() > 0.5 ? `rgba(255, 245, 225, ${0.06 + rand() * 0.1})` : `rgba(15, 8, 5, ${0.1 + rand() * 0.15})`;
    c.beginPath();
    c.arc(x, y, L * (0.004 + rand() * 0.01), 0, Math.PI * 2);
    c.fill();
  }
  // Balanes : petits cônes beiges, plissés, ouverts d'une fente (pas de rond sombre : on dirait des yeux).
  for (let i = 0; i < 3; i++) {
    const f = -1.1 + rand() * 2.2;
    const r = L * (0.45 + rand() * 0.45);
    const x = Math.cos(f) * r * ca - Math.sin(f) * r * sa;
    const y = Math.cos(f) * r * sa + Math.sin(f) * r * ca;
    const br = L * (0.016 + rand() * 0.014);
    c.save();
    c.translate(x, y);
    c.rotate(rand() * Math.PI);
    const g = c.createRadialGradient(-br * 0.3, -br * 0.3, br * 0.1, 0, 0, br);
    g.addColorStop(0, 'rgba(225, 214, 192, 0.9)');
    g.addColorStop(1, 'rgba(120, 108, 92, 0.85)');
    c.fillStyle = g;
    c.beginPath();
    for (let p = 0; p < 12; p++) {
      const a = (p / 12) * Math.PI * 2;
      const rr = br * (p % 2 ? 0.86 : 1);
      c.lineTo(Math.cos(a) * rr, Math.sin(a) * rr * 0.85);
    }
    c.closePath();
    c.fill();
    c.strokeStyle = 'rgba(70, 58, 48, 0.6)';
    c.lineWidth = Math.max(0.8, br * 0.18);
    c.beginPath();
    c.moveTo(-br * 0.35, 0);
    c.lineTo(br * 0.35, 0);
    c.stroke();
    c.restore();
  }
  // Reflet de la lumière du dessus.
  const sheen = c.createRadialGradient(lx, ly, 0, lx, ly, L * 0.7);
  sheen.addColorStop(0, 'rgba(255, 250, 235, 0.16)');
  sheen.addColorStop(1, 'rgba(255, 250, 235, 0)');
  c.fillStyle = sheen;
  c.fillRect(-L * 1.2, -L * 0.2, L * 2.4, L * 1.5);
  c.restore();
}

/** Extérieur de la valve : bandes de croissance en relief et bord dentelé (gardé en cache : c'est le dessin le plus lourd). */
export function drawShellExterior(c: CanvasRenderingContext2D, ax: number, ay: number, angle: number, L: number, ph: Phases): void {
  const scale = Math.min(typeof window === 'undefined' ? 1 : window.devicePixelRatio || 1, 2);
  const key = `${Math.round(L)}|${angle.toFixed(3)}|${ph.join(',')}|${scale}`;
  let cached = exteriorCache.get(key);
  if (!cached) {
    const points = shellOutline(0, 0, angle, L, ph, 0.05);
    const xs = points.map((p) => p[0]);
    const ys = points.map((p) => p[1]);
    const pad = L * 0.06;
    const minX = Math.min(...xs, 0) - pad;
    const minY = Math.min(...ys, 0) - pad;
    const canvas = document.createElement('canvas');
    canvas.width = Math.ceil((Math.max(...xs, 0) + pad - minX) * scale);
    canvas.height = Math.ceil((Math.max(...ys, 0) + pad - minY) * scale);
    const cc = canvas.getContext('2d')!;
    cc.scale(scale, scale);
    cc.translate(-minX, -minY);
    paintExterior(cc, angle, L, ph);
    cached = { canvas, ox: -minX, oy: -minY, scale };
    if (exteriorCache.size > 8) exteriorCache.delete(exteriorCache.keys().next().value!);
    exteriorCache.set(key, cached);
  }
  c.drawImage(cached.canvas, ax - cached.ox, ay - cached.oy, cached.canvas.width / cached.scale, cached.canvas.height / cached.scale);
}

/** Intérieur nacré, irisé, avec des reflets qui tournent lentement (t en secondes). */
export function drawNacre(c: CanvasRenderingContext2D, ax: number, ay: number, angle: number, L: number, ph: Phases, t: number): void {
  c.save();
  tracePath(c, shellOutline(ax, ay, angle, L, ph, 0));
  c.clip();
  const cx = ax + Math.cos(angle) * L * 0.5;
  const cy = ay + Math.sin(angle) * L * 0.5;
  const base = c.createRadialGradient(cx, cy, L * 0.05, cx, cy, L * 0.85);
  base.addColorStop(0, '#fdfaff');
  base.addColorStop(0.5, '#e7ddf2');
  base.addColorStop(1, '#a99fbd');
  c.fillStyle = base;
  c.fillRect(cx - L, cy - L, L * 2, L * 2);
  if ('createConicGradient' in c) {
    const iris = c.createConicGradient(t * 0.15 + ph[0], cx, cy);
    const colors = ['#ffd1e8', '#c9f2ff', '#fff2c4', '#d9ccff', '#c4ffe9', '#ffd1e8'];
    colors.forEach((col, i) => iris.addColorStop(i / (colors.length - 1), col));
    c.globalAlpha = 0.32;
    c.fillStyle = iris;
    c.fillRect(cx - L, cy - L, L * 2, L * 2);
    c.globalAlpha = 1;
  }
  for (let i = 0; i < 6; i++) {
    c.beginPath();
    c.ellipse(ax, ay, L * (0.35 + i * 0.11), L * (0.3 + i * 0.1), angle, -1.2, 1.2);
    c.strokeStyle = 'rgba(255,255,255,.12)';
    c.lineWidth = L * 0.01;
    c.stroke();
  }
  c.restore();
}

/** Chair de l'huître, autour de la perle (à mi-longueur de la valve). */
export function drawFlesh(c: CanvasRenderingContext2D, ax: number, ay: number, angle: number, L: number, ph: Phases): void {
  const fx = ax + Math.cos(angle) * L * 0.5;
  const fy = ay + Math.sin(angle) * L * 0.5;
  const rx = L * 0.34;
  const ry = L * 0.37;
  c.save();
  c.translate(fx, fy);
  c.rotate(angle);
  c.beginPath();
  for (let i = 0; i <= 140; i++) {
    const a = (i / 140) * Math.PI * 2;
    const w = 1 + 0.022 * Math.sin(a * 24 + ph[2]) + 0.035 * Math.sin(a * 5);
    c.lineTo(Math.cos(a) * rx * w, Math.sin(a) * ry * w);
  }
  c.closePath();
  const g = c.createRadialGradient(-rx * 0.2, -ry * 0.2, rx * 0.1, 0, 0, rx * 1.1);
  g.addColorStop(0, '#f4e8d2');
  g.addColorStop(0.7, '#d8c3a0');
  g.addColorStop(1, '#a88f6d');
  c.fillStyle = g;
  c.fill();
  c.lineWidth = L * 0.01;
  c.strokeStyle = 'rgba(98,80,64,.55)';
  c.stroke();
  for (let k = 1; k < 4; k++) {
    c.beginPath();
    c.ellipse(-rx * 0.1, 0, rx * (0.45 + k * 0.14), ry * (0.5 + k * 0.13), 0, -1.1, 1.1);
    c.strokeStyle = 'rgba(120,95,70,.22)';
    c.lineWidth = L * 0.007;
    c.stroke();
  }
  c.restore();
}
