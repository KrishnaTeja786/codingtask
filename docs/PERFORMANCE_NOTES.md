# Performance Notes

This document captures the performance choices made in Smart DevHub and the reasoning behind each.

## Measurement first

Before adding any optimization, the app measures. The Performance Lab tab is the visible surface of an internal `PerformanceMetrics` sink:

- **API timing** comes from a `Dio` interceptor that stamps `microsecondsSinceEpoch` on `onRequest` and emits the delta on `onResponse`/`onError`. Cost: one map lookup per request, no per-frame allocation.
- **DB timing** comes from a `DbReadTimer` extension method: `await metrics.timeDbRead('label', () => dao.foo())`. Stopwatch is started/stopped inside a `try/finally` so failed reads still report.
- **Cache hit/miss** is a counter incremented in repositories around `cache.get()`.
- **Background status** is a string updated by the `SyncJob` closure.

Snapshots are computed lazily; the metrics stream is broadcast so every Performance Lab open simply attaches a new listener — no replay, no buffering past `historyLimit = 50` samples.

## Rendering

- **`IndexedStack` over `PageView`/conditional widgets**. Tab switches are O(1) and BLoCs/scroll positions remain alive. Counter-argument: it costs memory, since all four tabs build at once. For four tabs of this complexity the trade-off is correct.
- **`ListView.builder` everywhere**. The large-list demo also sets `cacheExtent: 600` so fast flings don't reveal blank slots.
- **`cached_network_image`** with `memCacheWidth/Height` capped — keeps the GPU raster cache small. Without those caps the cache holds full-resolution decoded bitmaps.
- **`const` constructors**. Every leaf widget is `const` where its inputs allow it; this is what lets Flutter skip rebuild work even when an ancestor rebuilds.
- **Fine-grained `BlocSelector` / `buildWhen`**. The trends list uses three separate selectors — one for the search query, one for the offline banner tuple `(fromCache, fetchedAt)`, one for the body. Each selector returns the smallest comparable type so equality checks are cheap.

## Reducing rebuilds

Patterns used:

- **`buildWhen`** in every `BlocBuilder` that consumes a complex state — only rebuilds on the relevant slice.
- **`ValueKey` per item** in lists keyed by stable IDs (repo id, article id). Without keys, Flutter's element re-association can pair the wrong widget to the wrong state when items are added/removed.
- **Memoized derived state** in `FavoritesState`: `sortedRepos` and `sortedArticles` are computed once per state via `late final` fields.

## Heavy work off the UI isolate

- **`compute()` for JSON parse**. The GitHub search response (~80 KB for 30 repos) is parsed in a worker isolate. The cost is one isolate boot and a binary message copy; the win is a guaranteed-no-jank parse.
- **HN feed cache decode** also goes through `compute()` so re-opening the feed tab from a cold launch doesn't drop a frame.
- A future "trending diff" computation that compares yesterday's snapshot to today would be the next candidate.

## Network

- **GET-only retry** with exponential backoff (200 ms, 600 ms). Retrying POSTs is a footgun — many APIs treat them as non-idempotent.
- **Connect/receive timeouts** of 10 s / 15 s. Long enough for slow networks, short enough that an "Open" tap doesn't hang the user for a minute.
- **`LogInterceptor` only in debug**. Production builds skip the formatter entirely.
- **Concurrency cap of 8** for HN item batch fetches — picked empirically; HN has no documented rate limit but socket exhaustion on poor networks is real.

## Caching

- **Per-key TTL** stored in Drift, not in memory. Cache survives process restart.
- **Stale-cache fallback on failure**. A network error never wipes the cache — the user always gets *something* if there was *anything* before.
- **Force-refresh path** (`forceRefresh: true`) used by pull-to-refresh and the background sync job. Skips the freshness check but still writes the new payload back.

## Database

- **Drift with `LazyDatabase`** so the path provider lookup happens in the background isolate that opens the database. Cold-start `main()` doesn't await `getApplicationDocumentsDirectory()`.
- **Watched queries** for favorites — Drift recomputes only when the relevant tables change. The bloc pipeline is push-based all the way to the UI.
- **`PRAGMA foreign_keys = ON`** in `beforeOpen` for correctness.

## Background

- **`workmanager` periodic** with `Constraints(networkType: connected, requiresBatteryNotLow: true)`. The OS won't even invoke the callback if those don't hold.
- **`ExistingWorkPolicy.keep`** so registering twice never schedules duplicate jobs.
- **iOS limitations**: Apple's `BGTaskScheduler` is opportunistic. There is no guarantee the periodic job will fire while the app is killed. The honest fix is to (a) keep the manual "Sync now" button as the dependable refresh path and (b) document this clearly. Pretending a background job is reliable on iOS is a common interview red flag.
- **Top-level `callbackDispatcher`** is intentionally minimal: WorkManager spawns a fresh isolate without the host app's DI, so we cannot reuse the in-memory caches there. A production heavy version would re-init DI inside the isolate, run the use cases, and post a local notification — explicitly noted in the source as an extension point.

## What we didn't do (and why)

- **No `freezed` for entities**. They're small enough that hand-written `Equatable` is clearer and removes a build_runner dependency for the hot path.
- **No `riverpod`/`provider` mixed in**. One state-management story (BLoC) is easier to interview for and easier to onboard onto.
- **No GraphQL gateway**. Real APIs are REST; we exercise the same skill faster by going direct.
