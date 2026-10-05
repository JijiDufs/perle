// Le lagon de la Pêche (direction « lagon lumineux », AGENTS.md §6) : eau turquoise traversée de soleil,
// fond de sable où dansent les reflets (caustiques), récif au loin, algues, bulles, plancton, poissons.
// Tout est dessiné par code. Le fixe (eau, sable, récif) est calculé une fois par taille d'écran ;
// seul ce qui bouge est redessiné à chaque image.
import { rgba } from './color';

type Ctx = CanvasRenderingContext2D;

/** Ce que le décor doit savoir du sujet (l'huître) : où il est posé, et sa taille. */
export interface Focus {
  x: number;
  y: number;
  size: number;
}

interface Bubble {
  x: number;
  y: number;
  r: number;
  speed: number;
  phase: number;
}

interface Mote {
  x: number;
  y: number;
  r: number;
  drift: number;
  phase: number;
}

const TAU = Math.PI * 2;

/** Hasard déterministe : le décor est le même d'une fois sur l'autre. */
function seeded(seed: number): () => number {
  let s = seed;
  return () => (s = (s * 16807) % 2147483647) / 2147483647;
}

function makeCanvas(w: number, h: number): [HTMLCanvasElement, Ctx] {
  const canvas = document.createElement('canvas');
  canvas.width = Math.max(1, Math.round(w));
  canvas.height = Math.max(1, Math.round(h));
  return [canvas, canvas.getContext('2d')!];
}

/**
 * Motif de caustiques qui se répète sans couture : un réseau de lignes lumineuses ondulées,
 * comme la lumière qui traverse les vagues et se pose sur le sable.
 */
function causticTile(size: number): HTMLCanvasElement {
  const [canvas, c] = makeCanvas(size, size);
  const image = c.createImageData(size, size);
  const k = TAU / size;
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const a = Math.sin(x * k * 3 + 1.7 * Math.sin(y * k * 2)) + Math.sin(y * k * 3 + 1.9 * Math.sin(x * k * 2 + 1));
      const b = Math.sin((x + y) * k * 2 + 1.3 * Math.sin((x - y) * k * 1));
      const line = Math.max(0, 1 - Math.abs(a) * 1.6) ** 3 + 0.6 * Math.max(0, 1 - Math.abs(b) * 2.2) ** 4;
      const i = (y * size + x) * 4;
      image.data[i] = 220;
      image.data[i + 1] = 255;
      image.data[i + 2] = 245;
      image.data[i + 3] = Math.min(255, line * 200);
    }
  }
  c.putImageData(image, 0, 0);
  return canvas;
}

export class Lagoon {
  private base: HTMLCanvasElement | null = null;
  private vignette: HTMLCanvasElement | null = null;
  private key = '';
  private tile = causticTile(192);
  private caustics: [HTMLCanvasElement, Ctx] | null = null;
  private bubbles: Bubble[] = [];
  private motes: Mote[] = [];
  private horizon = 0;
  private w = 0;
  private h = 0;

  /** Dessine le décor, sous le sujet. `t` en secondes. */
  draw(c: Ctx, w: number, h: number, t: number, focus: Focus): void {
    const horizon = Math.round(focus.y - focus.size * 0.32);
    const key = `${Math.round(w)}x${Math.round(h)}@${horizon}`;
    if (key !== this.key) this.build(w, h, horizon, key);

    c.drawImage(this.base!, 0, 0, w, h);
    this.drawSurface(c, t);
    this.drawRays(c, t);
    this.drawCaustics(c, t);
    this.drawSeaweed(c, t);
    this.drawFish(c, t);
    this.drawParticles(c, t);
    // Ombre douce de l'huître sur le sable.
    const shadow = c.createRadialGradient(focus.x, focus.y + focus.size * 0.62, 0, focus.x, focus.y + focus.size * 0.62, focus.size * 1.05);
    shadow.addColorStop(0, 'rgba(0, 30, 35, 0.42)');
    shadow.addColorStop(1, 'rgba(0, 30, 35, 0)');
    c.save();
    c.translate(0, focus.y + focus.size * 0.62);
    c.scale(1, 0.42);
    c.translate(0, -(focus.y + focus.size * 0.62));
    c.fillStyle = shadow;
    c.fillRect(focus.x - focus.size * 1.1, focus.y - focus.size * 0.6, focus.size * 2.2, focus.size * 2.6);
    c.restore();
  }

