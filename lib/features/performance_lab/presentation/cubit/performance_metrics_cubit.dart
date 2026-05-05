import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/database/daos/sync_metadata_dao.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/performance/performance_metrics.dart';

class PerformanceMetricsState extends Equatable {
  const PerformanceMetricsState({
    required this.snapshot,
    this.lastSync,
  });

  final PerfSnapshot snapshot;
  final SyncMetadataData? lastSync;

  @override
  List<Object?> get props => [
        snapshot.apiCalls.length,
        snapshot.dbReads.length,
        snapshot.cacheHits,
        snapshot.cacheMisses,
        snapshot.backgroundStatus,
        lastSync?.lastSuccessAt,
        lastSync?.lastStatus,
        lastSync?.lastError,
      ];
}

class PerformanceMetricsCubit extends Cubit<PerformanceMetricsState> {
  PerformanceMetricsCubit(
    PerformanceMetrics metrics, {
    required SyncMetadataDao syncMetadataDao,
  })  : _metrics = metrics,
        _syncDao = syncMetadataDao,
        super(PerformanceMetricsState(snapshot: metrics.snapshot())) {
    _perfSub = metrics.stream.listen((s) => emit(
          PerformanceMetricsState(snapshot: s, lastSync: state.lastSync),
        ));
    _syncSub = _syncDao.watch('refresh_all').listen((sync) => emit(
          PerformanceMetricsState(
            snapshot: state.snapshot,
            lastSync: sync,
          ),
        ));
  }

  final PerformanceMetrics _metrics;
  final SyncMetadataDao _syncDao;
  late final StreamSubscription<PerfSnapshot> _perfSub;
  late final StreamSubscription<SyncMetadataData?> _syncSub;

  @override
  Future<void> close() async {
    await _perfSub.cancel();
    await _syncSub.cancel();
    return super.close();
  }
}
