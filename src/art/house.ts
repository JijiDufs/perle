// La Maison dessinée par code (Canvas 2D) : une cabane au bout d'un ponton, au crépuscule,
// dont chaque élément restauré par une lettre change l'image. Provisoire : phase 2 (design).
import type { HouseBrand, HouseFeature } from '../core/house';
import { rgba } from './color';
import { SERIF } from './cardStyle';

type Ctx = CanvasRenderingContext2D;

export interface HouseScene {
  restored: ReadonlySet<HouseFeature>;
  /** Enseigne peinte : Maison Rose, puis Pearl Inc. */
  brand: HouseBrand;
  /** Plus belle pièce, affichée dans la vitrine (déjà dessinée). */
  showcase: HTMLCanvasElement | null;
  /** Élément tout juste restauré et avancement de son apparition (0…1), pour l'éclat. */
  appearing: { feature: HouseFeature; progress: number } | null;
}

interface Layout {
  w: number;
  h: number;
  cx: number;
  horizon: number;
  ground: number;
  wallTop: number;
  x0: number;
  x1: number;
  door: { x: number; y: number; w: number; h: number };
  win: { x: number; y: number; w: number; h: number };
  lantern: { x: number; y: number };
  sign: { x: number; y: number; w: number; h: number };
  vitrine: { x: number; y: number; w: number; h: number };
  box: { x: number; y: number; s: number };
}

function layout(w: number, h: number): Layout {
  const cx = w * 0.57;
  const ground = h * 0.74;
  const wallH = Math.min(h * 0.39, w * 0.5);
  const wallW = Math.min(w * 0.7, h * 0.84);
  const x0 = cx - wallW / 2;
  const x1 = cx + wallW / 2;
  const wallTop = ground - wallH;
  const door = { x: x0 + wallW * 0.1, y: ground - wallH * 0.7, w: wallW * 0.22, h: wallH * 0.7 };
  const win = { x: x0 + wallW * 0.54, y: wallTop + wallH * 0.2, w: wallW * 0.32, h: wallH * 0.47 };
  return {
    w,
    h,
    cx,
    horizon: h * 0.6,
    ground,
    wallTop,
    x0,
    x1,
    door,
    win,
    lantern: { x: door.x + door.w + wallW * 0.055, y: door.y + wallH * 0.18 },
    sign: { x: x0 + wallW * 0.32, y: wallTop + wallH * 0.09, w: wallW * 0.42, h: wallH * 0.12 },
    vitrine: { x: x0 - wallW * 0.28, y: ground - wallH * 0.55, w: wallW * 0.24, h: wallH * 0.36 },
    box: { x: win.x + win.w * 0.8, y: ground - wallH * 0.12, s: wallH * 0.12 },
  };
}

/** Centre d'un élément, pour placer l'éclat de restauration. */
function anchor(l: Layout, feature: HouseFeature): [number, number] {
  switch (feature) {
    case 'door':
      return [l.door.x + l.door.w / 2, l.door.y + l.door.h / 2];
    case 'lantern':
      return [l.lantern.x, l.lantern.y];
    case 'sign':
      return [l.sign.x + l.sign.w / 2, l.sign.y + l.sign.h / 2];
    case 'notebook':
    case 'workbench':
      return [l.win.x + l.win.w / 2, l.win.y + l.win.h / 2];
    case 'vitrine':
      return [l.vitrine.x + l.vitrine.w / 2, l.vitrine.y + l.vitrine.h / 2];
    case 'box':
      return [l.box.x, l.box.y];
  }
}

/** Étoiles fixes (pseudo-hasard déterministe). */
function stars(c: Ctx, l: Layout, t: number): void {
  let seed = 7;
  const next = () => ((seed = (seed * 16807) % 2147483647) / 2147483647);
  for (let i = 0; i < 46; i++) {
    const x = next() * l.w;
    const y = next() * l.horizon * 0.8;
    const twinkle = 0.45 + 0.55 * Math.abs(Math.sin(t / 900 + i));
    c.fillStyle = `rgba(232, 241, 240, ${0.15 + 0.5 * twinkle * next()})`;
    c.fillRect(x, y, 1.6, 1.6);
  }
}

function glow(c: Ctx, x: number, y: number, r: number, color: string, alpha: number): void {
  const g = c.createRadialGradient(x, y, 0, x, y, r);
  g.addColorStop(0, rgba(color, alpha));
  g.addColorStop(1, rgba(color, 0));
  c.fillStyle = g;
  c.beginPath();
  c.arc(x, y, r, 0, Math.PI * 2);
  c.fill();
}

