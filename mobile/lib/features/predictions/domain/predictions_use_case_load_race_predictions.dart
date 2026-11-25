import 'dart:math' as math;

import 'predictions_entity_race_predictions.dart';
import 'predictions_repository_race_predictions.dart';

class LoadRacePredictions {
  const LoadRacePredictions(this._repository);

  final PredictionsRepository _repository;

  static const _distances = [
    ('100m', 100.0),
    ('200m', 200.0),
    ('400m', 400.0),
    ('5K', 5000.0),
    ('10K', 10000.0),
    ('Half Marathon', 21097.5),
    ('Marathon', 42195.0),
  ];

  Future<RacePredictions?> call() async {
    final runs = await _repository.loadRecentRuns(limit: 10);
    PredictionRun? baseline;
    for (final run in runs) {
      if (!run.distanceMeters.isFinite ||
          run.distanceMeters <= 0 ||
          run.durationSeconds <= 0) {
        continue;
      }
      if (baseline == null || run.distanceMeters >= baseline.distanceMeters) {
        baseline = run;
      }
    }
    if (baseline == null) return null;

    final referenceRun = baseline;
    final estimates = List<RaceEstimate>.unmodifiable(
      _distances.map((target) {
        final (label, meters) = target;
        // Riegel formula: T2 = T1 × (D2 / D1)^1.06.
        final seconds =
            referenceRun.durationSeconds *
            math.pow(meters / referenceRun.distanceMeters, 1.06);
        if (!seconds.isFinite) {
          throw StateError('The baseline run produces an invalid estimate.');
        }
        return RaceEstimate(label, meters, seconds.toDouble());
      }),
    );

    return RacePredictions(
      estimates: estimates,
      coachAdvice: await _loadAdvice(referenceRun, estimates),
    );
  }

  Future<String> _loadAdvice(
    PredictionRun baseline,
    List<RaceEstimate> estimates,
  ) async {
    try {
      final advice = (await _repository.loadCoachAdvice(
        baseline,
        estimates,
      ))?.trim();
      if (advice != null && advice.isNotEmpty) return advice;
    } catch (_) {
      // Advice is optional. The estimates are available without it.
    }
    return 'Keep training to achieve these times!';
  }
}
