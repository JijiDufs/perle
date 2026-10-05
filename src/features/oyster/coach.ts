// Textes d'accompagnement des premières huîtres (cahier §15). Uniquement de l'affichage :
// le déroulé (perles imposées, protection) est décidé dans src/core/tutorial.ts.
import type { OpeningPhase } from '../../core/opening';

/** Bulle affichée au-dessus de l'huître pendant le geste. `step` = nombre d'huîtres déjà ouvertes. */
export function coachDuringGesture(step: number, phase: OpeningPhase): string | null {
  if (step === 0) {
    if (phase === 'closed') return 'Glisse le pouce vers le haut pour ouvrir ta première huître.';
    if (phase === 'resisting') return 'Elle résiste… continue, elle va céder.';
    if (phase === 'opening') return 'Voilà ! Ouvre-la jusqu’au bout.';
  }
  if (step === 1 && (phase === 'closed' || phase === 'resisting')) {
    return 'Attention : à mi-ouverture, la perle est fragile. Si tu vas trop vite, elle se fêle et perd la moitié de sa valeur.';
  }
  if (step === 1 && phase === 'opening') return 'Doucement…';
  return null;
}

/** Phrase affichée au-dessus de la carte, après la révélation. */
export function coachAfterReveal(step: number, cracked: boolean): string | null {
  if (step === 0) return 'Ta première perle ! Elle rejoint ta collection.';
  if (step === 1) return cracked ? 'Fêlée… La prochaine fois, ralentis à mi-ouverture.' : 'Bien joué : ouverte en douceur, perle intacte.';
  if (step === 2) return 'Parfois, rien. C’est la mer. La prochaine sera peut-être la bonne.';
  if (step === 3) return 'Plus une perle est rare, plus elle se fait attendre. Les plus précieuses tremblent avant même qu’on les touche. Bonne pêche !';
  return null;
}
