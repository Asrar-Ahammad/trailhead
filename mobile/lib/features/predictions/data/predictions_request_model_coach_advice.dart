import 'package:trailhead_mobile/features/predictions/domain/predictions_entity_race_predictions.dart';

class PredictionsCoachAdviceRequestModel {
  const PredictionsCoachAdviceRequestModel({
    required this.age,
    required this.gender,
    required this.baseline,
    required this.estimates,
  });

  final String age;
  final String gender;
  final PredictionRun baseline;
  final List<RaceEstimate> estimates;

  List<Map<String, String>> toMessages() {
    final times = estimates
        .map(
          (estimate) =>
              '${estimate.label}: ${estimate.seconds.toStringAsFixed(2)} seconds',
        )
        .join(', ');
    return [
      {
        'role': 'system',
        'content':
            'You are an elite running coach. Be encouraging and concise.',
      },
      {
        'role': 'user',
        'content':
            'User context: Age: $age, Gender: $gender. '
            'Baseline: ${baseline.distanceMeters} meters in ${baseline.durationSeconds} seconds.\n'
            'Predictions: $times\n'
            'Give one sentence of personalized advice in under 25 words.',
      },
    ];
  }
}
