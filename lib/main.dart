import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/background/background_sync_service.dart';
import 'core/di/injector.dart';
import 'features/favorites/presentation/bloc/favorites_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();

  // Eagerly resolve the singleton FavoritesBloc so its DB watcher is wired
  // before any tab tries to read its state.
  sl<FavoritesBloc>();

  // Background sync. We don't await registration so cold-start isn't blocked
  // by plugin handshakes; failures are non-fatal and just leave the app
  // without periodic refresh.
  unawaited(_setupBackground());

  runApp(const SmartDevHubApp());
}

Future<void> _setupBackground() async {
  try {
    final svc = sl<BackgroundSyncService>();
    await svc.initialize();
    await svc.registerPeriodicSync();
  } on Object catch (e, st) {
    if (kDebugMode) {
      debugPrint('Background sync registration failed: $e\n$st');
    }
  }
}