  /** Par-dessus le sujet : vignette et voile de profondeur. */
  drawOverlay(c: Ctx, w: number, h: number): void {
    if (this.vignette) c.drawImage(this.vignette, 0, 0, w, h);
  }

  private build(w: number, h: number, horizon: number, key: string): void {
    this.key = key;
    this.w = w;
    this.h = h;
    this.horizon = horizon;
    const scale = Math.min(window.devicePixelRatio || 1, 2);
    const [base, c] = makeCanvas(w * scale, h * scale);
    c.scale(scale, scale);
    const rand = seeded(11);

    // L'eau : claire près de la surface, turquoise profond vers le fond.
    const water = c.createLinearGradient(0, 0, 0, horizon);
    water.addColorStop(0, '#7fe3dc');
    water.addColorStop(0.18, '#2fb7bd');
    water.addColorStop(0.62, '#11808c');
    water.addColorStop(1, '#0b5f6c');
    c.fillStyle = water;
    c.fillRect(0, 0, w, horizon + 2);

    // Le récif au loin, noyé dans la brume bleue.
    for (const [depth, color] of [
      [0.16, '#0f6c78'],
      [0.07, '#0d6170'],
    ] as const) {
      c.fillStyle = color;
      c.beginPath();
      c.moveTo(0, horizon);
      let x = 0;
      while (x < w) {
        const bump = 18 + rand() * 46;
        const height = horizon * depth * (0.4 + rand() * 0.9);
        c.quadraticCurveTo(x + bump / 2, horizon - height, x + bump, horizon - height * 0.25 * rand());
        x += bump;
      }
      c.lineTo(w, horizon + 4);
      c.lineTo(0, horizon + 4);
      c.closePath();
      c.fill();
      // Quelques coraux en éventail sur la crête.
      for (let i = 0; i < 4; i++) {
        const fx = rand() * w;
        const fy = horizon - horizon * depth * 0.6;
        c.strokeStyle = color;
        c.lineWidth = 2;
        for (let b = -3; b <= 3; b++) {
          c.beginPath();
          c.moveTo(fx, fy + 6);
          c.quadraticCurveTo(fx + b * 4, fy - 8, fx + b * 7, fy - 16 - rand() * 10);
          c.stroke();
        }
      }
    }

    // Le sable : brume turquoise à l'horizon, plus clair et chaud vers le bas.
    const sand = c.createLinearGradient(0, horizon, 0, h);
    sand.addColorStop(0, '#2c8f8e');
    sand.addColorStop(0.18, '#6fb3a0');
    sand.addColorStop(0.55, '#c9c39a');
    sand.addColorStop(1, '#a8a07a');
    c.fillStyle = sand;
    c.fillRect(0, horizon, w, h - horizon);

    // Rides du sable, plus serrées près de l'horizon (perspective).
    c.lineWidth = 1.2;
    for (let i = 2; i < 26; i++) {
      const k = i / 26;
      const y = horizon + (h - horizon) * k * k + 4;
      c.strokeStyle = `rgba(255, 250, 225, ${0.06 + 0.1 * k})`;
      c.beginPath();
      for (let x = -10; x <= w + 10; x += 12) {
        const yy = y + Math.sin(x / (14 + 30 * k) + i * 1.3) * (1 + 3 * k);
        if (x === -10) c.moveTo(x, yy);
        else c.lineTo(x, yy);
      }
      c.stroke();
      c.strokeStyle = `rgba(40, 70, 60, ${0.05 + 0.08 * k})`;
      c.beginPath();
      for (let x = -10; x <= w + 10; x += 12) {
        const yy = y + 2 + Math.sin(x / (14 + 30 * k) + i * 1.3) * (1 + 3 * k);
        if (x === -10) c.moveTo(x, yy);
        else c.lineTo(x, yy);
      }
      c.stroke();
    }

    // Galets et petits coquillages semés.
    for (let i = 0; i < 26; i++) {
      const k = 0.15 + rand() * 0.85;
      const y = horizon + (h - horizon) * k;
      const x = rand() * w;
      const r = (1.5 + rand() * 4) * (0.5 + k);
      c.fillStyle = rand() > 0.5 ? `rgba(120, 110, 90, ${0.35 + k * 0.3})` : `rgba(240, 225, 200, ${0.3 + k * 0.4})`;
      c.beginPath();
      c.ellipse(x, y, r * 1.4, r * 0.8, rand(), 0, TAU);
      c.fill();
    }
    // Deux étoiles de mer.
    for (const [sx, sy, sr] of [
      [w * 0.12, horizon + (h - horizon) * 0.78, 13],
      [w * 0.88, horizon + (h - horizon) * 0.55, 9],
    ]) {
      c.save();
      c.translate(sx, sy);
      c.scale(1, 0.6);
      c.fillStyle = '#e07a52';
      c.beginPath();
      for (let p = 0; p < 10; p++) {
        const a = (p / 10) * TAU - Math.PI / 2;
        const r = p % 2 ? sr * 0.42 : sr;
        c.lineTo(Math.cos(a) * r, Math.sin(a) * r);
      }
      c.closePath();
      c.fill();
      c.restore();
    }

    // Brume à l'horizon, par-dessus les rides : l'eau et le sable se fondent l'un dans l'autre.
    const haze = c.createLinearGradient(0, horizon - horizon * 0.22, 0, horizon + (h - horizon) * 0.22);
    haze.addColorStop(0, 'rgba(18, 120, 132, 0)');
    haze.addColorStop(0.5, 'rgba(24, 128, 138, 0.85)');
    haze.addColorStop(1, 'rgba(40, 140, 140, 0)');
    c.fillStyle = haze;
    c.fillRect(0, horizon - horizon * 0.22, w, horizon * 0.22 + (h - horizon) * 0.22);

    this.base = base;

    // Vignette : bords plus sombres, comme vus à travers un masque de plongée.
    const [vignette, v] = makeCanvas(w, h);
    const g = v.createRadialGradient(w / 2, h * 0.5, Math.min(w, h) * 0.35, w / 2, h * 0.5, Math.max(w, h) * 0.8);
    g.addColorStop(0, 'rgba(0, 20, 30, 0)');
    g.addColorStop(1, 'rgba(0, 20, 30, 0.55)');
    v.fillStyle = g;
    v.fillRect(0, 0, w, h);
    this.vignette = vignette;

    // Caustiques : dessinées à basse résolution (elles sont floues de toute façon).
    this.caustics = makeCanvas(w / 2, (h - horizon) / 2);

    // Bulles et plancton.
    const r2 = seeded(5);
    this.bubbles = Array.from({ length: 14 }, () => ({ x: r2() * w, y: horizon + r2() * (h - horizon), r: 1.5 + r2() * 3.5, speed: 18 + r2() * 30, phase: r2() * TAU }));
    this.motes = Array.from({ length: 34 }, () => ({ x: r2() * w, y: r2() * h, r: 0.6 + r2() * 1.4, drift: 4 + r2() * 10, phase: r2() * TAU }));
  }

