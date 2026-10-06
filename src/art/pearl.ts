// Dessin procédural des perles et de leur halo (Canvas 2D), repris du prototype Duo.
import type { PearlType } from '../core/catalog';
import { rgba, shade } from './color';

function pearlScale(pearl: PearlType): [number, number, number] {
  switch (pearl.id) {
    case 'rose': return [0.94, 1.02, -0.08];
    case 'baroque': return [1.08, 0.94, 0.04];
    case 'black': return [1.04, 0.96, 0.06];
    case 'golden': return [1.02, 0.98, -0.02];
    case 'giant': return [0.98, 1.02, 0];
    case 'cursed': return [0.9, 1.07, -0.12];
    default: return [1, 1, 0];
  }
}

function tracePearl(c: CanvasRenderingContext2D, x: number, y: number, rad: number, pearl: PearlType): void {
  const [wide, tall, tilt] = pearlScale(pearl);
  c.beginPath();
  if (pearl.shape === 'baroque' || pearl.id === 'rose' || pearl.id === 'cursed' || pearl.id === 'golden') {
    const lobes = pearl.id === 'cursed' ? 7 : pearl.id === 'baroque' ? 3 : pearl.id === 'golden' ? 8 : 1;
    for (let i = 0; i <= 64; i++) {
      const a = (i / 64) * Math.PI * 2;
      const k = pearl.id === 'rose'
        ? 1 + 0.13 * Math.sin(a) + 0.025 * Math.sin(a * 3)
        : pearl.id === 'cursed'
          ? 1 + 0.095 * Math.sin(a * lobes + 0.7) + 0.025 * Math.sin(a * 13)
          : pearl.id === 'golden'
            ? 1 + 0.025 * Math.cos(a * lobes)
            : 1 + 0.13 * Math.sin(a * lobes + 0.7) + 0.055 * Math.sin(a * 7 + 2.1) + 0.025 * Math.cos(a * 11);
      const px = x + Math.cos(a + tilt) * rad * wide * k;
      const py = y + Math.sin(a + tilt) * rad * tall * k;
      if (i === 0) c.moveTo(px, py);
      else c.lineTo(px, py);
    }
    c.closePath();
  } else {
    c.ellipse(x, y, rad * wide, rad * tall, tilt, 0, Math.PI * 2);
  }
}

function iridescence(c: CanvasRenderingContext2D, x: number, y: number, pearl: PearlType): CanvasGradient | null {
  if (!('createConicGradient' in c)) return null;
  const gradient = c.createConicGradient(-0.72, x, y);
  const palettes: Record<PearlType['id'], readonly string[]> = {
    empty: [],
    white: ['#6de2db', '#f3c8f1', '#fff4c8', '#b7e9ef', '#6de2db'],
    rose: ['#ff8eaf', '#ffd9ae', '#a6eee4', '#ffd9e1', '#ff8eaf'],
    baroque: ['#a2b5ff', '#e9b2dc', '#fff0b8', '#93d9d1', '#a2b5ff'],
    black: ['#52dcbe', '#b8cc63', '#6f6cc4', '#265e69', '#52dcbe'],
    golden: ['#fff1a5', '#d99430', '#fff0c4', '#8ec5b0', '#fff1a5'],
    giant: ['#91ebf3', '#fff7d5', '#e5caff', '#fbffff', '#91ebf3'],
    cursed: ['#fa356e', '#70268d', '#27c6a7', '#3a0f2a', '#fa356e'],
  };
  palettes[pearl.id].forEach((color, i, colors) => gradient.addColorStop(i / (colors.length - 1), color));
  return gradient;
}

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

  tracePearl(c, x, y, rad, pearl);
  const body = c.createRadialGradient(x - rad * 0.35, y - rad * 0.4, rad * 0.05, x, y, rad * 1.08);
  body.addColorStop(0, '#ffffff');
  body.addColorStop(0.24, pearl.color);
  body.addColorStop(0.72, shade(pearl.color, pearl.id === 'cursed' ? 0.28 : 0.65));
  body.addColorStop(1, shade(pearl.color, pearl.id === 'cursed' ? 0.05 : 0.42));
  c.fillStyle = body;
  c.fill();

  // Nacre irisée : un voile de couleur glisse sur la surface sans masquer la teinte de la perle.
  c.save();
  tracePearl(c, x, y, rad, pearl);
  c.clip();
  const sheen = iridescence(c, x, y, pearl);
  if (sheen) {
    c.globalAlpha = pearl.id === 'cursed' ? 0.32 : pearl.id === 'black' ? 0.27 : 0.2;
    c.fillStyle = sheen;
    c.fillRect(x - rad * 1.4, y - rad * 1.4, rad * 2.8, rad * 2.8);
  }
  if (pearl.id === 'golden' || pearl.id === 'giant' || pearl.id === 'cursed') {
    c.globalAlpha = pearl.id === 'cursed' ? 0.38 : 0.26;
    c.strokeStyle = pearl.id === 'cursed' ? '#ff6c91' : pearl.id === 'golden' ? '#fff0ad' : '#e8fbff';
    c.lineWidth = Math.max(1, rad * 0.045);
    c.beginPath();
    c.ellipse(x, y, rad * 0.75, rad * 0.27, pearl.id === 'cursed' ? -0.55 : -0.32, Math.PI * 0.1, Math.PI * 1.7);
    c.stroke();
  }
  const sweep = c.createLinearGradient(x - rad, y + rad * 0.55, x + rad, y - rad * 0.65);
  sweep.addColorStop(0, 'rgba(255,255,255,0)');
  sweep.addColorStop(0.48, 'rgba(255,255,255,.18)');
  sweep.addColorStop(0.68, 'rgba(255,255,255,.03)');
  sweep.addColorStop(1, 'rgba(255,255,255,0)');
  c.globalAlpha = 1;
  c.fillStyle = sweep;
  c.fillRect(x - rad, y - rad, rad * 2, rad * 2);
  c.restore();

  c.globalAlpha = 0.35;
  c.strokeStyle = pearl.glow;
  c.lineWidth = rad * 0.08;
  tracePearl(c, x, y, rad, pearl);
  c.stroke();
  c.globalAlpha = 1;

  // Reflets larges et petits éclats nets : la nacre reste lisible même sur les petites cartes.
  c.beginPath();
  c.ellipse(x - rad * 0.35, y - rad * 0.42, rad * 0.22, rad * 0.13, -0.6, 0, Math.PI * 2);
  c.fillStyle = 'rgba(255,255,255,.85)';
  c.fill();
  c.beginPath();
  c.ellipse(x + rad * 0.45, y + rad * 0.28, rad * 0.1, rad * 0.035, -0.55, 0, Math.PI * 2);
  c.fillStyle = pearl.id === 'cursed' ? 'rgba(255,92,143,.62)' : 'rgba(255,255,255,.34)';
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
    c.lineWidth = Math.max(1, rad * 0.045);
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
