// La Maison dessinée par code (Canvas 2D) : une cabane au bout d'un ponton, au crépuscule,
// dont chaque élément restauré par une lettre change l'image. Provisoire : phase 2 (design).
import type { HouseFeature } from '../core/house';
import { rgba } from './color';
import { SERIF } from './cardStyle';

type Ctx = CanvasRenderingContext2D;

export interface HouseScene {
  restored: ReadonlySet<HouseFeature>;
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
  const cx = w * 0.56;
  const ground = h * 0.74;
  const wallH = Math.min(h * 0.3, w * 0.42);
  const wallW = Math.min(w * 0.58, h * 0.8);
  const x0 = cx - wallW / 2;
  const x1 = cx + wallW / 2;
  const wallTop = ground - wallH;
  const door = { x: x0 + wallW * 0.12, y: ground - wallH * 0.68, w: wallW * 0.22, h: wallH * 0.68 };
  const win = { x: x0 + wallW * 0.5, y: wallTop + wallH * 0.2, w: wallW * 0.36, h: wallH * 0.36 };
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
    lantern: { x: door.x + door.w / 2, y: door.y - wallH * 0.1 },
    sign: { x: cx - wallW * 0.36, y: wallTop - wallH * 0.2, w: wallW * 0.72, h: wallH * 0.17 },
    vitrine: { x: x0 - wallW * 0.36, y: ground - wallH * 0.62, w: wallW * 0.26, h: wallH * 0.36 },
    box: { x: win.x + win.w * 0.68, y: ground - wallH * 0.12, s: wallH * 0.12 },
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

  // Mer.
  const sea = c.createLinearGradient(0, l.horizon, 0, h);
  sea.addColorStop(0, '#20414a');
  sea.addColorStop(1, '#06121a');
  c.fillStyle = sea;
  c.fillRect(0, l.horizon, w, h - l.horizon);
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
  // Reflet de la lune : une colonne de petits traits qui scintillent sur l'eau.
  glow(c, w * 0.18, l.horizon + (h - l.horizon) * 0.35, w * 0.12, '#cfe6ff', 0.08);
  for (let i = 0; i < 14; i++) {
    const k = i / 14;
    const y = l.horizon + 3 + k * (h - l.horizon) * 0.8;
    const width = w * (0.015 + k * 0.05) * (0.6 + 0.4 * Math.sin(t / 300 + i * 1.7));
    c.fillStyle = `rgba(220, 235, 255, ${0.35 * (1 - k)})`;
    c.fillRect(w * 0.18 - width / 2 + Math.sin(t / 700 + i) * 3, y, width, 1.5);
  }

