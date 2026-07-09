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
/// The stream is driven by Isar's live query — updates arrive automatically
/// when the background isolate writes new points.
final routePointsProvider = StreamProvider<List<LatLng>>((ref) async* {
  final trackerState = ref.watch(runTrackerProvider);
  final clientRunId = trackerState.clientRunId;

  if (clientRunId == null) {
    yield [];
    return;
  }

  // Initial fetch
  final initialPoints = await isarInstance.runPointIsars
      .filter()
      .clientRunIdEqualTo(clientRunId)
      .findAll();
  
  initialPoints.sort((a, b) => a.sequence.compareTo(b.sequence));
  yield initialPoints
      .where((p) => p.lat != null && p.lng != null)
      .map((p) => LatLng(p.lat!, p.lng!))
      .toList();

  // Listen for changes
  await for (final _ in isarInstance.runPointIsars.watchLazy()) {
    final points = await isarInstance.runPointIsars
        .filter()
        .clientRunIdEqualTo(clientRunId)
        .findAll();

    points.sort((a, b) => a.sequence.compareTo(b.sequence));

    yield points
        .where((p) => p.lat != null && p.lng != null)
        .map((p) => LatLng(p.lat!, p.lng!))
        .toList();
  }
});