  /** Le dessous de la surface, qui ondule tout en haut. */
  private drawSurface(c: Ctx, t: number): void {
    const { w } = this;
    const top = this.horizon * 0.14;
    c.save();
    c.globalCompositeOperation = 'lighter';
    for (let i = 0; i < 3; i++) {
      c.strokeStyle = `rgba(230, 255, 250, ${0.1 - i * 0.025})`;
      c.lineWidth = 2;
      c.beginPath();
      for (let x = -10; x <= w + 10; x += 10) {
        const y = top * (0.25 + i * 0.3) + Math.sin(x / 38 + t * (0.9 + i * 0.3) + i) * 3 + Math.sin(x / 13 - t * 1.7) * 1.2;
        if (x === -10) c.moveTo(x, y);
        else c.lineTo(x, y);
      }
      c.stroke();
    }
    c.restore();
  }

  /** Rayons de soleil qui descendent en biais et ondulent doucement. */
  private drawRays(c: Ctx, t: number): void {
    const { w, horizon } = this;
    const bottom = horizon + (this.h - horizon) * 0.45;
    c.save();
    c.globalCompositeOperation = 'lighter';
    for (let i = 0; i < 6; i++) {
      const sway = Math.sin(t * 0.25 + i * 1.9) * w * 0.04;
      const x0 = w * (0.02 + i * 0.19) + sway;
      const top = w * (0.035 + 0.02 * Math.sin(i * 3.1));
      const spread = w * (0.12 + 0.05 * Math.sin(i * 2.3));
      const skew = w * 0.16;
      const alpha = 0.08 + 0.05 * Math.sin(t * 0.6 + i * 2.1);
      const g = c.createLinearGradient(0, 0, 0, bottom);
      g.addColorStop(0, `rgba(255, 255, 225, ${alpha})`);
      g.addColorStop(0.6, `rgba(220, 255, 240, ${alpha * 0.45})`);
      g.addColorStop(1, 'rgba(220, 255, 240, 0)');
      c.fillStyle = g;
      c.beginPath();
      c.moveTo(x0, 0);
      c.lineTo(x0 + top, 0);
      c.lineTo(x0 + top + skew + spread, bottom);
      c.lineTo(x0 + skew - spread * 0.2, bottom);
      c.closePath();
      c.fill();
    }
    c.restore();
  }

