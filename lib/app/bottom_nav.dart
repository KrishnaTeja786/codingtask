import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/favorites/presentation/pages/favorites_page.dart';
import '../features/github_trends/presentation/pages/github_trends_page.dart';
import '../features/performance_lab/presentation/pages/performance_lab_page.dart';
import '../features/tech_feed/presentation/pages/tech_feed_page.dart';
import 'bottom_nav_cubit.dart';
import 'offline_banner.dart';

/// Top-level shell. Uses [IndexedStack] so each tab keeps its scroll position
/// and BLoC state when the user switches tabs — much better UX than
/// rebuilding from scratch.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const _tabs = <Widget>[
    GithubTrendsPage(),
    TechFeedPage(),
    FavoritesPage(),
    PerformanceLabPage(),
  ];

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.trending_up_outlined),
      selectedIcon: Icon(Icons.trending_up),
      label: 'Trends',
    ),
    NavigationDestination(
      icon: Icon(Icons.article_outlined),
      selectedIcon: Icon(Icons.article),
      label: 'Feed',
    ),
    NavigationDestination(
      icon: Icon(Icons.star_outline),
      selectedIcon: Icon(Icons.star),
      label: 'Favorites',
    ),
    NavigationDestination(
      icon: Icon(Icons.speed_outlined),
      selectedIcon: Icon(Icons.speed),
      label: 'Lab',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BottomNavCubit, int>(
      builder: (context, index) {
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const OfflineBanner(),
                Expanded(
                  child: IndexedStack(index: index, children: _tabs),
                ),
              ],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            destinations: _destinations,
            onDestinationSelected:
                context.read<BottomNavCubit>().select,
          ),
        );
      },
    );
  }
}
