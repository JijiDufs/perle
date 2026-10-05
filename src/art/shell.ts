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

const EXTERIOR_BANDS = ['#3a322b', '#57493c', '#2e2722', '#6a5a49', '#433931', '#7a6a57', '#3b332c'];

/** Extérieur de la valve : bandes de croissance brunes et bord dentelé. */
export function drawShellExterior(c: CanvasRenderingContext2D, ax: number, ay: number, angle: number, L: number, ph: Phases): void {
  EXTERIOR_BANDS.forEach((color, k) => {
    tracePath(c, shellOutline(ax, ay, angle, L * (1 - k * 0.085), [ph[0] + k * 0.2, ph[1], ph[2] + k], 0.045 - k * 0.004));
    c.fillStyle = color;
    c.fill();
    c.lineWidth = 2;
    c.strokeStyle = 'rgba(220,200,170,.10)';
    c.stroke();
  });
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
