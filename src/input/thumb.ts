import type { OpeningSample } from '../core/opening';
import type { Tuning } from '../tuning';

/**
 * Convertit la distance parcourue par le pouce (pt, vers le haut) en angle d'ouverture.
 * Pendant la résistance, la coquille bouge à peine ; une fois la distance de résistance
 * franchie, l'angle saute à l'angle du pop : c'est le « pop » ressenti.
 */
export function thumbDistanceToAngle(distance: number, tuning: Tuning): number {
  if (distance <= 0) return 0;
  if (distance < tuning.resistanceDistance) {
    return tuning.popAngle * tuning.resistanceAngleRatio * (distance / tuning.resistanceDistance);
  }
  const beyond = distance - tuning.resistanceDistance;
  return Math.min(180, tuning.popAngle + (beyond * (180 - tuning.popAngle)) / tuning.fullOpenDistance);
}

export interface ThumbCallbacks {
  onSample(sample: OpeningSample, distance: number): void;
  onRelease(): void;
}

/**
 * Source de geste « pouce vers le haut » (iPhone classique).
 * La distance s'accumule d'un appui à l'autre : on peut reprendre une ouverture entamée.
 */
export class ThumbInput {
  private distance = 0;
  private floor = 0;
  private pointerId: number | null = null;
  private startY = 0;
  private startDistance = 0;

  constructor(
    private readonly element: HTMLElement,
    private readonly getTuning: () => Tuning,
    private readonly callbacks: ThumbCallbacks,
  ) {
    element.addEventListener('pointerdown', this.onDown);
    element.addEventListener('pointermove', this.onMove);
    element.addEventListener('pointerup', this.onUp);
    element.addEventListener('pointercancel', this.onUp);
  }

  /** Après le pop, le pouce ne peut plus refermer la coquille sous l'angle du pop. */
  lockAfterPop(): void {
    this.floor = this.getTuning().resistanceDistance;
    this.distance = Math.max(this.distance, this.floor);
  }

  /** Nouvelle huître, ou coquille refermée pendant la résistance. */
  reset(): void {
    this.distance = 0;
    this.floor = 0;
  }

  destroy(): void {
    this.element.removeEventListener('pointerdown', this.onDown);
    this.element.removeEventListener('pointermove', this.onMove);
    this.element.removeEventListener('pointerup', this.onUp);
    this.element.removeEventListener('pointercancel', this.onUp);
  }

  private onDown = (event: PointerEvent): void => {
    if (this.pointerId !== null) return;
    this.pointerId = event.pointerId;
    this.startY = event.clientY;
    this.startDistance = this.distance;
    this.element.setPointerCapture(event.pointerId);
  };

  private onMove = (event: PointerEvent): void => {
    if (event.pointerId !== this.pointerId) return;
    this.distance = Math.max(this.floor, this.startDistance + (this.startY - event.clientY));
    const angle = thumbDistanceToAngle(this.distance, this.getTuning());
    this.callbacks.onSample({ angle, time: event.timeStamp }, this.distance);
  };

  private onUp = (event: PointerEvent): void => {
    if (event.pointerId !== this.pointerId) return;
    this.pointerId = null;
    this.callbacks.onRelease();
  };
}
