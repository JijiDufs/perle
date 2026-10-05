// Dessin de l'écrin (Canvas 2D) : coffret de velours en relief (couvercle bombé, médaillon à la perle,
// cadre d'or biseauté, tranches avant avec fermoir), satin capitonné à l'intérieur.
import { shade } from './color';
import { goldGradient, lighten } from './jewel';

type Ctx = CanvasRenderingContext2D;

export const VELVETS = ['#1d2b5c', '#5a1030', '#0f4a3c', '#3d1747'];

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

/** Rectangle aux coins arrondis ajouté à un Path2D (sans `roundRect`, récent sur Safari). */
function addRoundRect(path: Path2D, x: number, y: number, w: number, h: number, r: number): void {
  path.moveTo(x + r, y);
  path.arcTo(x + w, y, x + w, y + h, r);
  path.arcTo(x + w, y + h, x, y + h, r);
  path.arcTo(x, y + h, x, y, r);
  path.arcTo(x, y, x + w, y, r);
  path.closePath();
}

/** Grain de velours seul (sans fond), pour les surfaces déjà peintes. */
function fillGrain(c: Ctx, x: number, y: number, w: number, h: number, seed: number): void {
  let state = seed;
  const random = () => ((state = (state * 16807) % 2147483647) - 1) / 2147483646;
  for (let i = 0; i < (w * h) / 80; i++) {
    c.fillStyle = random() < 0.5 ? 'rgba(255,255,255,.04)' : 'rgba(0,0,0,.08)';
    c.fillRect(x + random() * w, y + random() * h, 1.4, 1.4);
  }
}

/** Pré-rendu de l'écrin pour une taille donnée : base (coussin de velours) et couvercle (extérieur / satin intérieur). */
export interface EcrinArt {
  base: HTMLCanvasElement;
  lidOutside: HTMLCanvasElement;
  lidInside: HTMLCanvasElement;
  /** Tranche avant de la base et du couvercle (profondeur du coffret), et leurs hauteurs. */
  baseFront: HTMLCanvasElement;
  lidFront: HTMLCanvasElement;
  baseFrontHeight: number;
  lidFrontHeight: number;
}

/** Perle en volume (médaillon du couvercle). */
function pearlSphere(c: Ctx, x: number, y: number, r: number): void {
  const shadow = c.createRadialGradient(x + r * 0.15, y + r * 0.35, 0, x + r * 0.15, y + r * 0.35, r * 1.3);
  shadow.addColorStop(0, 'rgba(0,0,0,.45)');
  shadow.addColorStop(1, 'rgba(0,0,0,0)');
  c.fillStyle = shadow;
  c.beginPath();
  c.arc(x + r * 0.15, y + r * 0.35, r * 1.3, 0, Math.PI * 2);
  c.fill();
  const g = c.createRadialGradient(x - r * 0.35, y - r * 0.4, r * 0.05, x, y, r);
  g.addColorStop(0, '#ffffff');
  g.addColorStop(0.35, '#f6efe4');
  g.addColorStop(0.8, '#cdbfae');
  g.addColorStop(1, '#8d8070');
  c.fillStyle = g;
  c.beginPath();
  c.arc(x, y, r, 0, Math.PI * 2);
  c.fill();
  // Irisation discrète et reflet net.
  const iris = c.createLinearGradient(x - r, y + r, x + r, y - r);
  iris.addColorStop(0, 'rgba(255, 190, 220, .25)');
  iris.addColorStop(0.5, 'rgba(190, 240, 255, 0)');
  iris.addColorStop(1, 'rgba(255, 240, 190, .2)');
  c.fillStyle = iris;
  c.beginPath();
  c.arc(x, y, r, 0, Math.PI * 2);
  c.fill();
  c.fillStyle = 'rgba(255,255,255,.95)';
  c.beginPath();
  c.ellipse(x - r * 0.35, y - r * 0.4, r * 0.22, r * 0.14, -0.6, 0, Math.PI * 2);
  c.fill();
}

