// Sertissage (cahier §6) : refermer les deux moitiés de l'établi. Sur iPhone classique, en pinçant deux doigts ;
// sur Duo, en refermant le téléphone. Une fermeture ni trop brusque ni trop hésitante donne un sertissage parfait.
// Comme pour l'huître, toute source de geste produit des échantillons, et le moteur juge.
import type { Tuning } from '../tuning';

export interface SettingSample {
  /** Fermeture, de 0 (ouvert) à 1 (refermé). */
  closure: number;
  /** ms */
  time: number;
}

export type SettingVerdict = 'parfait' | 'bien' | 'brusque' | 'hesitant';

export interface SettingResult {
  /** Réussite du geste, 0…1. */
  score: number;
  verdict: SettingVerdict;
  durationMs: number;
}

export class SettingEngine {
  closure = 0;
  private startedAt: number | null = null;
  private last: SettingSample | null = null;
  private speeds: number[] = [];
  result: SettingResult | null = null;

  constructor(private readonly tuning: Tuning) {}

  get done(): boolean {
    return this.result !== null;
  }

  push(sample: SettingSample): SettingResult | null {
    if (this.result) return this.result;
    const closure = Math.max(0, Math.min(1, sample.closure));
    if (this.startedAt === null && closure >= this.tuning.settingStartAt) this.startedAt = sample.time;
    // On ne rouvre pas : la fermeture ne recule pas (le doigt tremble).
    this.closure = Math.max(this.closure, closure);
    // Vitesse mesurée sur une fenêtre de temps, pas d'un échantillon à l'autre : avec deux doigts, chaque doigt
    // envoie ses propres mouvements, et la fermeture avance par à-coups d'un événement à l'autre.
    if (!this.last || this.startedAt === null) this.last = { closure: this.closure, time: sample.time };
    else if (sample.time - this.last.time >= this.tuning.velocityWindowMs) {
      const speed = (this.closure - this.last.closure) / ((sample.time - this.last.time) / 1000);
      if (speed > 0) this.speeds.push(speed);
      this.last = { closure: this.closure, time: sample.time };
    }
    if (this.closure >= this.tuning.settingCompleteAt && this.startedAt !== null) {
      this.result = judgeSetting(sample.time - this.startedAt, this.speeds, this.tuning);
    }
    return this.result;
  }

  /** Doigts levés avant la fin : on recommence sans pénalité. */
  release(): void {
    if (this.result) return;
    this.closure = 0;
    this.startedAt = null;
    this.last = null;
    this.speeds = [];
  }
}

export function judgeSetting(durationMs: number, speeds: readonly number[], tuning: Tuning): SettingResult {
  const { settingIdealMinMs: min, settingIdealMaxMs: max } = tuning;
  // Durée : 1 dans la fenêtre idéale, puis décroît jusqu'à 0 à la moitié du minimum ou au double du maximum.
  let durationScore = 1;
  if (durationMs < min) durationScore = Math.max(0, (durationMs - min / 2) / (min / 2));
  else if (durationMs > max) durationScore = Math.max(0, 1 - (durationMs - max) / max);
  // Régularité : coefficient de variation de la vitesse, comme le lustre.
  let smoothScore = 1;
  if (speeds.length >= 3) {
    const mean = speeds.reduce((a, b) => a + b, 0) / speeds.length;
    const sd = Math.sqrt(speeds.reduce((a, b) => a + (b - mean) ** 2, 0) / speeds.length);
    smoothScore = Math.max(0, 1 - sd / mean / tuning.settingMaxVariation);
  }
  const score = Math.round((0.65 * durationScore + 0.35 * smoothScore) * 100) / 100;
  const verdict: SettingVerdict =
    score >= tuning.settingPerfectScore ? 'parfait' : durationMs < min ? 'brusque' : durationMs > max ? 'hesitant' : 'bien';
  return { score, verdict, durationMs: Math.round(durationMs) };
}
