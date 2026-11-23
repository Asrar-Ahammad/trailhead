import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import '../../../shared/state/app_cubits.dart';
import '../../history/data/run_history_repository.dart';
import '../../run_tracking/data/models/run_point_isar.dart';

class RunPointsState {
  const RunPointsState({this.rawPoints = const {}, this.routes = const {}});

  final Map<String, AsyncState<List<RunPointIsar>>> rawPoints;
  final Map<String, AsyncState<List<LatLng>>> routes;

  AsyncState<List<RunPointIsar>> rawFor(String id) =>
      rawPoints[id] ?? const AsyncState.loading();
  AsyncState<List<LatLng>> routeFor(String id) =>
      routes[id] ?? const AsyncState.loading();
}

class RunPointsCubit extends Cubit<RunPointsState> {
  RunPointsCubit({required RunHistoryRepository repository})
    : _repository = repository,
      super(const RunPointsState());

  final RunHistoryRepository _repository;
  final Set<String> _loadingIds = {};

  Future<void> load(String clientRunId) async {
    final current = state.rawFor(clientRunId);
    if (current.status == AsyncStatus.data || _loadingIds.contains(clientRunId))
      return;
    _loadingIds.add(clientRunId);
    final raw = Map<String, AsyncState<List<RunPointIsar>>>.of(state.rawPoints)
      ..[clientRunId] = const AsyncState.loading();
    final routes = Map<String, AsyncState<List<LatLng>>>.of(state.routes)
      ..[clientRunId] = const AsyncState.loading();
    emit(RunPointsState(rawPoints: raw, routes: routes));

    try {
      final points = await _repository.getRunPoints(clientRunId);
      final route = points
          .map((point) => LatLng(point.lat ?? 0.0, point.lng ?? 0.0))
          .toList();
      final loadedRaw = Map<String, AsyncState<List<RunPointIsar>>>.of(
        state.rawPoints,
      )..[clientRunId] = AsyncState.data(points);
      final loadedRoutes = Map<String, AsyncState<List<LatLng>>>.of(
        state.routes,
      )..[clientRunId] = AsyncState.data(route);
      emit(RunPointsState(rawPoints: loadedRaw, routes: loadedRoutes));
    } catch (error, stackTrace) {
      final failedRaw = Map<String, AsyncState<List<RunPointIsar>>>.of(
        state.rawPoints,
      )..[clientRunId] = AsyncState.error(error, stackTrace);
      final failedRoutes = Map<String, AsyncState<List<LatLng>>>.of(
        state.routes,
      )..[clientRunId] = AsyncState.error(error, stackTrace);
      emit(RunPointsState(rawPoints: failedRaw, routes: failedRoutes));
    } finally {
      _loadingIds.remove(clientRunId);
    }
  }
}
