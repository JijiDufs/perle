import type { SettingSample } from '../core/setting';
import type { Tuning } from '../tuning';

export interface PinchCallbacks {
  onSample(sample: SettingSample): void;
  /** Tous les doigts levés. */
  onRelease(): void;
}

/**
 * Source de geste « pincer deux doigts » (iPhone classique) pour le sertissage.
 * Un seul doigt (ou la souris) : glisser vers le bas fait la même chose, pour l'accessibilité et les tests.
 * Sur Duo, une source « charnière » produira les mêmes SettingSample.
 */
export class PinchInput {
  private pointers = new Map<number, { x: number; y: number }>();
  private mode: 'none' | 'pinch' | 'drag' | 'ended' = 'none';
  private startDistance = 0;
  private startY = 0;

  constructor(
    private readonly element: HTMLElement,
    private readonly getTuning: () => Tuning,
    private readonly callbacks: PinchCallbacks,
  ) {
    element.addEventListener('pointerdown', this.onDown);
    element.addEventListener('pointermove', this.onMove);
    element.addEventListener('pointerup', this.onUp);
    element.addEventListener('pointercancel', this.onUp);
  }

  destroy(): void {
    this.element.removeEventListener('pointerdown', this.onDown);
    this.element.removeEventListener('pointermove', this.onMove);
    this.element.removeEventListener('pointerup', this.onUp);
    this.element.removeEventListener('pointercancel', this.onUp);
  }

  private distance(): number {
    const [a, b] = [...this.pointers.values()];
    return Math.hypot(a.x - b.x, a.y - b.y);
  }

  private onDown = (event: PointerEvent): void => {
    this.pointers.set(event.pointerId, { x: event.clientX, y: event.clientY });
    try {
      this.element.setPointerCapture(event.pointerId);
    } catch {
      // Capture impossible : le geste marche quand même.
    }
    if (this.pointers.size === 1 && this.mode === 'none') {
      this.mode = 'drag';
      this.startY = event.clientY;
    } else if (this.pointers.size === 2 && this.mode !== 'ended') {
      // Le deuxième doigt arrive : on passe au pincement, depuis l'écart actuel.
      this.mode = 'pinch';
      this.startDistance = this.distance();
    }
  };

  private onMove = (event: PointerEvent): void => {
    if (!this.pointers.has(event.pointerId)) return;
    this.pointers.set(event.pointerId, { x: event.clientX, y: event.clientY });
    const span = this.getTuning().settingPinchDistance;
    let closure: number | null = null;
    if (this.mode === 'pinch' && this.pointers.size === 2) closure = (this.startDistance - this.distance()) / span;
    else if (this.mode === 'drag' && this.pointers.size === 1) closure = (event.clientY - this.startY) / span;
    if (closure !== null) this.callbacks.onSample({ closure: Math.max(0, Math.min(1, closure)), time: event.timeStamp });
  };

  private onUp = (event: PointerEvent): void => {
    if (!this.pointers.delete(event.pointerId)) return;
    // Un doigt levé pendant le pincement : on attend que l'autre se lève aussi.
    if (this.mode === 'pinch') this.mode = 'ended';
    if (this.pointers.size === 0) {
      this.mode = 'none';
      this.callbacks.onRelease();
    }
  };
}
