import type { Tuning } from '../tuning';

export type Lustre = 'S' | 'A' | 'B' | 'C';

/**
 * Note la régularité de l'ouverture à partir des vitesses mesurées pendant l'ouverture.
 * On utilise le coefficient de variation (écart-type / moyenne) : plus il est bas, plus le geste est régulier.
 */
export function gradeLustre(velocities: readonly number[], tuning: Tuning): Lustre {
  if (velocities.length < tuning.lustreMinSamples) return 'C';
  const mean = velocities.reduce((s, v) => s + v, 0) / velocities.length;
  if (mean <= 0) return 'C';
  const variance = velocities.reduce((s, v) => s + (v - mean) ** 2, 0) / velocities.length;
  const variation = Math.sqrt(variance) / mean;
  if (variation <= tuning.lustreMaxVariationS) return 'S';
  if (variation <= tuning.lustreMaxVariationA) return 'A';
  if (variation <= tuning.lustreMaxVariationB) return 'B';
  return 'C';
}
