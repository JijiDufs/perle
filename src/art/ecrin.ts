// Dessin de l'écrin (Canvas 2D) : velours, satin capitonné, filets d'or. Repris du prototype Duo.
import { shade } from './color';
import { goldGradient, lighten } from './jewel';

type Ctx = CanvasRenderingContext2D;

export const VELVETS = ['#1d2b5c', '#5a1030', '#0f3d33', '#22202a'];

export function roundRectPath(c: Ctx, x: number, y: number, w: number, h: number, r: number): void {
  c.beginPath();
  c.moveTo(x + r, y);
  c.arcTo(x + w, y, x + w, y + h, r);
  c.arcTo(x + w, y + h, x, y + h, r);
  c.arcTo(x, y + h, x, y, r);
  c.arcTo(x, y, x + w, y, r);
  c.closePath();
}

/** Velours : couleur, grain fin et vignettage. `seed` fixe le grain pour qu'il ne scintille pas. */
export function fillVelvet(c: Ctx, x: number, y: number, w: number, h: number, color: string, seed = 1): void {
  c.fillStyle = color;
  c.fillRect(x, y, w, h);
  let state = seed;
  const random = () => ((state = (state * 16807) % 2147483647) - 1) / 2147483646;
  for (let i = 0; i < (w * h) / 90; i++) {
    c.fillStyle = random() < 0.5 ? 'rgba(255,255,255,.035)' : 'rgba(0,0,0,.07)';
    c.fillRect(x + random() * w, y + random() * h, 1.5, 1.5);
  }
  const g = c.createRadialGradient(x + w / 2, y + h / 2, Math.min(w, h) * 0.2, x + w / 2, y + h / 2, Math.max(w, h) * 0.75);
  g.addColorStop(0, 'rgba(255,255,255,.08)');
  g.addColorStop(1, 'rgba(0,0,0,.45)');
  c.fillStyle = g;
  c.fillRect(x, y, w, h);
}

/** Pré-rendu de l'écrin pour une taille donnée : base (coussin de velours) et couvercle (extérieur / satin intérieur). */
export interface EcrinArt {
  base: HTMLCanvasElement;
  lidOutside: HTMLCanvasElement;
  lidInside: HTMLCanvasElement;
}

function makeCanvas(w: number, h: number, dpr: number): [HTMLCanvasElement, Ctx] {
  const canvas = document.createElement('canvas');
  canvas.width = Math.round(w * dpr);
  canvas.height = Math.round(h * dpr);
  const c = canvas.getContext('2d')!;
  c.scale(dpr, dpr);
  return [canvas, c];
}

export function renderEcrinArt(w: number, h: number, velvet: string, dpr: number): EcrinArt {
  const radius = Math.min(w, h) * 0.08;
  const border = Math.max(2, w * 0.008);

  // Base : coffret de velours, coussin bombé, filet d'or.
  const [base, b] = makeCanvas(w, h, dpr);
  roundRectPath(b, 0, 0, w, h, radius);
  b.save();
  b.clip();
  fillVelvet(b, 0, 0, w, h, shade(velvet, 0.25), 7);
  const inset = w * 0.07;
  roundRectPath(b, inset, inset, w - inset * 2, h - inset * 2, radius * 1.6);
  const cushion = b.createLinearGradient(0, inset, 0, h - inset);
  cushion.addColorStop(0, lighten(velvet, 0.2));
  cushion.addColorStop(0.5, velvet);
  cushion.addColorStop(1, shade(velvet, 0.4));
  b.fillStyle = cushion;
  b.fill();
  b.lineWidth = border;
  b.strokeStyle = 'rgba(0,0,0,.35)';
  b.stroke();
  b.restore();
  b.lineWidth = border * 1.5;
  b.strokeStyle = goldGradient(b, 0, 0, w, h);
  roundRectPath(b, border, border, w - border * 2, h - border * 2, radius);
  b.stroke();

  // Couvercle, extérieur : velours, double filet d'or, monogramme.
  const [lidOutside, o] = makeCanvas(w, h, dpr);
  roundRectPath(o, 0, 0, w, h, radius);
  o.save();
  o.clip();
  fillVelvet(o, 0, 0, w, h, velvet, 3);
  o.restore();
  o.lineWidth = border * 2;
  o.strokeStyle = goldGradient(o, 0, 0, w, h);
  roundRectPath(o, border * 2, border * 2, w - border * 4, h - border * 4, radius);
  o.stroke();
  o.lineWidth = border * 0.7;
  roundRectPath(o, w * 0.06, w * 0.06, w - w * 0.12, h - w * 0.12, radius * 0.8);
  o.stroke();
  o.textAlign = 'center';
  o.textBaseline = 'middle';
  o.font = `${Math.round(h * 0.42)}px "Young Serif", Georgia, serif`;
  o.fillStyle = 'rgba(255,255,255,.07)';
  o.fillText('É', w / 2 + 2, h * 0.53 + 2);
  o.fillStyle = 'rgba(0,0,0,.34)';
  o.fillText('É', w / 2, h * 0.53);

  // Couvercle, intérieur : satin crème capitonné, reflet.
  const [lidInside, n] = makeCanvas(w, h, dpr);
  roundRectPath(n, 0, 0, w, h, radius);
  n.save();
  n.clip();
  const satin = n.createLinearGradient(0, 0, w, h);
  satin.addColorStop(0, '#f6eedf');
  satin.addColorStop(1, '#d6c6a8');
  n.fillStyle = satin;
  n.fillRect(0, 0, w, h);
  const step = w * 0.12;
  n.lineWidth = Math.max(1, w * 0.004);
  n.strokeStyle = 'rgba(120,96,60,.22)';
  for (let d = -h; d < w + h; d += step) {
    n.beginPath();
    n.moveTo(d, 0);
    n.lineTo(d + h, h);
    n.stroke();
    n.beginPath();
    n.moveTo(d, 0);
    n.lineTo(d - h, h);
    n.stroke();
  }
  const sheen = n.createLinearGradient(0, 0, w, 0);
  sheen.addColorStop(0, 'rgba(255,255,255,0)');
  sheen.addColorStop(0.45, 'rgba(255,255,255,.28)');
  sheen.addColorStop(0.62, 'rgba(255,255,255,0)');
  n.fillStyle = sheen;
  n.fillRect(0, 0, w, h);
  n.restore();
  n.lineWidth = border * 1.5;
  n.strokeStyle = goldGradient(n, 0, 0, w, h);
  roundRectPath(n, border, border, w - border * 2, h - border * 2, radius);
  n.stroke();
  n.textAlign = 'center';
  n.textBaseline = 'middle';
  n.fillStyle = goldGradient(n, w * 0.3, h * 0.3, w * 0.7, h * 0.7);
  n.font = `600 ${Math.round(h * 0.05)}px "Figtree", system-ui, sans-serif`;
  n.fillText('MAISON', w / 2, h * 0.36);
  n.font = `${Math.round(h * 0.16)}px "Young Serif", Georgia, serif`;
  n.fillText('Écrin', w / 2, h * 0.52);

  return { base, lidOutside, lidInside };
}
