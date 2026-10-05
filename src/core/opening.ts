import type { Tuning } from '../tuning';
import { gradeLustre, type Lustre } from './lustre';

/** Une mesure du geste, quelle que soit sa source (pouce, charnière…). */
export interface OpeningSample {
  /** Angle d'ouverture en degrés, 0 (fermée) à 180. */
  angle: number;
  /** Instant de la mesure en millisecondes. */
  time: number;
}

export type OpeningPhase = 'closed' | 'resisting' | 'opening' | 'revealed';

export type OpeningEvent =
  | { type: 'pop' }
  | { type: 'crack' }
  | { type: 'reveal'; lustre: Lustre; cracked: boolean };

/**
 * Moteur d'ouverture d'une huître : reçoit des mesures d'angle, calcule la vitesse,
 * et décide du pop, de la fêlure et de la révélation.
 * closed → resisting → opening → revealed
 */
export class OpeningEngine {
  phase: OpeningPhase = 'closed';
  angle = 0;
  /** Vitesse lissée en °/s (positive = ouverture). */
  velocity = 0;
  cracked = false;
  lustre: Lustre | null = null;

  private window: OpeningSample[] = [];
  private openingVelocities: number[] = [];

  constructor(
    private readonly tuning: Tuning,
    /** Désactive la fêlure (première huître du tutoriel). */
    private readonly crackProtected = false,
  ) {}

  get inFragileZone(): boolean {
    return this.angle >= this.tuning.fragileMinAngle && this.angle <= this.tuning.fragileMaxAngle;
  }

  push(sample: OpeningSample): OpeningEvent[] {
    if (this.phase === 'revealed') return [];
    const events: OpeningEvent[] = [];
    const t = this.tuning;

    // Une fois ouverte, la coquille ne redescend pas sous l'angle du pop.
    const angle = this.phase === 'opening' ? Math.max(sample.angle, t.popAngle) : sample.angle;
    this.angle = Math.min(Math.max(angle, 0), 180);
    this.updateVelocity({ angle: this.angle, time: sample.time });

    if (this.phase === 'closed' && this.angle > 0) this.phase = 'resisting';

    if (this.phase === 'resisting' && this.angle >= t.popAngle) {
      this.phase = 'opening';
      events.push({ type: 'pop' });
      // La vitesse de la résistance ne compte pas pour le lustre.
      this.window = [{ angle: this.angle, time: sample.time }];
      this.velocity = 0;
      return events;
    }

    if (this.phase === 'opening') {
      // Le lustre juge la régularité dans la zone fragile, là où elle compte
      // (l'ouverture automatique de la fin ne doit pas la fausser).
      if (this.window.length >= 2 && this.inFragileZone) this.openingVelocities.push(this.velocity);

      if (!this.crackProtected && !this.cracked && this.inFragileZone && this.velocity > t.maxSafeVelocity) {
        this.cracked = true;
        events.push({ type: 'crack' });
      }

      if (this.angle >= t.revealAngle) {
        this.phase = 'revealed';
        this.lustre = gradeLustre(this.openingVelocities, t);
        events.push({ type: 'reveal', lustre: this.lustre, cracked: this.cracked });
      }
    }
    return events;
  }

  /** Le doigt quitte l'écran. Pendant la résistance, la coquille se referme. */
  release(): void {
    if (this.phase === 'resisting') {
      this.phase = 'closed';
      this.angle = 0;
    }
    this.velocity = 0;
    this.window = [];
  }

  private updateVelocity(sample: OpeningSample): void {
    this.window.push(sample);
    const cutoff = sample.time - this.tuning.velocityWindowMs;
    while (this.window.length > 2 && this.window[0].time < cutoff) this.window.shift();
    const first = this.window[0];
    const dt = (sample.time - first.time) / 1000;
    this.velocity = dt > 0 ? (sample.angle - first.angle) / dt : 0;
  }
}
