import 'predictions_entity_race_predictions.dart';

abstract interface class PredictionsRepository {
  Future<List<PredictionRun>> loadRecentRuns({required int limit});

  Future<String?> loadCoachAdvice(
    PredictionRun baseline,
    List<RaceEstimate> estimates,
  );
}
