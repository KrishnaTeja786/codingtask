import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin connectivity wrapper. Repos depend on this abstraction so tests can
/// inject a fake without pulling in the connectivity_plus plugin channel.
abstract interface class NetworkInfo {
  Future<bool> get isOnline;
  Stream<bool> get onStatusChange;
}

class ConnectivityNetworkInfo implements NetworkInfo {
  ConnectivityNetworkInfo([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  @override
  Stream<bool> get onStatusChange =>
      _connectivity.onConnectivityChanged.map(_hasConnection);

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }
}
