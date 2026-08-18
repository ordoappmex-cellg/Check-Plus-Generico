// Service Worker (17/8) — cachea SOLO el shell estático de la app. Nada de
// Supabase pasa por aquí jamás (ver el primer if de fetch, es la línea más
// importante del archivo). NO modulariza nada de index.html — vive aparte
// porque un service worker TIENE que ser su propio archivo, no porque se
// esté rompiendo la regla de "un solo archivo" del proyecto (ver CLAUDE.md
// sección 1, mismo espíritu que form.html/land.html).

// APP_VERSION llega por querystring en el register() de index.html
// (navigator.serviceWorker.register('/sw.js?v='+APP_VERSION)) en vez de
// duplicar la constante aquí a mano — un solo punto de verdad. OJO: esto
// hace que el NOMBRE del caché seleccionado en cada instalación fresca siga
// a APP_VERSION, pero NO fuerza por sí solo una instalación fresca — el
// navegador decide si hay que reinstalar comparando los BYTES de este
// archivo contra la versión ya instalada, y el querystring no cambia esos
// bytes. Ver el razonamiento completo (por qué esto no es el mecanismo real
// de frescura) en el reporte de esta tarea.
const APP_VERSION = new URL(self.location).searchParams.get('v') || 'dev';
const CACHE_NAME = 'cp-shell-v' + APP_VERSION;

// Shell estático — nada más se cachea, nunca por defecto.
const SHELL_URLS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/assets/icono-192.png',
  '/assets/icono-512.png'
];

async function precacheShell() {
  const cache = await caches.open(CACHE_NAME);
  // cache.addAll() es todo-o-nada: si UNA sola URL falla (404), tumba la
  // instalación completa. Hoy los íconos 192/512 (Punto 2 de PWA) todavía no
  // existen en el repo — con addAll() el service worker jamás llegaría a
  // instalarse mientras eso siga pendiente. Por eso cada URL se cachea con
  // su propio try/catch: lo que exista se precachea, lo que falte se ignora
  // hoy y se precacheará solo en la próxima instalación fresca, sin tocar
  // este archivo de nuevo cuando el Punto 2 se resuelva.
  await Promise.all(SHELL_URLS.map(async (url) => {
    try {
      const res = await fetch(url, { cache: 'no-store' });
      if (res && res.ok) await cache.put(url, res);
    } catch (e) {
      console.warn('[sw] no se pudo precachear (se ignora, no tumba la instalación):', url, e);
    }
  }));
}

self.addEventListener('install', (event) => {
  event.waitUntil(precacheShell());
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((names) => Promise.all(
        names.filter((n) => n !== CACHE_NAME).map((n) => caches.delete(n))
      ))
      .then(() => self.clients.claim())
  );
});

// Network-first con fallback a caché SOLO si no hay red. fetch(request,
// {cache:'no-store'}) es obligatorio aquí, no un fetch() plano: sin
// no-store, este fetch respetaría el Cache-Control que mande Vercel/el
// navegador y podría devolver una copia HTTP-cacheada vieja sin llegar a
// pegarle a la red de verdad — "network-first" a medias, exactamente el
// problema de caché vieja que ya costó tiempo en esta sesión (dos veces).
async function networkFirst(request) {
  try {
    const fresh = await fetch(request, { cache: 'no-store' });
    if (fresh && fresh.ok) {
      const cache = await caches.open(CACHE_NAME);
      cache.put(request, fresh.clone());
    }
    return fresh;
  } catch (e) {
    const cached = await caches.match(request, { ignoreSearch: true });
    if (cached) return cached;
    throw e;
  }
}

self.addEventListener('fetch', (event) => {
  const req = event.request;
  const url = new URL(req.url);

  // ── Supabase: bypass total, SIEMPRE. Verificado dos veces (ver reporte):
  // (1) por hostname exacto (termina en .supabase.co, no un substring
  // frágil de la URL completa), (2) es el PRIMER check de todo el handler,
  // antes de cualquier otra rama — ningún camino posterior a este return
  // puede tocar caches.match/put para una URL de Supabase. Ni siquiera se
  // llama event.respondWith(): el navegador la maneja como si este service
  // worker no existiera para esta petición. ──
  if (url.hostname.endsWith('.supabase.co')) return;

  // Solo GET del propio origen — nunca cross-origin, nunca POST/PUT/DELETE.
  if (req.method !== 'GET' || url.origin !== self.location.origin) return;

  const isShell = req.mode === 'navigate' || SHELL_URLS.includes(url.pathname);
  if (!isShell) return; // todo lo demás pasa normal, sin interceptar ni cachear

  event.respondWith(networkFirst(req));
});
