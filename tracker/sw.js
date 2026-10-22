// Minimal service worker: lets the tracker install to the home screen.
// It does not cache anything, so you always get the latest version.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', e => e.waitUntil(self.clients.claim()));
self.addEventListener('fetch', () => {});