  /** Reflets de lumière sur le sable : deux nappes de caustiques qui glissent l'une sur l'autre. */
  private drawCaustics(c: Ctx, t: number): void {
    if (!this.caustics) return;
    const [canvas, cc] = this.caustics;
    const cw = canvas.width;
    const ch = canvas.height;
    cc.clearRect(0, 0, cw, ch);
    for (const [speed, dir, scale, alpha] of [
      [6, 1, 1, 0.75],
      [5, -1, 1.3, 0.55],
    ] as const) {
      const pattern = cc.createPattern(this.tile, 'repeat')!;
      pattern.setTransform(new DOMMatrix().translateSelf(t * speed * dir, t * speed * 0.6).scaleSelf(scale * 0.55, scale * 0.3));
      cc.globalAlpha = alpha;
      cc.fillStyle = pattern;
      cc.fillRect(0, 0, cw, ch);
    }
    cc.globalAlpha = 1;
    // Plus discrètes à l'horizon, dans la brume.
    cc.globalCompositeOperation = 'destination-in';
    const fade = cc.createLinearGradient(0, 0, 0, ch);
    fade.addColorStop(0, 'rgba(0,0,0,0)');
    fade.addColorStop(0.25, 'rgba(0,0,0,0.6)');
    fade.addColorStop(1, 'rgba(0,0,0,1)');
    cc.fillStyle = fade;
    cc.fillRect(0, 0, cw, ch);
    cc.globalCompositeOperation = 'source-over';
    c.save();
    c.globalCompositeOperation = 'lighter';
    c.globalAlpha = 0.32;
    c.drawImage(canvas, 0, this.horizon, this.w, this.h - this.horizon);
    c.restore();
  }

