// Mesure du comportement des joueurs.
// Pour l'instant : les événements sont gardés localement (consultables dans Réglages) et
// affichés dans la console. L'outil définitif (PostHog, etc.) se branchera ICI uniquement :
// les écrans appellent track() et ne savent pas où partent les données.

export type AnalyticsEvent =
  | 'session_start'
  | 'oyster_shown'
  | 'gesture_start'
  | 'released_before_pop'
  | 'pop'
  | 'crack'
  | 'reveal'
  | 'card_dismissed'
  | 'screen_view'
  | 'card_zoomed'
  | 'collection_sorted'
  | 'collection_filtered'
  | 'tutorial_step'
  | 'tutorial_completed'
  | 'card_shared'
  | 'install_hint_shown'
  | 'install_hint_dismissed'
  | 'stock_empty'
  | 'ecrin_earned'
  | 'ecrin_shown'
  | 'ecrin_perfect'
  | 'ecrin_reveal'
  | 'ecrin_odds_viewed'
  | 'ecrin_variant'
  | 'expertise_started'
  | 'expertise_finished'
  | 'dust_shop_viewed'
  | 'dust_melted'
  | 'dust_piece_bought'
  | 'dust_ecrin_bought'
  | 'achievement_unlocked'
  | 'quests_viewed'
  | 'quest_claimed'
  | 'title_worn'
  | 'level_up'
  | 'chapter_opened'
  | 'chapter_read';

export interface TrackedEvent {
  name: AnalyticsEvent;
  time: number;
  props: Record<string, string | number | boolean>;
}

const MAX_LOCAL_EVENTS = 500;
const KEY = 'perle.analytics.v1';

function readLocal(): TrackedEvent[] {
  try {
    return JSON.parse(localStorage.getItem(KEY) ?? '[]') as TrackedEvent[];
  } catch {
    return [];
  }
}

export function track(name: AnalyticsEvent, props: TrackedEvent['props'] = {}): void {
  const event: TrackedEvent = { name, time: Date.now(), props };
  if (import.meta.env.DEV) console.debug('[analytics]', name, props);
  try {
    const events = readLocal();
    events.push(event);
    localStorage.setItem(KEY, JSON.stringify(events.slice(-MAX_LOCAL_EVENTS)));
  } catch {
    // Stockage indisponible : on perd l'événement, le jeu continue.
  }
}

export function localEvents(): TrackedEvent[] {
  return readLocal();
}
