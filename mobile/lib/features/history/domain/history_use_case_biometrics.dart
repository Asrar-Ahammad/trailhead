import '../../stats/domain/stats_use_case_grade_adjusted_pace.dart';
import 'history_use_case_elevation_gain.dart';

typedef ActivityBiometrics = ({double? pace, double? elevation, int? steps});

ActivityBiometrics activityBiometrics({
  required double? storedPace,
  required double? storedElevation,
  required int? steps,
  required double? cadence,
  required int? duration,
  required List<GapSample> route,
}) => (
  pace: (storedPace ?? 0) > 0 ? storedPace : GapCalculator.computeGap(route),
  elevation: (storedElevation ?? 0) > 0
      ? storedElevation
      : calculateElevationGain(route.map((point) => point.elevation).toList()),
  steps:
      steps ??
      ((cadence ?? 0) > 0 && (duration ?? 0) > 0
          ? (cadence! * duration! / 60).round()
          : null),
);
