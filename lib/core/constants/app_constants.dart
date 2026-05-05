/// Centralized constants. Keeps magic strings/numbers out of feature code.
abstract final class AppConstants {
  static const String appName = 'Smart DevHub';

  // API
  static const String githubBaseUrl = 'https://api.github.com';
  static const String hackerNewsBaseUrl =
      'https://hacker-news.firebaseio.com/v0';

  // Networking
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const int maxRetries = 2;

  // Cache
  static const Duration defaultCacheTtl = Duration(minutes: 15);
  static const Duration trendsCacheTtl = Duration(minutes: 30);
  static const Duration feedCacheTtl = Duration(minutes: 10);

  // Pagination
  static const int defaultPageSize = 20;

  // Background sync
  static const String bgTaskRefreshAll = 'smart_devhub.refresh_all';
  static const Duration bgPeriod = Duration(hours: 1);
}

abstract final class CacheKeys {
  static const String githubTrends = 'github_trends';
  static const String hackerNewsTop = 'hn_top';
  static String hackerNewsItem(int id) => 'hn_item_$id';
}
