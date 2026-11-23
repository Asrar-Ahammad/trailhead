import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';
import 'package:latlong2/latlong.dart';

import '../data/models/run_point_isar.dart';
import 'run_tracker_controller.dart';

/// Tracks route points for the active run and refreshes when Isar changes.
class RouteCubit extends Cubit<List<LatLng>> {
  RouteCubit({required Isar isar, required RunTrackerCubit runTracker})
      : _isar = isar,
        super(const []) {
    _trackerSubscription = runTracker.stream.listen(
      (state) => _watchRun(state.clientRunId),
    );
    _watchRun(runTracker.state.clientRunId);
  }

  final Isar _isar;
  StreamSubscription<RunTrackerState>? _trackerSubscription;
  StreamSubscription<void>? _pointsSubscription;
  int _generation = 0;

  Future<void> _watchRun(String? clientRunId) async {
    final generation = ++_generation;
    await _pointsSubscription?.cancel();
    _pointsSubscription = null;
    if (clientRunId == null) {
      emit(const []);
      return;
    }

    await _refresh(clientRunId, generation);
    if (generation != _generation || isClosed) return;
    _pointsSubscription = _isar.runPointIsars.watchLazy().listen((_) {
      _refresh(clientRunId, generation);
    });
  }

  Future<void> _refresh(String clientRunId, int generation) async {
    final points = await _isar.runPointIsars
        .filter()
        .clientRunIdEqualTo(clientRunId)
        .findAll();
    if (generation != _generation || isClosed) return;
    points.sort((a, b) => a.sequence.compareTo(b.sequence));
    emit(points
        .where((point) => point.lat != null && point.lng != null)
        .map((point) => LatLng(point.lat!, point.lng!))
        .toList(growable: false));
  }

  @override
  Future<void> close() async {
    await _trackerSubscription?.cancel();
    await _pointsSubscription?.cancel();
    await super.close();
  }
}
