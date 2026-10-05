// Le salon du joaillier, décor des écrins (direction « luxe », AGENTS.md §6) : mur prune tendu de soie,
// lumières floues au loin, table de velours bordeaux, faisceau chaud qui tombe sur l'écrin
// et poussières dorées qui y dansent. Le fixe est calculé une fois par taille d'écran.

type Ctx = CanvasRenderingContext2D;

/** L'écrin posé sur la table : son centre, et la taille de sa base. */
export interface SalonFocus {
  x: number;
  y: number;
  w: number;
  h: number;
}

interface Light {
  x: number;
  y: number;
  r: number;
  hue: string;
  phase: number;
}

interface Mote {
  x: number;
  y: number;
  r: number;
  speed: number;
  phase: number;
}

const TAU = Math.PI * 2;

function seeded(seed: number): () => number {
  let s = seed;
  return () => (s = (s * 16807) % 2147483647) / 2147483647;
}

export class Salon {
  private base: HTMLCanvasElement | null = null;
  private vignette: HTMLCanvasElement | null = null;
  private key = '';
  private lights: Light[] = [];
  private motes: Mote[] = [];

  draw(c: Ctx, w: number, h: number, t: number, focus: SalonFocus): void {
    const table = Math.round(focus.y - focus.h * 1.2);
    const key = `${Math.round(w)}x${Math.round(h)}@${table}`;
    if (key !== this.key) this.build(w, h, table, key);
    c.drawImage(this.base!, 0, 0, w, h);
    this.drawLights(c, t);
    this.drawBeam(c, t, focus);
    // Ombre de l'écrin sur le velours.
    // (Dégradé plutôt que `filter: blur`, que Safari ne gère pas sur un canvas.)
    const sy = focus.y + focus.h * 0.6;
    const shadow = c.createRadialGradient(focus.x, sy, 0, focus.x, sy, focus.w * 0.7);
    shadow.addColorStop(0, 'rgba(10, 0, 4, 0.6)');
    shadow.addColorStop(0.7, 'rgba(10, 0, 4, 0.35)');
    shadow.addColorStop(1, 'rgba(10, 0, 4, 0)');
    c.save();
    c.translate(0, sy);
    c.scale(1, 0.85);
    c.translate(0, -sy);
    c.fillStyle = shadow;
    c.fillRect(focus.x - focus.w, sy - focus.w, focus.w * 2, focus.w * 2);
    c.restore();
  }

  /** Par-dessus l'écrin : poussières dans la lumière, vignette. */
  drawOverlay(c: Ctx, w: number, h: number, t: number, focus: SalonFocus): void {
    this.drawMotes(c, t, focus);
    if (this.vignette) c.drawImage(this.vignette, 0, 0, w, h);
  }

  private build(w: number, h: number, table: number, key: string): void {
    this.key = key;
    const scale = Math.min(window.devicePixelRatio || 1, 2);
    const base = document.createElement('canvas');
    base.width = Math.round(w * scale);
    base.height = Math.round(h * scale);
    const c = base.getContext('2d')!;
    c.scale(scale, scale);
    const rand = seeded(3);

    // Le mur : soie prune, plus sombre en haut.
    const wall = c.createLinearGradient(0, 0, 0, table);
    wall.addColorStop(0, '#12080d');
    wall.addColorStop(0.7, '#2a1220');
    wall.addColorStop(1, '#3a1829');
    c.fillStyle = wall;
    c.fillRect(0, 0, w, table + 1);
    // Motif losangé très discret (papier peint damassé).
    c.strokeStyle = 'rgba(232, 190, 90, 0.045)';
    c.lineWidth = 1;
    const step = 34;
    for (let x = -table; x < w + table; x += step) {
      c.beginPath();
      c.moveTo(x, 0);
      c.lineTo(x + table, table);
      c.moveTo(x, 0);
      c.lineTo(x - table, table);
      c.stroke();
    }
    for (let y = step / 2; y < table; y += step) {
      for (let x = (y / step) % 2 ? step / 2 : 0; x < w; x += step) {
        c.fillStyle = 'rgba(232, 190, 90, 0.05)';
        c.beginPath();
        c.arc(x, y, 1.4, 0, TAU);
        c.fill();
      }
    }
    // Plinthe sombre et fin filet doré au bas du mur.
    const skirting = c.createLinearGradient(0, table - 16, 0, table);
    skirting.addColorStop(0, 'rgba(10, 3, 7, 0)');
    skirting.addColorStop(1, 'rgba(10, 3, 7, 0.7)');
    c.fillStyle = skirting;
    c.fillRect(0, table - 16, w, 16);
    c.fillStyle = 'rgba(232, 190, 90, 0.45)';
    c.fillRect(0, table - 3, w, 1);

    // La table : velours bordeaux, reflet doux qui suit la perspective.
    const velvet = c.createLinearGradient(0, table, 0, h);
    // Plus sombre que les écrins (eux aussi en velours) pour qu'ils ressortent dans le faisceau.
    velvet.addColorStop(0, '#3a0e1d');
    velvet.addColorStop(0.35, '#220710');
    velvet.addColorStop(1, '#0c0205');
    c.fillStyle = velvet;
    c.fillRect(0, table, w, h - table);
    const sheen = c.createRadialGradient(w / 2, table + (h - table) * 0.15, 0, w / 2, table + (h - table) * 0.15, w * 0.9);
    sheen.addColorStop(0, 'rgba(255, 170, 190, 0.12)');
    sheen.addColorStop(1, 'rgba(255, 170, 190, 0)');
    c.fillStyle = sheen;
    c.fillRect(0, table, w, h - table);
    // Grain du velours.
    for (let i = 0; i < 900; i++) {
      const y = table + rand() * (h - table);
      c.fillStyle = rand() > 0.5 ? 'rgba(255, 200, 215, 0.035)' : 'rgba(0, 0, 0, 0.08)';
      c.fillRect(rand() * w, y, 1.2, 1.2);
    }
    // Ombre du mur sur le bord de la table.
    const edge = c.createLinearGradient(0, table, 0, table + 18);
    edge.addColorStop(0, 'rgba(8, 0, 4, 0.55)');
    edge.addColorStop(1, 'rgba(8, 0, 4, 0)');
    c.fillStyle = edge;
    c.fillRect(0, table, w, 18);

    this.base = base;

    const vignette = document.createElement('canvas');
    vignette.width = Math.round(w);
    vignette.height = Math.round(h);
    const v = vignette.getContext('2d')!;
    const g = v.createRadialGradient(w / 2, h * 0.5, Math.min(w, h) * 0.3, w / 2, h * 0.5, Math.max(w, h) * 0.75);
    g.addColorStop(0, 'rgba(6, 0, 3, 0)');
    g.addColorStop(1, 'rgba(6, 0, 3, 0.7)');
    v.fillStyle = g;
    v.fillRect(0, 0, w, h);
    this.vignette = vignette;

    const r2 = seeded(9);
    const hues = ['#ffd27a', '#ffb3c6', '#fff1d6', '#ffc56b'];
    this.lights = Array.from({ length: 10 }, () => ({
      x: r2() * w,
      y: table * (0.15 + r2() * 0.75),
      r: 10 + r2() * 26,
      hue: hues[Math.floor(r2() * hues.length)],
      phase: r2() * TAU,
    }));
    this.motes = Array.from({ length: 30 }, () => ({ x: r2(), y: r2(), r: 0.6 + r2() * 1.6, speed: 4 + r2() * 9, phase: r2() * TAU }));
  }