  // Ponton.
  c.fillStyle = '#3a2c22';
  c.fillRect(0, l.ground, w, h * 0.035);
  c.fillStyle = '#2a1f18';
  for (let x = 6; x < w; x += w / 9) c.fillRect(x, l.ground + h * 0.035, w * 0.018, h - l.ground);
  c.strokeStyle = 'rgba(0, 0, 0, 0.35)';
  for (let x = 0; x < w; x += w / 22) {
    c.beginPath();
    c.moveTo(x, l.ground);
    c.lineTo(x, l.ground + h * 0.035);
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

  // Murs en planches.
  c.fillStyle = has('door') ? '#6a4f3b' : '#4a3b31';
  c.fillRect(l.x0, l.wallTop, l.x1 - l.x0, l.ground - l.wallTop);
  c.strokeStyle = 'rgba(0, 0, 0, 0.28)';
  c.lineWidth = 1.2;
  for (let x = l.x0; x < l.x1; x += (l.x1 - l.x0) / 14) {
    c.beginPath();
    c.moveTo(x, l.wallTop);
    c.lineTo(x, l.ground);
    c.stroke();
  }

  // Toit.
  c.fillStyle = '#23222b';
  c.beginPath();
  c.moveTo(l.x0 - w * 0.05, l.wallTop + 2);
  c.lineTo(l.cx, l.wallTop - (l.ground - l.wallTop) * 0.62);
  c.lineTo(l.x1 + w * 0.05, l.wallTop + 2);
  c.closePath();
  c.fill();
  c.strokeStyle = 'rgba(232, 241, 240, 0.08)';
  c.stroke();

  // Fenêtre : sale et sombre, ou éclairée avec le carnet (et l'établi).
  const { win } = l;
  if (has('notebook')) {
    const inside = c.createLinearGradient(0, win.y, 0, win.y + win.h);
    inside.addColorStop(0, '#ffdca0');
    inside.addColorStop(1, '#c98a3a');
    c.fillStyle = inside;
    c.fillRect(win.x, win.y, win.w, win.h);
    glow(c, win.x + win.w / 2, win.y + win.h / 2, win.w * 1.1, '#ffc56b', 0.25);
    if (has('workbench')) {
      c.fillStyle = 'rgba(60, 35, 15, 0.85)';
      c.fillRect(win.x + win.w * 0.08, win.y + win.h * 0.62, win.w * 0.84, win.h * 0.08);
      c.fillRect(win.x + win.w * 0.14, win.y + win.h * 0.7, win.w * 0.05, win.h * 0.3);
      c.fillRect(win.x + win.w * 0.8, win.y + win.h * 0.7, win.w * 0.05, win.h * 0.3);
      c.fillRect(win.x + win.w * 0.3, win.y + win.h * 0.42, win.w * 0.04, win.h * 0.2);
      c.beginPath();
      c.arc(win.x + win.w * 0.62, win.y + win.h * 0.55, win.w * 0.06, Math.PI, 0);
      c.fill();
    }
    // Le carnet sur le rebord.
    c.fillStyle = '#7a2141';
    c.fillRect(win.x + win.w * 0.12, win.y + win.h - win.h * 0.14, win.w * 0.24, win.h * 0.1);
    c.fillStyle = '#f2e6cf';
    c.fillRect(win.x + win.w * 0.14, win.y + win.h - win.h * 0.13, win.w * 0.2, win.h * 0.03);
  } else {
    c.fillStyle = '#1c2228';
    c.fillRect(win.x, win.y, win.w, win.h);
    c.fillStyle = 'rgba(140, 150, 140, 0.18)';
    for (let i = 0; i < 7; i++) c.fillRect(win.x + ((i * 37) % win.w), win.y + ((i * 23) % win.h), win.w * 0.18, win.h * 0.12);
  }
  c.strokeStyle = '#2a1f18';
  c.lineWidth = 3;
  c.strokeRect(win.x, win.y, win.w, win.h);
  c.beginPath();
  c.moveTo(win.x + win.w / 2, win.y);
  c.lineTo(win.x + win.w / 2, win.y + win.h);
  c.moveTo(win.x, win.y + win.h / 2);
  c.lineTo(win.x + win.w, win.y + win.h / 2);
  c.stroke();

  // Porte : condamnée, ou rouverte avec un filet de lumière.
  const { door } = l;
  if (has('door')) {
    c.fillStyle = '#7a4b2e';
    c.fillRect(door.x, door.y, door.w, door.h);
    const leak = c.createLinearGradient(door.x + door.w, 0, door.x + door.w + door.w * 0.25, 0);
    leak.addColorStop(0, rgba('#ffc56b', has('notebook') ? 0.7 : 0.4));
    leak.addColorStop(1, rgba('#ffc56b', 0));
    c.fillStyle = leak;
    c.fillRect(door.x + door.w, door.y, door.w * 0.25, door.h);
    c.strokeStyle = 'rgba(0, 0, 0, 0.3)';
    c.lineWidth = 1.5;
    c.strokeRect(door.x + door.w * 0.12, door.y + door.h * 0.08, door.w * 0.76, door.h * 0.36);
    c.strokeRect(door.x + door.w * 0.12, door.y + door.h * 0.52, door.w * 0.76, door.h * 0.4);
    c.fillStyle = '#e8be5a';
    c.beginPath();
    c.arc(door.x + door.w * 0.82, door.y + door.h * 0.55, door.w * 0.05, 0, Math.PI * 2);
    c.fill();
  } else {
    c.fillStyle = '#241c17';
    c.fillRect(door.x, door.y, door.w, door.h);
    c.save();
    c.translate(door.x + door.w / 2, door.y + door.h / 2);
    c.fillStyle = '#5b4535';
    for (const angle of [0.5, -0.5]) {
      c.save();
      c.rotate(angle);
      c.fillRect(-door.h * 0.55, -door.w * 0.09, door.h * 1.1, door.w * 0.18);
      c.restore();
    }
    c.restore();
  }

  // Lanterne.
  const { lantern } = l;
  const ls = door.w * 0.32;
  c.strokeStyle = '#1c1a20';
  c.lineWidth = 2;
  c.beginPath();
  c.moveTo(lantern.x, lantern.y - ls * 1.1);
  c.lineTo(lantern.x, lantern.y - ls * 0.6);
  c.stroke();
  if (lit) glow(c, lantern.x, lantern.y, ls * 2.6, '#ffc56b', 0.75);
  c.fillStyle = lit ? '#ffe2a6' : '#3b3d44';
  c.fillRect(lantern.x - ls * 0.4, lantern.y - ls * 0.6, ls * 0.8, ls * 1.1);
  c.strokeStyle = '#1c1a20';
  c.strokeRect(lantern.x - ls * 0.4, lantern.y - ls * 0.6, ls * 0.8, ls * 1.1);

  // Enseigne.
  const { sign } = l;
  c.fillStyle = has('sign') ? '#f2e6cf' : '#5d5a55';
  c.fillRect(sign.x, sign.y, sign.w, sign.h);
  c.strokeStyle = has('sign') ? '#b88a2a' : '#3e3b37';
  c.lineWidth = 2;
  c.strokeRect(sign.x, sign.y, sign.w, sign.h);
  c.textAlign = 'center';
  c.textBaseline = 'middle';
  c.font = `${Math.round(sign.h * 0.55)}px ${SERIF}`;
  c.fillStyle = has('sign') ? '#7a5000' : 'rgba(30, 28, 26, 0.35)';
  c.fillText(has('sign') ? 'Maison Rose' : 'M  i  o   R  s', sign.x + sign.w / 2, sign.y + sign.h / 2 + 1);

  // Vitrine sur le ponton : bâchée, ou éclairée avec la plus belle pièce.
  const { vitrine } = l;
  c.fillStyle = '#2a1f18';
  c.fillRect(vitrine.x + vitrine.w * 0.1, vitrine.y + vitrine.h, vitrine.w * 0.8, l.ground - vitrine.y - vitrine.h);
  if (has('vitrine')) {
    glow(c, vitrine.x + vitrine.w / 2, vitrine.y + vitrine.h / 2, vitrine.w * 1.1, '#fff1d6', 0.22);
    c.fillStyle = 'rgba(30, 26, 40, 0.92)';
    c.fillRect(vitrine.x, vitrine.y, vitrine.w, vitrine.h);
    if (scene.showcase) {
      const s = Math.min(vitrine.w, vitrine.h) * 0.95;
      c.drawImage(scene.showcase, vitrine.x + (vitrine.w - s) / 2, vitrine.y + (vitrine.h - s) / 2, s, s);
    }
    c.fillStyle = 'rgba(255, 255, 255, 0.12)';
    c.beginPath();
    c.moveTo(vitrine.x, vitrine.y);
    c.lineTo(vitrine.x + vitrine.w * 0.4, vitrine.y);
    c.lineTo(vitrine.x, vitrine.y + vitrine.h * 0.6);
    c.fill();
    c.strokeStyle = '#b88a2a';
    c.lineWidth = 2;
    c.strokeRect(vitrine.x, vitrine.y, vitrine.w, vitrine.h);
  } else {
    c.fillStyle = '#5d5a55';
    c.beginPath();
    c.moveTo(vitrine.x - 3, vitrine.y + vitrine.h);
    c.quadraticCurveTo(vitrine.x + vitrine.w * 0.2, vitrine.y - vitrine.h * 0.1, vitrine.x + vitrine.w / 2, vitrine.y);
    c.quadraticCurveTo(vitrine.x + vitrine.w * 0.8, vitrine.y - vitrine.h * 0.1, vitrine.x + vitrine.w + 3, vitrine.y + vitrine.h);
    c.closePath();
    c.fill();
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
