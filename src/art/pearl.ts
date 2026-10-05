// Dessin procédural des perles et de leur halo (Canvas 2D), repris du prototype Duo.
import type { PearlType } from '../core/catalog';
import { rgba, shade } from './color';

export function drawPearl(c: CanvasRenderingContext2D, x: number, y: number, rad: number, pearl: PearlType, cracked: boolean): void {
  if (!pearl.glow) {
    // Huître vide : une petite tache, rien de plus.
    c.fillStyle = 'rgba(110,92,74,.7)';
    c.beginPath();
    c.arc(x + rad * 0.4, y + rad * 0.2, rad * 0.13, 0, Math.PI * 2);
    c.fill();
    return;
  }
  c.save();
  const shadow = c.createRadialGradient(x + rad * 0.2, y + rad * 0.3, rad * 0.2, x + rad * 0.2, y + rad * 0.3, rad * 1.35);
  shadow.addColorStop(0, 'rgba(60,40,30,.45)');
  shadow.addColorStop(1, 'rgba(60,40,30,0)');
  c.fillStyle = shadow;
  c.fillRect(x - rad * 2, y - rad * 2, rad * 4, rad * 4);

  c.beginPath();
  if (pearl.shape === 'baroque') {
    for (let i = 0; i <= 48; i++) {
      const a = (i / 48) * Math.PI * 2;
      const k = 1 + 0.12 * Math.sin(a * 3 + 1) + 0.07 * Math.sin(a * 5 + 2);
      c.lineTo(x + Math.cos(a) * rad * k, y + Math.sin(a) * rad * k * 1.08);
    }
    c.closePath();
  } else {
    c.arc(x, y, rad, 0, Math.PI * 2);
  }
  const body = c.createRadialGradient(x - rad * 0.35, y - rad * 0.4, rad * 0.05, x, y, rad * 1.08);
  body.addColorStop(0, '#ffffff');
  body.addColorStop(0.28, pearl.color);
  body.addColorStop(1, shade(pearl.color, 0.5));
  c.fillStyle = body;
  c.fill();
  c.globalAlpha = 0.35;
  c.strokeStyle = pearl.glow;
  c.lineWidth = rad * 0.08;
  c.stroke();
  c.globalAlpha = 1;

  // Reflet de lumière.
  c.beginPath();
  c.ellipse(x - rad * 0.35, y - rad * 0.42, rad * 0.22, rad * 0.13, -0.6, 0, Math.PI * 2);
  c.fillStyle = 'rgba(255,255,255,.85)';
  c.fill();

  if (cracked) {
    c.beginPath();
    c.moveTo(x - rad * 0.1, y - rad * 0.9);
    c.lineTo(x + rad * 0.12, y - rad * 0.3);
    c.lineTo(x - rad * 0.08, y + rad * 0.1);
    c.lineTo(x + rad * 0.2, y + rad * 0.7);
    c.moveTo(x + rad * 0.12, y - rad * 0.3);
    c.lineTo(x + rad * 0.55, y - rad * 0.15);
    c.strokeStyle = 'rgba(40,24,20,.85)';
    c.lineWidth = rad * 0.05;
    c.stroke();
  }
  c.restore();
}

/**
 * Halo lumineux. `additive` (par défaut) brille fort sur fond sombre ;
 * passer false sur des surfaces claires (nacre) pour éclairer sans brûler.
 */
export function drawGlow(c: CanvasRenderingContext2D, x: number, y: number, rad: number, color: string | null, alpha: number, additive = true): void {
  if (!color || alpha <= 0.001) return;
  c.save();
  c.globalCompositeOperation = additive ? 'lighter' : 'screen';
  const g = c.createRadialGradient(x, y, 0, x, y, rad);
  g.addColorStop(0, rgba(color, alpha));
  g.addColorStop(0.4, rgba(color, alpha * 0.35));
  g.addColorStop(1, rgba(color, 0));
  c.fillStyle = g;
  c.fillRect(x - rad, y - rad, rad * 2, rad * 2);
  c.restore();
}

/** Petite toile contenant une perle (cartes, collection). `size` en pixels CSS. */
export function pearlCanvas(pearl: PearlType, size: number, cracked: boolean, radiusRatio = 0.3): HTMLCanvasElement {
  const dpr = Math.min(window.devicePixelRatio || 1, 3);
  const canvas = document.createElement('canvas');
  canvas.width = canvas.height = Math.round(size * dpr);
  canvas.style.width = canvas.style.height = `${size}px`;
  const c = canvas.getContext('2d')!;
  c.scale(dpr, dpr);
  const mid = size / 2;
  drawGlow(c, mid, mid, size * 0.5, pearl.glow, 0.55);
  drawPearl(c, mid, mid, size * radiusRatio, pearl, cracked);
  return canvas;
}
