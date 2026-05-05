# Interview Talk Track

## 2-minute version

> Smart DevHub is a Flutter app I built to demonstrate how I structure a senior-level mobile project end-to-end. It's a Developer Intelligence Dashboard with four tabs: GitHub trending repositories, a Hacker News tech feed, an offline favorites/bookmarks tab backed by a local Drift database, and a Performance Lab that surfaces live metrics from inside the app.
>
> Architecturally it's Clean Architecture with strict layering — presentation depends on domain, data depends on domain, and the domain layer is pure Dart with no Flutter import. Errors flow as a sealed `Failure` hierarchy wrapped in a `Result<T>` so the compiler enforces exhaustive handling at every call site.
>
> State management is `flutter_bloc`. I use `bloc_concurrency` transformers — `restartable` for search and refresh, `droppable` for pagination — and I have one app-scoped `FavoritesBloc` that watches Drift streams so toggling a star anywhere updates everywhere.
>
> The repositories are offline-first: cache → network → stale-cache fallback, with a per-key TTL stored in SQLite. There's a real `workmanager` periodic job on Android, abstracted behind an interface so the same code path is testable in-process.
>
> I instrumented the app with a `PerformanceMetrics` sink fed by a Dio interceptor and a `timeDbRead` extension. The Performance Lab tab visualizes API latency, DB read latency, cache hit rate, and last sync time — so when I claim "this is fast" in an interview, I can show you the number.
>
> There are unit tests for use cases and the Result type, repository tests with in-memory Drift, four BLoC test suites, a DAO test, and a widget test. CI runs format, analyze, build_runner, tests with coverage, and a debug APK build.
>
> I documented the AI workflow I used to scaffold this — every AI suggestion was treated like a PR from a new contributor: read it, run analyze, run tests, mutate the production code, verify the tests still catch the regression.

## 5-minute version

(Use the 2-minute version, then expand on these four threads in any order the interviewer probes.)

### Architecture

> The dependency rule is enforced by directory layout. The domain layer holds entities, repository *interfaces*, and use cases — it has zero imports of Flutter, Drift, or Dio. The data layer holds DTOs, datasources, and repository *implementations*. The presentation layer holds BLoCs and widgets that depend only on domain.
>
> I use a sealed `Failure` class with seven variants (Network, Timeout, Server, Parse, Cache, NotFound, Unknown) and a sealed `Result<T>` (Ok / Err). Every infrastructure exception is funneled through `mapDioError()` once, so the rest of the codebase pattern-matches on typed failures. There are no try/catches in BLoCs.

### State management discipline

> Each tab has its own bloc except favorites, which is app-scoped because it watches the database and is consumed from multiple tabs. I use `BlocSelector` and `buildWhen` everywhere — the trends list, for example, has three separate selectors so the search bar doesn't rebuild when the items change.
>
> The bottom navigation uses `IndexedStack` so all four tabs stay alive — you don't lose scroll position or BLoC state when you switch. That costs a bit of memory, but it's the right trade for four tabs of this complexity.

### Performance

> The Dio interceptor stamps a microsecond timestamp on `onRequest` and emits a delta on `onResponse` — single map lookup, no per-frame allocation. The `timeDbRead` extension uses a Stopwatch in a try/finally so even failed reads are recorded. Both feed a broadcast stream that the Performance Lab tab listens to.
>
> Heavy JSON parsing — the GitHub search response, the cached HN feed — runs in `compute()` so the UI isolate never skips a frame on cold-cache reads. The large-list demo uses `ListView.builder` with `cacheExtent: 600` and `cached_network_image` with capped `memCacheWidth/Height` so the GPU raster cache stays small.

### Background sync — and the iOS conversation

> Android uses real `workmanager` with `Constraints` requiring network and non-low battery, registered with `ExistingWorkPolicy.keep` so registration is idempotent. The job updates `SyncMetadata` rows and emits a status to the metrics sink.
>
> iOS is honest in the docs: `BGTaskScheduler` is opportunistic, not guaranteed. I keep a manual "Sync now" button as the dependable refresh path and document the limitation in `PERFORMANCE_NOTES.md`. Pretending background tasks are reliable on iOS is a common interview red flag — I'd rather state the constraint and design around it.
