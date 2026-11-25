import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:trailhead_mobile/features/run_tracking/application/route_provider.dart';
import 'package:trailhead_mobile/features/run_tracking/application/run_tracker_controller.dart';

void main() {
  test(
    'a transition during the first route read still clears the map',
    () async {
      final states = StreamController<RunTrackerState>.broadcast(sync: true);
      final reading = Completer<void>();
      final firstSnapshot = Completer<List<LatLng>>();
      final routes = watchRunRouteSnapshots(
        initial: RunTrackerState(status: 'running', clientRunId: 'run-1'),
        changes: states.stream,
        read: (state) async {
          if (state.status == 'idle') return [];
          reading.complete();
          return firstSnapshot.future;
        },
      ).toList();
      await reading.future;
      states.add(RunTrackerState(status: 'idle'));
      final closing = states.close();
      firstSnapshot.complete([const LatLng(1, 2)]);
      expect(await routes, [
        [const LatLng(1, 2)],
        <LatLng>[],
      ]);
      await closing;
    },
  );
}
