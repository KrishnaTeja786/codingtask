# Smart DevHub

> A senior-level Flutter portfolio app: **Developer Intelligence Dashboard** — fetches GitHub trending repos and Hacker News stories, supports offline-first browsing, runs background refresh, and ships an in-app Performance Lab that surfaces real timings.

This project is intentionally over-engineered for its size. The point isn't the feature set — the point is to demonstrate how a senior Flutter engineer **structures**, **tests**, and **measures** a real app.

---

## Why this project stands out

- **Clean Architecture** with a strict dependency rule (presentation → domain ← data). Domain is pure Dart; you can run the use cases in a server.
- **Typed errors**: a sealed `Failure` hierarchy + a `Result<T>` (sealed `Ok` / `Err`). No exceptions cross the domain boundary.
- **Offline-first repositories**: cache → network → stale-cache fallback, with a per-key TTL stored in Drift.
- **Reactive favorites**: a single app-scoped `FavoritesBloc` watches Drift streams, so toggling a star anywhere updates everywhere.
- **Background sync** via `workmanager` (real plugin on Android), with a documented in-process abstraction for tests and iOS limits.
- **Performance Lab** tab shows live API latency, DB read latency, cache hit rate, and last sync time — driven by a `PerformanceMetrics` sink fed by a Dio interceptor and a `timeDbRead` extension.
- **Modern Dart**: sealed classes, pattern matching `switch` expressions, records, `interface class`, `final class`, `extension methods`, immutable state.
- **Tests** for use cases, repo (mocked + in-memory Drift), 4 BLoCs, DAO, and widgets.
- **CI** that formats, analyzes, runs build_runner, runs tests with coverage, and builds a debug APK.

---

## Architecture

```
lib/
├── core/
│   ├── constants/        # App + cache constants
│   ├── errors/           # sealed Failure, Result<T>
│   ├── network/          # DioClient, retry, timing, NetworkInfo, error mapper
│   ├── database/         # Drift AppDatabase + DAOs (favorites, cache, sync)
│   ├── di/               # get_it composition root
│   ├── theme/            # Material 3 light + dark
│   ├── utils/            # Debouncer, date formatters
│   ├── performance/      # PerformanceMetrics sink + DbReadTimer extension
│   └── background/       # BackgroundSyncService (workmanager + in-process)
├── features/
│   ├── github_trends/    # entity, DTO, datasource, repo, use case, bloc, pages
│   ├── tech_feed/        # Hacker News slice
│   ├── favorites/        # Drift-backed offline favorites & bookmarks
│   └── performance_lab/  # cubit + metrics panel + large list demo
├── app/
│   ├── app.dart          # Root MaterialApp + app-scoped providers
│   ├── router.dart       # go_router
│   ├── bottom_nav.dart   # Shell with IndexedStack (keeps tab state)
│   └── offline_banner.dart
└── main.dart             # DI bootstrap + non-blocking background register
```

**Dependency rule** (enforced by directory layout, not lint):

```
presentation ──▶ domain ◀── data
                  │
       use cases, entities,
       repository interfaces
       (pure Dart, no Flutter)
```

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the full breakdown.

---

## Features

### Tab 1 — GitHub Trends
- Search GitHub repositories by query (default `flutter language:dart`)
- Topic chips (Flutter / Dart / Android / AI / Mobile)
- Pull-to-refresh + infinite scroll pagination
- Repo detail screen with external launcher
- Star to save offline (Drift)

### Tab 2 — Tech Feed (Hacker News)
- Top stories from the public HN Firebase API (no auth)
- Topic filter chips
- Article detail with link + HN discussion launcher
- Bookmark to save offline

### Tab 3 — Offline Favorites
- Two tabs: starred repos & bookmarked articles
- Sort by date saved / stars / title
- Works fully offline (DB-only)

### Tab 4 — Performance Lab
- Live metrics: avg API ms, avg DB read ms, cache hit rate, background status, last sync time
- Recent API call list with latency
- 1,000-item cached-image list demo
- Manual "Sync now" trigger

---

## API integration

| API | Auth? | Use |
|---|---|---|
| `https://api.github.com/search/repositories` | none | trending repos |
| `https://hacker-news.firebaseio.com/v0/topstories.json` | none | top stories |
| `https://hacker-news.firebaseio.com/v0/item/{id}.json` | none | story details |

Networking goes through `core/network/dio_client.dart`:
- 10s connect / 15s receive timeouts
- `dio_smart_retry` with exponential backoff, **GET-only** retry on 408/429/5xx
- `LogInterceptor` enabled only in `kDebugMode`
- Per-request timing emitted to `PerformanceMetrics`
- All exceptions go through `mapDioError()` → typed `Failure`

