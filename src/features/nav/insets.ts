/**
 * Bande visible d'un écran plein cadre : ce qui n'est caché ni par la barre du haut ni par les onglets du bas
 * (ni par le pied de l'écran, s'il est donné).
 * Les scènes dessinées (huître, écrin) y centrent leur sujet, et peignent leur fond sur tout l'écran.
 */
export function visibleBand(element: HTMLElement, footer?: Element | null): { top: number; bottom: number } {
  const rect = element.getBoundingClientRect();
  const hud = document.querySelector('.hud')?.getBoundingClientRect();
  // En bas : le pied de l'écran (message et jauge) s'il y en a un, sinon les onglets.
  const tabbar = (footer ?? document.querySelector('.tabbar'))?.getBoundingClientRect();
  // La barre du haut se fond dans le décor : on ne compte que ses boutons, pas son dégradé.
  const top = hud ? Math.max(0, hud.top + (hud.height - 14) - rect.top) : 0;
  const bottom = tabbar ? Math.max(0, rect.bottom - tabbar.top) : 0;
  return { top, bottom };
}
