// Service worker de Pearl Inc. : permet de jouer hors ligne une fois l'app ouverte une première fois.
// - Page (navigation) : réseau d'abord, sinon la version en cache → les mises à jour arrivent dès qu'il y a du réseau.
// - Fichiers de build (/assets/, noms uniques à chaque build) : cache d'abord.
// - Polices Google et autres fichiers : cache, puis rafraîchissement en arrière-plan.
// Changer CACHE_VERSION force le nettoyage des anciens caches.
const CACHE_VERSION = 'perle-v2';
// ignoreVary : certains serveurs répondent « Vary: Origin » ; sans cette option, une requête de script
// (qui porte un en-tête Origin) ne retrouve pas la réponse mise en cache sans cet en-tête.
const MATCH = { ignoreVary: true };
const PRECACHE = ['/', '/manifest.webmanifest', '/icons/icon.svg', '/icons/icon-192.png', '/icons/icon-512.png', '/icons/apple-touch-icon.png'];

self.addEventListener('install', (event) => {
  event.waitUntil(caches.open(CACHE_VERSION).then((cache) => cache.addAll(PRECACHE)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) => Promise.all(keys.filter((key) => key !== CACHE_VERSION).map((key) => caches.delete(key))))
      .then(() => self.clients.claim()),
  );
});

// La page envoie la liste des fichiers déjà chargés avant que le service worker soit actif.
self.addEventListener('message', (event) => {
  if (event.data?.type !== 'cache-urls') return;
  event.waitUntil(
    caches.open(CACHE_VERSION).then((cache) =>
      Promise.all(event.data.urls.map((url) => cache.match(url, MATCH).then((hit) => hit || cache.add(url)).catch(() => undefined))),
    ),
  );
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);

  if (request.mode === 'navigate') {
    event.respondWith(
      fetch(request)
        .then((response) => {
          const copy = response.clone();
          caches.open(CACHE_VERSION).then((cache) => cache.put('/', copy));
          return response;
        })
        .catch(() => caches.match('/', MATCH)),
    );
    return;
  }

  const sameOrigin = url.origin === self.location.origin;
  const isFont = url.hostname === 'fonts.googleapis.com' || url.hostname === 'fonts.gstatic.com';
  if (!sameOrigin && !isFont) return;

  if (sameOrigin && url.pathname.startsWith('/assets/')) {
    event.respondWith(caches.match(request, MATCH).then((hit) => hit || fetchAndCache(request)));
    return;
  }

  event.respondWith(
    caches.match(request, MATCH).then((hit) => {
      const network = fetchAndCache(request).catch(() => hit);
      return hit || network;
    }),
  );
});

function fetchAndCache(request) {
  return fetch(request).then((response) => {
    if (response.ok || response.type === 'opaque') {
      const copy = response.clone();
      caches.open(CACHE_VERSION).then((cache) => cache.put(request, copy));
    }
    return response;
  });
}
