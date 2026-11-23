import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:isar/isar.dart';
import '../../../main.dart';
import '../data/models/run_point_isar.dart';
import 'run_tracker_controller.dart';

/// Watches [RunPointIsar] records for the current active run and emits an
/// updated [List<LatLng>] whenever new GPS points are written to Isar.
///
/// Emits an empty list when no run is active (status == 'idle' or no clientRunId).
///
/// ⚠️ Why polling instead of watchLazy()?
/// Isar 3's watchLazy() uses an isolate-local ReceivePort — it only fires for
/// transactions committed in the SAME Dart isolate. The LocationTaskHandler
/// background task runs in its own isolate (spawned by flutter_foreground_task)
/// and writes GPS points from there. Those writes are invisible to the main
/// isolate's watcher. Polling every 1.5 s is reliable regardless of isolate
/// topology and adds negligible overhead during a run.
final routePointsProvider = StreamProvider<List<LatLng>>((ref) async* {
  final trackerState = ref.watch(runTrackerProvider);
  final clientRunId = trackerState.clientRunId;

  // No active run — yield empty and stop.
  if (clientRunId == null || trackerState.status == 'idle') {
    yield [];
    return;
  }

  /// Helper that fetches the current sorted points from Isar.
  Future<List<LatLng>> fetchPoints() async {
    final points = await isarInstance.runPointIsars
        .filter()
        .clientRunIdEqualTo(clientRunId)
        .findAll();
    points.sort((a, b) => a.sequence.compareTo(b.sequence));
    return points
        .where((p) => p.lat != null && p.lng != null)
        .map((p) => LatLng(p.lat!, p.lng!))
        .toList();
  }

  // Emit the current snapshot immediately so the map shows existing points
  // without waiting for the first poll tick (e.g. on resume after pause).
  yield await fetchPoints();

  // Poll every 800 milliseconds for new points written to Isar.
  // The timer is cancelled automatically when the StreamProvider is disposed
  // (clientRunId changes or run ends) because the async* generator is torn down.
  await for (final _ in Stream.periodic(const Duration(milliseconds: 800))) {
    yield await fetchPoints();
  }
});

/// Integer counter used as a "re-center map now" signal.
///
/// The location button increments this when tapped. [LiveRunMap] listens for
/// changes and immediately moves the camera to the current GPS position,
/// bypassing the [_lastCenteredAt] de-duplication guard. Using a signal rather
/// than watching state means the map re-centers even when the GPS position
/// hasn't changed (e.g. user panned away and wants to come back).
final recenterSignalProvider = StateProvider<int>((ref) => 0);
