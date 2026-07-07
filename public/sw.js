const CACHE_NAME = 'trailhead-cache-v1';
const ASSETS_TO_CACHE = [
  '/',
  '/manifest.json',
  '/icon-192.png',
  '/icon-512.png',
];

// Install Event - Pre-cache core assets
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(ASSETS_TO_CACHE);
    }).then(() => {
      return self.skipWaiting();
    })
  );
});

// Activate Event - Clean up stale caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((name) => {
          if (name !== CACHE_NAME) {
            return caches.delete(name);
          }
        })
      );
    }).then(() => {
      return self.clients.claim();
    })
  );
});

// Fetch Event - Network-First for documents, Cache-First for static assets
self.addEventListener('fetch', (event) => {
  const request = event.request;

  // Skip non-GET requests and API calls
  if (request.method !== 'GET' || request.url.includes('/api/')) {
    return;
  }

  // Document pages: Network-first to ensure fresh user sessions
  if (request.mode === 'navigate') {
    event.respondWith(
      fetch(request)
        .then((response) => {
          // Cache a copy of the fresh page shell
          const copy = response.clone();
          caches.open(CACHE_NAME).then((cache) => {
            cache.put(request, copy);
          });
          return response;
        })
        .catch(() => {
          // Fall back to offline cached app shell page
          return caches.match(request).then((cachedResponse) => {
            if (cachedResponse) return cachedResponse;
            return caches.match('/');
          });
        })
    );
    return;
  }

  // Static Assets (JS, CSS, Images, Fonts): Cache-First
  event.respondWith(
    caches.match(request).then((cachedResponse) => {
      if (cachedResponse) {
        // Return cached asset immediately, but optionally refresh cache in background
        fetch(request).then((freshResponse) => {
          if (freshResponse.status === 200) {
            caches.open(CACHE_NAME).then((cache) => cache.put(request, freshResponse));
          }
        }).catch(() => {/* Ignore background refresh failures offline */});
        
        return cachedResponse;
      }

      return fetch(request).then((response) => {
        if (response.status === 200) {
          const copy = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(request, copy));
        }
        return response;
      });
    })
  );
});
