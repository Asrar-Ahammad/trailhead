import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'run_tracking_state_live_session.dart';

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
