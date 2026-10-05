// Image verticale 1080×1920 (format story) d'une carte, pour la partager (cahier §10).
import { pearlById } from '../core/catalog';
import type { PearlCard } from '../core/player';
import { CARD_FRAMES, SANS, SERIF, serialLabel } from './cardStyle';
import { drawGlow, drawPearl } from './pearl';

const W = 1080;
const H = 1920;

function roundRect(c: CanvasRenderingContext2D, x: number, y: number, w: number, h: number, r: number): void {
  c.beginPath();
  c.moveTo(x + r, y);
  c.arcTo(x + w, y, x + w, y + h, r);
  c.arcTo(x + w, y + h, x, y + h, r);
  c.arcTo(x, y + h, x, y, r);
  c.arcTo(x, y, x + w, y, r);
  c.closePath();
}

/** Écrit un texte sur plusieurs lignes ; renvoie la position y après la dernière ligne. */
function wrapText(c: CanvasRenderingContext2D, text: string, x: number, y: number, maxWidth: number, lineHeight: number): number {
  let line = '';
  for (const word of text.split(' ')) {
    const attempt = line ? `${line} ${word}` : word;
    if (c.measureText(attempt).width > maxWidth && line) {
      c.fillText(line, x, y);
      line = word;
      y += lineHeight;
    } else {
      line = attempt;
    }
  }
  if (line) c.fillText(line, x, y);
  return y + lineHeight;
}

export async function renderStoryImage(card: PearlCard): Promise<Blob> {
  await Promise.all([document.fonts.load(`64px ${SERIF}`), document.fonts.load(`600 32px ${SANS}`), document.fonts.load(`italic 32px ${SANS}`)]).catch(() => undefined);
  const pearl = pearlById(card.pearlId);
  const frame = CARD_FRAMES[card.pearlId];
  const canvas = document.createElement('canvas');
  canvas.width = W;
  canvas.height = H;
  const c = canvas.getContext('2d')!;

  // Fond : eau profonde, reflets, halo de la perle.
  const bg = c.createLinearGradient(0, 0, 0, H);
  bg.addColorStop(0, '#0c3b45');
  bg.addColorStop(1, '#03161c');
  c.fillStyle = bg;
  c.fillRect(0, 0, W, H);
  [[0.2, 0.15], [0.85, 0.35], [0.3, 0.8], [0.75, 0.92]].forEach(([fx, fy]) => {
    const g = c.createRadialGradient(W * fx, H * fy, 0, W * fx, H * fy, 520);
    g.addColorStop(0, 'rgba(170,240,235,.08)');
    g.addColorStop(1, 'rgba(170,240,235,0)');
    c.fillStyle = g;
    c.fillRect(0, 0, W, H);
  });
  drawGlow(c, W / 2, H * 0.47, 900, pearl.glow, 0.35);

  // En-tête.
  c.textAlign = 'center';
  c.fillStyle = '#e8f1f0';
  c.font = `96px ${SERIF}`;
  c.fillText('Perle', W / 2, 200);
  c.font = `500 36px ${SANS}`;
  c.fillStyle = '#9db5b5';
  c.fillText(`Pêchée à La Crique · ${serialLabel(card.serial)}`, W / 2, 262);

  // Carte.
  const cw = 800;
  const ch = Math.round((cw * 88) / 63);
  const cx = (W - cw) / 2;
  const cy = 340;
  c.save();
  c.shadowColor = 'rgba(0,0,0,.55)';
  c.shadowBlur = 60;
  c.shadowOffsetY = 24;
  roundRect(c, cx, cy, cw, ch, 44);
  const fg = c.createLinearGradient(cx, cy, cx + cw, cy + ch);
  fg.addColorStop(0, frame.colors[0]);
  fg.addColorStop(1, frame.colors[1]);
  c.fillStyle = fg;
  c.fill();
  c.restore();

  const ink = frame.dark ? '#eef0ff' : '#1b2326';
  const pad = 48;
  c.textAlign = 'left';
  c.fillStyle = ink;
  c.font = `64px ${SERIF}`;
  c.fillText(`${pearl.name}${card.cracked ? ' fêlée' : ''}`, cx + pad, cy + 100, cw - 200);
  c.textAlign = 'right';
  c.font = `600 48px ${SANS}`;
  c.fillText(pearl.rarity, cx + cw - pad, cy + 96);

  // Zone nacrée et perle.
  const ax = cx + 36;
  const ay = cy + 140;
  const aw = cw - 72;
  const ah = Math.round(ch * 0.52);
  c.save();
  roundRect(c, ax, ay, aw, ah, 28);
  c.clip();
  const nacre = c.createRadialGradient(ax + aw / 2, ay + ah * 0.6, 10, ax + aw / 2, ay + ah * 0.6, aw * 0.75);
  nacre.addColorStop(0, '#fdfaff');
  nacre.addColorStop(0.45, '#e7ddf2');
  nacre.addColorStop(1, '#a99fbd');
  c.fillStyle = nacre;
  c.fillRect(ax, ay, aw, ah);
  drawGlow(c, ax + aw / 2, ay + ah / 2, aw * 0.55, pearl.glow, 0.55, false);
  drawPearl(c, ax + aw / 2, ay + ah / 2, aw * (card.pearlId === 'giant' ? 0.27 : 0.19), pearl, card.cracked);
  c.restore();

  // Statistiques.
  const stats: [string, string][] = [
    ['Taille', `${card.sizeMm.toFixed(1)} mm`],
    ['Lustre', card.lustre],
    ['Valeur', String(card.value)],
    ['N°', serialLabel(card.serial)],
  ];
  const sy = ay + ah + 70;
  const colWidth = (cw - pad * 2) / stats.length;
  c.textAlign = 'left';
  stats.forEach(([label, value], i) => {
    const x = cx + pad + i * colWidth;
    c.globalAlpha = 0.7;
    c.font = `500 28px ${SANS}`;
    c.fillStyle = ink;
    c.fillText(label, x, sy);
    c.globalAlpha = 1;
    c.font = `700 38px ${SANS}`;
    c.fillText(value, x, sy + 48);
  });

  c.font = `italic 34px ${SANS}`;
  c.globalAlpha = 0.85;
  let y = wrapText(c, pearl.flavor, cx + pad, sy + 130, cw - pad * 2, 46);
  c.globalAlpha = 1;
  if (card.cracked) {
    c.font = `600 30px ${SANS}`;
    c.fillStyle = frame.dark ? '#ffb3a6' : '#8a2a1e';
    y = wrapText(c, 'Fêlée : valeur divisée par deux', cx + pad, y, cw - pad * 2, 40);
  }

  // Pied de page.
  c.textAlign = 'center';
  c.fillStyle = '#e8f1f0';
  c.font = `52px ${SERIF}`;
  c.fillText('Et toi, tu vas trouver quoi ?', W / 2, H - 200);
  c.font = `600 34px ${SANS}`;
  c.fillStyle = '#e8be5a';
  c.fillText('PERLE · BÊTA', W / 2, H - 130);

  return new Promise((resolve, reject) => canvas.toBlob((blob) => (blob ? resolve(blob) : reject(new Error('Image impossible'))), 'image/png'));
}
