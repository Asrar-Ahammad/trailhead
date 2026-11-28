import 'run_tracking_use_case_calculations.dart';

class SessionMetrics {
  const SessionMetrics({
    required this.distance,
    required this.duration,
    required this.steps,
    required this.elevation,
    required this.weight,
  });

  final double distance;
  final int duration;
  final int steps;
  final double elevation;
  final double? weight;

  double? get stride => steps > 0 ? distance / steps : null;
  double? get cadence =>
      steps > 0 ? (duration > 0 ? steps * 60 / duration : 0) : null;
  double? get pace => distance > 0 ? duration / (distance / 1000) : null;
  double? get calories => TrackingCalcs.estimateCalories(
    weightKg: weight,
    distanceM: distance,
    durationS: duration,
  );
}