/** Petit ornement doré d'angle : deux volutes et une perle d'or. */
function cornerOrnament(c: Ctx, x: number, y: number, size: number, sx: number, sy: number): void {
  c.save();
  c.translate(x, y);
  c.scale(sx, sy);
  c.strokeStyle = goldGradient(c, 0, 0, size, size);
  c.lineWidth = Math.max(1, size * 0.09);
  c.lineCap = 'round';
  c.beginPath();
  c.moveTo(0, size);
  c.quadraticCurveTo(0, 0, size, 0);
  c.moveTo(size * 0.25, size * 0.95);
  c.quadraticCurveTo(size * 0.3, size * 0.3, size * 0.95, size * 0.25);
  c.stroke();
  c.fillStyle = goldGradient(c, 0, 0, size, size);
  c.beginPath();
  c.arc(size * 0.32, size * 0.32, size * 0.11, 0, Math.PI * 2);
  c.fill();
  c.restore();
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

  // Couvercle, extérieur : coussin de velours bombé, cadre d'or biseauté, médaillon à la perle.
  const [lidOutside, o] = makeCanvas(w, h, dpr);
  roundRectPath(o, 0, 0, w, h, radius);
  o.save();
  o.clip();
  fillVelvet(o, 0, 0, w, h, shade(velvet, 0.15), 3);
  // Le coussin : plus clair au centre, il bombe sous la lumière qui tombe d'en haut.
  const pad = w * 0.085;
  roundRectPath(o, pad, pad, w - pad * 2, h - pad * 2, radius * 1.8);
  const dome = o.createRadialGradient(w * 0.42, h * 0.36, Math.min(w, h) * 0.05, w * 0.5, h * 0.5, Math.max(w, h) * 0.62);
  dome.addColorStop(0, lighten(velvet, 0.42));
  dome.addColorStop(0.45, lighten(velvet, 0.12));
  dome.addColorStop(1, shade(velvet, 0.45));
  o.fillStyle = dome;
  o.fill();
  // Grain du velours sur le coussin, et le pli de lumière du poil couché.
  fillGrain(o, pad, pad, w - pad * 2, h - pad * 2, 11);
  const nap = o.createLinearGradient(0, 0, w, h);
  nap.addColorStop(0.25, 'rgba(255,255,255,0)');
  nap.addColorStop(0.42, 'rgba(255,255,255,.12)');
  nap.addColorStop(0.55, 'rgba(255,255,255,0)');
  o.fillStyle = nap;
  roundRectPath(o, pad, pad, w - pad * 2, h - pad * 2, radius * 1.8);
  o.fill();
  // Le coussin s'arrondit vers ses bords : ombre intérieure floue (pas de rainure ni de paliers).
  o.save();
  const pillow = new Path2D();
  addRoundRect(pillow, pad, pad, w - pad * 2, h - pad * 2, radius * 1.8);
  o.clip(pillow);
  const frame = new Path2D();
  frame.rect(-w, -h, w * 3, h * 3);
  addRoundRect(frame, pad, pad, w - pad * 2, h - pad * 2, radius * 1.8);
  o.shadowColor = 'rgba(0, 0, 0, 0.6)';
  o.shadowBlur = w * 0.09;
  o.shadowOffsetY = w * 0.012;
  o.fillStyle = '#000';
  o.fill(frame, 'evenodd');
  o.restore();
  // Le bord du coffret sous le coussin, plus sombre.
  o.lineWidth = w * 0.012;
  o.strokeStyle = 'rgba(0,0,0,.35)';
  roundRectPath(o, pad * 0.75, pad * 0.75, w - pad * 1.5, h - pad * 1.5, radius * 1.5);
  o.stroke();
  o.restore();

  // Cadre d'or biseauté : large filet doré, arête sombre à l'intérieur, reflet clair en haut.
  o.lineWidth = border * 3;
  o.strokeStyle = goldGradient(o, 0, 0, w, h);
  roundRectPath(o, border * 1.5, border * 1.5, w - border * 3, h - border * 3, radius);
  o.stroke();
  o.lineWidth = Math.max(1, border * 0.6);
  o.strokeStyle = 'rgba(70, 45, 10, .65)';
  roundRectPath(o, border * 3.2, border * 3.2, w - border * 6.4, h - border * 6.4, radius * 0.9);
  o.stroke();
  o.strokeStyle = 'rgba(255, 248, 220, .7)';
  o.lineWidth = Math.max(1, border * 0.5);
  o.beginPath();
  o.moveTo(radius + border, border * 0.8);
  o.lineTo(w - radius - border, border * 0.8);
  o.stroke();

  // Ornements d'angle.
  const orn = w * 0.075;
  const at = pad * 0.55;
  cornerOrnament(o, at, at, orn, 1, 1);
  cornerOrnament(o, w - at, at, orn, -1, 1);
  cornerOrnament(o, at, h - at, orn, 1, -1);
  cornerOrnament(o, w - at, h - at, orn, -1, -1);

  // Médaillon central : anneau d'or ciselé, fond de velours, perle en volume.
  const mx = w / 2;
  const my = h / 2;
  const mr = Math.min(w, h) * 0.17;
  const halo = o.createRadialGradient(mx, my, mr * 0.6, mx, my, mr * 1.6);
  halo.addColorStop(0, 'rgba(0,0,0,.35)');
  halo.addColorStop(1, 'rgba(0,0,0,0)');
  o.fillStyle = halo;
  o.beginPath();
  o.ellipse(mx, my + mr * 0.12, mr * 1.6, mr * 1.45, 0, 0, Math.PI * 2);
  o.fill();
  o.fillStyle = goldGradient(o, mx - mr, my - mr, mx + mr, my + mr);
  o.beginPath();
  o.ellipse(mx, my, mr * 1.08, mr, 0, 0, Math.PI * 2);
  o.fill();
  o.fillStyle = shade(velvet, 0.35);
  o.beginPath();
  o.ellipse(mx, my, mr * 0.86, mr * 0.79, 0, 0, Math.PI * 2);
  o.fill();
  // Ciselure : petits traits tout autour de l'anneau.
  o.strokeStyle = 'rgba(90, 60, 15, .55)';
  o.lineWidth = Math.max(0.8, w * 0.0025);
  for (let i = 0; i < 36; i++) {
    const a = (i / 36) * Math.PI * 2;
    o.beginPath();
    o.moveTo(mx + Math.cos(a) * mr * 0.9, my + Math.sin(a) * mr * 0.83);
    o.lineTo(mx + Math.cos(a) * mr * 1.04, my + Math.sin(a) * mr * 0.96);
    o.stroke();
  }
  o.strokeStyle = 'rgba(255, 245, 210, .55)';
  o.lineWidth = Math.max(1, w * 0.003);
  o.beginPath();
  o.ellipse(mx, my, mr * 1.08, mr, 0, Math.PI * 1.1, Math.PI * 1.75);
  o.stroke();
  pearlSphere(o, mx, my, mr * 0.5);

  // Tranches avant : celle du couvercle (avec le fermoir) et celle de la base.
  const lidFrontHeight = Math.round(h * 0.07);
  const baseFrontHeight = Math.round(h * 0.16);
  const [lidFront, lf] = makeCanvas(w, lidFrontHeight, dpr);
  const lfg = lf.createLinearGradient(0, 0, 0, lidFrontHeight);
  lfg.addColorStop(0, shade(velvet, 0.25));
  lfg.addColorStop(1, shade(velvet, 0.55));
  lf.fillStyle = lfg;
  lf.fillRect(radius * 0.4, 0, w - radius * 0.8, lidFrontHeight);
  lf.fillStyle = goldGradient(lf, 0, 0, w, 0);
  lf.fillRect(radius * 0.4, 0, w - radius * 0.8, Math.max(1.5, border));
  // Fermoir doré au milieu.
  const cw = w * 0.11;
  lf.fillStyle = goldGradient(lf, w / 2 - cw / 2, 0, w / 2 + cw / 2, lidFrontHeight);
  roundRectPath(lf, w / 2 - cw / 2, lidFrontHeight * 0.15, cw, lidFrontHeight * 0.95, lidFrontHeight * 0.2);
  lf.fill();
  lf.fillStyle = 'rgba(70, 45, 10, .6)';
  lf.beginPath();
  lf.arc(w / 2, lidFrontHeight * 0.62, lidFrontHeight * 0.13, 0, Math.PI * 2);
  lf.fill();

  const [baseFront, bf] = makeCanvas(w, baseFrontHeight, dpr);
  const bfg = bf.createLinearGradient(0, 0, 0, baseFrontHeight);
  bfg.addColorStop(0, shade(velvet, 0.4));
  bfg.addColorStop(1, shade(velvet, 0.7));
  bf.fillStyle = bfg;
  roundRectPath(bf, radius * 0.4, -radius, w - radius * 0.8, baseFrontHeight + radius - 2, radius * 0.8);
  bf.fill();
  // Jointure sombre sous le couvercle, filet d'or en bas.
  bf.fillStyle = 'rgba(0,0,0,.55)';
  bf.fillRect(radius * 0.4, 0, w - radius * 0.8, Math.max(1.5, baseFrontHeight * 0.05));
  bf.fillStyle = goldGradient(bf, 0, 0, w, 0);
  bf.fillRect(radius * 0.9, baseFrontHeight - Math.max(2, border * 1.4) - 3, w - radius * 1.8, Math.max(1.5, border));
  fillGrain(bf, 0, 0, w, baseFrontHeight, 5);

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

  return { base, lidOutside, lidInside, baseFront, lidFront, baseFrontHeight, lidFrontHeight };
}