---

## Local database

`drift` 2.x with `sqlite3_flutter_libs`. Tables:

- `FavoriteRepos` — denormalized repo snapshot
- `BookmarkedArticles` — denormalized article snapshot
- `HttpCacheEntries` — generic key/value response cache w/ `expiresAt`
- `SyncMetadata` — per-job last status / success time / run count

Migration strategy (`MigrationStrategy`) in `app_database.dart` includes a commented example showing the production pattern — bump `schemaVersion`, add `m.addColumn(...)` in `onUpgrade`. `PRAGMA foreign_keys = ON` is enabled in `beforeOpen`.

---

## Background processing

- **Android**: real `workmanager` periodic task, registered in `main.dart`. Permissions added to manifest. `Constraints` require network + non-low battery. `ExistingWorkPolicy.keep` makes registration idempotent.
- **iOS**: documented in [`docs/PERFORMANCE_NOTES.md`](docs/PERFORMANCE_NOTES.md). Apple's `BGTaskScheduler` is not guaranteed to fire; we surface a manual "Sync now" button as the dependable fallback.
- **Tests**: an `InProcessBackgroundSyncService` implements the same interface using a `Timer.periodic`, no plugin channel.

The shared `SyncJob` closure refreshes both repositories with `forceRefresh: true`, updates `SyncMetadata`, and emits a `backgroundStatus` to the metrics sink. Errors are caught and recorded — the background isolate must never crash the host app.

---

## Performance optimization

A non-exhaustive list (see [`docs/PERFORMANCE_NOTES.md`](docs/PERFORMANCE_NOTES.md) for rationale):

- `compute()` (worker isolate) for GitHub search JSON parse and HN feed cache decode
- `IndexedStack` keeps tab BLoCs and scroll positions alive
- `BlocSelector` + `buildWhen` everywhere — only the smallest subtree rebuilds
- `const` constructors throughout, including in lists
- `cached_network_image` with `memCacheWidth/Height` to keep raster cache small
- `ListView.builder` with explicit `cacheExtent: 600` on the large-list demo
- Debounced search input (350ms) via `Debouncer`
- Repo-level cache TTL avoids redundant network calls
- `bloc_concurrency` — `restartable` for query, `droppable` for paginate
- Stopwatch-instrumented DB reads via `DbReadTimer` extension
- Dio interceptor records per-request latency without allocating per call

---

## Testing strategy

```
flutter test
```

Covers:

- **Pure**: `Result.fold/map`, `mapDioError` for all Dio types, `RepoDto.fromJson` happy + sparse
- **Use case**: `SearchRepositoriesUseCase` w/ mocked repo
- **Repository**: `GithubRepositoryImpl` w/ in-memory Drift + mocked datasource (offline-no-cache → failure, fresh-cache → no network call)
- **DAO**: `FavoritesDao` upsert/isFavorite/remove for repos AND articles
- **BLoC**: GitHub Trends (loading→success / failure / pagination / empty), Tech Feed (success / cache / failure), Favorites (watcher emit / sort / remove)
- **Cubit**: Performance Metrics (api emit / sync metadata change)
- **Widget**: empty / error retry / offline banner

Stack: `flutter_test`, `bloc_test`, `mocktail`, `drift/native` for in-memory SQLite.

---

## How to run

Prerequisites: Flutter 3.22+ (Dart 3.3+), Android Studio / Xcode for device targets.

```bash
# 1. Install dependencies
flutter pub get

# 2. Generate Drift (and any future freezed/json) code
dart run build_runner build --delete-conflicting-outputs

# 3. Run on a device / simulator
flutter run
```

For the iOS simulator, no extra setup is needed for HTTP since both APIs use HTTPS.

## How to test

```bash
flutter test                       # all unit, bloc, DAO, widget tests
flutter test --coverage            # produces coverage/lcov.info
flutter analyze --no-fatal-infos   # static analysis (very_good_analysis)
dart format --set-exit-if-changed lib test
```

## CI

`.github/workflows/flutter_ci.yml` runs on push/PR:
1. `flutter pub get`
2. `dart run build_runner build`
3. `dart format` (fail on diff)
4. `flutter analyze`
5. `flutter test --coverage`
6. (separate job) `flutter build apk --debug`

---

## Screenshots

> _Place screenshots in `docs/screenshots/` and reference them here:_
>
> - `docs/screenshots/01_trends.png`
> - `docs/screenshots/02_feed.png`
> - `docs/screenshots/03_favorites.png`
> - `docs/screenshots/04_perf_lab.png`

---

## License

MIT (sample / portfolio).
