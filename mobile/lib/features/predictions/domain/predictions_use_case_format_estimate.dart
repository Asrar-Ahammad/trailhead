import 'predictions_entity_race_predictions.dart';
import '../../run_tracking/domain/run_tracking_use_case_format_activity.dart';

String formatRaceEstimate(RaceEstimate estimate) {
  if (estimate.distanceMeters <= 400)
    return '${estimate.seconds.toStringAsFixed(2)}s';
  final formatted = RunFormatUtils.formatDuration(estimate.seconds.round());
  return formatted.startsWith('0') ? formatted.substring(1) : formatted;
}
