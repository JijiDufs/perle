// Petits utilitaires de couleur et d'interpolation pour le dessin.

export function hexRgb(hex: string): [number, number, number] {
  const h = hex.replace('#', '');
  return [parseInt(h.slice(0, 2), 16), parseInt(h.slice(2, 4), 16), parseInt(h.slice(4, 6), 16)];
}

export function rgba(hex: string, alpha: number): string {
  const [r, g, b] = hexRgb(hex);
  return `rgba(${r},${g},${b},${alpha})`;
}

/** Assombrit une couleur (k = 0 : identique, 1 : noir). */
export function shade(hex: string, k: number): string {
  return `rgb(${hexRgb(hex).map((v) => Math.round(v * (1 - k))).join(',')})`;
}

export const clamp = (v: number, min: number, max: number) => Math.min(max, Math.max(min, v));

/** Transition douce de 0 à 1 entre a et b. */
export function smoothstep(a: number, b: number, x: number): number {
  const t = clamp((x - a) / (b - a), 0, 1);
  return t * t * (3 - 2 * t);
}
