import type { Tuning } from '../tuning';
import { OpeningEngine, type OpeningPhase, type OpeningSample } from './opening';
import type { Rng } from './rng';

export type GlintEvent = { type: 'pop' } | { type: 'perfect' } | { type: 'reveal'; perfect: boolean };

/** Tire l'angle d'éclat caché d'un écrin. */
export function rollSweetAngle(rng: Rng, tuning: Tuning): number {
  return Math.round(tuning.glintMinAngle + rng() * (tuning.glintMaxAngle - tuning.glintMinAngle));
}

/**
 * Moteur d'ouverture d'un écrin (cahier §7) : même ouverture que l'huître (résistance, pop, révélation),
 * sans fêlure, plus l'angle d'éclat. Tenir le geste immobile sur cet angle assez longtemps donne un éclat parfait.
 * Le pouce immobile n'envoie plus de mesures : tick() doit être appelé à chaque image pour faire avancer le temps.
 */
export class GlintEngine {
  /** Proximité de l'angle d'éclat, 0 (loin) à 1 (dessus) : pilote le scintillement. */
  closeness = 0;
  /** Temps (ms) déjà tenu sur l'angle d'éclat. */
  holdMs = 0;
  perfect = false;

  private readonly opening: OpeningEngine;
  private lastSampleTime = -Infinity;
  private lastTickTime: number | null = null;

  constructor(
    private readonly tuning: Tuning,
    readonly sweetAngle: number,
  ) {
    this.opening = new OpeningEngine(tuning, true);
  }

  get phase(): OpeningPhase {
    return this.opening.phase;
  }

  get angle(): number {
    return this.opening.angle;
  }

  /** Vitesse en °/s, ramenée à 0 si aucune mesure récente (pouce immobile). */
  velocityAt(time: number): number {
    return time - this.lastSampleTime > this.tuning.velocityWindowMs ? 0 : this.opening.velocity;
  }

  /** Progression de l'éclat parfait, 0 à 1. */
  get holdProgress(): number {
    return this.perfect ? 1 : Math.min(1, this.holdMs / this.tuning.glintHoldMs);
  }

  push(sample: OpeningSample): GlintEvent[] {
    this.lastSampleTime = sample.time;
    const events: GlintEvent[] = [];
    for (const event of this.opening.push(sample)) {
      if (event.type === 'pop') events.push({ type: 'pop' });
      if (event.type === 'reveal') events.push({ type: 'reveal', perfect: this.perfect });
    }
    events.push(...this.tick(sample.time));
    return events;
  }

  /** Fait avancer le temps (à appeler à chaque image, même sans mouvement). */
  tick(time: number): GlintEvent[] {
    const dt = this.lastTickTime === null ? 0 : Math.max(0, time - this.lastTickTime);
    this.lastTickTime = time;
    const t = this.tuning;
    const opening = this.phase === 'opening';
    const gap = Math.abs(this.angle - this.sweetAngle);
    this.closeness = opening ? Math.max(0, 1 - gap / t.glintSparkleRange) : 0;
    if (this.perfect || !opening) return [];

    const still = Math.abs(this.velocityAt(time)) < t.glintMaxVelocity;
    if (gap < t.glintTolerance && still) this.holdMs += dt;
    else this.holdMs = Math.max(0, this.holdMs - dt * 2);

    if (this.holdMs >= t.glintHoldMs) {
      this.perfect = true;
      return [{ type: 'perfect' }];
    }
    return [];
  }

  release(): void {
    this.opening.release();
  }
}