  /** Algues sur les bords, qui ondulent avec le courant. */
  private drawSeaweed(c: Ctx, t: number): void {
    const { w, h, horizon } = this;
    const strands: [number, number, number, string][] = [
      [w * 0.04, h * 0.42, 0, '#2f9a6a'],
      [w * 0.1, h * 0.3, 1.3, '#3fb37a'],
      [w * 0.93, h * 0.36, 2.1, '#2f9a6a'],
      [w * 0.985, h * 0.26, 0.7, '#46b985'],
      [w * 0.2, h * 0.14, 3.1, '#5ac08a'],
    ];
    for (const [x, height, phase, color] of strands) {
      const baseY = Math.min(h, horizon + (h - horizon) * 0.95);
      c.save();
      c.fillStyle = color;
      c.globalAlpha = 0.85;
      c.beginPath();
      const steps = 8;
      const left: [number, number][] = [];
      const right: [number, number][] = [];
      for (let s = 0; s <= steps; s++) {
        const k = s / steps;
        const sway = Math.sin(t * 1.1 + phase + k * 2.4) * 14 * k * k;
        const px = x + sway;
        const py = baseY - height * k;
        const width = 7 * (1 - k * 0.85);
        left.push([px - width, py]);
        right.push([px + width, py]);
      }
      c.moveTo(...left[0]);
      for (const p of left) c.lineTo(...p);
      for (const p of right.reverse()) c.lineTo(...p);
      c.closePath();
      c.fill();
      // Nervure claire.
      c.strokeStyle = rgba('#d8ffd0', 0.18);
      c.lineWidth = 1;
      c.beginPath();
      for (let s = 0; s <= steps; s++) {
        const k = s / steps;
        const px = x + Math.sin(t * 1.1 + phase + k * 2.4) * 14 * k * k;
        const py = baseY - height * k;
        if (s === 0) c.moveTo(px, py);
        else c.lineTo(px, py);
      }
      c.stroke();
      c.restore();
    }
  }

  /** Un petit banc de poissons traverse au loin, de temps en temps. */
  private drawFish(c: Ctx, t: number): void {
    const period = 22;
    const cycle = t % period;
    if (cycle > 11) return;
    const pass = Math.floor(t / period);
    const fromLeft = pass % 2 === 0;
    const k = cycle / 11;
    const { w, horizon } = this;
    const baseX = fromLeft ? -60 + k * (w + 120) : w + 60 - k * (w + 120);
    const baseY = horizon * (0.42 + 0.18 * Math.sin(pass * 1.7));
    c.save();
    c.fillStyle = 'rgba(8, 70, 80, 0.55)';
    for (let i = 0; i < 6; i++) {
      const fx = baseX + (fromLeft ? -1 : 1) * (i % 3) * 16 + Math.sin(t * 2 + i) * 3;
      const fy = baseY + Math.floor(i / 3) * 12 + (i % 3) * 5 + Math.sin(t * 3 + i * 1.3) * 2;
      c.save();
      c.translate(fx, fy);
      if (!fromLeft) c.scale(-1, 1);
      c.beginPath();
      c.ellipse(0, 0, 7, 2.6, 0, 0, TAU);
      c.moveTo(-6, 0);
      c.lineTo(-11, -3.2 + Math.sin(t * 12 + i) * 0.8);
      c.lineTo(-11, 3.2 + Math.sin(t * 12 + i) * 0.8);
      c.closePath();
      c.fill();
      c.restore();
    }
    c.restore();
  }

  /** Bulles qui montent du sable, plancton qui flotte dans la lumière. */
  private drawParticles(c: Ctx, t: number): void {
    const { w, h, horizon } = this;
    c.save();
    for (const m of this.motes) {
      const x = (m.x + Math.sin(t * 0.3 + m.phase) * m.drift + t * 3) % w;
      const y = (m.y - t * m.drift * 0.6 + h * 4) % h;
      c.fillStyle = `rgba(235, 255, 245, ${0.25 + 0.25 * Math.sin(t + m.phase)})`;
      c.beginPath();
      c.arc(x, y, m.r, 0, TAU);
      c.fill();
    }
    for (const b of this.bubbles) {
      const travel = h - horizon * 0.2;
      const y = horizon + (h - horizon) * 0.9 - (((t * b.speed + b.phase * 100) % travel) + travel) % travel;
      const x = b.x + Math.sin(t * 2 + b.phase) * 4;
      const fade = Math.min(1, Math.max(0, y / (horizon * 0.5)));
      c.strokeStyle = `rgba(240, 255, 255, ${0.55 * fade})`;
      c.lineWidth = 1;
      c.beginPath();
      c.arc(x, y, b.r, 0, TAU);
      c.stroke();
      c.fillStyle = `rgba(255, 255, 255, ${0.6 * fade})`;
      c.beginPath();
      c.arc(x - b.r * 0.35, y - b.r * 0.35, b.r * 0.3, 0, TAU);
      c.fill();
    }
    c.restore();
  }
}