function archPath(c: Ctx, x: number, y: number, w: number, h: number): void {
  c.beginPath();
  c.moveTo(x, y + h);
  c.lineTo(x, y + h * 0.34);
  c.quadraticCurveTo(x, y, x + w / 2, y);
  c.quadraticCurveTo(x + w, y, x + w, y + h * 0.34);
  c.lineTo(x + w, y + h);
  c.closePath();
}

function roundedRect(c: Ctx, x: number, y: number, w: number, h: number, r: number): void {
  const radius = Math.min(r, w / 2, h / 2);
  c.beginPath();
  c.moveTo(x + radius, y);
  c.lineTo(x + w - radius, y);
  c.quadraticCurveTo(x + w, y, x + w, y + radius);
  c.lineTo(x + w, y + h - radius);
  c.quadraticCurveTo(x + w, y + h, x + w - radius, y + h);
  c.lineTo(x + radius, y + h);
  c.quadraticCurveTo(x, y + h, x, y + h - radius);
  c.lineTo(x, y + radius);
  c.quadraticCurveTo(x, y, x + radius, y);
  c.closePath();
}

export function drawHouse(c: Ctx, w: number, h: number, scene: HouseScene, t: number): void {
  const l = layout(w, h);
  const has = (f: HouseFeature) => scene.restored.has(f);
  const lit = has('lantern');

  // Ciel et lune.
  const sky = c.createLinearGradient(0, 0, 0, l.horizon);
  sky.addColorStop(0, '#081422');
  sky.addColorStop(0.6, '#173041');
  sky.addColorStop(1, '#3a5560');
  c.fillStyle = sky;
  c.fillRect(0, 0, w, l.horizon);
  stars(c, l, t);
  glow(c, w * 0.18, h * 0.16, w * 0.16, '#cfe6ff', 0.18);
  c.fillStyle = '#e9f1f4';
  c.beginPath();
  c.arc(w * 0.18, h * 0.16, w * 0.045, 0, Math.PI * 2);
  c.fill();
  // Quelques cratères, pour que la lune ne soit pas un simple disque.
  c.fillStyle = 'rgba(160, 180, 195, 0.35)';
  for (const [dx, dy, r] of [[-0.012, -0.01, 0.009], [0.014, 0.008, 0.007], [0.002, 0.018, 0.005]]) {
    c.beginPath();
    c.arc(w * (0.18 + dx), h * 0.16 + w * dy, w * r, 0, Math.PI * 2);
    c.fill();
  }

  // Nuages qui passent lentement devant le ciel.
  for (let i = 0; i < 3; i++) {
    const cy = h * (0.08 + i * 0.07);
    // `t` en ms : quelques pixels par seconde.
    const cx = ((t * (0.004 + i * 0.002) + i * w * 0.4) % (w * 1.6)) - w * 0.3;
    c.fillStyle = `rgba(120, 150, 170, ${0.1 - i * 0.02})`;
    for (const [ox, rx, ry] of [[0, 0.16, 0.025], [0.1, 0.12, 0.02], [-0.09, 0.1, 0.018]]) {
      c.beginPath();
      c.ellipse(cx + w * ox, cy, w * rx, h * ry, 0, 0, Math.PI * 2);
      c.fill();
    }
  }

  // Le phare, au loin sur la pointe : son feu tourne.
  const lhx = w * 0.9;
  const lhy = l.horizon;
  c.fillStyle = '#16232c';
  c.beginPath();
  c.moveTo(w * 0.8, lhy);
  c.quadraticCurveTo(w * 0.9, lhy - h * 0.025, w * 1.02, lhy);
  c.fill();
  c.fillStyle = '#2a3a44';
  c.fillRect(lhx - w * 0.008, lhy - h * 0.07, w * 0.016, h * 0.06);
  const beam = (Math.sin(t / 900) + 1) / 2;
  glow(c, lhx, lhy - h * 0.072, w * (0.03 + 0.06 * beam), '#fff1c4', 0.35 + 0.5 * beam);

  // Mer lumineuse : l'eau garde les bleus profonds de la Maison, avec un reflet lagon sous l'horizon.
  const sea = c.createLinearGradient(0, l.horizon, 0, h);
  sea.addColorStop(0, '#28616a');
  sea.addColorStop(0.28, '#173b4a');
  sea.addColorStop(1, '#06121a');
  c.fillStyle = sea;
  c.fillRect(0, l.horizon, w, h - l.horizon);
  glow(c, w * 0.62, l.horizon + h * 0.08, w * 0.44, '#68d4c4', 0.09);
  c.strokeStyle = 'rgba(207, 230, 255, 0.12)';
  c.lineWidth = 1;
  for (let i = 0; i < 9; i++) {
    const y = l.horizon + ((i + 1) / 10) * (h - l.horizon);
    const shift = Math.sin(t / 1400 + i) * 12;
    c.beginPath();
    for (let x = -20; x < w + 20; x += 18) {
      const yy = y + Math.sin((x + shift * 4) / 26 + i) * (1 + i * 0.25);
      if (x === -20) c.moveTo(x, yy);
      else c.lineTo(x, yy);
    }
    c.stroke();
  }
  // Reflets en écaille et caustiques sous le ponton.
  c.save();
  c.globalAlpha = 0.25;
  c.strokeStyle = '#9fe2d3';
  c.lineWidth = 1;
  for (let row = 0; row < 5; row++) {
    const y = l.horizon + (h - l.horizon) * (0.18 + row * 0.15);
    const span = w * (0.08 + row * 0.11);
    const center = w * (0.57 + Math.sin(t / 2400 + row) * 0.08);
    for (let col = -2; col <= 2; col++) {
      const x = center + col * span * 0.44;
      const r = span * 0.2;
      c.beginPath();
      c.arc(x, y, r, Math.PI * 1.08, Math.PI * 1.92);
      c.stroke();
    }
  }
  c.restore();
  // Reflet de la lune : une colonne de petits traits qui scintillent sur l'eau.
  glow(c, w * 0.18, l.horizon + (h - l.horizon) * 0.35, w * 0.12, '#cfe6ff', 0.08);
  for (let i = 0; i < 14; i++) {
    const k = i / 14;
    const y = l.horizon + 3 + k * (h - l.horizon) * 0.8;
    const width = w * (0.015 + k * 0.05) * (0.6 + 0.4 * Math.sin(t / 300 + i * 1.7));
    c.fillStyle = `rgba(220, 235, 255, ${0.35 * (1 - k)})`;
    c.fillRect(w * 0.18 - width / 2 + Math.sin(t / 700 + i) * 3, y, width, 1.5);
  }

  // Ponton : large platelage au premier plan, lames usées et reflets de marée.
  const dockTop = l.ground;
  const dockLip = dockTop + h * 0.035;
  const dock = c.createLinearGradient(0, dockTop, 0, dockLip);
  dock.addColorStop(0, '#725a43');
  dock.addColorStop(0.22, '#48392f');
  dock.addColorStop(1, '#201c1c');
  c.fillStyle = dock;
  c.fillRect(0, dockTop, w, h * 0.035);
  c.strokeStyle = 'rgba(232, 202, 144, 0.24)';
  c.lineWidth = 1;
  for (let x = -w * 0.04; x < w * 1.04; x += w / 7) {
    c.beginPath();
    c.moveTo(x, dockTop + 2);
    c.lineTo(x + w * 0.015, dockLip - 2);
    c.stroke();
  }
  c.fillStyle = '#332720';
  for (let x = 6; x < w; x += w / 9) {
    c.beginPath();
    c.moveTo(x, dockLip);
    c.lineTo(x + w * 0.018, dockLip);
    c.lineTo(x + w * 0.045, h);
    c.lineTo(x - w * 0.018, h);
    c.closePath();
    c.fill();
  }
  c.strokeStyle = 'rgba(0, 0, 0, 0.36)';
  for (let x = 0; x < w; x += w / 22) {
    c.beginPath();
    c.moveTo(x, dockTop);
    c.lineTo(x, dockLip);
    c.stroke();
  }

  // Lumière de la lanterne sur le ponton et le mur.
  if (lit) {
    const flicker = 0.85 + 0.15 * Math.sin(t / 130) * Math.sin(t / 370);
    glow(c, l.lantern.x, l.lantern.y + h * 0.04, w * 0.42, '#ffc56b', 0.22 * flicker);
    // Reflet chaud de la lanterne sur l'eau, sous le ponton.
    for (let i = 0; i < 8; i++) {
      const y = l.ground + h * 0.05 + i * h * 0.022;
      const width = w * (0.04 + i * 0.012) * (0.6 + 0.4 * Math.sin(t / 260 + i * 2.1));
      c.fillStyle = `rgba(255, 200, 120, ${0.28 * (1 - i / 8) * flicker})`;
      c.fillRect(l.lantern.x - width / 2 + Math.sin(t / 500 + i) * 2, y, width, 1.5);
    }
  }

  // Silhouette de boutique maritime sur pilotis, pensée comme un lieu habité.
  const houseW = l.x1 - l.x0;
  const houseH = l.ground - l.wallTop;
  const peakX = l.x0 + houseW * 0.39;
  const peakY = l.wallTop - houseH * 0.38;
  const leftEaveX = l.x0 - w * 0.055;
  const rightEaveX = l.x1 + w * 0.075;

  c.fillStyle = 'rgba(0, 5, 10, 0.52)';
  c.beginPath();
  c.ellipse(l.cx + w * 0.03, l.ground + h * 0.055, w * 0.44, h * 0.045, 0, 0, Math.PI * 2);
  c.fill();
  // Poutres noyées dans l'eau.
  for (const x of [l.x0 + houseW * 0.12, l.x0 + houseW * 0.42, l.x0 + houseW * 0.76, l.x1 - houseW * 0.02]) {
    c.fillStyle = '#302b2a';
    c.beginPath();
    c.moveTo(x - w * 0.018, l.ground - h * 0.01);
    c.lineTo(x + w * 0.022, l.ground - h * 0.01);
    c.lineTo(x + w * 0.035, h);
    c.lineTo(x - w * 0.025, h);
    c.closePath();
    c.fill();
    c.strokeStyle = 'rgba(230, 197, 143, 0.25)';
    c.beginPath();
    c.moveTo(x - w * 0.012, l.ground + h * 0.015);
    c.lineTo(x - w * 0.018, h);
    c.stroke();
  }

  // Mur latéral et façade en forme de pignon.
  c.fillStyle = '#142c34';
  c.beginPath();
  c.moveTo(l.x1, l.wallTop + houseH * 0.08);
  c.lineTo(l.x1 + w * 0.075, l.wallTop - houseH * 0.025);
  c.lineTo(l.x1 + w * 0.075, l.ground - h * 0.015);
  c.lineTo(l.x1, l.ground);
  c.closePath();
  c.fill();

  const wallPath = () => {
    c.beginPath();
    c.moveTo(l.x0, l.wallTop + houseH * 0.1);
    c.lineTo(peakX, peakY + houseH * 0.035);
    c.lineTo(l.x1, l.wallTop + houseH * 0.08);
    c.lineTo(l.x1, l.ground);
    c.lineTo(l.x0, l.ground);
    c.closePath();
  };
  const wallPaint = c.createLinearGradient(l.x0, l.wallTop, l.x1, l.ground);
  wallPaint.addColorStop(0, has('door') ? '#3d8580' : '#42666a');
  wallPaint.addColorStop(0.46, has('door') ? '#28636a' : '#354d53');
  wallPaint.addColorStop(1, '#163944');
  wallPath();
  c.fillStyle = wallPaint;
  c.fill();
  c.save();
  wallPath();
  c.clip();
  // Larges lames verticales, peintes à la main, avec une lumière salée sur le bord.
  for (let i = 0; i <= 10; i++) {
    const x = l.x0 + houseW * i / 10;
    c.strokeStyle = i % 2 ? 'rgba(5, 25, 31, 0.2)' : 'rgba(167, 221, 204, 0.1)';
    c.lineWidth = Math.max(1, w * 0.004);
    c.beginPath();
    c.moveTo(x, l.wallTop - houseH * 0.12);
    c.lineTo(x, l.ground);
    c.stroke();
  }
  c.restore();
  c.strokeStyle = '#a9875d';
  c.lineWidth = Math.max(2, w * 0.009);
  wallPath();
  c.stroke();
  // Moulure de soubassement et deux jardinières suspendues.
  c.fillStyle = '#b58c5e';
  c.fillRect(l.x0 - w * 0.012, l.ground - h * 0.022, houseW + w * 0.025, h * 0.024);
  for (const x of [l.x0 + houseW * 0.39, l.x1 - houseW * 0.13]) {
    c.fillStyle = '#182f34';
    roundedRect(c, x, l.ground - houseH * 0.13, houseW * 0.095, houseH * 0.075, houseH * 0.018);
    c.fill();
    for (let i = 0; i < 3; i++) {
      c.strokeStyle = ['#7cac78', '#95b980', '#528f82'][i];
      c.lineWidth = 2;
      c.beginPath();
      c.moveTo(x + houseW * (0.025 + i * 0.026), l.ground - houseH * 0.12);
      c.quadraticCurveTo(x + houseW * (0.005 + i * 0.03), l.ground - houseH * 0.19, x + houseW * (0.018 + i * 0.03), l.ground - houseH * 0.205);
      c.stroke();
    }
  }

  // Toit dissymétrique en bardeaux bleu pétrole, avec une longue marquise côté mer.
  c.fillStyle = 'rgba(4, 11, 17, 0.5)';
  c.beginPath();
  c.moveTo(peakX, peakY + h * 0.025);
  c.lineTo(rightEaveX + w * 0.035, l.wallTop + houseH * 0.16);
  c.lineTo(rightEaveX + w * 0.02, l.wallTop + houseH * 0.205);
  c.lineTo(l.x1 - w * 0.015, l.wallTop + houseH * 0.14);
  c.closePath();
  c.fill();
  const roof = c.createLinearGradient(0, peakY, 0, l.wallTop + houseH * 0.17);
  roof.addColorStop(0, '#497b7a');
  roof.addColorStop(0.42, '#234d57');
  roof.addColorStop(1, '#142c3a');
  c.beginPath();
  c.moveTo(leftEaveX, l.wallTop + houseH * 0.13);
  c.lineTo(peakX, peakY);
  c.lineTo(rightEaveX, l.wallTop + houseH * 0.12);
  c.lineTo(rightEaveX - w * 0.015, l.wallTop + houseH * 0.17);
  c.lineTo(l.x1 - w * 0.015, l.wallTop + houseH * 0.16);
  c.closePath();
  c.fillStyle = roof;
  c.fill();
  c.save();
  c.clip();
  for (let row = 1; row <= 6; row++) {
    const u = row / 7;
    const y = peakY + (l.wallTop + houseH * 0.16 - peakY) * u;
    c.strokeStyle = `rgba(226, 218, 183, ${0.12 + u * 0.06})`;
    c.lineWidth = 1;
    c.beginPath();
    c.moveTo(leftEaveX + houseW * u * 0.3, y);
    c.quadraticCurveTo(l.cx + houseW * 0.12, y + h * 0.009, rightEaveX - houseW * u * 0.08, y - h * 0.003);
    c.stroke();
    for (let tile = 0; tile < 8; tile++) {
      const tx = leftEaveX + (rightEaveX - leftEaveX) * (tile + (row % 2 ? 0.18 : 0.66)) / 8;
      c.strokeStyle = 'rgba(5, 20, 27, 0.22)';
      c.beginPath();
      c.moveTo(tx, y - h * 0.012);
      c.lineTo(tx - w * 0.004, y + h * 0.008);
      c.stroke();
    }
  }
  c.restore();
  c.strokeStyle = 'rgba(237, 207, 150, 0.72)';
  c.lineWidth = Math.max(1.5, w * 0.005);
  c.beginPath();
  c.moveTo(leftEaveX, l.wallTop + houseH * 0.13);
  c.lineTo(peakX, peakY);
  c.lineTo(rightEaveX, l.wallTop + houseH * 0.12);
  c.stroke();
  // Petite cheminée en terre cuite au-dessus de la pente longue.
  c.fillStyle = '#9a6755';
  c.beginPath();
  c.moveTo(l.x1 - houseW * 0.13, l.wallTop - houseH * 0.02);
  c.lineTo(l.x1 - houseW * 0.12, l.wallTop - houseH * 0.28);
  c.lineTo(l.x1 - houseW * 0.045, l.wallTop - houseH * 0.25);
  c.lineTo(l.x1 - houseW * 0.055, l.wallTop - houseH * 0.01);
  c.closePath();
  c.fill();
  c.fillStyle = '#d4a77a';
  roundedRect(c, l.x1 - houseW * 0.15, l.wallTop - houseH * 0.29, houseW * 0.12, houseH * 0.055, houseH * 0.018);
  c.fill();
  c.fillStyle = 'rgba(191, 208, 196, 0.32)';
  for (let i = 0; i < 3; i++) {
    const rise = (t / (2800 + i * 200) + i * 0.33) % 1;
    c.beginPath();
    c.arc(l.x1 - houseW * 0.09 - rise * w * 0.025, l.wallTop - houseH * 0.31 - rise * h * 0.07, w * (0.012 + rise * 0.014), 0, Math.PI * 2);
    c.fill();
  }

  // Fenêtre cintrée : la lumière intérieure apparaît avec le carnet, puis l'établi.
  const { win } = l;
  archPath(c, win.x - houseW * 0.025, win.y - houseH * 0.018, win.w + houseW * 0.05, win.h + houseH * 0.018);
  c.fillStyle = '#9c805c';
  c.fill();
  archPath(c, win.x, win.y, win.w, win.h);
  c.save();
  c.clip();
  if (has('notebook')) {
    const inside = c.createLinearGradient(0, win.y, 0, win.y + win.h);
    inside.addColorStop(0, '#ffe6aa');
    inside.addColorStop(0.55, '#eab56c');
    inside.addColorStop(1, '#8d503d');
    c.fillStyle = inside;
    c.fillRect(win.x, win.y, win.w, win.h);
    glow(c, win.x + win.w * 0.5, win.y + win.h * 0.45, win.w * 0.9, '#ffc875', 0.27);
    // Silhouette de l'établi et de sa petite lampe.
    if (has('workbench')) {
      c.fillStyle = 'rgba(55, 38, 30, 0.9)';
      c.fillRect(win.x + win.w * 0.08, win.y + win.h * 0.7, win.w * 0.82, win.h * 0.08);
      c.fillRect(win.x + win.w * 0.18, win.y + win.h * 0.76, win.w * 0.07, win.h * 0.27);
      c.fillRect(win.x + win.w * 0.74, win.y + win.h * 0.76, win.w * 0.07, win.h * 0.27);
      glow(c, win.x + win.w * 0.68, win.y + win.h * 0.52, win.w * 0.13, '#ffe7a0', 0.85);
      c.fillStyle = '#2e3a3a';
      c.fillRect(win.x + win.w * 0.64, win.y + win.h * 0.55, win.w * 0.08, win.h * 0.14);
    }
    // Le carnet rouge de Rose reste lisible sur le rebord.
    c.fillStyle = '#8a3e4d';
    roundedRect(c, win.x + win.w * 0.1, win.y + win.h * 0.82, win.w * 0.23, win.h * 0.12, win.h * 0.02);
    c.fill();
    c.fillStyle = '#f5ddb0';
    c.fillRect(win.x + win.w * 0.13, win.y + win.h * 0.85, win.w * 0.16, win.h * 0.015);
  } else {
    const dusty = c.createLinearGradient(win.x, win.y, win.x + win.w, win.y + win.h);
    dusty.addColorStop(0, '#28454b');
    dusty.addColorStop(1, '#101f2b');
    c.fillStyle = dusty;
    c.fillRect(win.x, win.y, win.w, win.h);
    c.strokeStyle = 'rgba(202, 218, 197, 0.14)';
    c.lineWidth = 2;
    c.beginPath();
    c.moveTo(win.x + win.w * 0.14, win.y + win.h * 0.76);
    c.lineTo(win.x + win.w * 0.42, win.y + win.h * 0.16);
    c.moveTo(win.x + win.w * 0.34, win.y + win.h * 0.94);
    c.lineTo(win.x + win.w * 0.76, win.y + win.h * 0.25);
    c.stroke();
  }
  // Reflet diagonal, une seule traverse fine : la fenêtre reste vitrée, pas quadrillée.
  c.strokeStyle = 'rgba(255, 245, 216, 0.38)';
  c.lineWidth = Math.max(2, w * 0.006);
  c.beginPath();
  c.moveTo(win.x + win.w * 0.15, win.y + win.h * 0.66);
  c.lineTo(win.x + win.w * 0.46, win.y + win.h * 0.12);
  c.stroke();
  c.restore();
  archPath(c, win.x, win.y, win.w, win.h);
  c.strokeStyle = '#d2b77e';
  c.lineWidth = Math.max(2, w * 0.008);
  c.stroke();
  c.fillStyle = '#c5a471';
  c.fillRect(win.x - houseW * 0.035, win.y + win.h - houseH * 0.01, win.w + houseW * 0.07, houseH * 0.035);

  // Porte cintrée à deux panneaux, d'abord calfeutrée puis repeinte corail.
  const { door } = l;
  archPath(c, door.x - houseW * 0.035, door.y - houseH * 0.02, door.w + houseW * 0.07, door.h + houseH * 0.02);
  c.fillStyle = '#b08a60';
  c.fill();
  archPath(c, door.x, door.y, door.w, door.h);
  c.save();
  c.clip();
  const doorPaint = c.createLinearGradient(door.x, door.y, door.x + door.w, door.y + door.h);
  doorPaint.addColorStop(0, has('door') ? '#c77861' : '#302a2a');
  doorPaint.addColorStop(0.55, has('door') ? '#9d514b' : '#201e24');
  doorPaint.addColorStop(1, has('door') ? '#543941' : '#141b23');
  c.fillStyle = doorPaint;
  c.fillRect(door.x, door.y, door.w, door.h);
  c.strokeStyle = has('door') ? 'rgba(244, 194, 143, 0.42)' : 'rgba(153, 127, 98, 0.4)';
  c.lineWidth = 1.2;
  roundedRect(c, door.x + door.w * 0.12, door.y + door.h * 0.1, door.w * 0.76, door.h * 0.34, door.w * 0.055);
  c.stroke();
  roundedRect(c, door.x + door.w * 0.12, door.y + door.h * 0.5, door.w * 0.76, door.h * 0.42, door.w * 0.055);
  c.stroke();
  if (!has('door')) {
    c.strokeStyle = '#8a765e';
    c.lineWidth = Math.max(2, w * 0.006);
    for (const offset of [-0.25, 0.16]) {
      c.beginPath();
      c.moveTo(door.x + door.w * 0.03, door.y + door.h * (0.32 + offset));
      c.lineTo(door.x + door.w * 0.97, door.y + door.h * (0.63 + offset));
      c.stroke();
    }
  }
  c.restore();
  archPath(c, door.x, door.y, door.w, door.h);
  c.strokeStyle = '#e1bd82';
  c.lineWidth = Math.max(2, w * 0.008);
  c.stroke();
  c.fillStyle = has('door') ? '#f2d08b' : '#a68b62';
  c.beginPath();
  c.arc(door.x + door.w * 0.78, door.y + door.h * 0.58, Math.max(2, door.w * 0.045), 0, Math.PI * 2);
  c.fill();
  // Petite marquise au-dessus du seuil.
  c.fillStyle = '#193b42';
  c.beginPath();
  c.moveTo(door.x - houseW * 0.09, door.y + houseH * 0.035);
  c.lineTo(door.x + door.w * 0.5, door.y - houseH * 0.09);
  c.lineTo(door.x + door.w + houseW * 0.08, door.y + houseH * 0.035);
  c.closePath();
  c.fill();
  c.strokeStyle = '#d0a96e';
  c.lineWidth = 1.5;
  c.stroke();

  // Lanterne de quai en verre ambré et cuivre.
  const { lantern } = l;
  const ls = Math.max(9, door.w * 0.29);
  c.strokeStyle = '#bd9a68';
  c.lineWidth = 1.8;
  c.beginPath();
  c.moveTo(lantern.x, lantern.y - ls * 1.25);
  c.lineTo(lantern.x, lantern.y - ls * 0.78);
  c.moveTo(lantern.x - ls * 0.52, lantern.y - ls * 0.68);
  c.lineTo(lantern.x + ls * 0.52, lantern.y - ls * 0.68);
  c.stroke();
  if (lit) glow(c, lantern.x, lantern.y, ls * 3.8, '#ffc56b', 0.78);
  c.fillStyle = lit ? '#ffdf91' : '#53646a';
  c.beginPath();
  c.moveTo(lantern.x - ls * 0.36, lantern.y - ls * 0.48);
  c.lineTo(lantern.x + ls * 0.36, lantern.y - ls * 0.48);
  c.lineTo(lantern.x + ls * 0.46, lantern.y + ls * 0.34);
  c.lineTo(lantern.x, lantern.y + ls * 0.6);
  c.lineTo(lantern.x - ls * 0.46, lantern.y + ls * 0.34);
  c.closePath();
  c.fill();
  c.strokeStyle = '#392f2c';
  c.lineWidth = 2;
  c.stroke();
  c.fillStyle = lit ? '#fff5c8' : '#798589';
  c.beginPath();
  c.ellipse(lantern.x, lantern.y + ls * 0.1, ls * 0.16, ls * 0.27, 0, 0, Math.PI * 2);
  c.fill();

  // Enseigne émaillée suspendue dans le pignon.
  const { sign } = l;
  c.strokeStyle = '#b48d5e';
  c.lineWidth = 1.5;
  c.beginPath();
  c.moveTo(sign.x + sign.w * 0.18, sign.y - houseH * 0.045);
  c.lineTo(sign.x + sign.w * 0.18, sign.y + sign.h * 0.2);
  c.moveTo(sign.x + sign.w * 0.82, sign.y - houseH * 0.045);
  c.lineTo(sign.x + sign.w * 0.82, sign.y + sign.h * 0.2);
  c.stroke();
  const signPaint = c.createLinearGradient(0, sign.y, 0, sign.y + sign.h);
  signPaint.addColorStop(0, has('sign') ? '#fff0c9' : '#988b76');
  signPaint.addColorStop(1, has('sign') ? '#d7b87c' : '#5f6461');
  roundedRect(c, sign.x, sign.y, sign.w, sign.h, sign.h * 0.22);
  c.fillStyle = signPaint;
  c.fill();
  c.strokeStyle = has('sign') ? '#e7c77f' : '#485056';
  c.lineWidth = Math.max(1.5, w * 0.005);
  c.stroke();
  c.textAlign = 'center';
  c.textBaseline = 'middle';
  c.font = `700 ${Math.max(8, Math.round(sign.h * (has('sign') ? 0.4 : 0.37)))}px ${SERIF}`;
  c.fillStyle = has('sign') ? '#65483a' : 'rgba(27, 37, 40, 0.78)';
  const pearlInc = has('sign') && scene.brand === 'pearl-inc';
  c.fillText(pearlInc ? 'PEARL INC.' : has('sign') ? 'MAISON ROSE' : 'ROSE', sign.x + sign.w / 2, sign.y + sign.h * 0.43);
  c.font = `600 ${Math.max(5, Math.round(sign.h * 0.16))}px sans-serif`;
  c.fillStyle = has('sign') ? '#80684d' : 'rgba(30, 35, 36, 0.55)';
  c.fillText(pearlInc ? 'JOAILLIERS' : 'PERLES FINES', sign.x + sign.w / 2, sign.y + sign.h * 0.76);

  // Vitrine-bijoutière au bout du ponton, bâchée avant sa restauration.
  const { vitrine } = l;
  const pedestalY = vitrine.y + vitrine.h;
  c.fillStyle = '#302a28';
  c.beginPath();
  c.moveTo(vitrine.x + vitrine.w * 0.13, pedestalY);
  c.lineTo(vitrine.x + vitrine.w * 0.87, pedestalY);
  c.lineTo(vitrine.x + vitrine.w * 0.95, l.ground);
  c.lineTo(vitrine.x + vitrine.w * 0.05, l.ground);
  c.closePath();
  c.fill();
  if (has('vitrine')) {
    const vx = vitrine.x;
    const vy = vitrine.y;
    const vw = vitrine.w;
    const vh = vitrine.h;
    glow(c, vx + vw * 0.5, vy + vh * 0.48, vw * 1.35, '#ffdf96', 0.32);
    roundedRect(c, vx, vy, vw, vh, vw * 0.08);
    c.fillStyle = '#302b39';
    c.fill();
    roundedRect(c, vx + vw * 0.09, vy + vh * 0.08, vw * 0.82, vh * 0.76, vw * 0.06);
    c.fillStyle = 'rgba(15, 29, 43, 0.84)';
    c.fill();
    if (scene.showcase) {
      const s = Math.min(vw * 0.68, vh * 0.68);
      c.drawImage(scene.showcase, vx + (vw - s) / 2, vy + (vh - s) / 2, s, s);
    } else {
      glow(c, vx + vw * 0.5, vy + vh * 0.42, vw * 0.36, '#f4d994', 0.62);
      c.fillStyle = '#f0ddb5';
      c.beginPath();
      c.arc(vx + vw * 0.5, vy + vh * 0.42, vw * 0.09, 0, Math.PI * 2);
      c.fill();
    }
    c.strokeStyle = 'rgba(247, 229, 186, 0.56)';
    c.lineWidth = 1;
    c.beginPath();
    c.moveTo(vx + vw * 0.14, vy + vh * 0.72);
    c.lineTo(vx + vw * 0.5, vy + vh * 0.1);
    c.stroke();
    c.strokeStyle = '#c7a56b';
    c.lineWidth = 2;
    roundedRect(c, vx, vy, vw, vh, vw * 0.08);
    c.stroke();
  } else {
    c.fillStyle = '#65605a';
    c.beginPath();
    c.moveTo(vitrine.x - 3, vitrine.y + vitrine.h);
    c.quadraticCurveTo(vitrine.x + vitrine.w * 0.16, vitrine.y + vitrine.h * 0.02, vitrine.x + vitrine.w / 2, vitrine.y);
    c.quadraticCurveTo(vitrine.x + vitrine.w * 0.84, vitrine.y + vitrine.h * 0.02, vitrine.x + vitrine.w + 3, vitrine.y + vitrine.h);
    c.closePath();
    c.fill();
    c.strokeStyle = '#aaa18d';
    c.setLineDash([3, 3]);
    c.stroke();
    c.setLineDash([]);
  }

  // La boîte qui n'aurait pas dû briller.
  if (has('box')) {
    const pulse = 0.5 + 0.5 * Math.sin(t / 700);
    glow(c, l.box.x, l.box.y, l.box.s * 2.2, '#ff2f72', 0.25 + 0.2 * pulse);
    c.fillStyle = '#2b1020';
    c.fillRect(l.box.x - l.box.s / 2, l.box.y - l.box.s / 2, l.box.s, l.box.s * 0.8);
    c.fillStyle = '#e8be5a';
    c.fillRect(l.box.x - l.box.s * 0.08, l.box.y - l.box.s * 0.2, l.box.s * 0.16, l.box.s * 0.2);
  }

  // Lucioles autour de la lanterne allumée.
  if (lit) {
    for (let i = 0; i < 6; i++) {
      const a = t / (1800 + i * 300) + i * 1.3;
      const fx = l.lantern.x + Math.cos(a) * w * (0.08 + 0.03 * i) + Math.sin(t / 700 + i) * 8;
      const fy = l.lantern.y + Math.sin(a * 1.3) * h * 0.06 + h * 0.02;
      const blink = Math.max(0, Math.sin(t / 400 + i * 2.3));
      glow(c, fx, fy, 7, '#fff3a0', 0.8 * blink);
    }
  }

  // Éclat de restauration.
  if (scene.appearing) {
    const [ax, ay] = anchor(l, scene.appearing.feature);
    const p = scene.appearing.progress;
    glow(c, ax, ay, w * 0.25 * (0.5 + p), '#fff1c4', 0.6 * (1 - p));
    c.strokeStyle = `rgba(255, 241, 196, ${1 - p})`;
    c.lineWidth = 1.5;
    for (let i = 0; i < 10; i++) {
      const a = (i / 10) * Math.PI * 2 + p;
      const r0 = w * 0.04 + p * w * 0.08;
      const r1 = r0 + w * 0.05 * (1 - p);
      c.beginPath();
      c.moveTo(ax + Math.cos(a) * r0, ay + Math.sin(a) * r0);
      c.lineTo(ax + Math.cos(a) * r1, ay + Math.sin(a) * r1);
      c.stroke();
    }
  }
}
