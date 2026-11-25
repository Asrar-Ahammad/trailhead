import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';
import 'package:isar/isar.dart';
import '../data/models/run_point_isar.dart';
import 'run_tracker_controller.dart';

/// Watches [RunPointIsar] records for the current active run and emits an
/// updated [List<LatLng>] whenever new GPS points are written to Isar.
///
/// Emits an empty list when no run is active (status == 'idle' or no clientRunId).
///
/// Run tracker state changes trigger a fresh Isar snapshot. The background
/// location task updates the tracker in the foreground isolate as GPS samples
/// arrive, so the map does not rely on cross-isolate Isar notifications.
final routePointsProvider = StreamProvider<List<LatLng>>((ref) {
  final tracker = GetIt.instance<RunTrackerCubit>();
  Future<List<LatLng>> fetchPoints(String clientRunId) async {
    final points = await GetIt.instance<Isar>().runPointIsars
        .filter()
        .clientRunIdEqualTo(clientRunId)
        .findAll();
    points.sort((a, b) => a.sequence.compareTo(b.sequence));
    return points
        .where((p) => p.lat != null && p.lng != null)
        .map((p) => LatLng(p.lat!, p.lng!))
        .toList();
  }

  Future<List<LatLng>> pointsForState(RunTrackerState state) async {
    final clientRunId = state.clientRunId;
    if (clientRunId == null || state.status == 'idle') return [];
    return fetchPoints(clientRunId);
  }

  return watchRunRouteSnapshots(
    initial: tracker.state,
    changes: tracker.stream,
    read: pointsForState,
  );
});

Stream<List<LatLng>> watchRunRouteSnapshots({
  required RunTrackerState initial,
  required Stream<RunTrackerState> changes,
  required Future<List<LatLng>> Function(RunTrackerState state) read,
}) => Stream<RunTrackerState>.multi((output) {
  output.add(initial);
  // Subscribe before the initial database read so a stop or pause cannot
  // slip between the first snapshot and the subscription.
  final subscription = changes.listen(
    output.add,
    onError: output.addError,
    onDone: output.close,
  );
  output.onCancel = subscription.cancel;
}).asyncMap(read);

/// Integer counter used as a "re-center map now" signal.
///
/// The location button increments this when tapped. [LiveRunMap] listens for
/// changes and immediately moves the camera to the current GPS position,
/// bypassing the [_lastCenteredAt] de-duplication guard. Using a signal rather
/// than watching state means the map re-centers even when the GPS position
/// hasn't changed (e.g. user panned away and wants to come back).
final recenterSignalProvider = StateProvider<int>((ref) => 0);
