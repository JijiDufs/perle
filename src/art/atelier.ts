// L'établi (cahier §6) : la perle à gauche de la pliure, la monture à droite. Refermer les deux moitiés sertit le bijou.
import { metalById, type Recipe } from '../core/atelier';
import type { Jewel } from '../core/jewels';
import { rgba } from './color';
import { drawJewel, jewelYOffset } from './jewel';

type Ctx = CanvasRenderingContext2D;

export interface WorkbenchScene {
  /** Le bijou fini (perles comprises). */
  jewel: Jewel;
  /** Fermeture 0…1. */
  closure: number;
  /** Instant où le sertissage s'est terminé (ms, horloge du dessin), ou null. */
  doneAt: number | null;
  glow: string;
}

function pearlBall(c: Ctx, x: number, y: number, r: number, color: string): void {
  const g = c.createRadialGradient(x - r * 0.35, y - r * 0.4, r * 0.05, x, y, r);
  g.addColorStop(0, '#ffffff');
  g.addColorStop(0.45, color);
  g.addColorStop(1, 'rgba(0,0,0,0.55)');
  c.fillStyle = g;
  c.beginPath();
  c.arc(x, y, r, 0, Math.PI * 2);
  c.fill();
}

export function drawWorkbench(c: Ctx, w: number, h: number, scene: WorkbenchScene, t: number): void {
  // Le bois de l'établi.
  const wood = c.createLinearGradient(0, 0, 0, h);
  wood.addColorStop(0, '#3b2a1e');
  wood.addColorStop(1, '#1c130d');
  c.fillStyle = wood;
  c.fillRect(0, 0, w, h);
  c.strokeStyle = 'rgba(0, 0, 0, 0.25)';
  c.lineWidth = 1;
  for (let y = 12; y < h; y += 26) {
    c.beginPath();
    c.moveTo(0, y + Math.sin(y) * 3);
    c.bezierCurveTo(w * 0.3, y - 4, w * 0.6, y + 5, w, y);
    c.stroke();
  }
  // Le feutre au centre.
  const felt = c.createRadialGradient(w / 2, h / 2, 10, w / 2, h / 2, Math.max(w, h) * 0.6);
  felt.addColorStop(0, '#2f3d4a');
  felt.addColorStop(1, 'rgba(20, 28, 34, 0)');
  c.fillStyle = felt;
  c.fillRect(0, 0, w, h);

  const cy = h * 0.5;
  const size = Math.min(w * 0.85, h * 0.55);
  const s = size / 440;

  if (scene.doneAt !== null) {
    // Le bijou serti, qui brille.
    const age = Math.min(1, (t - scene.doneAt) / 700);
    const halo = c.createRadialGradient(w / 2, cy, 0, w / 2, cy, size * (0.6 + 0.4 * age));
    halo.addColorStop(0, rgba(scene.glow, 0.55 * (1 - age * 0.5)));
    halo.addColorStop(1, rgba(scene.glow, 0));
    c.fillStyle = halo;
    c.fillRect(0, 0, w, h);
    c.save();
    c.translate(w / 2, cy);
    c.scale(0.9 + 0.1 * age, 0.9 + 0.1 * age);
    drawJewel(c, 0, (jewelYOffset(scene.jewel) - 0.5) * 440 * s * 1.25, s * 1.25, scene.jewel);
    c.restore();
    return;
  }

  // La pliure.
  const k = scene.closure;
  c.setLineDash([6, 8]);
  c.strokeStyle = `rgba(232, 241, 240, ${0.25 + 0.5 * k})`;
  c.lineWidth = 1.5;
  c.beginPath();
  c.moveTo(w / 2, h * 0.12);
  c.lineTo(w / 2, h * 0.88);
  c.stroke();
  c.setLineDash([]);

  // À droite : la monture seule (sans les perles), qui glisse vers la pliure.
  const frame: Jewel = { ...scene.jewel, pearls: false, gem: null, pearlColors: undefined };
  const rightX = w * 0.75 - k * w * 0.25;
  c.save();
  c.globalAlpha = 0.95;
  drawJewel(c, rightX, cy + (jewelYOffset(frame) - 0.5) * 440 * s * 0.62, s * 0.62, frame);
  c.restore();

  // À gauche : les perles, qui glissent vers la pliure.
  const colors = scene.jewel.pearlColors?.length ? scene.jewel.pearlColors : ['#f2ece4'];
  const leftX = w * 0.25 + k * w * 0.25;
  const r = Math.min(w, h) * 0.045;
  colors.forEach((color, i) => {
    const angle = (i / colors.length) * Math.PI * 2 + t / 2400;
    const spread = colors.length > 1 ? r * 1.6 : 0;
    pearlBall(c, leftX + Math.cos(angle) * spread, cy + Math.sin(angle) * spread, r, color);
  });

  // Les deux moitiés se rapprochent : une lueur monte à la pliure.
  if (k > 0.6) {
    const g = c.createRadialGradient(w / 2, cy, 0, w / 2, cy, size * 0.5);
    g.addColorStop(0, rgba(scene.glow, (k - 0.6) * 1.2));
    g.addColorStop(1, rgba(scene.glow, 0));
    c.fillStyle = g;
    c.fillRect(0, 0, w, h);
  }
}

/** Le bijou à dessiner pour une recette, avec les couleurs des perles utilisées. */
export function craftedJewel(recipe: Pick<Recipe, 'name' | 'type' | 'metal'>, pearlColors: string[]): Jewel {
  const metal = metalById(recipe.metal);
  return {
    rarityId: 'perles',
    type: recipe.type,
    name: recipe.name,
    metal: metal.color,
    metalName: metal.name,
    gem: null,
    candy: false,
    pearls: true,
    carats: 0,
    value: 0,
    flavor: '',
    pearlColors,
  };
}

