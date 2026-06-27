/* Aziza Food storefront service worker.
 * Goal: instant repeat loads + offline shell + installable PWA.
 * Strategy: stale-while-revalidate for the app shell (serve from cache
 * immediately, refresh in the background so the next load is up to date —
 * no manual version bumps needed). API + images are left to the network.
 */
const CACHE = 'aziza-client-shell-v1';
const SHELL = ['./', './index.html', './app.js', './styles.css', './manifest.webmanifest'];

self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open(CACHE).then((c) => c.addAll(SHELL)).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  // Only handle this app's own shell. API calls (fresh data) and product
  // images are left to the network / HTTP cache. (The SW scope is /client/,
  // so /api and /static are already out of scope — these are belt-and-braces.)
  if (url.origin !== self.location.origin) return;
  if (url.pathname.startsWith('/api/') || url.pathname.startsWith('/static/')) return;

  e.respondWith(
    caches.open(CACHE).then((cache) =>
      cache.match(req).then((cached) => {
        const network = fetch(req)
          .then((res) => {
            if (res && res.ok) cache.put(req, res.clone());
            return res;
          })
          .catch(() => cached);
        return cached || network;
      })
    )
  );
});
