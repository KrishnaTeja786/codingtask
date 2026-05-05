# Architecture

Smart DevHub is a **Clean Architecture** Flutter app organized by feature, with a small shared `core/` layer.

## Layers

```
┌─────────────────── presentation ───────────────────┐
│  Pages, Widgets, BLoCs/Cubits                      │
│  Depends on: domain                                │
└────────────────────────────────────────────────────┘
                       ▲
                       │
┌─────────────────────domain─────────────────────────┐
│  Entities (pure Dart)                              │
│  Repository interfaces                             │
│  Use cases (single-method classes)                 │
│  No Flutter, no Drift, no Dio.                     │
└────────────────────────────────────────────────────┘
                       ▲
                       │
┌──────────────────────data──────────────────────────┐
│  DTOs (JSON ↔ DTO ↔ entity mapping)                │
│  Remote data sources (Dio)                         │
│  Repository implementations                        │
│  Drift DAOs accessed here                          │
└────────────────────────────────────────────────────┘
```

The dependency rule is enforced by directory layout. There is no lint rule that prevents a domain file from importing Flutter, but every code review should reject any such PR.

## Error model

A sealed `Failure` hierarchy:

```dart
sealed class Failure { ... }
final class NetworkFailure extends Failure { ... }
final class TimeoutFailure extends Failure { ... }
final class ServerFailure extends Failure { final int? statusCode; }
final class ParseFailure extends Failure { ... }
final class CacheFailure extends Failure { ... }
final class NotFoundFailure extends Failure { ... }
final class UnknownFailure extends Failure { ... }
```

Use cases return `Result<T>` — a sealed `Ok<T>` / `Err<T>` pair with `fold`, `map`, `isOk/isErr`, `valueOrNull`, `failureOrNull`. No `try/catch` lives in the presentation layer; failures are exhaustively pattern-matched in BLoCs and surfaced as state.

## State management

`flutter_bloc` exclusively. Choices made:

- **`BLoC`** for streams of events with multiple async paths (search/refresh/paginate). `bloc_concurrency` transformers:
  - `restartable` for query and refresh — cancel any in-flight on a new event
  - `droppable` for "load next page" — ignore taps while already paginating
- **`Cubit`** where the surface is just "external thing changed → emit new state": `BottomNavCubit`, `PerformanceMetricsCubit`.
- **App-scoped** (lazy singleton) for `FavoritesBloc` because it watches the DB and is read across multiple tabs and detail screens.
- **Tab-scoped** (factory) for `GithubTrendsBloc` and `TechFeedBloc` — instantiated on tab build and disposed when the tree leaves.

Rebuild discipline:
- Every consumer uses `BlocSelector` or `BlocBuilder` with `buildWhen` so we never rebuild the whole tree for a status flag flip.
- Detail pages use `BlocSelector<FavoritesBloc, _, bool>` to read just the "is favorited" boolean.

## Data flow: a search request

```
User types → debounced TextField onChanged
  → bloc.add(TrendsQueryChanged(q))
    → SearchRepositoriesUseCase(q, page=1)
      → GithubRepositoryImpl
        ├── CacheDao.get(key)            ← timed via metrics.timeDbRead
        ├── if fresh: return Ok(fromCache: true)
        ├── NetworkInfo.isOnline?
        │   ├── false + cache exists: serve stale
        │   └── false + no cache:     Result.err(NetworkFailure)
        └── DioClient.getJson           ← timed via _TimingInterceptor
            ├── compute(_parseSearch)   ← isolate JSON decode
            ├── CacheDao.put(payload, ttl)
            └── return Ok(items, ...)
```

Failures flow back as `Result.err(Failure)`; the bloc emits `TrendsStatus.failure` and `state.failure` for the UI.

## Offline-first

Every read-heavy repo follows the same template:

1. **Try cache first** for instant first-paint, unless `forceRefresh`.
2. If offline and cache exists, **serve stale**; if offline and no cache, return `NetworkFailure`.
3. On network success, **write to cache** with a TTL and return fresh data.
4. On network failure, **fall back to stale cache** if any.

The presentation layer is given a `fromCache` boolean and a `fetchedAt` timestamp on every snapshot, which it uses to render the "Showing cached data" banner.

## DI

`get_it`, manual registration in `core/di/injector.dart`. Composition order:

1. Singletons: `PerformanceMetrics`, `NetworkInfo`, `DioClient`, `AppDatabase`
2. Lazy singletons: DAOs, datasources, repositories, use cases, `FavoritesBloc`
3. Factories: tab BLoCs, `BottomNavCubit`, `PerformanceMetricsCubit`
4. Singleton: `BackgroundSyncService` with the `SyncJob` closure that reads other singletons

Tests pass `overrideDb: AppDatabase.forTesting(NativeDatabase.memory())` to bypass `path_provider`.

## Routing

`go_router`. The shell at `/` hosts the bottom nav + `IndexedStack`. Detail routes (`/trends/:id`, `/feed/:id`) are pushed on top via `context.push(..., extra: entity)` and re-provide the per-page bloc on demand. They reuse the app-scoped `FavoritesBloc`.

## Background

`BackgroundSyncService` is an interface with two implementations:

- `WorkManagerBackgroundSyncService` — registers a real periodic task with battery + network constraints, idempotent via uniqueName.
- `InProcessBackgroundSyncService` — `Timer.periodic` for tests / local-only scenarios.

The shared `SyncJob` is a closure passed at construction so both implementations execute the same code path.
