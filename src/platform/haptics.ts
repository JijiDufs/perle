// Retour haptique dans le navigateur.
// - Android : navigator.vibrate.
// - iOS (Safari 18+) : astuce non officielle. Basculer un <input type="checkbox" switch>
//   déclenche un petit « tic » Taptic. Ne marche de façon fiable que pendant un geste de l'utilisateur.
// Dans l'app native, ce fichier sera remplacé par Core Haptics (voir AGENTS.md §7).

let iosTrigger: HTMLLabelElement | null = null;

function ensureIosTrigger(): HTMLLabelElement {
  if (iosTrigger) return iosTrigger;
  const box = document.createElement('div');
  box.setAttribute('aria-hidden', 'true');
  box.style.cssText = 'position:fixed;left:-9999px;top:0;opacity:0;pointer-events:none;';
  const input = document.createElement('input');
  input.type = 'checkbox';
  input.setAttribute('switch', '');
  input.id = 'perle-haptic-switch';
  input.tabIndex = -1;
  const label = document.createElement('label');
  label.htmlFor = input.id;
  box.append(input, label);
  document.body.append(box);
  iosTrigger = label;
  return label;
}

/** Un tic haptique court. */
export function hapticTick(): void {
  try {
    if (typeof navigator.vibrate === 'function') {
      navigator.vibrate(8);
      return;
    }
    ensureIosTrigger().click();
  } catch {
    // Pas d'haptique disponible : le jeu reste jouable.
  }
}

/** Plusieurs tics espacés (au-delà du premier, peut être ignoré par iOS hors geste). */
export function hapticBurst(count: number, gapMs: number): void {
  for (let i = 0; i < count; i++) setTimeout(hapticTick, i * gapMs);
}