  /** Lumières floues au loin (bokeh), qui respirent. */
  private drawLights(c: Ctx, t: number): void {
    c.save();
    c.globalCompositeOperation = 'lighter';
    for (const light of this.lights) {
      const alpha = 0.06 + 0.05 * Math.sin(t * 0.7 + light.phase);
      const x = light.x + Math.sin(t * 0.08 + light.phase) * 6;
      const g = c.createRadialGradient(x, light.y, light.r * 0.55, x, light.y, light.r);
      g.addColorStop(0, hexAlpha(light.hue, alpha));
      g.addColorStop(0.8, hexAlpha(light.hue, alpha * 0.8));
      g.addColorStop(1, hexAlpha(light.hue, 0));
      c.fillStyle = g;
      c.beginPath();
      c.arc(x, light.y, light.r, 0, TAU);
      c.fill();
    }
    c.restore();
  }

  /** Le faisceau chaud qui tombe d'en haut sur l'écrin. */
  private drawBeam(c: Ctx, t: number, focus: SalonFocus): void {
    const breathe = 0.9 + 0.1 * Math.sin(t * 0.8);
    c.save();
    c.globalCompositeOperation = 'lighter';
    const g = c.createLinearGradient(0, 0, 0, focus.y + focus.h);
    g.addColorStop(0, `rgba(255, 220, 160, ${0.02 * breathe})`);
    g.addColorStop(1, `rgba(255, 220, 160, ${0.09 * breathe})`);
    c.fillStyle = g;
    c.beginPath();
    c.moveTo(focus.x - focus.w * 0.18, 0);
    c.lineTo(focus.x + focus.w * 0.18, 0);
    c.lineTo(focus.x + focus.w * 0.95, focus.y + focus.h * 1.1);
    c.lineTo(focus.x - focus.w * 0.95, focus.y + focus.h * 1.1);
    c.closePath();
    c.fill();
    // Flaque de lumière sur le velours.
    const pool = c.createRadialGradient(focus.x, focus.y + focus.h * 0.5, 0, focus.x, focus.y + focus.h * 0.5, focus.w * 1.1);
    pool.addColorStop(0, `rgba(255, 190, 150, ${0.3 * breathe})`);
    pool.addColorStop(1, 'rgba(255, 190, 150, 0)');
    c.fillStyle = pool;
    c.save();
    c.translate(0, focus.y + focus.h * 0.5);
    c.scale(1, 0.62);
    c.translate(0, -(focus.y + focus.h * 0.5));
    c.fillRect(focus.x - focus.w * 1.2, focus.y - focus.h * 1.5, focus.w * 2.4, focus.h * 4);
    c.restore();
    c.restore();
  }

  /** Poussières dorées qui scintillent dans le faisceau. */
  private drawMotes(c: Ctx, t: number, focus: SalonFocus): void {
    c.save();
    c.globalCompositeOperation = 'lighter';
    const top = 0;
    const bottom = focus.y + focus.h;
    for (const m of this.motes) {
      const y = top + (((m.y * (bottom - top) - t * m.speed) % (bottom - top)) + (bottom - top)) % (bottom - top);
      const k = y / bottom;
      const halfWidth = focus.w * (0.18 + 0.77 * k);
      const x = focus.x + (m.x * 2 - 1) * halfWidth + Math.sin(t * 0.5 + m.phase) * 6;
      const twinkle = 0.25 + 0.75 * Math.max(0, Math.sin(t * 1.6 + m.phase * 3));
      c.fillStyle = `rgba(255, 230, 170, ${0.55 * twinkle})`;
      c.beginPath();
      c.arc(x, y, m.r, 0, TAU);
      c.fill();
    }
    c.restore();
  }
}

function hexAlpha(hex: string, alpha: number): string {
  const n = parseInt(hex.slice(1), 16);
  return `rgba(${(n >> 16) & 255}, ${(n >> 8) & 255}, ${n & 255}, ${Math.max(0, alpha)})`;
}