/**
 * Dessine une image en perspective : le bord du haut (le fond du coffret) est plus étroit que celui du bas.
 * On découpe l'image en bandes horizontales, chacune un peu plus large que la précédente.
 */
export function drawTapered(c: Ctx, image: HTMLCanvasElement, x: number, y: number, w: number, h: number, taper: number): void {
  if (h <= 0.5) return;
  const strips = Math.max(4, Math.min(40, Math.round(h / 6)));
  const sh = image.height / strips;
  for (let i = 0; i < strips; i++) {
    const k = (i + 0.5) / strips;
    const width = w * (1 - taper * (1 - k));
    const top = y + (h * i) / strips;
    // Un pixel de recouvrement pour éviter les fentes entre bandes.
    c.drawImage(image, 0, i * sh, image.width, sh, x + (w - width) / 2, top, width, h / strips + 0.75);
  }
}

/** Contour du coffret en perspective (trapèze), pour les ombres et reflets posés dessus. */
export function taperPath(c: Ctx, x: number, y: number, w: number, h: number, taper: number, radius = 0): void {
  const inset = (w * taper) / 2;
  const r = Math.min(radius, h / 2);
  c.beginPath();
  c.moveTo(x + inset + r, y);
  c.arcTo(x + w - inset, y, x + w, y + h, r);
  c.arcTo(x + w, y + h, x, y + h, r);
  c.arcTo(x, y + h, x + inset, y, r);
  c.arcTo(x + inset, y, x + w - inset, y, r);
  c.closePath();
}
