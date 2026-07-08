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
final routePointsProvider = StreamProvider<List<LatLng>>((ref) {
  final trackerState = ref.watch(runTrackerProvider);
  final clientRunId = trackerState.clientRunId;

  if (clientRunId == null) {
    return Stream.value([]);
  }

  // Isar watchLazy() fires whenever any RunPointIsar record changes.
  // We re-query on each event to build the full ordered list.
  return isarInstance.runPointIsars
      .watchLazy()
      .asyncMap((_) async {
    // Isar 3: findAll() is only available on QQueryOperations state.
    // After filter(), we're in QAfterFilterCondition which supports findAll().
    // Sort in Dart to avoid the QAfterSortBy incompatibility.
    final points = await isarInstance.runPointIsars
        .filter()
        .clientRunIdEqualTo(clientRunId)
        .findAll();

    points.sort((a, b) => a.sequence.compareTo(b.sequence));

    return points
        .where((p) => p.lat != null && p.lng != null)
        .map((p) => LatLng(p.lat!, p.lng!))
        .toList();
  });
});
