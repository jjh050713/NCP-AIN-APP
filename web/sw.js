// Kill switch: any previously-installed service worker (from older app
// versions) that intercepted requests with a cache-first strategy could
// keep serving stale HTML/JS forever, even after the server is fixed,
// because the browser never gets a chance to fetch the new files.
//
// This version replaces that old worker: it takes over immediately,
// wipes every cache, unregisters itself, and forces open tabs to reload
// so all future requests go straight to the network.
self.addEventListener('install', () => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const keys = await caches.keys();
      await Promise.all(keys.map((key) => caches.delete(key)));
      await self.registration.unregister();
      const clientsList = await self.clients.matchAll({ type: 'window' });
      clientsList.forEach((client) => client.navigate(client.url));
    })()
  );
});
