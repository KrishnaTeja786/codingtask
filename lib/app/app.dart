import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/di/injector.dart';
import '../core/theme/app_theme.dart';
import '../features/favorites/presentation/bloc/favorites_bloc.dart';
import 'bottom_nav_cubit.dart';
import 'router.dart';

/// Root widget. Sets up app-scoped providers (FavoritesBloc, BottomNavCubit)
/// once so descendants — including pushed routes — reuse the same instances.
class SmartDevHubApp extends StatelessWidget {
  const SmartDevHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<BottomNavCubit>(create: (_) => BottomNavCubit()),
        BlocProvider<FavoritesBloc>.value(value: sl<FavoritesBloc>()),
      ],
      child: MaterialApp.router(
        title: 'Smart DevHub',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        routerConfig: buildRouter(),
      ),
    );
  }
}
