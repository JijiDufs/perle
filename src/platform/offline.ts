// Mode hors ligne (service worker) et détection de l'installation sur l'écran d'accueil.

/** Enregistre le service worker (build de production seulement : il gênerait le rechargement à chaud en dev). */
export function registerOffline(): void {
  if (!import.meta.env.PROD || !('serviceWorker' in navigator)) return;
  window.addEventListener('load', async () => {
    try {
      await navigator.serviceWorker.register('/sw.js');
      const registration = await navigator.serviceWorker.ready;
      // Les fichiers chargés avant l'activation du service worker n'ont pas été mis en cache : on les lui envoie.
      const urls = [location.origin + '/', ...performance.getEntriesByType('resource').map((entry) => entry.name)];
      registration.active?.postMessage({ type: 'cache-urls', urls });
    } catch {
      // Sans service worker, le jeu marche quand même, simplement pas hors ligne.
    }
  });
}

/** Vrai si l'app est lancée depuis l'écran d'accueil. */
export function isStandalone(): boolean {
  return matchMedia('(display-mode: standalone)').matches || (navigator as Navigator & { standalone?: boolean }).standalone === true;
}

/** Vrai sur iPhone / iPad, où l'installation passe par Partager → « Sur l'écran d'accueil ». */
export function isIos(): boolean {
  return /iPhone|iPad|iPod/.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
}
